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

Use the bundled wrapper script for Gemini reviews. For PR and branch diff
contexts the wrapper prefers Google's code-review extension (interactive mode
with full-file access) when installed. Falls back to rich pipe mode (prompt +
full changed files + diff) when the extension is unavailable, and for contexts
the extension does not support (uncommitted, full codebase).

### Commands by Context

| Context | Command |
|---|---|
| PR | `cli-review-gemini.sh pr <baseRefName>` |
| Branch diff | `cli-review-gemini.sh branch <default-branch>` |
| Uncommitted | `cli-review-gemini.sh uncommitted` |
| Full codebase | `cli-review-gemini.sh full` |

### Wrapper Modes

| Mode | When Used | Details |
|---|---|---|
| Extension | PR/branch when `~/.gemini/extensions/code-review/` exists | Runs `gemini "/code-review" --yolo -e code-review`. Gemini can read full files interactively. |
| Rich pipe | Uncommitted, or PR/branch without extension | Sends prompt + full changed-file contents + diff to `gemini --model pro -p - --sandbox`. Files >500 lines or binary are skipped. |
| Full codebase | Explicit `full` context | Runs `gemini --all-files --model pro -p "<prompt>" --sandbox` |
| Fallback | Extension command fails | Falls back to rich pipe with warning |

Output always goes to `.agents/scratch/gemini-review.md`.

### Extension Setup (Optional, Recommended)

```bash
gemini extensions install https://github.com/gemini-cli-extensions/code-review
```

The extension uses interactive mode (`--yolo`) so Gemini can read full files,
check imports, and verify claims — significantly reducing false positives
compared to raw pipe mode. The wrapper detects the extension automatically.

### Key Flags

| Flag | Purpose |
|---|---|
| `--model pro` | Gemini Pro for raw-pipe reviews (better reasoning, fewer false positives) |
| `-p -` | Non-interactive mode, read prompt from stdin |
| `--sandbox` | Sandboxed execution for safety (raw pipe mode) |
| `--yolo` | Auto-approve tool calls (extension mode) |
| `-e code-review` | Enable code-review extension |
| `--all-files` | Include all files in current directory as context |

### Prerequisites

- **Check:** `command -v gemini`
- **Auth:** Run `gemini` interactively once to complete Google authentication
- **Verify:** `gemini -p "What is 2+2?"`
- **Extension (optional):** `gemini extensions install https://github.com/gemini-cli-extensions/code-review`

### Troubleshooting

| Problem | Solution |
|---|---|
| `command not found: gemini` | Install from https://github.com/google-gemini/gemini-cli |
| Auth error / "Not authenticated" | Run `gemini` interactively to authenticate |
| Hangs indefinitely | Missing `-p` flag in raw pipe mode — Gemini waits for interactive input |
| Rate limits | Wait 1–5 minutes, then retry |
| Large diff truncated | Gemini has context limits — consider scoping to specific directories |
| Extension not found | Run `gemini extensions install https://github.com/gemini-cli-extensions/code-review` |
| Extension diffs against wrong base | Extension uses `origin/HEAD`; wrapper warns when this differs from PR base |
| Extension command fails | Wrapper auto-falls back to rich pipe with stderr warning |

### Model Selection Guide

| Model | Best For | Speed |
|---|---|---|
| `pro` (used in raw pipe) | Code reviews, security audits, architecture decisions | Slower |
| `flash` | Quick questions, large diffs where speed matters | Fast |
| Extension default | Extension mode — model selected by Gemini CLI auto setting | Varies |

The extension's interactive mode (full-file access) compensates for any model
differences. For raw pipe mode, `--model pro` is hardcoded in the wrapper.
