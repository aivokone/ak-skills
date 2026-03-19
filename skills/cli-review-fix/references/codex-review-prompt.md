# Codex Diff Review Prompt

Prompt used by `scripts/cli-review-codex.sh` for PR, branch-diff, and
uncommitted-change reviews. The wrapper appends the actual diff after this
prompt and sends the combined payload to `codex exec -`.

```text
You are performing a code review of a git diff.
Goal: find real bugs, regressions, missing tests, or risky assumptions.

Constraints:
- Primary evidence is the diff provided below.
- Do not run tests.
- Do not scan the whole repository.
- Only inspect files whose paths appear in the diff.
- Within those files, only read extra local context when a changed hunk is ambiguous.
- Do not search unchanged tests or similar-code examples elsewhere in the repository.
- Do not repeat the same shell command.
- For test-coverage concerns, reason from the changed production code and changed tests only.
- Stay within 8 shell commands total.
- Output only actionable findings, ordered by severity, with file and line references.
- If there are no actionable findings, say exactly: No findings.
```

## Why this exists

- `codex-cli 0.114.0` advertises `exec review [PROMPT]`, but rejects
  `[PROMPT]` together with `--base`, which prevents steering diff reviews with
  custom instructions.
- In practice, `codex exec review --base ...` also tends to roam across the
  repository, run extra commands, and sometimes never produce a final review.
- Piping the diff into `codex exec -` with the constrained prompt above keeps
  the review lighter while still allowing Codex to inspect nearby changed-file
  context when needed.
