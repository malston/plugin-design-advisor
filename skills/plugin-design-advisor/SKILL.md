---
name: plugin-design-advisor
description: Heuristics for choosing the right Claude Code plugin mechanism -- skill, agent, command, or hook. Use when designing, reviewing, or refactoring plugin architecture.
status: active
phase: 1
---

# Plugin Design Advisor

## When to invoke

Use this skill when you are deciding how to structure a Claude Code plugin, reviewing an existing
plugin's architecture, or debating whether something should be a skill, agent, command, or hook.

**The core rule:** Skills inject knowledge into context. Agents spawn isolated Claude instances.
Commands orchestrate multi-step workflows. Hooks automate invisible, event-driven actions.

When unsure, ask: "Does this need its own context window?" If yes, agent. If no, skill. Then
ask: "Is the trigger a user action or a system event?" User action: command. System event: hook.

See the decision framework below for the full matrix.

---

## Decision Framework

### Quick classification matrix

| Signal                      | Skill | Agent | Command | Hook |
| --------------------------- | ----- | ----- | ------- | ---- |
| Injects domain knowledge    | Yes   | No    | No      | No   |
| Needs isolated context      | No    | Yes   | No      | No   |
| Parallel workstreams        | No    | Yes   | No      | No   |
| Different model per subtask | No    | Yes   | No      | No   |
| Multi-phase orchestration   | No    | No    | Yes     | No   |
| Explicit user trigger       | Maybe | Maybe | Yes     | No   |
| System event trigger        | No    | No    | No      | Yes  |
| Invisible to user           | No    | No    | No      | Yes  |
| Reusable across agents      | Yes   | No    | No      | No   |

### Heuristics by mechanism

**1. Does the capability encode knowledge that Claude should apply inline? Skill.**

_Signals:_ Pattern libraries, coding standards, domain heuristics, decision frameworks.
Content is reference material, not a procedure. Auto-invocation from conversation context is the
right trigger. Knowledge applies across multiple tasks or agents. Context cost is acceptable
(target < 2,000 words).

_Anti-signals:_ The "skill" mostly runs tools and produces structured output (that's an agent).
The knowledge is only useful to one specific agent (embed it in the agent prompt). The content
is so large it would crowd out the user's actual task.

_Structure:_ Progressive disclosure. Lean trigger section first (~200 words), then layers of
detail. Claude reads what it needs and stops.

**2. Does the work need isolation? Agent.**

_Signals:_ Subtask is large enough to fill a significant portion of the context window. Read-only
analysis where tool restrictions improve safety. Model tiering saves cost or matches capability
to task (Sonnet for reasoning, Haiku for extraction). Multiple independent subtasks that can run
in parallel. Output needs confidence scoring or structured filtering. Well-defined input/output
contract.

_Anti-signals:_ Agent does trivial work that could be a prompt section (agent-as-skill
anti-pattern). No parallelism, no isolation, no tiering benefit -- just added latency. Agent
shares most of the main context anyway.

_Output format:_ Structured JSON with pre-filled assistant message and stop sequence pattern.
Define the schema explicitly so callers can parse results reliably.

**3. Does the user explicitly trigger a multi-step workflow? Command.**

_Signals:_ Workflow has predetermined steps (analyze, plan, execute, verify). Orchestrates
multiple agents and aggregates their results. `/slash-command` invocation feels natural. User
needs to see intermediate progress or make decisions between phases.

_Anti-signals:_ Single-step action that doesn't need orchestration (just use a skill or agent).
Trigger should be a system event, not user action (that's a hook).

**4. Should it fire automatically on a system event? Hook.**

_Signals:_ Trigger is a system event: file write, session start, tool invocation. Guidance the
user would otherwise forget to request. Enforcement of conventions or guardrails. Action is
lightweight and fast.

_Anti-signals:_ Hook fires too often, producing noise (needs suppression logic). Action requires
user judgment or decisions (make it a command). Action is expensive or slow (agents triggered by
hooks need careful gating).

_Suppression:_ Consider how to avoid redundant firings. Track whether the relevant skill is
already in context, or use path filters to limit scope.

**5. Does an agent need injected domain knowledge? Skill + Agent.**

The skill provides reusable expertise; the agent provides isolation. Same skill can serve
multiple agents in the plugin.

**6. Almost never: MCP Server.**

Only justified when the plugin genuinely wraps an external service with its own protocol,
authentication, or persistent connection.

---

## Anti-Patterns

### Agent-as-skill

A read-only agent with no parallelism, isolation, or tiering benefit. It spawns a separate Claude
instance just to answer a question that could be handled by injecting knowledge into the main
context. The result: added latency, added cost, no benefit. Fix: convert to a skill.

### Skill-as-agent

Domain knowledge buried in an agent prompt instead of a reusable skill. Other agents that need
the same knowledge can't access it. The knowledge isn't auto-invocable from conversation context.
Fix: extract the knowledge into a skill; have the agent reference it.

### Procedure-as-skill

A multi-step procedural workflow stuffed into a skill. The "skill" executes tools, manages state,
and makes decisions based on outputs -- none of which is knowledge injection. Fix: convert to an
agent (if it needs isolation) or a command (if it needs orchestration and user decisions).

### Command-without-hook

A workflow that should trigger on a system event but is implemented as an explicit command the
user must remember to invoke. Users forget; the guardrail fails silently.
Fix: implement as a hook, or add a hook that reminds/invokes the command.

### Hook-without-suppression

A hook that fires on every matching event without checking whether its action is already in
effect. Produces noise, erodes trust, and trains users to ignore hook output.
Fix: add suppression logic -- check session state or context before acting.

### MCP-for-no-reason

An MCP server added to a plugin that doesn't wrap an external service. MCP adds protocol
overhead, deployment complexity, and a maintenance burden with no payoff.
Fix: use skills, agents, or commands instead.

---

## Worked Examples

### pr-review-toolkit: Command + 6 parallel agents

**Why command?** Code review is a multi-phase workflow: gather PR context, run domain-specific
analyses, aggregate findings. The user explicitly triggers it with `/review-pr`.
**Why 6 agents?** Each review domain (security, performance, style, testing, architecture, docs)
needs isolated context and can run in parallel. Confidence scoring per agent filters low-signal
findings before surfacing.
**Not a skill** -- review analysis is too large for inline context.

### feature-dev: Command + 3 agents + frontend-design skill

**Why command?** Feature development has distinct phases (understand, plan, implement) with user
decisions between them.
**Why skill + agent?** The `frontend-design` skill injects design expertise into the relevant
agent. The same skill could serve other plugins that need design knowledge.
**Not all agents** -- the design knowledge is reusable reference material, not an isolated task.

### hookify: Agent + skill

**Why agent?** Analyzing conversation patterns for hook opportunities benefits from isolated
context and structured output.
**Why skill?** Rule-writing knowledge is reusable reference material that the agent needs
injected. Other plugins could reuse the same skill for hook authoring.

### claude-code-setup: Pure skill

**Why skill?** Read-only analysis and knowledge injection. The setup guidance is reference
material applied inline. No isolation, parallelism, or orchestration needed.
**Not an agent** -- zero benefit from a separate context window.
