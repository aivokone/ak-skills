#!/usr/bin/env bash
# cli-review-detect.sh — context detection for cli-review-fix skill
# Output: JSON with context type, base branch, CLI availability, diff size
#
# Usage: bash cli-review-detect.sh [full]
#   Pass "full" as argument to force full codebase context.

set -euo pipefail

# Require python3 for JSON output
command -v python3 >/dev/null 2>&1 || { echo >&2 "python3 is required but not installed."; exit 1; }

# CLI availability
CODEX_AVAILABLE=$(command -v codex >/dev/null 2>&1 && echo true || echo false)
GEMINI_AVAILABLE=$(command -v gemini >/dev/null 2>&1 && echo true || echo false)

# Default branch detection
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
  | sed 's@^refs/remotes/origin/@@' || true)
if [ -z "$DEFAULT_BRANCH" ]; then
  if git rev-parse --verify main >/dev/null 2>&1; then
    DEFAULT_BRANCH="main"
  elif git rev-parse --verify master >/dev/null 2>&1; then
    DEFAULT_BRANCH="master"
  else
    DEFAULT_BRANCH=""
  fi
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# Context detection (priority order)
CONTEXT="none"
BASE=""
PR_NUMBER=""
PR_URL=""
PR_TITLE=""
DIFF_LINES=0

# Check for explicit full codebase request
if [ "${1:-}" = "full" ]; then
  CONTEXT="full"
else
  # 1. PR?
  PR_JSON=$(gh pr view --json number,baseRefName,url,title 2>/dev/null || echo "")
  if [ -n "$PR_JSON" ]; then
    CONTEXT="pr"
    # Parse all PR fields in a single python3 call
    eval "$(printf '%s' "$PR_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'BASE={d[\"baseRefName\"]}')
print(f'PR_NUMBER={d[\"number\"]}')
print(f'PR_URL={d[\"url\"]}')
print(f'PR_TITLE={d.get(\"title\",\"\")}')" 2>/dev/null || echo "")"

  # 2. Branch diff?
  elif [ -n "$DEFAULT_BRANCH" ] && [ -n "$CURRENT_BRANCH" ] && \
       [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ] && \
       [ -n "$(git log "${DEFAULT_BRANCH}..HEAD" --oneline 2>/dev/null)" ]; then
    CONTEXT="branch"
    BASE="$DEFAULT_BRANCH"

  # 3. Uncommitted changes?
  elif [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    CONTEXT="uncommitted"
  fi
fi

# Diff size estimate
if [ "$CONTEXT" = "pr" ] || [ "$CONTEXT" = "branch" ]; then
  DIFF_LINES=$(git diff "${BASE}...HEAD" 2>/dev/null | wc -l | tr -d ' ')
elif [ "$CONTEXT" = "uncommitted" ]; then
  DIFF_LINES=$( (git diff --cached 2>/dev/null && git diff 2>/dev/null) | wc -l | tr -d ' ')
fi

# Create scratch directory (after context detection to avoid false git status)
mkdir -p .agents/scratch

# Output JSON (use env vars to avoid shell quoting issues)
CODEX_AVAILABLE="$CODEX_AVAILABLE" \
GEMINI_AVAILABLE="$GEMINI_AVAILABLE" \
CONTEXT="$CONTEXT" \
BASE="$BASE" \
CURRENT_BRANCH="$CURRENT_BRANCH" \
DEFAULT_BRANCH="$DEFAULT_BRANCH" \
DIFF_LINES="$DIFF_LINES" \
PR_NUMBER="$PR_NUMBER" \
PR_URL="$PR_URL" \
PR_TITLE="$PR_TITLE" \
python3 -c "
import json, os
print(json.dumps({
    'codex': os.environ['CODEX_AVAILABLE'] == 'true',
    'gemini': os.environ['GEMINI_AVAILABLE'] == 'true',
    'context': os.environ['CONTEXT'],
    'base': os.environ['BASE'],
    'current_branch': os.environ['CURRENT_BRANCH'],
    'default_branch': os.environ['DEFAULT_BRANCH'],
    'diff_lines': int(os.environ['DIFF_LINES']),
    'pr_number': os.environ['PR_NUMBER'],
    'pr_url': os.environ['PR_URL'],
    'pr_title': os.environ['PR_TITLE'],
}, indent=2))
"
