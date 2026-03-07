---
description: Analyze a feature description and recommend the right plugin mechanism (skill, agent, command, or hook)
argument-hint: <feature description>
allowed-tools: Read, Task
---

## Prerequisite

Before producing your recommendation, read `skills/plugin-design-advisor/SKILL.md` to load
the decision framework. Use it to map agent outputs to mechanism recommendations.

## Input validation

The feature description is: $ARGUMENTS

Before launching analysis, validate the input:

1. If the description is fewer than 10 words OR does not describe a clear capability (no verb
   indicating what the feature does), ask ONE clarifying question to get a more specific
   description. Do not launch agents until you have a usable description.

2. Once you have a valid description, proceed to analysis.

## Analysis

Launch the **requirements-analyzer** and **constraint-extractor** agents in parallel using
the Task tool. Pass the feature description to each agent.

- requirements-analyzer classifies: task_type, trigger, context_need, reusability
- constraint-extractor identifies: needs_parallelism, needs_tool_isolation, needs_model_tiering,
  context_budget, has_io_contract

Wait for both agents to complete. If one agent fails or returns malformed JSON, proceed with
the available output and note the gap in your recommendation.

## Recommendation

Aggregate the two JSON outputs and produce a structured recommendation:

### 1. Component list

For each component the feature needs, specify:

- **Type**: skill, agent, command, or hook
- **Purpose**: what this component does
- **Justification**: which signals from the analysis drove this choice (reference specific
  field values from the agent outputs)

Use the decision framework from `skills/plugin-design-advisor/SKILL.md` to map signals to
mechanisms:

- task_type=knowledge + context_need=inline + trigger=natural → skill
- task_type=action + context_need=isolated + has_io_contract=true → agent
- needs_parallelism=true → multiple agents (one per independent domain)
- task_type=workflow + trigger=explicit → command
- trigger=event → hook
- reusability=true + context_need=inline → extract shared knowledge into a skill

### 2. Confidence level

Rate your recommendation as **high**, **medium**, or **low** with reasoning:

- **High**: All signals align clearly with one mechanism pattern
- **Medium**: Most signals align but one or two are ambiguous
- **Low**: Signals conflict or the description is too abstract for certainty

### 3. Self-proof annotation

Identify which component of THIS plugin (plugin-design-advisor) demonstrates the
recommended pattern. For example:

- If recommending a skill → point to `skills/plugin-design-advisor/SKILL.md`
- If recommending parallel agents → point to requirements-analyzer + constraint-extractor
- If recommending a command → point to this design command
- If recommending a hook → note that `hooks/plugin-file-guard.json` is planned for Phase 3

This self-proof validates that the recommendation follows a proven pattern within the
plugin's own architecture.

### Output format

Present the recommendation in this structure:

```
## Recommended Architecture

### Components

| # | Type    | Purpose                    | Justification              |
|---|---------|----------------------------|-----------------------------|
| 1 | <type>  | <what it does>             | <which signals, why>        |

### Confidence: <high|medium|low>

<reasoning>

### Self-proof

<which component of this plugin demonstrates the pattern>
```
