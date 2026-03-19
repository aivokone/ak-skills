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

Presented after the review phase. Two parts: a summary table for quick scanning,
followed by detailed explanations.

### Fix Report Template

```markdown
## CLI Review Fix Report

**Context:** PR #42 (feature-branch → main)
**Engines:** Codex CLI, Gemini CLI
**Findings:** 7 total → 3 fixed, 2 wontfix, 1 deferred, 1 question

### Summary

| # | Severity | Location | Finding | Source | Status |
|---|----------|----------|---------|--------|--------|
| 1 | CRITICAL | src/auth.ts:L42 | JWT signature not verified | AGREED | FIXED |
| 2 | HIGH | src/api/users.ts:L100 | Missing authorization check | AGREED | FIXED |
| 3 | HIGH | src/api/users.ts:L88 | SQL injection risk | GEMINI | QUESTION |
| 4 | MEDIUM | src/utils/cache.ts:L55 | Cache stampede on expiry | CODEX | FIXED |
| 5 | MEDIUM | src/db/query.ts:L200 | N+1 query pattern | GEMINI | DEFERRED |
| 6 | LOW | src/config.ts:L12 | Magic number 3600 | CODEX | WONTFIX |
| 7 | LOW | review-prompt.md:L4 | AI-to-AI framing brittle | GEMINI | WONTFIX |

### Details

**1. src/auth.ts:L42 `validateToken`** — CRITICAL — FIXED
JWT signature was not verified before extracting claims. Attacker could forge
arbitrary tokens. Fixed by adding `jwt.verify(token, secret)` before
`jwt.decode()`. Verified: `npm test` passes.

**2. src/api/users.ts:L100 `deleteUser`** — HIGH — FIXED
No authorization check before user deletion. Added `requireAdmin(req)` guard.
Verified: `npm test` passes.

**3. src/api/users.ts:L88 `updateUser`** — HIGH — QUESTION
Gemini flags SQL injection via unsanitized input. However, the input is already
parameterized by the ORM layer (`prisma.user.update`). Is additional escaping
needed here, or is the ORM sufficient?

**4. src/utils/cache.ts:L55 `getOrSet`** — MEDIUM — FIXED
Cache stampede risk on key expiry under high concurrency. Added
stale-while-revalidate pattern with a 30s grace window.

**5. src/db/query.ts:L200 `buildQuery`** — MEDIUM — DEFERRED
N+1 query pattern is a known issue (tracked in #456). Fixing requires schema
changes and a migration — out of scope for this review pass.

**6. src/config.ts:L12** — LOW — WONTFIX
Magic number `3600` is a standard TTL in seconds (1 hour). Already documented
in the inline comment. Extracting to a constant adds indirection without
improving clarity.

**7. review-prompt.md:L4** — LOW — WONTFIX
AI-to-AI framing prefix is a tested prompting pattern. If a future model
handles it differently, the prompt can be updated in the reference file.
```

### Source Column Values

| Value | Meaning |
|---|---|
| AGREED | Both engines flagged this issue (higher confidence) |
| CODEX | Only Codex CLI flagged this |
| GEMINI | Only Gemini CLI flagged this |
| (engine name) | When only one engine was used, show its name |

### Fix Statuses

| Status | Meaning | Required Info |
|---|---|---|
| FIXED | Issue resolved in code | What was changed + verification |
| WONTFIX | Intentionally not fixing | Reason (why it's not an issue or is intentional) |
| DEFERRED | Valid but not fixing now | Why (test failure, tracked issue, needs design decision) |
| QUESTION | Needs human decision | Specific question for the user to answer |

### Report Structure Rules

1. **Summary table first** — one row per finding, scannable at a glance
2. **Details second** — numbered to match the table, with full context
3. **FIXED details** include: what was wrong, what was changed, verification
4. **WONTFIX details** include: why the finding was rejected (hallucination,
   intentional design, already handled)
5. **QUESTION details** include: the specific question and enough context for
   the user to decide
