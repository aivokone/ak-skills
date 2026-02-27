#!/bin/bash
# Check for NEW feedback on a PR since a given timestamp (differential check)
# Usage: ./check-new-feedback.sh [PR_NUMBER] --since TIMESTAMP
#
# Like check-pr-feedback.sh but filters for items created after TIMESTAMP
# and excludes comments by the authenticated gh user. Designed for loop mode
# where you need to distinguish new feedback from already-addressed items.

set -euo pipefail

# Check for required dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' (GitHub CLI) is not installed. Please install it to use this script." >&2
  echo "See: https://cli.github.com/" >&2
  exit 1
fi

# --- Argument parsing ---
PR_ARG=""
SINCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --since)
      shift
      SINCE="${1:-}"
      shift
      ;;
    --since=*)
      SINCE="${1#--since=}"
      shift
      ;;
    [0-9]*)
      PR_ARG="$1"
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 [PR_NUMBER] --since TIMESTAMP" >&2
      exit 1
      ;;
  esac
done

if [ -z "$SINCE" ]; then
  echo "Error: --since TIMESTAMP is required." >&2
  echo "Usage: $0 [PR_NUMBER] --since TIMESTAMP" >&2
  echo "" >&2
  echo "Example: $0 --since 2026-02-27T12:00:00Z" >&2
  exit 1
fi

# --- PR detection ---
PR="${PR_ARG:-$(gh pr view --json number -q .number 2>/dev/null || echo "")}"
if [ -z "$PR" ]; then
  echo "Error: No PR number provided and couldn't detect current PR" >&2
  echo "Usage: $0 [PR_NUMBER] --since TIMESTAMP" >&2
  exit 1
fi

# Derive base repo (fork-safe)
REPO=$(gh pr view "$PR" --json url -q '.url | split("/pull/")[0] | split("/") | .[-2:] | join("/")' 2>/dev/null)
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi

# Get authenticated user login (to exclude self-posted comments)
SELF=$(gh api user --jq .login 2>/dev/null || echo "")

echo "Checking new feedback on PR #$PR in $REPO (since $SINCE, excluding @$SELF)"
echo ""

# --- Conversation comments ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 NEW CONVERSATION COMMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
COMMENTS=$(gh api "repos/$REPO/issues/$PR/comments?since=$SINCE" \
  --jq "[.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")] | .[] | \"[\(.id)] [\(.user.login)] \(.created_at | split(\"T\")[0])\n\(.body)\n---\"" 2>/dev/null || echo "")
CONV_COUNT=0
if [ -z "$COMMENTS" ]; then
  echo "None"
else
  printf "%s\n" "$COMMENTS"
  CONV_COUNT=$(gh api "repos/$REPO/issues/$PR/comments?since=$SINCE" \
    --jq "[.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")] | length" 2>/dev/null || echo "0")
fi

# --- Inline comments ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💬 NEW INLINE COMMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INLINE=$(gh api "repos/$REPO/pulls/$PR/comments?since=$SINCE" \
  --jq "[.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")] | .[] | \"[\(.id)] \(.path):\(.line // .original_line) [\(.user.login)]\n\(.body)\n---\"" 2>/dev/null || echo "")
INLINE_COUNT=0
if [ -z "$INLINE" ]; then
  echo "None"
else
  printf "%s\n" "$INLINE"
  INLINE_COUNT=$(gh api "repos/$REPO/pulls/$PR/comments?since=$SINCE" \
    --jq "[.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")] | length" 2>/dev/null || echo "0")
fi

# --- Reviews ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ NEW REVIEWS (state + body)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REVIEWS=$(gh api "repos/$REPO/pulls/$PR/reviews" \
  --jq "[.[] | select(.user.login != \"$SELF\") | select(.submitted_at > \"$SINCE\")] | .[] | \"[\(.id)] \(.state) [\(.user.login)] \(.submitted_at | split(\"T\")[0])\n\(.body // \"No body\")\n---\"" 2>/dev/null || echo "")
REV_COUNT=0
if [ -z "$REVIEWS" ]; then
  echo "None"
else
  printf "%s\n" "$REVIEWS"
  REV_COUNT=$(gh api "repos/$REPO/pulls/$PR/reviews" \
    --jq "[.[] | select(.user.login != \"$SELF\") | select(.submitted_at > \"$SINCE\")] | length" 2>/dev/null || echo "0")
fi

# --- Summary ---
echo ""
echo "Summary: $CONV_COUNT conversation, $INLINE_COUNT inline, $REV_COUNT reviews"
