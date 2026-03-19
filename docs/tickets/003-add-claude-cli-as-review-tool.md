# 003: Add Claude CLI as a review tool

**Status:** Open
**Skill:** cli-review-fix
**Created:** 2026-03-19

## Summary

Add Claude CLI (`claude`) as a review engine alongside Codex and Gemini. This
enables three-way cross-engine review and leverages Claude's strengths in code
understanding directly from the command line.

## Motivation

The current skill dispatches reviews to Codex (OpenAI) and Gemini (Google) but
not to Claude (Anthropic), despite the user likely already having Claude CLI
installed and authenticated (since the skill runs inside Claude Code). Adding
Claude CLI as a third engine:

- Enables three-way agreement analysis (higher confidence when all three agree)
- Leverages Claude's strong code reasoning from a separate CLI context
- Provides a review perspective independent of the hosting agent's own analysis
- Completes the "big three" frontier model coverage

## Claude CLI details

- **Repo:** https://github.com/anthropics/claude-code
- **Command:** `claude`
- **Check:** `command -v claude`
- **Auth:** Anthropic API key or existing Claude Code session
- **Non-interactive flag:** `-p "prompt"` (print mode, no interactive session)
- **Output:** stdout (capture with `>` redirection, same as Gemini)

## Proposed invocation

| Context | Command |
|---|---|
| PR / Branch | `git diff <base>...HEAD \| claude -p "<prompt>" > .agents/scratch/claude-review.md` |
| Uncommitted | `(git diff --cached && git diff) \| claude -p "<prompt>" > .agents/scratch/claude-review.md` |
| Full codebase | `claude -p "<prompt>" > .agents/scratch/claude-review.md` |

## Changes needed

### scripts/cli-review-detect.sh
- Add `claude` availability check: `command -v claude`
- Add `"claude": true/false` to JSON output

### SKILL.md
- Add Claude to prerequisites table
- Add Claude CLI commands table
- Update invocation examples: `/cli-review-fix claude`
- Update multi-engine agreement tags to include `CLAUDE ONLY`

### references/cli-commands.md
- Add Claude CLI section with commands, flags, troubleshooting

### references/review-prompt.md
- Add Claude-specific review prompt (may need different framing since the
  reviewing agent IS Claude — avoid the AI-to-AI prefix used for Gemini)

### references/output-format.md
- Update agreement analysis for 3-engine scenarios
- Add tags: `ALL AGREED`, `2/3 AGREED`, engine-specific

### evals.json
- Add Claude-only invocation test case
- Add three-engine agreement test case

## Design considerations

### Self-review paradox

When running inside Claude Code, the hosting agent is Claude and the review
engine is also Claude (via CLI). This is a separate process with its own
context, so findings will differ from the host agent's own analysis. However,
the review prompt should avoid the `[Claude Code consulting Gemini]` framing
and instead use neutral language.

### Three-engine agreement

With three engines, the agreement analysis needs updating:

| Tag | Meaning |
|---|---|
| ALL AGREED | All three engines flagged the issue |
| 2/3 AGREED | Two of three engines flagged the issue |
| CODEX ONLY | Only Codex flagged this |
| GEMINI ONLY | Only Gemini flagged this |
| CLAUDE ONLY | Only Claude flagged this |

## Open questions

- Should the Claude CLI review use a different model than the hosting agent
  (e.g., if host is Opus, review with Sonnet for a different perspective)?
- How to handle the case where Claude CLI is available but shares the same
  API quota as the hosting session?
- Should this be implemented together with ticket #001 (config file) to allow
  model selection per engine?
