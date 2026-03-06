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
      if [[ -z "${2:-}" || "${2:0:2}" == "--" ]]; then
        echo "Error: --since requires a value." >&2
        exit 1
      fi
      SINCE="$2"
      shift 2
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

# NOTE: --paginate returns one JSON array per page. We use jq -s 'add // []'
# to merge all pages into a single array before filtering/counting.

# --- Conversation comments ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 NEW CONVERSATION COMMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RAW_COMMENTS=$(gh api --paginate "repos/$REPO/issues/$PR/comments?since=$SINCE" 2>/dev/null \
  | jq -s "add // [] | [.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")]" || echo "[]")
CONV_COUNT=$(echo "$RAW_COMMENTS" | jq 'length' 2>/dev/null || echo "0")
if [ "$CONV_COUNT" -eq 0 ]; then
  echo "None"
else
  echo "$RAW_COMMENTS" | jq -r '.[] | "[\(.id)] [\(.user.login)] \(.created_at | split("T")[0])\n\(.body)\n---"'
fi

# --- Inline comments ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💬 NEW INLINE COMMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RAW_INLINE=$(gh api --paginate "repos/$REPO/pulls/$PR/comments?since=$SINCE" 2>/dev/null \
  | jq -s "add // [] | [.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")]" || echo "[]")
INLINE_COUNT=$(echo "$RAW_INLINE" | jq 'length' 2>/dev/null || echo "0")
if [ "$INLINE_COUNT" -eq 0 ]; then
  echo "None"
else
  echo "$RAW_INLINE" | jq -r '.[] | "[\(.id)] \(.path):\(.line // .original_line) [\(.user.login)]\n\(.body)\n---"'
fi

# --- Reviews ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ NEW REVIEWS (state + body)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RAW_REVIEWS=$(gh api --paginate "repos/$REPO/pulls/$PR/reviews" 2>/dev/null \
  | jq -s "add // [] | [.[] | select(.user.login != \"$SELF\") | select(.submitted_at > \"$SINCE\")]" || echo "[]")
REV_COUNT=$(echo "$RAW_REVIEWS" | jq 'length' 2>/dev/null || echo "0")
if [ "$REV_COUNT" -eq 0 ]; then
  echo "None"
else
  echo "$RAW_REVIEWS" | jq -r '.[] | "[\(.id)] \(.state) [\(.user.login)] \(.submitted_at | split("T")[0])\n\(.body // "No body")\n---"'
fi

# --- Summary ---
echo ""
echo "Summary: $CONV_COUNT conversation, $INLINE_COUNT inline, $REV_COUNT reviews"
