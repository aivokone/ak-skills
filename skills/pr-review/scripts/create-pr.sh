#!/bin/bash
# Create a PR for the current branch (idempotent — returns existing PR if one exists)
# Usage: ./create-pr.sh --title TITLE [--body BODY]
#        echo "body" | ./create-pr.sh --title TITLE
#
# Idempotent: if a PR already exists for the current branch, outputs its info and exits 0.
# Pushes branch to remote first if not yet pushed.
# Refuses to create a PR from main/master.

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
      BODY="$2"
      shift 2
      ;;
    --body=*)
      BODY="${1#--body=}"
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 --title TITLE [--body BODY]" >&2
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
EXISTING=$(gh pr view --json number,url --jq '"PR #\(.number) \(.url)"' 2>/dev/null || echo "")
if [ -n "$EXISTING" ]; then
  echo "$EXISTING"
  echo "(PR already exists for branch $BRANCH)"
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

# --- Create PR ---
CREATE_ARGS=(gh pr create --title "$TITLE")
if [ -n "$BODY" ]; then
  CREATE_ARGS+=(--body "$BODY")
fi

PR_URL=$("${CREATE_ARGS[@]}")
PR_NUM=${PR_URL##*/}

echo "PR #$PR_NUM $PR_URL"
