# Misclassified Plugin Test Fixture

Test plugin with 6 intentional misclassifications across 4 anti-pattern types,
used by the architecture-validator agent to verify detection logic.

## Hook file format

The hook JSON files in `hooks/` use a simplified schema for validator testing
purposes. They are **not runtime hooks** -- they exist only so the validator can
read and analyze them for anti-patterns (e.g., hook-without-suppression).

The actual Claude Code plugin hook format uses `hooks/hooks.json` with the
wrapper structure documented in the hook-development skill. See
`../../hooks/hooks.json` in the project root for a runtime example.
