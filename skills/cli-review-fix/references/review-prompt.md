# Review Prompt Templates

Prompt templates sent to Gemini CLI. Codex diff reviews use
`references/codex-review-prompt.md` via `scripts/cli-review-codex.sh`.

## Diff Review Prompt

Used for the **raw-pipe fallback** path when the code-review extension is not
active. When the extension is installed, its built-in "Principal Software
Engineer" persona handles prompting and Gemini can read full files interactively.

For raw-pipe contexts, the wrapper sends this prompt + full changed-file contents
+ the diff to `gemini --model pro -p - --sandbox`:

```
[Claude Code consulting Gemini for peer review]

Task: Code review the following diff. Find real bugs, regressions, security issues, or risky assumptions in the changed lines.

Constraints — you see ONLY diff hunks, not full files:
- Never claim something is missing (import, variable, function, call) unless the diff shows its deletion.
- Do not assume what exists outside the visible hunks. If you cannot verify a claim from the diff alone, do not report it.
- Focus on logic errors, regressions, and security issues visible in the changed lines.
- Do not report style nits or naming suggestions unless they introduce a bug.
- If there are no actionable findings, say exactly: No findings.

For each finding report:
- Severity: CRITICAL, HIGH, MEDIUM, or LOW
- File and line: file.ext:L42
- Description: what the issue is and why it matters
- Suggestion: concrete fix (not vague guidance)

Severity definitions:
- CRITICAL: security vulnerabilities, data loss, crashes
- HIGH: bugs, logic errors, broken functionality
- MEDIUM: code quality, performance, maintainability issues
- LOW: style, naming, minor improvements

Group findings by severity (CRITICAL first). Be concise and actionable. Do not repeat the diff back.
```

## Full Codebase Review Prompt

Used with `--all-files` when user requests a full codebase review. In this mode
Gemini sees full files, so the diff-only constraints do not apply.

```
[Claude Code consulting Gemini for peer review]

Task: Review the codebase in the current directory. Focus on architecture, correctness, security, and code quality.

Constraints:
- Only report issues you can verify from the code you see. Do not speculate about runtime behavior you cannot confirm.
- Focus on the most impactful issues — do not list every minor style nit.
- Limit to the top 20 findings.
- If there are no actionable findings, say exactly: No findings.

For each finding report:
- Severity: CRITICAL, HIGH, MEDIUM, or LOW
- File and line: file.ext:L42
- Description: what the issue is and why it matters
- Suggestion: concrete fix or improvement

Severity definitions:
- CRITICAL: security vulnerabilities, data loss, crashes
- HIGH: bugs, logic errors, broken functionality
- MEDIUM: code quality, performance, maintainability issues
- LOW: style, naming, minor improvements

Group findings by severity (CRITICAL first). Be concise and actionable.
```

## Prompt Construction Notes

- Always prefix with `[Claude Code consulting Gemini for peer review]` — this
  AI-to-AI framing produces more direct, actionable output.
- Keep severity definitions in the prompt so Gemini classifies consistently.
- For diff reviews, the diff content arrives via stdin pipe — the prompt should
  reference "the following diff" without repeating it.
- For full codebase, `--all-files` provides file context — the prompt should
  reference "the codebase in the current directory."
- **Diff-only constraints are critical for raw pipe.** Without explicit "do not
  claim missing unless deleted" constraints, Gemini hallucinates missing imports,
  variables, and calls that exist outside the visible hunks.
- **Rich context mode** (wrapper sends full changed files alongside the diff)
  mitigates this by giving Gemini the full file content. The diff-only
  constraints still apply as a safety net but are less likely to trigger.
- **Extension mode bypasses this prompt entirely.** The code-review extension
  runs Gemini interactively — it can read files on demand and uses its own
  built-in review persona.
