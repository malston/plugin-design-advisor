# plugin-design-advisor

A self-demonstrating Claude Code plugin that encodes heuristics for plugin design decisions.
The plugin's own architecture enacts the rules it teaches.

## Project Purpose

Developers building Claude Code plugins frequently choose the wrong mechanism (skill vs. agent
vs. command vs. hook), producing plugins that are slow, brittle, or hard to maintain. This plugin
encodes the selection heuristics and demonstrates them through its own structure.

## Core Principle

**Skills inject knowledge into context. Agents spawn isolated Claude instances.**

This single sentence resolves most ambiguous cases. If you're building something to teach Claude
how to do X correctly → skill. If you need separate context, separate tool permissions, or a
separate model → agent.

## Architecture

```sh
plugin-design-advisor/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest
├── commands/
│   └── design.md                      # /plugin-design-advisor:design
├── agents/
│   ├── requirements-analyzer.md       # Classifies task characteristics (Sonnet, read-only)
│   ├── constraint-extractor.md        # Identifies parallelism/isolation/tiering needs (Sonnet, read-only)
│   └── architecture-validator.md      # Audits existing plugin structure (Sonnet, read-only)
├── skills/
│   ├── plugin-design-advisor/
│   │   └── SKILL.md                   # Core heuristics — the primary artifact
│   └── decision-explorer/
│       └── SKILL.md                   # Interactive HTML decision tree for learners
├── hooks/
│   └── plugin-file-guard.json         # PreToolUse on Write/Edit to agents/ and skills/ paths
├── tests/
│   └── fixtures/
│       └── misclassified-plugin/      # 6 misclassifications across 4 anti-pattern types
└── README.md
```

## Implementation Phases

- **Phase 1 (complete):** Core skill + architecture-validator agent + validate command
  - Validator correctly identifies all 4 anti-pattern types
  - Self-audit passes: 0 critical findings against own source
  - Known pattern: agent must load skill at runtime to avoid definition drift
- **Phase 2 (complete):** Design command + requirements-analyzer + constraint-extractor agents
  - `/plugin-design-advisor:design` orchestrates parallel analysis via Task tool
  - `DECISIONS.md` suppression for intentional deviations
- **Phase 3:** plugin-file-guard hook (after Phase 1 signal:noise is measured)
- **Phase 4:** decision-explorer playground skill

## Primary Heuristics (seed content for SKILL.md)

### Use a skill when

- Encoding domain knowledge/patterns for Claude to apply inline
- Auto-invocation from natural language is the right trigger
- Knowledge is reusable across multiple agents
- Work stays in the main context; context cost is acceptable

### Use an agent when

- Parallel or isolated workstreams needed
- Different tool restrictions per subtask
- Model tiering by subtask (e.g., Sonnet for reasoning, Haiku for structured extraction)
- Subtask large enough to exhaust context alone
- Well-defined input/output contract
- Confidence-based filtering needed

### Use a command when

- Multi-phase workflow with predetermined steps
- Explicit user invocation is the correct trigger
- Orchestrating agents with aggregation

### Use a hook when

- Automation should be invisible and event-driven
- Trigger is a system event (file write, session start, tool use)
- Guidance the user would otherwise forget to request

### Use skill + agent when

- Agent needs injected domain knowledge
- Same knowledge reusable across multiple agents in the plugin

## Anti-Patterns to Encode

- **Agent-as-skill:** Read-only agent with no parallelism/isolation/tiering benefit -- just adds latency
- **Skill-as-agent:** Domain knowledge buried in agent prompt that should be a reusable skill
- **Procedure-as-skill:** Multi-step procedural workflow stuffed into a skill instead of an agent or command
- **Command-without-hook:** Workflow triggered by system event but implemented as explicit command
- **Hook-without-suppression:** Hook fires repeatedly in same session, producing noise
- **MCP-for-no-reason:** MCP server added without genuine external service dependency

## Reference Plugins (for worked examples in SKILL.md)

| Plugin            | Classification                             | Reason                                                              |
| ----------------- | ------------------------------------------ | ------------------------------------------------------------------- |
| pr-review-toolkit | Command + 6 parallel agents                | Each domain needs isolated context; confidence scoring per agent    |
| feature-dev       | Command + 3 agents + frontend-design skill | Phase isolation; skill injects design expertise into relevant agent |
| hookify           | Agent + skill                              | Agent analyzes behavior; skill provides rule-writing knowledge      |
| claude-code-setup | Pure skill                                 | Read-only analysis; knowledge injected inline is correct pattern    |

## Key Design Decisions & Open Questions

### Decided

- MCP server: out of scope -- no external service dependency justified
- Agent model: Sonnet for all analysis agents (not Haiku -- reasoning quality matters)
- Validator output format: `{ component, finding_type, severity, recommendation }`
- Hook path filter: walk up max 4 directories looking for `.claude-plugin/plugin.json`

### Open

- Hook suppression: how to detect if main skill is already in context this session?
- Validator false positives: resolved -- `DECISIONS.md` suppression implemented in Phase 2
- decision-explorer state: stateless HTML artifact acceptable, or persist via storage API?
- Agent schema versioning: maintenance contract when heuristics evolve?

## Success Criteria

| Criterion                            | Pass                                                                     |
| ------------------------------------ | ------------------------------------------------------------------------ |
| Skill auto-invokes reliably          | Fires on plugin design phrases; does not fire on unrelated tasks         |
| Command produces actionable output   | Architecture recommendation with component-level justification           |
| Validator catches misclassifications | Identifies >=3 of 4 intentional misclassifications in test plugin        |
| Hook signal:noise                    | >=90% relevant writes, <=5% irrelevant writes                            |
| Self-consistency                     | Validator run against this plugin's own source -> zero critical findings |
