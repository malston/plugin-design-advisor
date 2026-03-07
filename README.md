# plugin-design-advisor

A self-demonstrating Claude Code plugin that encodes heuristics for plugin design decisions.
The plugin's own architecture enacts the rules it teaches -- skill vs. agent vs. command vs. hook.

## Core Principle

**Skills inject knowledge into context. Agents spawn isolated Claude instances.**

This single sentence resolves most ambiguous cases. If you're building something to teach Claude
how to do X correctly, it's a skill. If you need separate context, tool permissions, or a
different model, it's an agent.

## What's Included

| Component                          | Purpose                                                 |
| ---------------------------------- | ------------------------------------------------------- |
| `skills/plugin-design-advisor/`    | Core heuristics for choosing the right plugin mechanism |
| `agents/architecture-validator.md` | Audits existing plugin structure for misclassifications |
| `agents/requirements-analyzer.md`  | Classifies task characteristics                         |
| `agents/constraint-extractor.md`   | Identifies parallelism/isolation/tiering needs          |
| `commands/design.md`               | Multi-phase design workflow with parallel analysis      |
| `commands/validate.md`             | Run architecture-validator against a plugin directory   |
| `hooks/hooks.json`                 | PreToolUse guard on Write/Edit to agents/ and skills/   |
| `skills/decision-explorer/`        | Interactive decision tree for learners (Phase 4)        |

## Anti-Patterns Detected

The skill and architecture-validator identify these misclassifications:

- **Agent-as-skill** -- read-only agent with no isolation benefit; should be a skill
- **Skill-as-agent** -- domain knowledge buried in an agent prompt; should be a reusable skill
- **Procedure-as-skill** -- procedural workflow stuffed into a skill; should be an agent or command
- **Command-without-hook** -- system-event workflow implemented as explicit command; should be a hook
- **Hook-without-suppression** -- hook fires on every event without checking session state
- **MCP-for-no-reason** -- MCP server added without external service dependency

## Status

- **Phase 1 (complete):** Core skill + architecture-validator agent
- **Phase 2 (complete):** Design command + parallel analyzer agents
- **Phase 3 (complete):** plugin-file-guard PreToolUse hook
- **Phase 4 (planned):** decision-explorer interactive skill

See `docs/DESIGN.md` for the full design specification.
