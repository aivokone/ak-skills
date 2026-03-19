---
name: cli-review-fix
disable-model-invocation: true
description: "Send code review requests to external CLI tools (Codex CLI, Gemini CLI), critically evaluate findings, fix valid issues, and present a fix report. Auto-detects context (PR, branch, uncommitted changes). Run /cli-review-fix to launch all available CLIs, or /cli-review-fix codex for a specific one."
---

# CLI Review & Fix

Dispatch code review requests to external CLI agents (Codex CLI, Gemini CLI),
critically evaluate their findings, fix valid issues, and present a consolidated
fix report. Runs CLIs in parallel when multiple are available. Single-pass — no
re-review loops.

## Invocation

| Invocation | Behavior |
|---|---|
| `/cli-review-fix` | Launch ALL available CLIs in parallel |
| `/cli-review-fix codex` | Codex CLI only |
| `/cli-review-fix gemini` | Gemini CLI only |

## Prerequisites

Check CLI availability before running. If a requested CLI is missing, show
install instructions and continue with any other available CLIs.

| CLI | Check | Auth | Install |
|---|---|---|---|
| Codex | `command -v codex` | `OPENAI_API_KEY` env var | `npm i -g @openai/codex` |
| Gemini | `command -v gemini` | Google auth (run `gemini` once) | `npm i -g @anthropic/gemini-cli` |

If neither CLI is available, inform the user with install instructions for both
and stop.

## Context Detection

Detect what to review automatically. Follow this priority order — use the first
match:

### Decision Tree

```
1. PR?
   gh pr view --json number,baseRefName,url,title 2>/dev/null
   → success: CONTEXT = "pr", base = baseRefName

2. Branch diff?
   git branch --show-current → not main/master
   git log main..HEAD --oneline → non-empty
   → CONTEXT = "branch", base = main

3. Uncommitted changes?
   git status --porcelain → non-empty
   → CONTEXT = "uncommitted"

4. Full codebase?
   User prompt contains "full codebase", "full review", or similar
   → CONTEXT = "full"

5. Nothing to review
   → Inform user, suggest making changes or specifying scope, stop
```

### Detecting the Default Branch

Use `main` as default. If `main` doesn't exist, try `master`:
```bash
git rev-parse --verify main 2>/dev/null && echo main || echo master
```

## Execution Flow

### Phase 1: Review

1. **Parse arguments** — determine which CLIs to run (default: all available)
2. **Check availability** — run `command -v codex` and/or `command -v gemini`
3. **Validate** — if specific CLI requested but unavailable, error with install
   instructions; if no CLIs available at all, stop
