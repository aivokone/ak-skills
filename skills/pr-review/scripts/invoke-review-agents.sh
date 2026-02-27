#!/bin/bash
# Invoke review agents on a PR by posting trigger comments
# Usage: ./invoke-review-agents.sh [--agents SLUG,...] [--list] [PR_NUMBER]
#
# Without --agents, invokes all known agents.
# With --agents codex,gemini, invokes only those agents.
# --list shows the agent registry and exits.
#
# If PR_NUMBER not provided, auto-detects from current branch.

set -euo pipefail

# Check for required dependencies
if ! command -v gh &> /dev/null; then
  echo "Error: 'gh' (GitHub CLI) is not installed. Please install it to use this script." >&2
  echo "See: https://cli.github.com/" >&2
  exit 1
fi

# --- Agent registry (macOS-compatible: indexed arrays + case, not declare -A) ---
# Add a new agent by:
#   1. Appending its slug to AGENT_SLUGS
#   2. Adding matching entries to AGENT_NAMES and AGENT_USERS arrays (same index)
#   3. Adding a case block in the invoke_agent() function below

AGENT_SLUGS=(codex gemini coderabbit)
AGENT_NAMES=("Codex" "Gemini Code Assist" "CodeRabbit")
AGENT_USERS=(codex gemini-code-assist coderabbitai)

# Print the registry table and exit
list_agents() {
  printf "%-15s %-22s %-20s %s\n" "Slug" "Name" "GitHub user" "Trigger type"
  printf "%-15s %-22s %-20s %s\n" "----" "----" "-----------" "------------"
  for i in "${!AGENT_SLUGS[@]}"; do
    slug="${AGENT_SLUGS[$i]}"
    name="${AGENT_NAMES[$i]}"
    user="${AGENT_USERS[$i]}"
    case "$slug" in
      codex)      trigger="@-mention (1 comment)";;
      gemini)     trigger="@-mention (1 comment)";;
      coderabbit) trigger="@-mention (1 comment)";;
      *)          trigger="@-mention (1 comment)";;
    esac
    printf "%-15s %-22s %-20s %s\n" "$slug" "$name" "$user" "$trigger"
  done
}

# Post the trigger comment(s) for a single agent
# Args: $1=slug  $2=REPO  $3=PR
invoke_agent() {
  local slug="$1"
  local repo="$2"
  local pr="$3"

  case "$slug" in
    codex)
      echo "  → Invoking Codex (@codex)..."
      gh pr comment "$pr" --repo "$repo" --body "@codex please review this PR."
      ;;
    gemini)
      echo "  → Invoking Gemini (@gemini-code-assist)..."
      gh pr comment "$pr" --repo "$repo" --body "@gemini-code-assist please review this PR."
      ;;
    coderabbit)
      echo "  → Invoking CodeRabbit (@coderabbitai)..."
      gh pr comment "$pr" --repo "$repo" --body "@coderabbitai review"
      ;;
    *)
      echo "  Warning: unknown agent slug '$slug' — skipping." >&2
      return 1
      ;;
  esac
}

# --- Argument parsing ---
FILTER_AGENTS=""
LIST_MODE=false
PR_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --list)
      LIST_MODE=true
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

# Build list of slugs to invoke
if [ -n "$FILTER_AGENTS" ]; then
  # Split comma-separated list into array
  IFS=',' read -ra SELECTED <<< "$FILTER_AGENTS"
else
  SELECTED=("${AGENT_SLUGS[@]}")
fi

# Invoke each selected agent
INVOKED=0
for slug in "${SELECTED[@]}"; do
  slug="${slug// /}"  # trim any whitespace
  if invoke_agent "$slug" "$REPO" "$PR"; then
    INVOKED=$((INVOKED + 1))
  fi
done

echo ""
if [ "$INVOKED" -eq 0 ]; then
  echo "Error: No agents were successfully invoked on PR #$PR." >&2
  exit 1
fi
echo "Done. Invoked $INVOKED agent(s) on PR #$PR."
echo "Wait for agent responses, then re-run check-pr-feedback.sh to collect feedback."
