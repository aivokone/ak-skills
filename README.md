# Aivokone Skills (`ak-skills`)

Agent skills using the open [skills standard](https://skills.sh/).

This repo hosts operational tools, documentation workflows, and development practices.
Each skill is self-contained under `skills/<skill-name>/`.

## Install (skills.sh / npx skills)

```bash
# Install all skills from this repo to current project
npx skills add aivokone/ak-skills
```

For full usage and installation details, see [skills.sh docs](https://skills.sh/docs).

## Skills Index

The table below is the canonical skills index for this repository.

| Name | Slug | Description |
|------|------|-------------|
| [Seravo Developer](skills/seravo-dev/) | `seravo-dev` | Seravo-hosted WordPress ops: custom `wp-*` CLI, Git deploys, DDEV local setup, DB sync, troubleshooting |
| [Google Ads Query](skills/google-ads-query/) | `google-ads-query` | Query Google Ads via GAQL: campaigns, conversions, keywords, ad performance, bidding |
| [GA4 Query](skills/ga4-query/) | `ga4-query` | Query Google Analytics 4 via the Data API: traffic, sessions, page views, realtime, conversions |
| [Agent Flight Recorder](skills/agent-flight-recorder/) | `agent-flight-recorder` | Always-on flight recorder for agent runs: logs deviations to per-run files |
| [Local Reference](skills/local-ref/) | `local-ref` | Cache library docs locally so every session reads from disk instead of re-fetching |
| [PR Review](skills/pr-review/) | `pr-review` | Systematic PR review workflow — check all feedback channels, respond, and report |
| [SwiftBar](skills/swiftbar/) | `swiftbar` | Create, edit, and debug SwiftBar menu bar plugins for macOS |

## Agents Index

Plugin-level sub-agents auto-discovered from `agents/`.

| Name | Slug | Description |
|------|------|-------------|
| [PR Reviewer](agents/pr-reviewer.md) | `pr-reviewer` | Sonnet-powered sub-agent for the full PR review lifecycle |

## Skill Catalog

### Seravo Developer (`seravo-dev`)

Operational WordPress guidance for Seravo-hosted projects, including deployment,
local environment setup, database workflows, and Seravo-specific incident
response. Includes IPv4-safe SSH onboarding patterns and DDEV-first local
workflows for Seravo host access and data sync.

Primary upstream knowledge comes from Seravo Help Center and Seravo developer
docs, with practical DDEV-first and safety-first operational patterns curated
for agent use.

Source:
- `skills/seravo-dev/SKILL.md`
- `skills/seravo-dev/references/seravo-guide.md`
- `skills/seravo-dev/references/seravo-to-local-to-github.md`

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill seravo-dev
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill seravo-dev -g
```

### Google Ads Query (`google-ads-query`)

Read-only GAQL query tool for Google Ads accounts. Provides a lightweight Python
CLI (`gads` alias) that executes Google Ads Query Language queries via stdin
piping (`echo "QUERY" | gads -`) and returns structured JSON. Covers campaign performance, conversion tracking audits, keyword
analysis, search terms reports, and ad group metrics. Includes enum code reference
and pre-built query patterns for common reporting tasks.

Source:
- `skills/google-ads-query/SKILL.md`
- `skills/google-ads-query/references/enums.md`
- `skills/google-ads-query/scripts/query.py`

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill google-ads-query
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill google-ads-query -g
```

### GA4 Query (`ga4-query`)

Subcommand-based CLI for querying Google Analytics 4 via the Data API. Supports
standard reports (dimensions, metrics, filters, date ranges, ordering), realtime
data, and admin commands (list accounts, property details, custom dimensions and
metrics). Includes curated dimension and metric references and a `--json`
passthrough for complex filter logic.

Source:
- `skills/ga4-query/SKILL.md`
- `skills/ga4-query/references/dimensions.md`
- `skills/ga4-query/references/metrics.md`
- `skills/ga4-query/scripts/query.py`

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill ga4-query
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill ga4-query -g
```

### Agent Flight Recorder (`agent-flight-recorder`)

Recorder-only flight logger for agent runs. Logs only deviations from the
expected path (detours, retries, setup surprises, missing context, blockers,
quality rework) to per-run files.

Source:
- `skills/agent-flight-recorder/SKILL.md`

Run output:
- `.agents/flight-recorder/flight-YYYY-MM-DD-HHMMSS-TZ.md`
- File header schema: `flight-recorder/v2.5`
- Header includes recorder metadata: `recorder_agent` (product name), `recorder_model` (exact model ID), optional `recorder_effort` and `task`
- Run footer with `entries`, `high_severity`, `outcome` for quick scanning
- Entries include `at` timestamp (ISO-8601 with timezone) for ordering and duration estimation
- Default git hygiene: ignore `/.agents/flight-recorder/` in `.gitignore` (opt out only if intentionally versioning logs)

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill agent-flight-recorder
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill agent-flight-recorder -g
```

### Project instruction snippet

If you want to enforce usage in a specific project, add a short note to the
project's agent instruction file (for example `AGENTS.md`, `CLAUDE.md`, or
similar).

```md
### Flight Recorder (`agent-flight-recorder`)

- For long or multi-step tasks, use the `agent-flight-recorder` skill when available.
- If the skill is unavailable, manually write one run file under `.agents/flight-recorder/`.
- Log only deviations: retries, detours, missing tools, blocking missing context, assumptions, and quality rework.
- Do not mention the log mid-task.
- At task completion, if entries were created, include: `Flight recorder: N entries logged. See <path>.`
```

### Local Reference (`local-ref`)

Cache library documentation locally so every session reads from disk instead of
re-fetching from external sources. Supports Context7 API, WebFetch, and manual
sources. Includes commands for initializing a project doc cache (`local-ref init`),
looking up docs local-first (`local-ref lookup`), updating cached docs
(`local-ref update`), and opportunistically saving fetched docs (`local-ref save`).

Docs are written to `docs/reference/<topic>.md` — project-specific, 100-200 lines
each, with cross-references to actual project files. Each file includes a
machine-readable header (`<!-- source="..." cached="..." -->`) that enables
reliable automated updates.

Source:
- `skills/local-ref/SKILL.md`

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill local-ref
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill local-ref -g
```

### PR Review (`pr-review`)

Systematic PR review workflow for checking, responding to, and reporting on
feedback from any source — human reviewers, review bots (CodeRabbit, Gemini,
Codex, Snyk, etc.), or AI agents. Ensures all three feedback channels
(conversation, inline, reviews) are checked so no feedback is missed. When no
feedback exists, automatically invokes review agents. Supports a continuous
loop mode (invoke → check → fix → report → re-invoke) until all feedback is
resolved.

Includes helper scripts (relative to skill directory):

- `scripts/get-context.sh` — current branch, PR, changes, timestamp (entry point for state detection)
- `scripts/open-branch.sh` — ensure working tree is on a non-main branch (idempotent)
- `scripts/check-pr-feedback.sh` — check all three feedback channels for a PR
- `scripts/reply-to-inline.sh` — reply in-thread to inline comments
- `scripts/post-fix-report.sh` — post Fix Report as a PR conversation comment (file-path or stdin)
- `scripts/invoke-review-agents.sh` — trigger review agents with a single combined comment (`--format-only` for embedding in PR body)
- `scripts/create-pr.sh` — idempotent PR creation with branch safety (`--invoke` embeds agent triggers, `CREATED:`/`EXISTS:` output)
- `scripts/commit-and-push.sh` — stage, commit, and push with branch safety
- `scripts/wait-for-reviews.sh` — poll for new feedback after invoking agents
- `scripts/check-new-feedback.sh` — differential feedback check (new items only since timestamp)

Source:
- `skills/pr-review/SKILL.md`

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill pr-review
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill pr-review -g
```

### Project instruction snippet

If you want to enforce usage in a specific project, add a short note to the
project's agent instruction file (for example `AGENTS.md`, `CLAUDE.md`, or
similar).