4. **Detect context** — follow the decision tree above
5. **Report context** — tell the user what was detected (e.g., "Detected PR #42,
   reviewing diff against main")
6. **Launch CLIs** — run selected CLIs. Prefer sub-agents for parallel execution
   (see Sub-Agent Recommendation). Fallback: direct Bash calls.
7. **Collect results** — read output from `/tmp/codex-review.md` and/or
   `/tmp/gemini-review.md`
8. **Present review findings** — format per `references/output-format.md` with
   severity levels and engine agreement tags

### Phase 2: Evaluate & Fix

9. **Critically evaluate** each finding (see Critical Evaluation below)
10. **Fix valid issues** — apply fixes for findings that pass evaluation
11. **Test** — run project tests if available (`npm test`, `pytest`, `make test`,
    etc.). If tests fail after a fix, revert that fix.
12. **Present fix report** — single report to the user (see Fix Report below)

## CLI Commands

Quick reference. See `references/cli-commands.md` for full flag details and
troubleshooting.

### Codex CLI

Codex has a purpose-built `exec review` subcommand:

| Context | Command |
|---|---|
| PR | `codex exec review --base <baseRefName> -o /tmp/codex-review.md` |
| Branch | `codex exec review --base <default-branch> -o /tmp/codex-review.md` |
| Uncommitted | `codex exec review --uncommitted -o /tmp/codex-review.md` |
| Full codebase | `codex exec review -o /tmp/codex-review.md` |

### Gemini CLI

Gemini uses `-p` prompt mode. Load the review prompt from
`references/review-prompt.md`.

| Context | Command |
|---|---|
| PR / Branch | `git diff <base>...HEAD \| gemini -p "<prompt>" --sandbox > /tmp/gemini-review.md` |
| Uncommitted | `git diff \| gemini -p "<prompt>" --sandbox > /tmp/gemini-review.md` |
| Full codebase | `gemini --all-files -p "<prompt>" --sandbox > /tmp/gemini-review.md` |

Key flags:
- `-p` — non-interactive (critical, prevents hanging)
- `--sandbox` — safe execution
- `--all-files` — full codebase context

For uncommitted changes, combine staged and unstaged:
```bash
(git diff --cached && git diff) | gemini -p "<prompt>" --sandbox > /tmp/gemini-review.md
```

## Critical Evaluation

**Never trust CLI review findings at face value.** Before fixing, evaluate EACH
finding:

1. **Verify the claim** — Read the actual code at the referenced file:line. Does
   the description match reality? CLI tools may misread context, reference wrong
   lines, or describe code that doesn't exist.

2. **Check for hallucinations** — CLI tools may fabricate issues: non-existent
   variables, imagined type mismatches, phantom security vulnerabilities. Confirm
   the issue exists in the actual code before fixing.

3. **Assess the fix** — Even if the issue is real, the suggested fix may be
   wrong, break existing behavior, or conflict with project conventions. Evaluate
   before applying. A better fix may exist.

4. **Conflicting suggestions** — When Codex and Gemini suggest different fixes
   for the same issue, evaluate both against project conventions and code
   context. Pick the better one, or mark as QUESTION if human judgment is needed.

## Fix Process

For each finding that passes critical evaluation:

1. Read the referenced file and understand the surrounding code
2. Apply the fix (or a better fix if the suggestion is suboptimal)
3. After all fixes, run project tests if they exist
4. If a test fails, revert the fix that caused it and mark as DEFERRED
5. Record each finding's status for the fix report

## Fix Report

Present a single fix report to the user after all fixes are applied. Load
`references/output-format.md` for the full template.

### Format

```markdown
## CLI Review Fix Report

**Context:** [PR #N / Branch diff / Uncommitted / Full codebase]
**Engines:** [Codex CLI, Gemini CLI]
**Findings:** N total → X fixed, Y wontfix, Z deferred, W question

### Fixed
- [file.ext:L10 Symbol]: FIXED — description of change. Verified: `test cmd` passes.

### Not Fixed
- [file.ext:L42 fn]: WONTFIX — reason (e.g., intentional design, already handled)
- [file.ext:L100 class]: DEFERRED — reason (e.g., tracked in #123, tests fail)
- [file.ext:L200 method]: QUESTION — question for the user
```

### Fix Statuses

| Status | Meaning | Required Info |
|---|---|---|
| FIXED | Issue resolved in code | What was changed + verification |
| WONTFIX | Intentionally not fixing | Reason (cite docs/conventions if applicable) |
| DEFERRED | Valid but not fixing now | Why (test failure, needs design decision, tracked issue) |
| QUESTION | Needs human decision | Specific question for the user |

## Result Presentation

Load `references/output-format.md` for full templates.

### Severity Levels

| Severity | Meaning |
|---|---|
| CRITICAL | Security vulnerabilities, data loss, crashes |
| HIGH | Bugs, logic errors, broken functionality |
| MEDIUM | Code quality, performance, maintainability |
| LOW | Style, naming, minor improvements |

### Multi-Engine Agreement Tags

| Tag | Meaning |
|---|---|
| AGREED | Both engines flagged the same issue — higher confidence |
| CODEX ONLY | Only Codex flagged this |
| GEMINI ONLY | Only Gemini flagged this |

## Sub-Agent Recommendation

When the Agent tool is available, delegate work to sub-agents to protect the
main context window from large CLI outputs.

**Recommended split:**

- **Review sub-agent(s)** — one per CLI for parallel execution. Each runs the
  CLI tool, parses output, and returns a concise structured finding list (not
  the full raw CLI output).
- **Fix sub-agent** (optional) — receives the parsed finding list, reads
  referenced files, critically evaluates each finding, applies fixes, runs
  tests. Returns the fix report.

**Why:** CLI review output can be very large (especially full codebase reviews).
Sub-agents absorb this without bloating the main conversation. Parallel
execution is also natural — each CLI in its own sub-agent.

**Fallback:** If the Agent tool is not available, run everything in the main
context. The skill works either way.

## Edge Cases

| Scenario | Behavior |
|---|---|
| Neither CLI installed | Show install instructions for both; stop |
| One CLI fails, other succeeds | Present results from successful CLI; note failure with error |
| Specific CLI requested but missing | Error with install instructions for that CLI; stop |
| No reviewable context | Inform user; suggest making changes or specifying scope |
| Large diff (>3000 lines) | Warn user; offer to scope to specific directories or file types |
| CLI times out | Report timeout; present any partial results |
| CLI returns no findings | Report "no findings" for that engine; skip fix phase |
| User says "full codebase" | Skip context detection; use full codebase mode |
| All findings are hallucinations | WONTFIX each with explanation; no code changes made |
| Tests fail after a fix | Revert that fix; mark as DEFERRED with test failure details |
| No project tests found | Skip test step; note "no tests available" in fix report |
| Conflicting suggestions (Codex vs Gemini) | Evaluate both; pick better one or mark QUESTION |

## Reference Loading

Load only what you need for the current step:
- CLI flags and troubleshooting → `references/cli-commands.md`
- Gemini review prompt template → `references/review-prompt.md`
- Result and fix report formatting → `references/output-format.md`

## Scope Limits

This skill is on-demand and single-pass. It does **not**:
- Loop or re-review — evaluates and fixes once, then reports
- Post results to GitHub or create commits (user decides what to do with fixes)
- Run as a hook or in CI
- Replace the agent's own review — it adds external perspectives and auto-fixes
