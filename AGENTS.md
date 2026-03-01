# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Repository Purpose

This is **ak-skills**: a multi-skill repository for **agent skills** — operational tools, documentation workflows, and development practices. Each skill is self-contained in its own directory under `skills/`.

## Architecture

### Repository Structure

```
ak-skills/
├── AGENTS.md                    # Repo-level agent guidance (this file)
├── CLAUDE.md                    # Claude-specific overrides (keep minimal)
├── README.md                    # Repository index / public landing page
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/                      # Plugin-level sub-agents
│   └── <agent-name>.md          # Agent definition (frontmatter + system prompt)
└── skills/                      # All skills live here
    └── <skill-name>/            # Each skill is self-contained
        ├── SKILL.md             # Skill entry point
        ├── evals.json           # Per-skill evaluations
        └── references/          # Skill-specific references
```

**Progressive Disclosure Pattern**: Each skill's SKILL.md is intentionally lean (under 500 lines) and references external files. This reduces context usage - load only the specific section needed for a task rather than the entire guide.

### Skill Structure Convention (Per-Skill File Contract)

Each skill follows this pattern:
- `SKILL.md` - Skill definition with frontmatter (`name`, `description`) and core guidance
- `evals.json` - Evaluation test cases with prompts and expected outcomes
- `references/` - Detailed procedures and topic-specific documentation

Per-skill `README.md` files are not used in this repository.

### Agent Structure Convention

Agents are markdown files in `agents/` with YAML frontmatter and a system prompt body:
- `name` (required) — agent slug, used for invocation
- `description` (required) — when to use this agent (drives proactive delegation)
- `model` — model to run on (e.g., `sonnet`, `haiku`, `opus`)
- `skills` — list of skill slugs to preload into the agent's context
- `tools` — comma-separated list of tools the agent can use

Agents are auto-discovered by the plugin system from the `agents/` directory. No `plugin.json` registration needed.

### Current Skills

Keep the skill list and per-skill descriptions in the root `README.md`.

### Root README Requirements

Treat root `README.md` as the public landing page. Keep it in sync with the
actual skills.

- `Skills Index` is the canonical compact list of all skills.
- In `Skills Index`, include both human-readable skill name and slug.
- `Skill Catalog` contains one subsection per skill with:
  - heading format: `### Human Name (`skill-slug`)`
  - short practical description
  - source paths (at least `skills/<skill-name>/SKILL.md`)
  - per-skill install commands using `npx skills add ... --skill <skill-name>`
    for project and global (`-g`) installs
- On major behavior changes to an existing skill, update that skill's catalog
  subsection in root `README.md`.

## Working with This Repository

### Editing Skills

When modifying a skill's SKILL.md:
- Keep the main file lean - move detailed procedures to `references/` subdirectories
- Preserve the frontmatter format (`---` delimiters with `name` and `description`)
- Use searchable keywords in references so `rg` searches find relevant content
- Do not add `skills/<skill-name>/README.md`; keep agent-essential behavior in `SKILL.md` and user-facing catalog details in root `README.md`

### Adding a New Skill

1. Create `skills/<skill-name>/` directory
2. Add `SKILL.md` with frontmatter (`name`, `description`)
3. Add `evals.json` with test cases
4. Add `references/` for detailed documentation
5. Update root `README.md`:
   - add row to `Skills Index`
   - include both human-readable name and slug in that row
   - add/update per-skill subsection in `Skill Catalog`
   - use heading format: `### Human Name (`skill-slug`)`
   - include project and global install commands for that skill
6. Update `.claude-plugin/plugin.json` (plugin manifest)

### Adding a New Agent

1. Create `agents/<agent-name>.md`
2. Add frontmatter with `name` and `description` (required), plus `model`, `skills`, `tools` as needed
3. Write system prompt as the markdown body
4. Update root `README.md` — add to Agents Index and Agent Catalog
5. No `plugin.json` update needed (auto-discovered from `agents/`)

### Major Skill Updates

When a skill changes significantly (new output format, behavior model, or
activation/reporting semantics), update at minimum:

1. `skills/<skill-name>/SKILL.md`
2. `skills/<skill-name>/evals.json`
3. Root `README.md` `Skill Catalog` subsection for that skill

### Adding Reference Content

Within a skill:
- Create numbered or topic-named markdown files in `references/`
- Create index files when you have many sections
- Use clear file naming for easy discovery

### Evaluation Cases

Format in each skill's `evals.json`:
```json
{
  "name": "Test case name",
  "prompt": "User prompt to test",
  "expectations": ["Expected behavior 1", "Expected behavior 2"]
}
```

## Public Repo Hygiene

- Do not add secrets (API keys, credentials, private hostnames, customer data) to skills or references.
- Prefer placeholders in examples (`example.com`, `USER`, `PROJECT_ID`) unless the target is explicitly public.

## Search Patterns

Search within a specific skill:
```bash
rg -n "keyword" skills/<skill-name>/references/
```

Search across all skills:
```bash
rg -n "keyword" skills/*/references/
```

Then open only the matching section file rather than loading everything.
