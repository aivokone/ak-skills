---
name: pr-review
description: Use FIRST for any PR/code review work — checking feedback, reading CR comments, responding to reviewers, addressing review bot or human comments, or preparing commits on a PR. Collects feedback from ALL sources (conversation, inline, reviews) to prevent the common failure of missing inline feedback. Start with check-pr-feedback.sh, then reply inline where needed and summarize with one Fix Report.
---

# PR Review Workflow

Systematic workflow for checking, responding to, and reporting on PR feedback from any source — human reviewers, review bots (CodeRabbit, Gemini, Codex, Snyk, etc.), or AI agents.

**Requirements:** GitHub repository with [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated.

**Key insight:** PR feedback arrives through three different channels (conversation comments, inline threads, review submissions). Missing any channel means missing feedback. This skill ensures all channels are checked systematically.

## Quick Commands

**Script path resolution:** Before running any script, determine the correct base path. Check in this order:
1. `~/.claude/skills/pr-review/scripts/` — global install for Claude Code
2. Other global paths by preference of the agent

Use whichever path exists. Script paths below use the global form; substitute accordingly for your agent or install method.

### Open Branch (Idempotent)

```bash
~/.claude/skills/pr-review/scripts/open-branch.sh [BRANCH_NAME]
```

If already on a non-main/master branch, prints branch name and exits. If on main/master, creates branch, switches, and pushes with `-u`. Default name: `review-loop-YYYYMMDD-HHMMSS`.

### Check All Feedback (CRITICAL - Use First)

```bash
~/.claude/skills/pr-review/scripts/check-pr-feedback.sh [PR_NUMBER]
```

Checks all three channels: conversation comments, inline comments, reviews.

If no PR number provided, detects current PR from branch.

### Reply to Inline Comment

```bash
~/.claude/skills/pr-review/scripts/reply-to-inline.sh <COMMENT_ID> "Your message"
```

Replies in-thread to inline comments. Uses `-F` flag (not `--raw-field`) which properly handles numeric ID conversion in `gh` CLI.

**Must be run from repository root** with an active PR branch.

**Important:** Always sign inline replies with your agent identity (e.g., `—Claude Sonnet 4.5`, `—GPT-4`, `—Custom Agent`) to distinguish agent responses from human responses in the GitHub UI.

### Invoke Review Agents

```bash
~/.claude/skills/pr-review/scripts/invoke-review-agents.sh [--agents SLUG,...] [--format-only] [PR_NUMBER]
```

Posts trigger comments to start agent reviews. Without `--agents`, invokes all known agents (Codex, Gemini, CodeRabbit). Use `--list` to see available agents. Use `--format-only` to print trigger text to stdout without posting (for embedding in PR body).

### Post Fix Report

```bash
~/.claude/skills/pr-review/scripts/post-fix-report.sh [PR_NUMBER] /tmp/fix-report.md
```

Or via stdin:

```bash
echo "$body" | ~/.claude/skills/pr-review/scripts/post-fix-report.sh [PR_NUMBER]
```

### Create PR (Idempotent)

```bash
~/.claude/skills/pr-review/scripts/create-pr.sh --title "PR title" --body /tmp/pr-body.md [--invoke]
```

Or body as text string or via stdin:

```bash
~/.claude/skills/pr-review/scripts/create-pr.sh --title "PR title" --body "Short description"
echo "Description" | ~/.claude/skills/pr-review/scripts/create-pr.sh --title "PR title"
```

`--body` auto-detects: if the value is a readable file, reads from it; otherwise treats as text. Idempotent: if a PR already exists, outputs its info. Refuses to run on `main`/`master`. Pushes branch if not yet pushed.

`--invoke` appends review agent trigger text to the PR body (via `invoke-review-agents.sh --format-only`), avoiding a separate trigger comment that causes double-invocations when auto-review is enabled.

Output prefixes (machine-parseable):
- `EXISTS: <url>` — PR already existed for this branch
- `CREATED: <url>` — new PR was created

### Commit and Push

```bash
~/.claude/skills/pr-review/scripts/commit-and-push.sh -m "fix: address review feedback"
```

Or message via stdin:

```bash
echo "fix: address review feedback" | ~/.claude/skills/pr-review/scripts/commit-and-push.sh
```

Stages all changes, commits, and pushes. Refuses to run on `main`/`master`. Never force-pushes. Outputs commit hash and branch.

### Wait for Reviews

```bash
~/.claude/skills/pr-review/scripts/wait-for-reviews.sh [PR_NUMBER] --since TIMESTAMP [--timeout 600] [--interval 30]
```

Polls all three feedback channels for new comments posted after `TIMESTAMP` by non-self users. Exits 0 when new feedback detected, exits 1 on timeout. Default: 10 min timeout, 30s interval.

### Check New Feedback (Differential)

```bash
~/.claude/skills/pr-review/scripts/check-new-feedback.sh [PR_NUMBER] --since TIMESTAMP
```

Like `check-pr-feedback.sh` but only shows feedback created after `TIMESTAMP`, excluding self-posted comments. Use in loop mode to distinguish new from already-addressed feedback. Ends with a summary line: `Summary: N conversation, M inline, K reviews`.

## Commit Workflows

### Quick Commit (No Approval)

Allowed when:
- Not on `main`/`master`
- No `--force` needed
- Changes clearly scoped

```bash
git add -A
git commit -m "<type>: <outcome>"
git push  # if requested
```

Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`

### Safe Commit (With Inspection)

Required for `main`/`master` or ambiguous changes:

1. Inspect: `git status --porcelain && git diff --stat`
2. Wait for approval if ambiguous
3. Stage selectively: `git add -A` or `git add -p <files>`
4. Commit: `git commit -m "<type>: <outcome>"`
5. Push (never `--force`)
6. Report: branch, commit hash, pushed (yes/no)

### Self-Check Before Commit

Before committing, verify:

1. **Test changes** - If modifying working code based on suggestions, test first
2. **Check latest feedback** - Run feedback check script to catch new comments
3. **User confirmation** - If user is active in session, ask before committing
4. **Verify claims** - If Fix Report says "verified:", actually verify

Example check:

```bash
# 1. Test changes (run project-specific tests)
npm test  # or: pytest, go test, etc.

# 2. Check for new feedback since last check (use ROUND_START from loop)
~/.claude/skills/pr-review/scripts/check-new-feedback.sh --since "$ROUND_START"
# (prevents "ready to merge" when new comments exist)

# 3. If user active: "Ready to commit these changes?"
```

## PR Creation

### Set Up Template (Once)

Create `.github/pull_request_template.md`:

```markdown
## Summary
-

## How to test
-

## Notes
- Review feedback may arrive in conversation comments, inline threads, or review submissions. Check all channels.
```

Or copy from `assets/pr_template.md`.

### Create PR

Fill Summary, How to test, and Notes sections.

## Code Review Coordination

### Feedback Channels

| Channel | Reviewer Type | Format |
|---------|---------------|--------|
| Conversation | AI agents, humans | Top-level comments |
| Inline | Review bots (CodeRabbit, Gemini, Codex, Snyk, etc.), humans | File/line threads |
| Reviews | Humans, some bots | Approve/Request Changes + optional body |

### Critical Rule: Check ALL Three Channels

```bash
~/.claude/skills/pr-review/scripts/check-pr-feedback.sh
```

**Why:** Different reviewers post in different channels. Missing any channel = missing feedback.

Three channels:

1. **Conversation comments** — general discussion, agent reviews
2. **Inline comments** — file/line-specific feedback from any reviewer
3. **Reviews** — approval state + optional body

### Critical Evaluation of Feedback

**Never trust review feedback at face value.** Before acting on any comment — whether from a human reviewer, review bot, or AI agent — critically evaluate it:

1. **Verify the claim** — Read the actual code being referenced. Does the reviewer's description match reality? Reviewers (especially bots) may misread context, reference wrong lines, or describe code that doesn't exist.
2. **Check for hallucinations** — Review bots may fabricate issues: non-existent variables, imagined type mismatches, phantom security vulnerabilities. Always confirm the issue exists before fixing it.
3. **Assess correctness** — Even if the issue is real, the suggested fix may be wrong. Evaluate whether the suggestion would break existing behavior, introduce regressions, or conflict with project conventions.
4. **Test before committing** — If a suggestion modifies working code, run tests before and after to confirm the change is actually an improvement.

If a review comment is incorrect, respond with a clear explanation of why rather than applying a bad fix. Use WONTFIX status with reasoning in the Fix Report.

### Responding to Inline Comments

1. **Critically evaluate the feedback** (see above), then address it in code if valid
2. **Reply inline** to each comment (sign with agent identity):

```bash
~/.claude/skills/pr-review/scripts/reply-to-inline.sh <COMMENT_ID> "Fixed @ abc123. [details] —[Your Agent Name]"
```

3. **Include in Fix Report** (conversation comment) — the Fix Report summarizes all changes, but inline replies ensure each comment gets a direct acknowledgment

## Invoking Review Agents

Run `invoke-review-agents.sh` when `check-pr-feedback.sh` returns empty output from **all three channels** — no feedback means no agents have reviewed yet.

```bash
# No feedback on the PR? Invoke all agents:
~/.claude/skills/pr-review/scripts/invoke-review-agents.sh

# User mentioned specific agents (e.g., "ask Gemini and Codex to review"):
~/.claude/skills/pr-review/scripts/invoke-review-agents.sh --agents gemini,codex
```

**Agent selection from prompt:** If the user's prompt names specific agents (e.g., "have Codex review this"), use `--agents` with the matching slug(s). Otherwise invoke all.

**Embedding in PR body:** When creating a new PR with `create-pr.sh --invoke`, trigger text is appended to the PR body automatically (via `--format-only`). This avoids a separate trigger comment that would cause double-invocations when auto-review is enabled. Only use `invoke-review-agents.sh` directly when the PR already exists.

**After invoking:** Inform the user that trigger comments were posted and suggest running `check-pr-feedback.sh` again once agents have had time to respond (typically a few minutes).

**See `references/review-agents.md` for the full agent registry and instructions for adding new agents.**

## Fix Reporting

After addressing feedback, **always** post ONE conversation comment (Fix Report). This is separate from requesting re-review — the Fix Report documents what was done, even if no re-review is needed.

Use the script to post it:

```bash
cat <<'EOF' | ~/.claude/skills/pr-review/scripts/post-fix-report.sh
### Fix Report

- [file.ext:L10 Symbol]: FIXED @ abc123 — verified: `npm test` passes
- [file.ext:L42 fn]: WONTFIX — reason: intentional per AGENTS.md
- [file.ext:L100 class]: DEFERRED — tracking: #123
- [file.ext:L200 method]: QUESTION — Should this handle X?
EOF
```

Optionally, if re-review is needed, add `@reviewer-username please re-review.` at the end of the body.

### Fix Statuses

| Status | Required Info |
|--------|---------------|
| FIXED | Commit hash + verification command/result |
| WONTFIX | Reason (cite docs if applicable) |
| DEFERRED | Issue/ticket link |
| QUESTION | Specific question to unblock |

**See `references/fix-report-examples.md` for real-world examples.**

Use `assets/fix-report-template.md` as starting point.

## Review Format (For Agent-Reviewers)

Agent-reviewers MUST post ONE top-level conversation comment:

```markdown
### Review - Actionable Findings

**Blocking**
- path/file.ext:L10-L15 (Symbol): Issue → Fix → Verify: `command`

**Optional**
- path/file.ext:L100 (class): Improvement → Fix
```

Rules:

- Blocking MUST include verification (runnable command or objective check)
- Use `file:line` + symbol anchor
- Actionable, not prose
- Group by severity

**Do NOT:**

- Create inline file/line comments
- Submit GitHub review submissions
- Post multiple separate comments

**Why:** Inline comments harder to retrieve. Conversation comments deterministic.

## Re-Review Loop

After Fix Report:

1. **Request re-review**: `@reviewer please re-review. See Fix Report.`
2. **Tag ALL reviewers** who provided feedback
3. **If QUESTION items**: Wait for clarification
4. **If blocking feedback was only provided inline**: Mention it was addressed, optionally ask to mirror to conversation for future determinism

## Loop Mode

Activate when the user's prompt requests a review loop, review cycle, or similar — in any words — meaning: run the full review-fix-review cycle autonomously until no new feedback remains.

**Default max rounds: 5.** Override with user instruction if needed.

**Loop workflow:**

0. **Branch** — `open-branch.sh` (idempotent — creates branch if on main/master)
1. **PR** — `create-pr.sh --invoke --title "..." --body /tmp/pr-body.md` — capture output prefix (`CREATED:` / `EXISTS:`)
2. **Timestamp** — capture `ROUND_START=$(date -u +%Y-%m-%dT%H:%M:%SZ); ROUND=$((ROUND+1))`
3. **Invoke** — Round 1: if step 1 output `CREATED:`, skip (triggers in PR body). If `EXISTS:`, run `invoke-review-agents.sh`. Rounds 2+: agents triggered by @-mentions in previous Fix Report footer (no separate invoke step)
4. **Wait** — `wait-for-reviews.sh --since $ROUND_START` (polls until new feedback or timeout)
5. **Check** — `check-new-feedback.sh --since $ROUND_START` (shows only new items)
6. **Fix** — address all new feedback (critically evaluate each item first)
7. **Commit** — `commit-and-push.sh -m "fix: address review feedback round N"`
8. **Reply inline** — `reply-to-inline.sh` for each inline comment; sign with agent identity; tag the reviewer's `@github-user`
9. **Fix Report** — `post-fix-report.sh $PR /tmp/fix-report.md`
   - Before max: footer has @-mentions + `@coderabbitai review` on its own line
   - At max: footer has max-reached message (see below)
10. **Loop** — if `ROUND < MAX_ROUNDS`, go to step 2

**Termination conditions** (any):
- `check-new-feedback.sh` summary reports 0 new items across all channels
- `wait-for-reviews.sh` times out (no new feedback after invocation)
- A reviewer posts an Approve review
- User explicitly stops the loop
- Max rounds reached

**Final round Fix Report footer:**

```markdown
Max review rounds (N) reached. Remaining items addressed above. Manual re-review recommended.
```

**Inline reply tagging:** When replying to a bot/agent inline comment, include the reviewer's GitHub username in the reply (e.g., `—Claude Sonnet 4.6 | addressed @gemini-code-assist feedback`).

**See `references/fix-report-examples.md` Examples 7–8 for loop-mode Fix Reports.**

## Multi-Reviewer Patterns

### Duplicate Feedback

If multiple reviewers flag the same issue:

```markdown
- [file.php:L42 (ALL flagged)]: FIXED @ abc123 — verified: `npm test` passes
  - Gemini: "use const"
  - Codex: "prefer immutable"
  - Claude: "const prevents reassignment"
```

### Conflicting Suggestions

```markdown
- [file.php:L100]: QUESTION — Gemini suggests pattern A, Codex suggests pattern B. Which aligns with project conventions? See AGENTS.md.
```

### Finding Comments by Reviewer

```bash
# Set REPO and PR for your context
REPO="owner/repo"  # or: gh repo view --json nameWithOwner -q .nameWithOwner
PR=42               # or: gh pr view --json number -q .number

# Find comments by a specific reviewer (e.g., CodeRabbit, Gemini)
gh api repos/$REPO/pulls/$PR/comments \
  --jq '.[] | select(.user.login | contains("coderabbitai")) | {id, line, path, body}'
```

## Troubleshooting

**"Can't find review comments"**
→ Check all three channels. Use `~/.claude/skills/pr-review/scripts/check-pr-feedback.sh`, not just `gh pr view`.

**"Reviewer posted inline, should I reply inline?"**
→ Yes, always. Reply inline with a brief ack so the comment can be resolved in GitHub UI. Also include in Fix Report.

**"Multiple reviewers flagged same issue"**
→ Fix once, report once (note all sources), tag all reviewers.

**"Conflicting suggestions"**
→ Mark QUESTION, check project docs, cite specific suggestions.

**"Script can't detect PR"**
→ Run from repository root. Must be on branch with open PR.

**"Reply script fails with HTTP 422"**
→ Use `-F in_reply_to=ID` not `--raw-field`. The `-F` flag works correctly with `gh` CLI for numeric IDs.

**"Review suggestion broke working code"**
→ Never trust suggestions blindly. Verify the issue exists, evaluate the fix, and test before committing. Review bots frequently hallucinate problems or suggest incorrect fixes.

**"No feedback on PR — all three channels empty"**
→ Agents haven't reviewed yet. Run `~/.claude/skills/pr-review/scripts/invoke-review-agents.sh` to trigger them, then wait and re-check.

**"Committed before checking latest feedback"**
→ Run feedback check script immediately before declaring PR "ready" or "complete."

## Summary

**Key principles:**

1. Always check all three channels (conversation + inline + reviews)
2. **Critically evaluate every comment** — reviewers can be wrong, misread context, or hallucinate issues
3. Any reviewer (human, bot, agent) can post in any channel
4. One Fix Report per round
5. Tag all reviewers explicitly
6. If no feedback exists, invoke agents first — never declare a PR complete without at least one review round

**Most common mistakes:**
❌ Only checking conversation or `gh pr view`
✅ Always run `~/.claude/skills/pr-review/scripts/check-pr-feedback.sh`

❌ Blindly applying review suggestions without verifying the issue exists
✅ Read the actual code, confirm the problem, test the fix
