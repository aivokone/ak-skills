# Fix Report Examples

Real-world examples of Fix Reports from code review scenarios with multiple reviewers.

## Example 1: Mixed Channels (inline + conversation)

```markdown
### Fix Report

**Addressed Gemini inline comments:**
- notifications.js:L15 (display_name logic): FIXED @ 9198866 — verified: no duplication, templates receive displayName
- notifications.js:L42 (template loading): FIXED @ 9198866 — verified: uses array syntax, simplified
- notifications.js:L146 (inline handler): WONTFIX — reason: matches lib/utils.js pattern (L50-60), keeps related code together per project conventions
- config.ts:L33 (hardcoded URL): WONTFIX — reason: single-tenant application, configuration overhead not justified

**Addressed agent-reviewer conversation review:**
- helpers.js:L100 (error handling): FIXED @ def456 — verified: `npm test` passes

**Note:** Responded to inline comment in thread: https://github.com/org/repo/pull/2#discussion_r123456789

@gemini-code-assist please re-review.
```

## Example 2: Security Alert + Agent Review

```markdown
### Fix Report

**Addressed Codex security alert:**
- auth.php:L50 (SQL injection risk): FIXED @ abc123 — verified: using prepared statement, `npm run security-scan` clean

**Addressed Claude review:**
- auth.php:L75 (rate limiting): FIXED @ abc123 — verified: max 5 attempts/minute, tested with `curl` loop
- config.php:L20 (env vars): FIXED @ abc123 — verified: all secrets in .env, not committed

@github-advanced-security @agent-reviewer please re-review.
```

## Example 3: Duplicate Feedback from Multiple Reviewers

```markdown
### Fix Report

**Addressed duplicate feedback (ALL reviewers flagged):**
- utils.js:L42 (use const instead of let): FIXED @ xyz789 — verified: `npm run lint` passes
  - Gemini: "prefer const for immutable bindings"
  - Codex: "const improves code clarity"
  - Claude: "const prevents accidental reassignment"

**Unique feedback:**
- utils.js:L100 (Gemini only - type annotation): DEFERRED — tracking: #456 (TypeScript migration epic)

@gemini-code-assist @github-advanced-security @agent-reviewer please re-review.
```

## Example 4: QUESTION Status (Conflicting Suggestions)

```markdown
### Fix Report

**Fixed:**
- api.php:L30 (error response format): FIXED @ 123abc — verified: returns JSON with {error, code, message}

**Question:**
- api.php:L100 (caching strategy): QUESTION — Gemini suggests Redis (L100-110), Codex suggests in-memory LRU (L100-105). Which aligns better with our infrastructure? See ARCHITECTURE.md for current stack.

@gemini-code-assist @github-advanced-security What's the recommended approach given our deployment on Heroku with Redis add-on?
```

## Example 5: DEFERRED with Tracking

```markdown
### Fix Report

**Fixed:**
- frontend.js:L50 (XSS vulnerability): FIXED @ aaa111 — verified: sanitizing user input, `npm run test:security` passes
- frontend.js:L80 (accessibility): FIXED @ aaa111 — verified: ARIA labels added, WCAG AA compliant

**Deferred:**
- frontend.js:L200 (performance optimization): DEFERRED — tracking: #789 (Q2 performance sprint)
  - Reason: Valid optimization but not blocking, scheduled for dedicated performance work

@gemini-code-assist please re-review blocking items. Performance item tracked separately.
```

## Example 6: Inline-only Feedback

```markdown
### Fix Report

**Addressed Gemini inline comments:**
(Note: All feedback was in inline threads, mirroring to conversation for visibility)

- styles.css:L30 (CSS variable naming): FIXED @ bbb222 — verified: using --prefix convention per STYLEGUIDE.md
- styles.css:L45 (media query order): FIXED @ bbb222 — verified: mobile-first ordering

**Replied to inline threads (signed with agent identity):**
- L30: https://github.com/org/repo/pull/3#discussion_r123456
- L45: https://github.com/org/repo/pull/3#discussion_r123457

@gemini-code-assist please re-review. Note: Future reviews - conversation comments preferred for easier tracking per workflow docs.
```

## Status Reference

| Status   | Required Info | When to Use |
|----------|---------------|-------------|
| FIXED    | Commit hash + verification | Change implemented and tested |
| WONTFIX  | Reason (cite docs) | Intentionally not changing (not a bug) |
| DEFERRED | Issue/ticket link | Valid but not urgent, tracked separately |
| QUESTION | Specific question | Need clarification before proceeding |

## Tips

- **One Fix Report per review round** - Consolidate all feedback sources
- **Include verification** - Show how you tested (command or objective check)
- **Tag all reviewers** - Mention bots and agents who provided feedback
- **Link inline replies** - If you replied to inline threads, include URLs
- **Cite project docs** - For WONTFIX, reference AGENTS.md, STYLEGUIDE.md, etc.
- **Sign inline replies** - Always end with agent identity (e.g., `—Claude Sonnet 4.5`, `—GPT-4`) to distinguish from human responses
