# Claude Code Kickoff Prompt — plugin-design-advisor

Paste this into Claude Code after `cd /Users/markalston/code/product-design-advisor`.

---

## Prompt to paste:

```
Read the CLAUDE.md in this directory to understand the project.

Then do the following in order:

1. Initialize git: `git init`, create a .gitignore (Node, Python, macOS, JetBrains, .env files)

2. Scaffold the full directory structure from the architecture section of CLAUDE.md —
   create all directories and empty placeholder files. For any SKILL.md or .md agent file,
   create it with a minimal frontmatter stub so the structure is navigable:
   ---
   status: stub
   phase: [phase number from CLAUDE.md]
   ---

3. Create .claude-plugin/plugin.json with:
   {
     "name": "plugin-design-advisor",
     "description": "Encode and demonstrate heuristics for Claude Code plugin design decisions — skill vs. agent vs. command vs. hook.",
     "version": "0.1.0",
     "author": "Mark Alston"
   }

4. Make an initial commit: "chore: scaffold project structure"

5. Now focus on Phase 1 only. Draft the full content for
   skills/plugin-design-advisor/SKILL.md using the heuristics in CLAUDE.md as seed content.
   Structure it with progressive disclosure:
   - Trigger section (~200 words max): when to invoke, one-liner rules, pointer to detail
   - Decision framework (~300 words): the core skill/agent/command/hook matrix
   - Detailed heuristics (~600 words): each mechanism with signals and anti-signals
   - Anti-patterns (~200 words): the five anti-patterns with brief descriptions
   - Worked examples (~300 words): the five reference plugins from the table in CLAUDE.md

   The skill should be authoritative but not verbose. Target 1,200–1,600 words total.
   Every heuristic should be actionable — a developer should be able to read a section
   and immediately know whether their idea fits.

6. After drafting the skill, create a minimal test plugin at tests/fixtures/misclassified-plugin/
   that intentionally contains the agent-as-skill and skill-as-agent anti-patterns.
   This will be used to test the architecture-validator agent in Phase 1.

7. Commit Phase 1 work: "feat(phase-1): core skill content and test fixture"

Do not start Phase 2 work yet. Ask me to review the skill content before proceeding.
```
