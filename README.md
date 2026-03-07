# plugin-design-advisor

A self-demonstrating Claude Code plugin that encodes heuristics for plugin design decisions.
The plugin's own architecture enacts the rules it teaches -- skill vs. agent vs. command vs. hook.

## Core Principle

**Skills inject knowledge into context. Agents spawn isolated Claude instances.**

This single sentence resolves most ambiguous cases. If you're building something to teach Claude
how to do X correctly, it's a skill. If you need separate context, tool permissions, or a
different model, it's an agent.

## What's Included

| Component                          | Purpose                                                  |
| ---------------------------------- | -------------------------------------------------------- |
| `skills/plugin-design-advisor/`    | Core heuristics for choosing the right plugin mechanism  |
| `agents/architecture-validator.md` | Audits existing plugin structure for misclassifications  |
| `agents/requirements-analyzer.md`  | Classifies task characteristics (Phase 2)                |
| `agents/constraint-extractor.md`   | Identifies parallelism/isolation/tiering needs (Phase 2) |
| `commands/design.md`               | Multi-phase design workflow (Phase 2)                    |
| `hooks/plugin-file-guard.json`     | Guards against accidental misclassification (Phase 3)    |
| `skills/decision-explorer/`        | Interactive decision tree for learners (Phase 4)         |

## Anti-Patterns Detected

The skill and architecture-validator identify these misclassifications:

- **Agent-as-skill** -- read-only agent with no isolation benefit; should be a skill
- **Skill-as-agent** -- domain knowledge buried in an agent prompt; should be a reusable skill
- **Procedure-as-skill** -- procedural workflow stuffed into a skill; should be an agent or command
- **Command-without-hook** -- system-event workflow implemented as explicit command; should be a hook
- **Hook-without-suppression** -- hook fires on every event without checking session state
- **MCP-for-no-reason** -- MCP server added without external service dependency

## Status

Phase 1 active: core skill content and test fixtures complete. Architecture-validator agent in progress.

See `docs/DESIGN.md` for the full design specification.
