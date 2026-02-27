#!/bin/bash
# Post a Fix Report as a PR conversation comment
# Usage: ./post-fix-report.sh [PR_NUMBER] [BODY]
#        echo "body" | ./post-fix-report.sh [PR_NUMBER]
#
# PR_NUMBER is optional — auto-detected from current branch if omitted.
# BODY can be passed as argument(s) or via stdin.

set -euo pipefail

# Check for required dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' (GitHub CLI) is not installed. Please install it to use this script." >&2
  echo "See: https://cli.github.com/" >&2
  exit 1
fi

# Parse optional PR number: if first arg is numeric, treat as PR number
PR=""
if [ $# -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
  PR="$1"
  shift
fi

# Auto-detect PR from branch if not provided
if [ -z "$PR" ]; then
  PR=$(gh pr view --json number -q .number 2>/dev/null || echo "")
fi

if [ -z "$PR" ]; then
  echo "Error: No PR number provided and couldn't detect current PR from branch" >&2
  echo "" >&2
  echo "Usage: $0 [PR_NUMBER] [BODY]" >&2
  echo "       echo 'body' | $0 [PR_NUMBER]" >&2
  echo "" >&2
  echo "Make sure you are:" >&2
  echo "  1. In a git repository root directory" >&2
  echo "  2. On a branch with an open PR (if not providing PR number)" >&2
  echo "" >&2
  echo "Current directory: $(pwd)" >&2
  echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')" >&2
  exit 1
fi

# Read body from remaining args or stdin
if [ $# -gt 0 ]; then
  BODY="$*"
elif [ ! -t 0 ]; then
  BODY=$(cat)
else
  echo "Error: No body provided." >&2
  echo "" >&2
  echo "Usage: $0 [PR_NUMBER] BODY" >&2
  echo "       echo 'body' | $0 [PR_NUMBER]" >&2
  exit 1
fi

# Derive base repo from PR URL (not head repo — fork PRs would break)
REPO=$(gh pr view "$PR" --json url -q '.url | split("/pull/")[0] | split("/") | .[-2:] | join("/")' 2>/dev/null)
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi

echo "Posting Fix Report to PR #$PR in $REPO..."

gh pr comment "$PR" --repo "$REPO" --body "$BODY" | cat
