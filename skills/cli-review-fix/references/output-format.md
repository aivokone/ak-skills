# Output Format Reference

Templates for presenting CLI review results and fix reports to the user.

## Severity Indicators

| Severity | Meaning | Examples |
|---|---|---|
| CRITICAL | Must fix before merge | Security vulnerabilities, data loss, crashes, auth bypass |
| HIGH | Likely bugs or broken behavior | Logic errors, race conditions, broken functionality |
| MEDIUM | Should improve | Code quality, performance, maintainability issues |
| LOW | Nice to have | Style, naming, minor improvements, documentation |

## Single-Engine Report

When only one CLI ran (either by user choice or availability):

```markdown
## CLI Review Results

**Context:** PR #42 (feature-branch → main)
**Engine:** Codex CLI

### CRITICAL
- **src/auth.ts:L42** `validateToken` — JWT signature not verified before claims extraction → Verify signature first: `jwt.verify(token, secret)` before `jwt.decode()`

### HIGH
- **src/api/users.ts:L100** `deleteUser` — Missing authorization check → Add `requireAdmin(req)` guard before deletion

### MEDIUM
- **src/utils/cache.ts:L55** `getOrSet` — Cache stampede on expiry → Use lock or stale-while-revalidate pattern

### LOW
- **src/config.ts:L12** — Magic number `3600` → Extract to named constant `SESSION_TTL_SECONDS`

**Summary:** 4 findings (1 critical, 1 high, 1 medium, 1 low)
```

## Multi-Engine Report

When both CLIs ran, add cross-engine agreement analysis:

```markdown
## CLI Review Results

**Context:** PR #42 (feature-branch → main)
**Engines:** Codex CLI, Gemini CLI

### CRITICAL
- **src/auth.ts:L42** `validateToken` — AGREED — JWT signature not verified
  - Codex: "signature bypass allows token forgery"
  - Gemini: "JWT decoded without verification — attacker can craft arbitrary claims"

### HIGH
- **src/api/users.ts:L100** `deleteUser` — CODEX ONLY — Missing authorization check
- **src/api/users.ts:L88** `updateUser` — GEMINI ONLY — SQL injection via unsanitized input

### MEDIUM
- **src/utils/cache.ts:L55** `getOrSet` — AGREED — Cache stampede risk
- **src/db/query.ts:L200** `buildQuery` — GEMINI ONLY — N+1 query pattern

### LOW
- **src/config.ts:L12** — CODEX ONLY — Magic number

### Engine Agreement

| Severity | Agreed | Codex Only | Gemini Only | Total |
|---|---|---|---|---|
| Critical | 1 | 0 | 0 | 1 |
| High | 0 | 1 | 1 | 2 |
| Medium | 1 | 0 | 1 | 2 |
| Low | 0 | 1 | 0 | 1 |
| **Total** | **2** | **2** | **2** | **6** |

**Agreement rate:** 33% of findings confirmed by both engines.
```

## Finding Tags

| Tag | Meaning |
|---|---|
| AGREED | Both engines flagged the same issue — higher confidence |
| CODEX ONLY | Only Codex CLI flagged this |
| GEMINI ONLY | Only Gemini CLI flagged this |

## Deduplication Heuristic

Two findings from different engines are considered the "same" when:
1. Same file path
2. Line numbers within 5 lines of each other
3. Similar issue category (security, performance, bug, style)

If ambiguous, list as separate findings with a note they may be related.
Use judgment — exact matching is impossible since each CLI uses different wording.

## Context Header Values

| Detected Context | Header Text |
|---|---|
| PR | `PR #<number> (<branch> → <base>)` |
| Branch diff | `Branch diff (<branch> vs main)` |
| Uncommitted changes | `Uncommitted changes` |
| Full codebase | `Full codebase review` |

---

## Fix Report

Presented after the review phase. Summarizes what was fixed and what wasn't.

### Fix Report Template

```markdown
## CLI Review Fix Report

**Context:** PR #42 (feature-branch → main)
**Engines:** Codex CLI, Gemini CLI
**Findings:** 6 total → 3 fixed, 1 wontfix, 1 deferred, 1 question

### Fixed
- [src/auth.ts:L42 validateToken]: FIXED — JWT signature now verified before
  claims extraction. Verified: `npm test` passes.
- [src/api/users.ts:L100 deleteUser]: FIXED — Added authorization check.
  Verified: `npm test` passes.
- [src/utils/cache.ts:L55 getOrSet]: FIXED — Added stale-while-revalidate
  pattern to prevent cache stampede.

### Not Fixed
- [src/config.ts:L12]: WONTFIX — Magic number `3600` is a standard TTL value,
  already documented in the inline comment.
- [src/db/query.ts:L200]: DEFERRED — N+1 query is a known issue, tracked
  in #456. Fixing requires schema changes.
- [src/api/users.ts:L88]: QUESTION — Gemini flags SQL injection but input
  is already sanitized by the ORM layer. Is additional escaping needed here?
```

### Fix Statuses

| Status | Meaning | Required Info |
|---|---|---|
| FIXED | Issue resolved in code | What was changed + verification (test command or objective check) |
| WONTFIX | Intentionally not fixing | Reason (cite docs, conventions, or explain why it's not an issue) |
| DEFERRED | Valid but not fixing now | Why (test failure, tracked issue, needs design decision) |
| QUESTION | Needs human decision | Specific question for the user to answer |

### Fix Report Summary Line

Always include a summary line at the top:
```
**Findings:** N total → X fixed, Y wontfix, Z deferred, W question
```

This gives the user an instant overview before reading details.
