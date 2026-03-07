# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin that encodes heuristics for plugin design decisions (skill vs. agent vs.
command vs. hook). The plugin's own architecture demonstrates the rules it teaches. See
`docs/DESIGN.md` for the full design specification, phase plan, and open questions.

**Core principle:** Skills inject knowledge into context. Agents spawn isolated Claude instances.

## Implementation Status

- **Phase 1 (active):** Core skill (`skills/plugin-design-advisor/SKILL.md`) + architecture-validator agent
- **Phase 2:** Design command + requirements-analyzer + constraint-extractor agents
- **Phase 3:** plugin-file-guard hook
- **Phase 4:** decision-explorer playground skill

## Plugin Structure

This is a Claude Code plugin (`.claude-plugin/plugin.json`). Components:

- `skills/` -- Markdown SKILL.md files with frontmatter. Content follows progressive disclosure: lean trigger section (~200 words max), then layered detail.
- `agents/` -- Markdown agent definitions with frontmatter (`description`, `model`, `tools`). All agents use Sonnet. All output structured JSON.
- `commands/` -- Markdown command files for user-invoked workflows.
- `hooks/` -- JSON hook definitions for event-driven automation.
- `tests/fixtures/misclassified-plugin/` -- Test plugin with 6 intentional misclassifications across 4 anti-pattern types (agent-as-skill, procedure-as-skill, command-without-hook, hook-without-suppression) for validating the architecture-validator agent.

## Coding Conventions

- All agent outputs: structured JSON using pre-filled assistant message + stop sequence pattern
- Hook path detection: walk up max 4 directories looking for `.claude-plugin/plugin.json`; prefer false negatives over false positives
- Self-audit: run architecture-validator against this repo before shipping any phase
- Anti-patterns tracked in SKILL.md: agent-as-skill, skill-as-agent, procedure-as-skill, command-without-hook, hook-without-suppression, MCP-for-no-reason

## Key Design Decisions

- No MCP server -- no external service dependency justifies one
- Sonnet for all analysis agents (not Haiku -- reasoning quality matters)
- Validator output: `{ component, finding_type, severity, recommendation }`
