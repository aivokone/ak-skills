#!/usr/bin/env bash
# cli-review-codex.sh — focused Codex review wrapper for cli-review-fix
#
# Usage:
#   bash cli-review-codex.sh pr <base>
#   bash cli-review-codex.sh branch <base>
#   bash cli-review-codex.sh uncommitted
#   bash cli-review-codex.sh full
#
# Output:
#   .agents/scratch/codex-review.md
# Optional debug artifacts when CLI_REVIEW_DEBUG_JSON=1:
#   .agents/scratch/codex-review.jsonl
#   .agents/scratch/codex-review.stderr

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  cli-review-codex.sh pr <base>
  cli-review-codex.sh branch <base>
  cli-review-codex.sh uncommitted
  cli-review-codex.sh full
EOF
}

if ! command -v codex >/dev/null 2>&1; then
  echo "codex is required but not installed." >&2
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
PROMPT_FILE="$SKILL_DIR/references/codex-review-prompt.md"
SCRATCH_DIR=".agents/scratch"
OUTPUT_FILE="$SCRATCH_DIR/codex-review.md"
JSON_FILE="$SCRATCH_DIR/codex-review.jsonl"
STDERR_FILE="$SCRATCH_DIR/codex-review.stderr"
DEBUG_JSON="${CLI_REVIEW_DEBUG_JSON:-0}"

mkdir -p "$SCRATCH_DIR"
rm -f "$OUTPUT_FILE" "$JSON_FILE" "$STDERR_FILE"

run_codex() {
  if [ "$DEBUG_JSON" = "1" ]; then
    codex exec - --json -o "$OUTPUT_FILE" >"$JSON_FILE" 2>"$STDERR_FILE"
  else
    codex exec - -o "$OUTPUT_FILE" 2>"$STDERR_FILE"
  fi
}

extract_prompt() {
  awk '
    /^```text$/ { in_block = 1; next }
    /^```$/ && in_block { exit }
    in_block { print }
  ' "$PROMPT_FILE"
}

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

if [ "$CONTEXT" = "full" ]; then
  if [ "$DEBUG_JSON" = "1" ]; then
    codex exec review --json -o "$OUTPUT_FILE" >"$JSON_FILE" 2>"$STDERR_FILE"
  else
    codex exec review -o "$OUTPUT_FILE" 2>"$STDERR_FILE"
  fi
  exit 0
fi

DIFF_FILE="$(mktemp)"
PAYLOAD_FILE="$(mktemp)"
cleanup() {
  rm -f "$DIFF_FILE" "$PAYLOAD_FILE"
}
trap cleanup EXIT

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

extract_prompt >"$PAYLOAD_FILE"
if [ ! -s "$PAYLOAD_FILE" ]; then
  echo "failed to extract prompt text from $PROMPT_FILE" >&2
  exit 1
fi
{
  printf '\n\nReview context: %s' "$CONTEXT"
  if [ -n "$BASE" ]; then
    printf ' (base: %s)' "$BASE"
  fi
  printf '\n\nDiff follows:\n\n'
} >>"$PAYLOAD_FILE"
cat "$DIFF_FILE" >>"$PAYLOAD_FILE"

run_codex <"$PAYLOAD_FILE"
