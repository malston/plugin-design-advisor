---
name: decision-explorer
description: Interactive decision tree that guides you through choosing the right Claude Code plugin mechanism. Use when asked "help me choose", "decision tree", "I'm not sure whether to use", "skill or agent", or "command or hook".
---

# Decision Explorer

## When to invoke

Use this skill when someone asks for help choosing a plugin mechanism: "interactive decision",
"help me choose", "decision tree", "I'm not sure whether to use", "skill or agent", or
"command or hook".

This skill provides a guided conversational exploration that asks questions one at a time and
narrows the design space step by step. At the end, it produces a copyable architecture
recommendation with the chosen mechanism, rationale, and suggested file structure.

The plugin-design-advisor skill is a reference for heuristics and anti-patterns -- consult it
when you already know the landscape and need to look something up. This skill is for when you
don't know where to start. It walks you through the decision interactively, so you don't need
to read the full framework yourself.

---

## How to guide the user

### Conversational flow rules

Ask one question at a time. Present options as a numbered list. Wait for the user's answer before
proceeding to the next node -- do not skip ahead or combine questions.

With each question, provide the signal examples listed under that node. These help the user
recognize which answer fits their situation. If the user is unsure, talk through the signals
together before moving on.

Track the path taken: which questions were asked and how the user answered. Use this path summary
when generating the final recommendation so the rationale connects directly to the user's answers.

### Decision tree

#### Q1: Does this capability need its own context window?

Signals to consider:

- Subtask is large enough to fill a significant portion of the context window
- There are parallel independent workstreams
- A different model is appropriate for the subtask
- The subtask needs different tool permissions than the main context

Options:

1. **Yes** -- proceed to Q2a.
2. **No** -- proceed to Q3.

#### Q2a: Are there multiple independent subtasks that can run in parallel?

Signals to consider:

- Each subtask produces independent output
- There is no data dependency between subtasks
- Results are aggregated after all subtasks complete

Options:

1. **Yes** -- recommend **Agent (parallel)**. Note: if the domain knowledge driving these agents is
   reusable, consider pairing with a Skill that each agent loads at runtime.
2. **No** -- proceed to Q2b.

#### Q2b: Is the main benefit isolation, model tiering, or tool restriction?

Signals to consider:

- Subtask needs read-only tool access
- A cheaper model is sufficient for the subtask (e.g., extraction or formatting)
- Subtask output needs confidence scoring or structured filtering

Options:

1. **Yes** -- recommend **Agent (isolated)**.
2. **No** -- the capability may not need an agent after all. Revisit Q3 to evaluate whether it
   fits as a skill, command, or hook instead.

#### Q3: Is the trigger a user action or a system event?

Signals to consider for user action:

- User types a slash command
- User asks for a workflow by name or description

Signals to consider for system event:

- Fires on file write
- Fires on session start
- Fires on tool invocation

Options:

1. **User action** -- proceed to Q4a.
2. **System event** -- proceed to Q4c.

#### Q4a: Does it orchestrate multiple steps with user decisions between them?

Signals to consider:

- Workflow has analyze/plan/execute phases
- User reviews intermediate results before the next step
- Multiple agents are coordinated with results aggregated

Options:

1. **Yes** -- recommend **Command**.
2. **No** -- proceed to Q4b.

#### Q4b: Is it reusable domain knowledge or a one-off workflow?

Signals to consider for knowledge:

- Pattern libraries, coding standards, decision frameworks, reference material
- Content is useful across multiple tasks or agents
- Auto-invocation from conversation context is the right trigger

Signals to consider for workflow:

- Single-use procedure or one-time setup
- Steps are specific to one scenario

Options:

1. **Knowledge** -- recommend **Skill**.
2. **Workflow** -- recommend **Command (simple)**.

#### Q4c: Should it fire invisibly without user initiation?

Signals to consider:

- User would forget to invoke it manually
- Enforces conventions or guardrails automatically
- Action is lightweight and fast

Options:

1. **Yes** -- recommend **Hook**. Remind the user to include suppression logic so the hook
   doesn't fire redundantly (e.g., check session state or whether the relevant skill is already
   in context).
2. **No** -- recommend **Command** (user-triggered on event notification).
