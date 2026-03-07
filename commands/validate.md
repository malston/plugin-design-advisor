---
description: Validate an existing plugin's architecture against design heuristics
argument-hint: <plugin-directory-path>
allowed-tools: Read, Glob
---

Validate the plugin at: $ARGUMENTS

Use the architecture-validator agent to audit the plugin structure.
The agent should:

1. Glob the directory to map all components (agents/, skills/, commands/, hooks/)
2. Read each component file
3. Evaluate each against the heuristics in skills/plugin-design-advisor/SKILL.md
4. Return findings as JSON:

```json
[
  {
    "component": "component name",
    "path": "relative/path",
    "finding_type": "misclassification | missing | over-engineered",
    "severity": "critical | warning | info",
    "evidence": "what in the file triggered this finding",
    "recommendation": "what to change and why"
  }
]
```