```md
### PR Review Workflow (`pr-review`)

- When checking PR feedback, reviewing code review comments, or responding to reviews, always use the `pr-review` skill first.
- This ensures all three feedback channels are checked (conversation, inline, reviews) and no feedback is missed.
```

### SwiftBar (`swiftbar`)

Create, edit, and debug SwiftBar menu bar plugins for macOS. Covers the full
SwiftBar/BitBar output protocol, plugin naming conventions, metadata format,
SF Symbols, streamable plugins, and common patterns. Supports bash and Python
plugins. Includes a debug workflow for diagnosing broken plugins.

Source:
- `skills/swiftbar/SKILL.md`
- `skills/swiftbar/references/patterns.md`

Install to project scope:

```bash
npx skills add aivokone/ak-skills --skill swiftbar
```

Install globally:

```bash
npx skills add aivokone/ak-skills --skill swiftbar -g
```

## Agent Catalog

### PR Reviewer (`pr-reviewer`)

Sonnet-powered sub-agent that handles the full PR review lifecycle. Delegates
all PR workflow operations to an isolated context: checking feedback across all
channels, responding to reviewers, committing fixes, posting Fix Reports, and
running continuous review loops. Preloads the `pr-review` skill automatically.

Use proactively for any PR/code review work instead of running review operations
in the main conversation.

Source:
- `agents/pr-reviewer.md`

## Contributing / Adding Skills

This repo follows a progressive disclosure pattern: keep `SKILL.md` lean and
put detailed procedures under `references/`.

Policy: do not add `skills/<skill-name>/README.md`; keep agent-essential
behavior in `SKILL.md` and keep user-facing catalog details in root
`README.md`.

When adding a new skill or making a major update to an existing skill, update:
- `README.md` (both `Skills Index` and `Skill Catalog` section for that skill)
- `.claude-plugin/plugin.json` (plugin manifest)

Contributor conventions live in `AGENTS.md`.
