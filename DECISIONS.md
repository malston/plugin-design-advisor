# Architecture Decisions

Documented deviations from the plugin-design-advisor heuristics, reviewed and accepted.
The architecture-validator downgrades findings to info severity when a component's path
appears in this file.

---

## requirements-analyzer and constraint-extractor: intentional agent-as-skill exception

**Paths:** `agents/requirements-analyzer.md`, `agents/constraint-extractor.md`

The architecture-validator flags these as agent-as-skill anti-patterns. This is
a deliberate deviation. Justification:

1. The design command runs both agents in parallel via the Task tool -- the parallelism is real,
   it lives in the orchestrator not the agents themselves.
2. This plugin is self-demonstrating. Collapsing these into skill sections would
   remove the only example of parallel agent orchestration in the plugin's own
   architecture, breaking the self-proof annotation.
3. Both have well-defined I/O contracts (structured JSON schemas) that are consumed
   programmatically by the design command.

Accept this finding as a known deviation. Do not convert to skills.
