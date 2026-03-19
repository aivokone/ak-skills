# 002: Add open-source review tools with configurable model providers

**Status:** Open
**Skill:** cli-review-fix
**Created:** 2026-03-19

## Summary

Add support for open-source CLI tools that can run code reviews using models
from any provider (e.g., OpenRouter, Ollama, self-hosted). This would allow
users to run reviews without requiring Codex or Gemini CLI subscriptions.

## Motivation

Currently, `cli-review-fix` only supports two vendor-locked CLIs:

- **Codex CLI** — requires OpenAI API key, uses OpenAI models only
- **Gemini CLI** — requires Google auth, uses Gemini models only

Open-source tools like Aider and Goose support multiple model providers
(OpenRouter, Ollama, Azure, AWS Bedrock, etc.), giving users flexibility to
choose models based on cost, privacy, or capability. This also enables running
reviews with frontier models from any provider via OpenRouter.

## Candidate tools

### Aider

- **Repo:** https://github.com/paul-gauthier/aider
- **Review capability:** Has built-in code review support
- **Model support:** OpenRouter, Ollama, OpenAI, Anthropic, Azure, many others
- **Config:** `.aider.conf.yml`, `--model` flag
- **Install:** `pip install aider-chat`
- **Check:** `command -v aider`

### Goose

- **Repo:** https://github.com/block/goose
- **Review capability:** General-purpose coding agent, can be prompted for review
- **Model support:** OpenRouter, Ollama, OpenAI, Anthropic, Google
- **Config:** `~/.config/goose/config.yaml`, profiles with provider settings
- **Install:** platform-specific (brew, cargo, binary)
- **Check:** `command -v goose`

## Proposed design

### Integration pattern

Follow the same pattern as existing Codex/Gemini support:

1. Add tool entry to prerequisites table in SKILL.md
2. Add CLI commands table in SKILL.md and `references/cli-commands.md`
3. Add availability check to `scripts/cli-review-detect.sh`
4. Add tool to the engine agreement/deduplication logic
5. Update config schema (ticket #001) to support new engines

### Detect script changes

Add to `cli-review-detect.sh` output:
```json
{
  "aider": true,
  "goose": false
}
```

### Invocation examples

```
/cli-review-fix aider          # Aider only
/cli-review-fix goose          # Goose only
/cli-review-fix aider,codex    # Aider + Codex in parallel
/cli-review-fix                # All available tools
```

### Review prompt

Both Aider and Goose would need review prompts similar to the Gemini prompt
in `references/review-prompt.md`, since neither has a dedicated review
subcommand like Codex.

## Research needed

- Verify Aider's exact CLI flags for non-interactive review mode
- Verify Goose's CLI flags for non-interactive prompt mode
- Determine how each tool handles piped diffs vs reading from repo
- Test review quality with various OpenRouter models (e.g., Claude, GPT-4,
  Llama, DeepSeek)
- Evaluate whether both tools are worth supporting or if one covers the use
  case sufficiently

## Open questions

- Should this be implemented together with ticket #001 (config file), since
  model provider configuration is essential for these tools?
- Should there be a generic "custom CLI" escape hatch for tools not explicitly
  supported?
- How to handle the multi-engine agreement analysis when 3+ engines are used?
