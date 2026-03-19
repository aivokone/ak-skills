# CLI Invocation Reference

Exact commands for each CLI tool, grouped by review context.

## Codex CLI

Codex has a purpose-built `exec review` subcommand with context-aware flags.

### Commands by Context

| Context | Command |
|---|---|
| PR | `codex exec review --base <baseRefName> -o .agents/scratch/codex-review.md` |
| Branch diff | `codex exec review --base main -o .agents/scratch/codex-review.md` |
| Uncommitted | `codex exec review --uncommitted -o .agents/scratch/codex-review.md` |
| Full codebase | `codex exec review -o .agents/scratch/codex-review.md` |

### Key Flags

| Flag | Purpose |
|---|---|
| `--base <ref>` | Compare against a base branch or commit |
| `--uncommitted` | Review uncommitted changes (staged + unstaged) |
| `-o <file>` | Write last message to file for capture |
| `--json` | Machine-readable JSON output |

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
| Timeout | Large repos may need more time — wait for completion |
| Empty output file | Check that the review produced findings; `-o` only writes when there's output |

---

## Gemini CLI

Gemini uses generic `-p` prompt mode. Diffs are piped via stdin; full codebase uses `--all-files`.

### Commands by Context

| Context | Command |
|---|---|
| PR | `git diff <base>...HEAD \| gemini -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |
| Branch diff | `git diff <default-branch>...HEAD \| gemini -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |
| Uncommitted | `(git diff --cached && git diff) \| gemini -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |
| Full codebase | `gemini --all-files -p "<prompt>" --sandbox > .agents/scratch/gemini-review.md` |

### Key Flags

| Flag | Purpose |
|---|---|
| `-p "prompt"` | Non-interactive mode (critical — prevents hanging) |
| `--sandbox` | Sandboxed execution for safety |
| `--all-files` | Include all files in current directory as context |
| `--model pro` | Use Gemini Pro (better for security/architecture) |
| `--model flash` | Use Gemini Flash (faster, default via `auto`) |
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
| `flash` (default via `auto`) | General code reviews, quick questions | Fast |
| `pro` | Security audits, architecture decisions, critical reviews | Slower |

Use `--model pro` for security-sensitive code. Default (`auto`) is fine for general reviews.
