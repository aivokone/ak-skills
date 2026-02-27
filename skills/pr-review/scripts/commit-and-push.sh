#!/bin/bash
# Stage all changes, commit, and push to tracking remote
# Usage: ./commit-and-push.sh -m MESSAGE
#        echo "message" | ./commit-and-push.sh
#
# Refuses to run on main/master. Never force-pushes.

set -euo pipefail

# --- Argument parsing ---
MESSAGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    -m)
      shift
      MESSAGE="${1:-}"
      shift
      ;;
    -m=*)
      MESSAGE="${1#-m=}"
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 -m MESSAGE" >&2
      echo "       echo 'message' | $0" >&2
      exit 1
      ;;
  esac
done

# Read message from stdin if not provided via -m
if [ -z "$MESSAGE" ] && [ ! -t 0 ]; then
  MESSAGE=$(cat)
fi

if [ -z "$MESSAGE" ]; then
  echo "Error: No commit message provided." >&2
  echo "Usage: $0 -m MESSAGE" >&2
  echo "       echo 'message' | $0" >&2
  exit 1
fi

# --- Branch safety ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo "Error: Not on a git branch (detached HEAD?)" >&2
  exit 1
fi

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "Error: Refusing to commit on $BRANCH. Switch to a feature branch first." >&2
  exit 1
fi

# --- Stage and commit ---
git add -A

if git diff --cached --quiet; then
  echo "Nothing to commit (working tree clean after staging)." >&2
  exit 1
fi

git commit -m "$MESSAGE"
HASH=$(git rev-parse HEAD)
echo "Committed: $HASH"

# --- Push ---
git push
echo "Pushed to origin/$BRANCH"
