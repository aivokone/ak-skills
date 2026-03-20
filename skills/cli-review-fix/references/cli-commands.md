# CLI Invocation Reference

Exact commands for each CLI tool, grouped by review context.

## Codex CLI

Use the bundled wrapper script for Codex reviews. For diff-based contexts the
wrapper feeds a constrained prompt plus the actual diff into `codex exec -`.
For explicit full codebase reviews it falls back to `codex exec review`.

### Commands by Context

| Context | Command |
|---|---|
| PR | `cli-review-codex.sh pr <baseRefName>` |
| Branch diff | `cli-review-codex.sh branch <default-branch>` |
| Uncommitted | `cli-review-codex.sh uncommitted` |
| Full codebase | `cli-review-codex.sh full` |

### Wrapper Behavior

| Behavior | Details |
|---|---|
| Diff contexts | Builds a prompt from `references/codex-review-prompt.md`, appends the diff, then runs `codex exec - -o .agents/scratch/codex-review.md` |
| Full codebase | Runs `codex exec review -o .agents/scratch/codex-review.md` |
| Debug mode | `CLI_REVIEW_DEBUG_JSON=1` adds `--json` and writes `.agents/scratch/codex-review.jsonl` plus `.agents/scratch/codex-review.stderr` |
| Output file | Always writes the last Codex message to `.agents/scratch/codex-review.md` |

Review is inherently read-only — no `--sandbox` needed.

### Prerequisites

- **Check:** `command -v codex`
- **Auth:** `OPENAI_API_KEY` environment variable must be set
- **Verify:** `codex --version`

### Troubleshooting

| Problem | Solution |
|---|---|
| `command not found: codex` | Install from https://github.com/openai/codex |
| Auth error | Set `OPENAI_API_KEY` or run `codex auth` |
| Diff review hangs or wanders | Use the wrapper script, not raw `codex exec review --base ...` |
| Need deeper Codex debugging | Re-run with `CLI_REVIEW_DEBUG_JSON=1` and inspect `.agents/scratch/codex-review.jsonl` |
| Timeout | Large repos may need more time — wait for completion |
| Empty output file | Check that the review produced findings; `-o` only writes when there's output |

---

## Gemini CLI

Gemini uses `-p` prompt mode with `--model pro` for review accuracy. Diffs are
piped via stdin; full codebase uses `--all-files`.

### Commands by Context

| Context | Command |
|---|---|
| PR | `git diff <base>...HEAD \| gemini --model pro -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |
| Branch diff | `git diff <default-branch>...HEAD \| gemini --model pro -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |
| Uncommitted | `(git diff --cached && git diff) \| gemini --model pro -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |
| Full codebase | `gemini --all-files --model pro -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |

### Key Flags

| Flag | Purpose |
|---|---|
| `--model pro` | Use Gemini Pro for reviews (default recommendation — better reasoning, fewer false positives) |
| `--model flash` | Gemini Flash (faster, but higher hallucination rate for code review) |
| `-p "prompt"` | Non-interactive mode (critical — prevents hanging) |
| `--sandbox` | Sandboxed execution for safety |
| `--all-files` | Include all files in current directory as context |
| `--output-format text` | Text output (default) |
| `--output-format json` | JSON output |

Output goes to stdout — capture with `>` redirection.

### Prerequisites

- **Check:** `command -v gemini`
- **Auth:** Run `gemini` interactively once to complete Google authentication
- **Verify:** `gemini -p "What is 2+2?"`

### Troubleshooting

| Problem | Solution |
|---|---|
| `command not found: gemini` | Install from https://github.com/google-gemini/gemini-cli |
| Auth error / "Not authenticated" | Run `gemini` interactively to authenticate |
| Hangs indefinitely | Missing `-p` flag — Gemini waits for interactive input without it |
| Rate limits | Wait 1–5 minutes, then retry |
| Large diff truncated | Gemini has context limits — consider scoping to specific directories |

### Model Selection Guide

| Model | Best For | Speed |
|---|---|---|
| `pro` (recommended for reviews) | Code reviews, security audits, architecture decisions | Slower |
| `flash` | Quick questions, large diffs where speed matters | Fast |

Use `--model pro` for all reviews by default. Gemini only sees piped diff hunks
(not full files), so the Pro model's stronger reasoning helps avoid false
positives about "missing" code that exists outside the visible hunks.
