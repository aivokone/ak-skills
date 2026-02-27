#!/bin/bash
# Wait for new review feedback to appear on a PR after a given timestamp
# Usage: ./wait-for-reviews.sh [PR_NUMBER] --since TIMESTAMP [--timeout 600] [--interval 30]
#
# Polls all three feedback channels (conversation, inline, reviews) for new
# comments posted after TIMESTAMP by users other than the authenticated gh user.
# Exits 0 when new feedback is detected, exits 1 on timeout.

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
TIMEOUT=600
INTERVAL=30

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
    --timeout)
      shift
      TIMEOUT="${1:-600}"
      shift
      ;;
    --timeout=*)
      TIMEOUT="${1#--timeout=}"
      shift
      ;;
    --interval)
      shift
      INTERVAL="${1:-30}"
      shift
      ;;
    --interval=*)
      INTERVAL="${1#--interval=}"
      shift
      ;;
    [0-9]*)
      PR_ARG="$1"
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 [PR_NUMBER] --since TIMESTAMP [--timeout 600] [--interval 30]" >&2
      exit 1
      ;;
  esac
done

if [ -z "$SINCE" ]; then
  echo "Error: --since TIMESTAMP is required." >&2
  echo "Usage: $0 [PR_NUMBER] --since TIMESTAMP [--timeout 600] [--interval 30]" >&2
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

echo "Waiting for new feedback on PR #$PR in $REPO (since $SINCE, timeout ${TIMEOUT}s)"

# --- Poll loop ---
ELAPSED=0

check_new_feedback() {
  local count=0

  # Conversation comments (since parameter is native; paginate for completeness)
  local conv
  conv=$(gh api --paginate "repos/$REPO/issues/$PR/comments?since=$SINCE" \
    --jq "[.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")] | length" 2>/dev/null || echo "0")
  count=$((count + conv))

  # Inline comments (since parameter is native; paginate for completeness)
  local inl
  inl=$(gh api --paginate "repos/$REPO/pulls/$PR/comments?since=$SINCE" \
    --jq "[.[] | select(.user.login != \"$SELF\") | select(.created_at > \"$SINCE\")] | length" 2>/dev/null || echo "0")
  count=$((count + inl))

  # Reviews (no native since — filter with jq; paginate)
  local rev
  rev=$(gh api --paginate "repos/$REPO/pulls/$PR/reviews" \
    --jq "[.[] | select(.user.login != \"$SELF\") | select(.submitted_at > \"$SINCE\")] | length" 2>/dev/null || echo "0")
  count=$((count + rev))

  echo "$count"
}

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  NEW=$(check_new_feedback)
  if [ "$NEW" -gt 0 ]; then
    echo ""
    echo "New feedback detected: $NEW item(s) since $SINCE"
    exit 0
  fi

  echo "[${ELAPSED}s] Waiting for reviews..."
  # Cap sleep to remaining time so we never exceed the timeout
  REMAINING=$((TIMEOUT - ELAPSED))
  SLEEP_FOR=$((INTERVAL < REMAINING ? INTERVAL : REMAINING))
  sleep "$SLEEP_FOR"
  ELAPSED=$((ELAPSED + SLEEP_FOR))
done

echo ""
echo "Timed out after ${TIMEOUT}s — no new feedback detected since $SINCE" >&2
exit 1
