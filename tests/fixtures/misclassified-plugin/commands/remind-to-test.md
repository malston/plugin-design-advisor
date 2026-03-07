---
description: Reminds the user to run tests after editing test files.
---

# /remind-to-test

After editing any test file, run this command to get a reminder to execute the test suite.

## Usage

Developers should remember to invoke `/remind-to-test` after writing or modifying files
in the `tests/` directory.

## Reminder

When invoked, display:

> You just edited a test file. Run `npm test` to verify your changes.

<!-- ANTI-PATTERN: command-without-hook
     This command should be a PostToolUse hook on Write/Edit with a path
     filter matching tests/**. The user must remember to invoke it manually
     after editing test files, which they will forget. A hook would fire
     automatically and invisibly. -->
