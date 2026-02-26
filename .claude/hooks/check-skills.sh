#!/usr/bin/env bash
# Skill convention checker — runs as a PreToolUse hook before git commit.
# Validates only skills with staged changes. Exits 0 (allow) or 2 (block).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Collect unique skill slugs from staged files
SLUGS=$(git diff --cached --name-only 2>/dev/null \
  | sed -n 's|^skills/\([^/]*\)/.*|\1|p' \
  | sort -u)

# No skill files staged — nothing to check
if [[ -z "$SLUGS" ]]; then
  exit 0
fi

ERRORS=()

fail() {
  ERRORS+=("  [$1] $2")
}

for SLUG in $SLUGS; do
  SKILL_DIR="skills/$SLUG"

  # --- File structure ---
  [[ -f "$SKILL_DIR/SKILL.md" ]]    || fail "$SLUG" "SKILL.md missing"
  [[ -f "$SKILL_DIR/evals.json" ]]  || fail "$SLUG" "evals.json missing"
  [[ -d "$SKILL_DIR/references" ]]  || fail "$SLUG" "references/ directory missing"
  [[ ! -f "$SKILL_DIR/README.md" ]] || fail "$SLUG" "README.md exists (forbidden by convention)"

  # --- SKILL.md frontmatter ---
  if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
    HEAD=$(head -20 "$SKILL_DIR/SKILL.md")

    # Check opening/closing --- delimiters
    FIRST_LINE=$(head -1 "$SKILL_DIR/SKILL.md")
    if [[ "$FIRST_LINE" != "---" ]]; then
      fail "$SLUG" "SKILL.md frontmatter: missing opening ---"
    else
      # Find closing delimiter (second ---)
      CLOSING=$(echo "$HEAD" | tail -n +2 | grep -n '^---$' | head -1 | cut -d: -f1)
      if [[ -z "$CLOSING" ]]; then
        fail "$SLUG" "SKILL.md frontmatter: missing closing ---"
      else
        FRONTMATTER=$(echo "$HEAD" | sed -n "2,$((CLOSING))p")
        echo "$FRONTMATTER" | grep -q '^name:' \
          || fail "$SLUG" "SKILL.md frontmatter: missing 'name' field"
        echo "$FRONTMATTER" | grep -q '^description:' \
          || fail "$SLUG" "SKILL.md frontmatter: missing 'description' field"

        # Check name matches slug
        FM_NAME=$(echo "$FRONTMATTER" | grep '^name:' | sed 's/^name:[[:space:]]*//')
        if [[ "$FM_NAME" != "$SLUG" ]]; then
          fail "$SLUG" "SKILL.md frontmatter: name '$FM_NAME' does not match slug '$SLUG'"
        fi
      fi
    fi

    # Line count
    LINES=$(wc -l < "$SKILL_DIR/SKILL.md")
    if (( LINES >= 500 )); then
      fail "$SLUG" "SKILL.md is $LINES lines (limit: 500)"
    fi
  fi

  # --- evals.json schema ---
  if [[ -f "$SKILL_DIR/evals.json" ]]; then
    if ! jq empty "$SKILL_DIR/evals.json" 2>/dev/null; then
      fail "$SLUG" "evals.json: invalid JSON"
    else
      TYPE=$(jq -r type "$SKILL_DIR/evals.json")
      if [[ "$TYPE" != "array" ]]; then
        fail "$SLUG" "evals.json: expected array, got $TYPE"
      else
        BAD=$(jq '[.[] | select(
          (.name | type) != "string" or
          (.prompt | type) != "string" or
          (.expectations | type) != "array" or
          (.expectations | all(type == "string") | not)
        )] | length' "$SKILL_DIR/evals.json")
        if (( BAD > 0 )); then
          fail "$SLUG" "evals.json: $BAD entries missing name/prompt/expectations"
        fi
      fi
    fi
  fi

  # --- Registry sync ---
  if [[ -f ".claude-plugin/plugin.json" ]]; then
    jq -e --arg s "$SLUG" '.skills | index($s) != null' \
      .claude-plugin/plugin.json >/dev/null 2>&1 \
      || fail "$SLUG" "Not listed in plugin.json skills array"
  fi

  if [[ -f "README.md" ]]; then
    grep -q "$SLUG" README.md \
      || fail "$SLUG" "Not found in README.md"
    grep -qE "^### .+ \(\`$SLUG\`\)" README.md \
      || fail "$SLUG" "No Skill Catalog subsection (### Name (\`$SLUG\`)) in README.md"
  fi

  # --- Secrets scan ---
  SECRETS_PATTERN='AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,}|password[[:space:]]*=[[:space:]]*[^[:space:]]+|secret[[:space:]]*=[[:space:]]*[^[:space:]]+'
  if grep -rEi "$SECRETS_PATTERN" "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references/" 2>/dev/null \
     | grep -viE 'YOUR_|example|xxx|placeholder' > /dev/null 2>&1; then
    fail "$SLUG" "Possible secrets detected in SKILL.md or references/"
  fi
done

if (( ${#ERRORS[@]} > 0 )); then
  echo '{"decision":"block","reason":"Skill convention check failed:\n'"$(printf '%s\\n' "${ERRORS[@]}")"'"}' >&2
  exit 2
fi

exit 0
