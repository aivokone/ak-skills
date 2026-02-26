#!/bin/bash
# Reply to an inline PR review comment
# Usage: ./reply-to-inline.sh <COMMENT_ID> <MESSAGE>
#
# Finds the PR automatically from current branch

set -euo pipefail

# Check for required dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' (GitHub CLI) is not installed. Please install it to use this script." >&2
  echo "See: https://cli.github.com/" >&2
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 <COMMENT_ID> <MESSAGE>" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 123456789 'Fixed. See Fix Report in conversation.'" >&2
  exit 1
fi

COMMENT_ID="$1"
shift
MESSAGE="$*"

PR=$(gh pr view --json number -q .number 2>/dev/null || echo "")
if [ -z "$PR" ]; then
  echo "Error: Couldn't detect current PR from branch" >&2
  echo "" >&2
  echo "Make sure you are:" >&2
  echo "  1. In a git repository root directory" >&2
  echo "  2. On a branch with an open PR" >&2
  echo "" >&2
  echo "Current directory: $(pwd)" >&2
  echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')" >&2
  exit 1
fi

# Derive base repo from PR URL (not head repo — fork PRs would break)
# Uses jq to extract owner/repo, works on github.com and GitHub Enterprise
REPO=$(gh pr view "$PR" --json url -q '.url | split("/pull/")[0] | split("/") | .[-2:] | join("/")' 2>/dev/null)
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi

echo "Replying to comment $COMMENT_ID on PR #$PR..."

gh api -X POST "repos/$REPO/pulls/$PR/comments" \
  -f body="$MESSAGE" \
  -F in_reply_to="$COMMENT_ID" \
  --jq '{url: .html_url, in_reply_to: .in_reply_to_id}'
