---
description: Checks that files follow project conventions on every save.
---

# /check-conventions

Runs automatically whenever a file is saved to verify it follows project conventions.

## Steps

1. Read the saved file
2. Check naming conventions
3. Check import ordering
4. Report violations inline

## Trigger

This command should run on every file write. Developers must remember to invoke
`/check-conventions` after editing files.

<!-- ANTI-PATTERN: command-without-hook
     This workflow triggers on a system event (file save) but is implemented as
     a command the user must remember to invoke. It should be a PreToolUse or
     PostToolUse hook on Write/Edit that fires automatically. Users will forget
     to run this manually, and the guardrail fails silently. -->
