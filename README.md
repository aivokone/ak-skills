# Aivokone Ops Skills (`ak-skills-ops`)

Platform- and tool-specific operational skills using the open [skills standard](https://skills.sh/).

This repo is for hosting platforms, deployment tools, infrastructure workflows,
and provider-specific operations.

This is a multi-skill repository: each skill is self-contained under `skills/<skill-name>/`.

## Install (skills.sh / npx skills)

```bash
# Install all skills from this repo to current project
npx skills add aivokone/ak-skills-ops
```

For full usage and installation details, see [skills.sh docs](https://skills.sh/docs).

## Skills Index

The table below is the canonical skills index for this repository.

| Name | Slug | Description |
|------|------|-------------|
| [Seravo Developer](skills/seravo-dev/) | `seravo-dev` | Seravo-hosted WordPress ops: custom `wp-*` CLI, Git deploys, DDEV local setup, DB sync, troubleshooting |
| [Google Ads Query](skills/google-ads-query/) | `google-ads-query` | Query Google Ads via GAQL: campaigns, conversions, keywords, ad performance, bidding |

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
npx skills add aivokone/ak-skills-ops --skill seravo-dev
```

Install globally:

```bash
npx skills add aivokone/ak-skills-ops --skill seravo-dev -g
```

### Google Ads Query (`google-ads-query`)

Read-only GAQL query tool for Google Ads accounts. Provides a lightweight Python
CLI (`gads` alias) that executes Google Ads Query Language queries and returns
structured JSON. Covers campaign performance, conversion tracking audits, keyword
analysis, search terms reports, and ad group metrics. Includes enum code reference
and pre-built query patterns for common reporting tasks.

Source:
- `skills/google-ads-query/SKILL.md`
- `skills/google-ads-query/references/enums.md`
- `skills/google-ads-query/scripts/query.py`

Install to project scope:

```bash
npx skills add aivokone/ak-skills-ops --skill google-ads-query
```

Install globally:

```bash
npx skills add aivokone/ak-skills-ops --skill google-ads-query -g
```

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
