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

If the goal is to teach Claude how to do something correctly, it's a skill. If the goal is to
run isolated work with its own context, tool permissions, or model tier, it's an agent. If the
goal is to orchestrate a multi-phase workflow triggered by the user, it's a command. If the
goal is to enforce something automatically on a system event, it's a hook.

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
| Explicit user trigger       | Maybe | No    | Yes     | No   |
| System event trigger        | No    | No    | No      | Yes  |
| Invisible to user           | No    | No    | No      | Yes  |
| Reusable across agents      | Yes   | No    | No      | No   |

### Decision sequence

1. **Does the capability encode knowledge that Claude should apply inline?** Skill.
   - Pattern libraries, coding standards, domain heuristics, decision frameworks.
   - The knowledge stays in the main conversation context.

2. **Does the work need isolation?** Agent.
   - Separate context window (subtask would exhaust the main one).
   - Restricted tool set (read-only analysis, no file writes).
   - Different model tier (Sonnet for reasoning, Haiku for extraction).
   - Parallel execution (multiple independent analyses).
   - Confidence-scored output that gets filtered before surfacing.

3. **Does the user explicitly trigger a multi-step workflow?** Command.
   - Predetermined phases with orchestration logic.
   - Aggregates results from multiple agents.
   - `/slash-command` invocation is the natural trigger.

4. **Should it fire automatically on a system event?** Hook.
   - PreToolUse, PostToolUse, SessionStart, or other lifecycle events.
   - The user would forget to ask for this manually.
   - Must be invisible and low-noise.

5. **Does an agent need injected domain knowledge?** Skill + Agent.
   - The skill provides reusable expertise; the agent provides isolation.
   - Same skill can serve multiple agents in the plugin.

---

## Detailed Heuristics

### Skills

**Use when:** You have domain knowledge, patterns, or decision frameworks that Claude should
apply within the current conversation. The knowledge is reusable and benefits from auto-invocation
based on natural language triggers.

**Signals:**

- Content is reference material, not a procedure
- Auto-invocation from conversation context is the right trigger
- No need for separate context, tool restrictions, or model tiering
- Knowledge applies across multiple tasks or agents
- Context cost of injecting the skill is acceptable (target < 2,000 words)

**Anti-signals:**

- The "skill" mostly runs tools and produces structured output (that's an agent)
- The knowledge is only useful to one specific agent (embed it in the agent prompt)
- The content is so large it would crowd out the user's actual task

**Structure:** Progressive disclosure. Lean trigger section first (~200 words), then layers of
detail. Claude reads what it needs and stops.

### Agents

**Use when:** The work benefits from isolation -- separate context, restricted tools, a different
model, or parallel execution.

**Signals:**

- Subtask is large enough to fill a significant portion of the context window
- Read-only analysis where tool restrictions improve safety
- Model tiering saves cost or matches capability to task (Sonnet for reasoning, Haiku for extraction)
- Multiple independent subtasks that can run in parallel
- Output needs confidence scoring or structured filtering
- Well-defined input/output contract

**Anti-signals:**

- Agent does trivial work that could be a prompt section (agent-as-skill anti-pattern)
- No parallelism, no isolation, no tiering benefit -- just added latency
- Agent shares most of the main context anyway

**Output format:** Structured JSON with pre-filled assistant message and stop sequence pattern.
Define the schema explicitly so callers can parse results reliably.

### Commands

**Use when:** A multi-phase workflow needs orchestration, and the user explicitly invokes it.

**Signals:**

- Workflow has predetermined steps (analyze, plan, execute, verify)
- Orchestrates multiple agents and aggregates their results
- `/slash-command` invocation feels natural
- User needs to see intermediate progress or make decisions between phases

**Anti-signals:**

- Single-step action that doesn't need orchestration (just use a skill or agent)
- Trigger should be a system event, not user action (that's a hook)

### Hooks

**Use when:** Automation should be invisible, event-driven, and low-noise.

**Signals:**

- Trigger is a system event: file write, session start, tool invocation
- Guidance the user would otherwise forget to request
- Enforcement of conventions or guardrails
- Action is lightweight and fast

**Anti-signals:**

- Hook fires too often, producing noise (needs suppression logic)
- Action requires user judgment or decisions (make it a command)
- Action is expensive or slow (agents triggered by hooks need careful gating)

**Suppression:** Consider how to avoid redundant firings. Track whether the relevant skill is
already in context, or use path filters to limit scope.

### MCP Servers

**Almost never the right choice for a plugin.** Only justified when the plugin genuinely wraps
an external service with its own protocol, authentication, or persistent connection.

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
**Why not a skill?** Review analysis is too large for inline context; each domain agent can fill
a significant portion of its context window.

### feature-dev: Command + 3 agents + frontend-design skill

**Why command?** Feature development has distinct phases (understand, plan, implement) with user
decisions between them.
**Why skill + agent?** The `frontend-design` skill injects design expertise into the relevant
agent. The same skill could serve other plugins that need design knowledge.
**Why not all agents?** The design knowledge is reusable reference material, not an isolated task.

### playground: Pure skill

**Why skill?** Encodes a behavior pattern that Claude applies inline. Auto-invoked when the
conversation context matches. No parallelism, no isolation, no orchestration needed.
**Why not an agent?** No benefit from a separate context window. The knowledge is small and
directly useful in the main conversation.

### hookify: Agent + skill

**Why agent?** Analyzing conversation patterns for hook opportunities benefits from isolated
context and structured output.
**Why skill?** Rule-writing knowledge is reusable reference material that the agent needs
injected. Other plugins could reuse the same skill for hook authoring.

### claude-code-setup: Pure skill

**Why skill?** Read-only analysis and knowledge injection. The setup guidance is reference
material applied inline. No isolation, parallelism, or orchestration needed.
**Why not an agent?** Adding a separate Claude instance would add latency for zero benefit.
The knowledge fits comfortably in the main context.
