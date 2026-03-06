#!/bin/bash
# Create a PR for the current branch (idempotent — returns existing PR if one exists)
# Usage: ./create-pr.sh --title TITLE [--body BODY_OR_FILE] [--invoke]
#        echo "body" | ./create-pr.sh --title TITLE
#
# --body accepts a file path (read from file) or a text string.
# --invoke appends review agent triggers to the PR body (avoids separate trigger comment).
# Idempotent: if a PR already exists for the current branch, outputs its info and exits 0.
# Pushes branch to remote first if not yet pushed.
# Refuses to create a PR from main/master.
#
# Output prefixes (machine-parseable):
#   EXISTS: <url>   — PR already existed
#   CREATED: <url>  — new PR was created

set -euo pipefail

# Check for required dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' (GitHub CLI) is not installed. Please install it to use this script." >&2
  echo "See: https://cli.github.com/" >&2
  exit 1
fi

# --- Argument parsing ---
TITLE=""
BODY=""
INVOKE=false
_SCRATCH_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --title)
      if [[ -z "${2:-}" || "${2:0:2}" == "--" ]]; then
        echo "Error: --title requires a value." >&2
        exit 1
      fi
      TITLE="$2"
      shift 2
      ;;
    --title=*)
      TITLE="${1#--title=}"
      shift
      ;;
    --body)
      if [[ -z "${2:-}" || "${2:0:2}" == "--" ]]; then
        echo "Error: --body requires a value." >&2
        exit 1
      fi
      if [ -f "$2" ]; then
        BODY=$(cat "$2")
        # Remember scratch file for cleanup after successful PR creation
        case "$2" in .agents/scratch/*|*/.agents/scratch/*) _SCRATCH_FILE="$2" ;; esac
      else
        BODY="$2"
      fi
      shift 2
      ;;
    --body=*)
      _val="${1#--body=}"
      if [ -f "$_val" ]; then
        BODY=$(cat "$_val")
        # Remember scratch file for cleanup after successful PR creation
        case "$_val" in .agents/scratch/*|*/.agents/scratch/*) _SCRATCH_FILE="$_val" ;; esac
      else
        BODY="$_val"
      fi
      shift
      ;;
    --invoke)
      INVOKE=true
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 --title TITLE [--body BODY] [--invoke]" >&2
      echo "       echo 'body' | $0 --title TITLE" >&2
      exit 1
      ;;
  esac
done

# Read body from stdin if not provided via --body
if [ -z "$BODY" ] && [ ! -t 0 ]; then
  BODY=$(cat)
fi

# --- Branch safety ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo "Error: Not on a git branch (detached HEAD?)" >&2
  exit 1
fi

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "Error: Refusing to create PR from $BRANCH. Switch to a feature branch first." >&2
  exit 1
fi

# --- Check for existing PR ---
EXISTING_URL=$(gh pr view --json url --jq '.url' 2>/dev/null || echo "")
if [ -n "$EXISTING_URL" ]; then
  # Cleanup scratch file even on idempotent exit (body was already read)
  if [ -n "$_SCRATCH_FILE" ] && [[ "$_SCRATCH_FILE" != *".."* ]]; then
    rm -f -- "$_SCRATCH_FILE"
  fi
  echo "EXISTS: $EXISTING_URL"
  exit 0
fi

# --- Title is required when creating ---
if [ -z "$TITLE" ]; then
  echo "Error: --title is required when creating a new PR." >&2
  echo "Usage: $0 --title TITLE [--body BODY]" >&2
  exit 1
fi

# --- Push branch if not yet on remote ---
if ! git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
  echo "Pushing branch $BRANCH to origin..."
  git push -u origin HEAD
fi

# --- Append review agent triggers if --invoke ---
if $INVOKE; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  TRIGGER_TEXT=$("$SCRIPT_DIR/invoke-review-agents.sh" --format-only)
  if [ -n "$TRIGGER_TEXT" ]; then
    BODY="${BODY:+$BODY

---

}${TRIGGER_TEXT}"
  fi
fi

# --- Create PR ---
CREATE_ARGS=(gh pr create --title "$TITLE")
if [ -n "$BODY" ]; then
  CREATE_ARGS+=(--body "$BODY")
fi

PR_URL=$("${CREATE_ARGS[@]}")

# Auto-cleanup scratch file after successful creation (avoids overwrite permission prompts)
if [ -n "$_SCRATCH_FILE" ] && [[ "$_SCRATCH_FILE" != *".."* ]]; then
  rm -f -- "$_SCRATCH_FILE"
fi

echo "CREATED: $PR_URL"
