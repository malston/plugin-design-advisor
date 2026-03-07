# plugin-file-guard Hook Test Scenarios

Executable tests in `test-plugin-file-guard.sh`. These scenarios validate the
path filter, plugin detection, and session dedup logic.

## Scenario 1: Write to agents/ in a plugin dir

- **Input:** Write to `<plugin-dir>/agents/new-agent.md` where `<plugin-dir>/.claude-plugin/plugin.json` exists
- **Expected:** Hook fires, injects skill-vs-agent reminder
- **Why:** File is under agents/ in a valid plugin directory

## Scenario 2: Write to skills/ in a plugin dir

- **Input:** Write to `<plugin-dir>/skills/new-skill/SKILL.md` where `<plugin-dir>/.claude-plugin/plugin.json` exists
- **Expected:** Hook fires, injects skill-vs-agent reminder
- **Why:** File is under skills/ in a valid plugin directory

## Scenario 3: Write to README.md in a plugin dir

- **Input:** Write to `<plugin-dir>/README.md` where `<plugin-dir>/.claude-plugin/plugin.json` exists
- **Expected:** Hook does NOT fire
- **Why:** File is not under agents/ or skills/ -- path filter excludes it

## Scenario 4: Write to agents/ in a non-plugin dir

- **Input:** Write to `<project-dir>/agents/something.md` where no `.claude-plugin/plugin.json` exists within 4 parent directories
- **Expected:** Hook does NOT fire
- **Why:** No plugin manifest found -- this is not a plugin directory

## Scenario 5: Session dedup (suppression)

- **Input:** Two consecutive writes to the same file path with the same session ID
- **Expected:** First write fires, second write is suppressed
- **Why:** Hook tracks which file paths have already received guidance this session
