#!/bin/bash
# Invoke review agents on a PR by posting a single combined trigger comment
# Usage: ./invoke-review-agents.sh [--agents SLUG,...] [--list] [--format-only] [PR_NUMBER]
#
# Without --agents, invokes all known agents.
# With --agents codex,gemini, invokes only those agents.
# --list shows the agent registry and exits.
# --format-only prints the trigger text to stdout without posting (for embedding in PR body).
#
# If PR_NUMBER not provided, auto-detects from current branch.

set -euo pipefail

# Check for required dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' (GitHub CLI) is not installed. Please install it to use this script." >&2
  echo "See: https://cli.github.com/" >&2
  exit 1
fi

# --- Agent registry (macOS-compatible: indexed arrays, not declare -A) ---
# Add a new agent by:
#   1. Appending its slug to AGENT_SLUGS
#   2. Adding matching entries to AGENT_NAMES and AGENT_USERS arrays (same index)

AGENT_SLUGS=(codex gemini coderabbit)
AGENT_NAMES=("Codex" "Gemini Code Assist" "CodeRabbit")
AGENT_USERS=(chatgpt-codex-connector gemini-code-assist coderabbitai)

# Print the registry table and exit
list_agents() {
  printf "%-15s %-25s %-30s\n" "Slug" "Name" "GitHub user"
  printf "%-15s %-25s %-30s\n" "----" "----" "-----------"
  for i in "${!AGENT_SLUGS[@]}"; do
    printf "%-15s %-25s %-30s\n" "${AGENT_SLUGS[$i]}" "${AGENT_NAMES[$i]}" "${AGENT_USERS[$i]}"
  done
}

# Resolve slug to GitHub username; returns empty + error for unknown slugs
slug_to_user() {
  local slug="$1"
  for i in "${!AGENT_SLUGS[@]}"; do
    if [ "${AGENT_SLUGS[$i]}" = "$slug" ]; then
      echo "${AGENT_USERS[$i]}"
      return 0
    fi
  done
  echo "  Warning: unknown agent slug '$slug' — skipping." >&2
  return 1
}

# --- Argument parsing ---
FILTER_AGENTS=""
LIST_MODE=false
FORMAT_ONLY=false
PR_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --list)
      LIST_MODE=true
      shift
      ;;
    --format-only)
      FORMAT_ONLY=true
      shift
      ;;
    --agents)
      shift
      if [[ -z "${1:-}" || "${1:0:2}" == "--" ]]; then
        echo "Error: --agents requires a value (e.g. --agents gemini,codex)" >&2
        exit 1
      fi
      FILTER_AGENTS="$1"
      shift
      ;;
    --agents=*)
      FILTER_AGENTS="${1#--agents=}"
      shift
      ;;
    [0-9]*)
      PR_ARG="$1"
      shift
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 [--agents SLUG,...] [--list] [PR_NUMBER]" >&2
      exit 1
      ;;
  esac
done

if $LIST_MODE; then
  list_agents
  exit 0
fi

if ! $FORMAT_ONLY; then
  # --- PR detection ---
  PR="${PR_ARG:-$(gh pr view --json number -q .number 2>/dev/null || echo "")}"
  if [ -z "$PR" ]; then
    echo "Error: No PR number provided and couldn't detect current PR" >&2
    echo "" >&2
    echo "Usage: $0 [--agents SLUG,...] [PR_NUMBER]" >&2
    echo "" >&2
    echo "Make sure you are:" >&2
    echo "  1. In a git repository root directory" >&2
    echo "  2. On a branch with an open PR (if not providing PR number)" >&2
    echo "" >&2
    echo "Current directory: $(pwd)" >&2
    echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')" >&2
    exit 1
  fi

  # Derive base repo from PR URL (fork-safe)
  REPO=$(gh pr view "$PR" --json url -q '.url | split("/pull/")[0] | split("/") | .[-2:] | join("/")' 2>/dev/null)
  if [ -z "$REPO" ]; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  fi

  echo "Invoking review agents on PR #$PR in $REPO"
  echo ""
fi

# Build list of slugs to invoke
if [ -n "$FILTER_AGENTS" ]; then
  # Split comma-separated list into array
  IFS=',' read -ra SELECTED <<< "$FILTER_AGENTS"
else
  SELECTED=("${AGENT_SLUGS[@]}")
fi

# Build combined comment body from selected agents
# Most agents trigger on any @-mention; CodeRabbit requires "@coderabbitai review" exactly.
MENTION_LINE=""
EXTRA_LINES=""
INVOKED=0
for slug in "${SELECTED[@]}"; do
  slug="${slug// /}"  # trim any whitespace
  user=$(slug_to_user "$slug") || continue
  INVOKED=$((INVOKED + 1))
  if ! $FORMAT_ONLY; then
    echo "  Including ${slug} (@${user})"
  fi
  if [ "$slug" = "coderabbit" ]; then
    EXTRA_LINES="${EXTRA_LINES}
@${user} review"
  else
    MENTION_LINE="${MENTION_LINE}@${user} "
  fi
done

if [ "$INVOKED" -eq 0 ]; then
  echo "Error: No valid agents selected." >&2
  exit 1
fi

# Build ONE combined comment body
BODY=""
if [ -n "$MENTION_LINE" ]; then
  BODY="${MENTION_LINE}please review this PR."
fi
if [ -n "$EXTRA_LINES" ]; then
  # EXTRA_LINES has a leading newline; strip it when BODY is empty
  if [ -n "$BODY" ]; then
    BODY="${BODY}${EXTRA_LINES}"
  else
    BODY="${EXTRA_LINES:1}"
  fi
fi

if $FORMAT_ONLY; then
  # Print trigger text to stdout (no API call)
  printf '%s\n' "$BODY"
  exit 0
fi

echo ""
echo "Posting combined trigger comment..."
gh pr comment "$PR" --repo "$REPO" --body "$BODY"

echo ""
echo "Done. Invoked $INVOKED agent(s) on PR #$PR with a single comment."
echo "Wait for agent responses, then re-run check-pr-feedback.sh to collect feedback."
