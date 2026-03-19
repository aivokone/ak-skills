# Review Prompt Templates

Prompt templates sent to Gemini CLI. Codex CLI has built-in review logic via
`exec review` and does not need a custom prompt for standard contexts.

## Diff Review Prompt

Used when reviewing PR diffs, branch diffs, or uncommitted changes piped via stdin:

```
[Claude Code consulting Gemini for peer review]

Task: Code review the following diff. Identify bugs, security issues, performance problems, and code quality concerns.

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

Group findings by severity (CRITICAL first). If no issues found, say "No findings."
Be concise and actionable. Do not repeat the diff back.
```

## Full Codebase Review Prompt

Used with `--all-files` when user requests a full codebase review:

```
[Claude Code consulting Gemini for peer review]

Task: Review the codebase in the current directory. Focus on architecture, correctness, security, and code quality.

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

Group findings by severity (CRITICAL first). Focus on the most impactful issues — do not list every minor style nit. Limit to the top 20 findings.
Be concise and actionable.
```

## Prompt Construction Notes

- Always prefix with `[Claude Code consulting Gemini for peer review]` — this
  AI-to-AI framing produces more direct, actionable output.
- Keep severity definitions in the prompt so Gemini classifies consistently.
- For diff reviews, the diff content arrives via stdin pipe — the prompt should
  reference "the following diff" without repeating it.
- For full codebase, `--all-files` provides file context — the prompt should
  reference "the codebase in the current directory."
