#!/bin/bash
# Ensure the working tree is on a non-main branch (idempotent)
# Usage: ./open-branch.sh [BRANCH_NAME]
#
# If already on a non-main/master branch, prints branch name and exits 0.
# If on main/master, creates a new branch, switches to it, and pushes with -u.
# Default branch name: review-loop-YYYYMMDD-HHMMSS

set -euo pipefail

# --- Current branch ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo "Error: Not on a git branch (detached HEAD?)" >&2
  exit 1
fi

# --- Idempotent: already on a feature branch ---
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
  echo "$BRANCH"
  exit 0
fi

# --- On main/master: create and switch to new branch ---
NEW_BRANCH="${1:-review-loop-$(date +%Y%m%d-%H%M%S)}"

if git show-ref --verify --quiet refs/heads/"$NEW_BRANCH"; then
  echo "On $BRANCH — switching to existing branch $NEW_BRANCH..."
  git checkout "$NEW_BRANCH"
else
  echo "On $BRANCH — creating branch $NEW_BRANCH..."
  git checkout -b "$NEW_BRANCH"
fi
git push -u origin "$NEW_BRANCH"

echo "$NEW_BRANCH"
