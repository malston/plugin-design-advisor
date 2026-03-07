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

---

## plugin-file-guard hook: suppression logic in external script

**Paths:** `hooks/hooks.json`

The architecture-validator flags this as hook-without-suppression because the JSON
config has a broad `Write|Edit` matcher with no path filtering or dedup logic in the
JSON itself. This is expected -- the hook delegates to `hooks/plugin-file-guard.sh`
which implements:

1. Walk-up path detection (max 4 parent directories for `.claude-plugin/plugin.json`)
2. Path filtering (only fires for files under `agents/` or `skills/`)
3. Session dedup (tracks fired file paths via temp files keyed by session ID)

The Claude Code hook JSON format cannot express these constraints declaratively.
The bash script is the suppression mechanism.

Accept this finding as a known limitation of the hook config format.
