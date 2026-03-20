#!/usr/bin/env bash
# cli-review-gemini.sh — Gemini review wrapper for cli-review-fix
#
# Usage:
#   bash cli-review-gemini.sh pr <base>
#   bash cli-review-gemini.sh branch <base>
#   bash cli-review-gemini.sh uncommitted
#   bash cli-review-gemini.sh full
#
# Output:
#   .agents/scratch/gemini-review.md
#
# For PR/branch contexts, prefers the code-review extension when installed
# (interactive mode — Gemini can read full files). Falls back to rich pipe
# (prompt + full changed files + diff) when extension is unavailable.
# Uncommitted always uses rich pipe. Full codebase uses --all-files.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  cli-review-gemini.sh pr <base>
  cli-review-gemini.sh branch <base>
  cli-review-gemini.sh uncommitted
  cli-review-gemini.sh full
EOF
}

if ! command -v gemini >/dev/null 2>&1; then
  echo "gemini is required but not installed." >&2
  exit 1
fi

CONTEXT="${1:-}"
BASE="${2:-}"
if [ -z "$CONTEXT" ]; then
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_FILE="$SKILL_DIR/references/review-prompt.md"
SCRATCH_DIR=".agents/scratch"
OUTPUT_FILE="$SCRATCH_DIR/gemini-review.md"
STDERR_FILE="$SCRATCH_DIR/gemini-review.stderr"
MAX_FILE_LINES=500

mkdir -p "$SCRATCH_DIR"
rm -f "$OUTPUT_FILE" "$STDERR_FILE"

# --- helpers ---

has_ext() {
  [ -d "${HOME}/.gemini/extensions/code-review" ]
}

# Extract the Nth ```-fenced code block from PROMPT_FILE (1-indexed)
extract_block() {
  local n="$1"
  awk -v target="$n" '
    /^```$/ || /^```[a-z]/ {
      if (in_block) { in_block = 0; count++; next }
      else          { in_block = 1; block++; next }
    }
    in_block && block == target { print }
  ' "$PROMPT_FILE"
}

extract_diff_prompt()  { extract_block 1; }
extract_full_prompt()  { extract_block 2; }

# --- context validation ---

case "$CONTEXT" in
  pr|branch)
    if [ -z "$BASE" ]; then
      echo "base branch is required for '$CONTEXT' reviews" >&2
      exit 1
    fi
    ;;
  uncommitted|full)
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "unknown context: $CONTEXT" >&2
    usage >&2
    exit 1
    ;;
esac

# --- full codebase (always raw --all-files) ---

if [ "$CONTEXT" = "full" ]; then
  PROMPT="$(extract_full_prompt)"
  if [ -z "$PROMPT" ]; then
    echo "failed to extract full codebase prompt from $PROMPT_FILE" >&2
    exit 1
  fi
  gemini --all-files --model pro -p "$PROMPT" --sandbox >"$OUTPUT_FILE" 2>"$STDERR_FILE"
  exit 0
fi

# --- diff-based contexts ---

DIFF_FILE="$(mktemp)"
PAYLOAD_FILE="$(mktemp)"
cleanup() {
  rm -f "$DIFF_FILE" "$PAYLOAD_FILE"
}
trap cleanup EXIT

# Build diff
case "$CONTEXT" in
  pr|branch)
    git diff "${BASE}...HEAD" >"$DIFF_FILE"
    ;;
  uncommitted)
    {
      git diff --cached
      git diff
    } >"$DIFF_FILE"
    ;;
esac

if [ ! -s "$DIFF_FILE" ]; then
  printf 'No findings.\n' >"$OUTPUT_FILE"
  exit 0
fi

# --- extension mode (PR/branch only, when installed) ---

run_extension() {
  # Warn if origin/HEAD differs from provided base
  if [ -n "$BASE" ]; then
    local origin_head
    origin_head=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
      | sed 's@^refs/remotes/origin/@@' || true)
    if [ -n "$origin_head" ] && [ "$origin_head" != "$BASE" ]; then
      echo "WARNING: extension diffs against origin/HEAD ($origin_head) but base is $BASE" >&2
    fi
  fi
  gemini "/code-review" --yolo -e code-review >"$OUTPUT_FILE" 2>"$STDERR_FILE"
}

# --- rich pipe mode (prompt + full changed files + diff) ---

run_rich_pipe() {
  local prompt
  prompt="$(extract_diff_prompt)"
  if [ -z "$prompt" ]; then
    echo "failed to extract diff review prompt from $PROMPT_FILE" >&2
    exit 1
  fi

  # Build payload: prompt + full changed files + diff
  printf '%s' "$prompt" >"$PAYLOAD_FILE"
  {
    printf '\n\nReview context: %s' "$CONTEXT"
    if [ -n "$BASE" ]; then
      printf ' (base: %s)' "$BASE"
    fi

    # Collect changed file paths
    local changed_files
    case "$CONTEXT" in
      pr|branch)
        changed_files=$(git diff --name-only "${BASE}...HEAD" 2>/dev/null || true)
        ;;
      uncommitted)
        changed_files=$({ git diff --cached --name-only; git diff --name-only; } | sort -u)
        ;;
    esac

    if [ -n "$changed_files" ]; then
      printf '\n\nChanged files (full content for reference):\n'
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        # Skip binary files
        if file --brief "$f" 2>/dev/null | grep -qi binary; then
          printf '\n=== %s === (binary, skipped)\n' "$f"
          continue
        fi
        # Skip files that are too large
        local line_count
        line_count=$(wc -l < "$f" 2>/dev/null || echo 0)
        line_count=$(echo "$line_count" | tr -d ' ')
        if [ "$line_count" -gt "$MAX_FILE_LINES" ]; then
          printf '\n=== %s === (%s lines, skipped — exceeds %s line limit)\n' "$f" "$line_count" "$MAX_FILE_LINES"
          continue
        fi
        # Skip deleted files
        if [ ! -f "$f" ]; then
          printf '\n=== %s === (deleted)\n' "$f"
          continue
        fi
        printf '\n=== %s ===\n' "$f"
        cat "$f"
      done <<< "$changed_files"
    fi

    printf '\n\nDiff follows:\n\n'
  } >>"$PAYLOAD_FILE"
  cat "$DIFF_FILE" >>"$PAYLOAD_FILE"

  gemini --model pro -p - --sandbox <"$PAYLOAD_FILE" >"$OUTPUT_FILE" 2>"$STDERR_FILE"
}

# --- dispatch ---

if [ "$CONTEXT" = "uncommitted" ]; then
  # Extension does not support uncommitted — always rich pipe
  run_rich_pipe
elif has_ext; then
  # PR/branch with extension installed — try extension, fall back to rich pipe
  if ! run_extension; then
    echo "WARNING: extension failed (exit $?), falling back to rich pipe" >&2
    run_rich_pipe
  fi
else
  # PR/branch without extension — rich pipe
  run_rich_pipe
fi
