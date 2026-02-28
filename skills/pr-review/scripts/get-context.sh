#!/bin/bash
# Detect current branch, PR, changes, and timestamp (entry point for state detection)
# Usage: ./get-context.sh
#
# Outputs key-value pairs:
#   branch: <name>
#   on_default: true|false
#   has_changes: true|false
#   change_summary: <short summary or empty>
#   pr_number: <number or empty>
#   pr_url: <url or empty>
#   pr_state: <OPEN|CLOSED|MERGED or empty>
#   timestamp: <UTC ISO-8601>
#   repo: <owner/repo or empty>
#
# Exits 1 only if not in a git repo or on detached HEAD.
# Gracefully handles missing `gh` (empty PR/repo fields, no error).

set -euo pipefail

# --- Must be in a git repo ---
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not inside a git repository." >&2
  exit 1
fi

# --- Branch ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo "Error: Not on a git branch (detached HEAD?)." >&2
  exit 1
fi

ON_DEFAULT=false
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  ON_DEFAULT=true
fi

# --- Changes ---
HAS_CHANGES=false
CHANGE_SUMMARY=""

STAGED=$(git diff --cached --stat 2>/dev/null || echo "")
UNSTAGED=$(git diff --stat 2>/dev/null || echo "")
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")

if [ -n "$STAGED" ] || [ -n "$UNSTAGED" ] || [ -n "$UNTRACKED" ]; then
  HAS_CHANGES=true
  # Build a compact summary
  PARTS=()
  STAGED_COUNT=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNSTAGED_COUNT=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED_COUNT=$(echo "$UNTRACKED" | grep -c . 2>/dev/null || echo "0")
  [ "$STAGED_COUNT" -gt 0 ] 2>/dev/null && PARTS+=("${STAGED_COUNT} staged")
  [ "$UNSTAGED_COUNT" -gt 0 ] 2>/dev/null && PARTS+=("${UNSTAGED_COUNT} modified")
  [ "$UNTRACKED_COUNT" -gt 0 ] 2>/dev/null && PARTS+=("${UNTRACKED_COUNT} untracked")
  CHANGE_SUMMARY=$(IFS=", "; echo "${PARTS[*]}")
fi

# --- PR and repo (requires gh) ---
PR_NUMBER=""
PR_URL=""
PR_STATE=""
REPO=""

if command -v gh &>/dev/null; then
  # Repo (1 API call)
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

  # PR for current branch (1 API call)
  PR_JSON=$(gh pr view --json number,url,state 2>/dev/null || echo "")
  if [ -n "$PR_JSON" ]; then
    PR_NUMBER=$(echo "$PR_JSON" | grep -o '"number":[0-9]*' | grep -o '[0-9]*' || echo "")
    PR_URL=$(echo "$PR_JSON" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"//' || echo "")
    PR_STATE=$(echo "$PR_JSON" | grep -o '"state":"[^"]*"' | sed 's/"state":"//;s/"//' || echo "")
  fi
fi

# --- Timestamp ---
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Output ---
echo "branch: $BRANCH"
echo "on_default: $ON_DEFAULT"
echo "has_changes: $HAS_CHANGES"
echo "change_summary: $CHANGE_SUMMARY"
echo "pr_number: $PR_NUMBER"
echo "pr_url: $PR_URL"
echo "pr_state: $PR_STATE"
echo "timestamp: $TIMESTAMP"
echo "repo: $REPO"
