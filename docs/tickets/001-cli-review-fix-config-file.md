# 001: Add configuration file for cli-review-fix

**Status:** Open
**Skill:** cli-review-fix
**Created:** 2026-03-19

## Summary

Add a dedicated configuration file to the `cli-review-fix` skill that allows
users to define default review tools, their language models, and other settings.

## Motivation

Currently, `/cli-review-fix` launches all available CLIs with their default
models and settings. Users have no way to:

- Set which CLIs to run by default (e.g., always Codex only)
- Configure which language model each CLI should use (e.g., Gemini Pro vs Flash)
- Customize review behavior per project without modifying the skill itself

A configuration file would make the skill adaptable to different project needs
without requiring argument flags on every invocation.

## Proposed Design

### Configuration file location

Check in order:
1. `.cli-review-fix.yml` in project root (project-specific config)
2. `~/.config/cli-review-fix/config.yml` (user-global config)
3. Built-in defaults (current behavior)

### Configuration schema

```yaml
# .cli-review-fix.yml
engines:
  codex:
    enabled: true
    # model: default        # model selection if supported by CLI
  gemini:
    enabled: true
    model: pro              # "auto", "flash", "pro"

# Severity threshold — only report findings at this level or above
min_severity: medium        # "critical", "high", "medium", "low"

# Auto-fix behavior
auto_fix: true              # false = review only, no fixes applied
```

### Behavior

- Config is loaded at the start of execution, before the detect script
- CLI arguments override config (e.g., `/cli-review-fix codex` overrides
  `engines.gemini.enabled: true`)
- Missing config file → use defaults (all engines enabled, default models)
- Invalid config → warn and fall back to defaults

## Files to modify

- `skills/cli-review-fix/SKILL.md` — add Configuration section
- `skills/cli-review-fix/scripts/cli-review-detect.sh` — optionally read config
- `skills/cli-review-fix/evals.json` — add config-related test cases

## Open questions

- Should the config file also support per-directory overrides (monorepo use case)?
- Should the detect script parse the config, or should the agent read it directly?
- Is YAML the right format, or would JSON be simpler (no extra dependency)?
