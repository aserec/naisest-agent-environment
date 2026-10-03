# agent-config

Agent skills and hook scripts shared by my projects. Any agent that reads `SKILL.md` folders can use the skills: Claude Code, Codex, Cursor and others.

## Layout

| Path | What |
| --- | --- |
| `skills/` | One folder per skill. Upstream skills are pinned in the project's own `skills-lock.json`. |
| `hooks/context-budget.sh` | Context warning at 120K and 150K tokens. Claude Code only: it reads the Claude transcript format. Test: `hooks/test-context-budget.sh`. |
| `hooks/deny-dangerous.sh`, `hooks/dangerous-patterns.txt`, `hooks/test-guard.sh` | Global guard against catastrophic shell commands. The live copy is in `~/.agents/hooks/`, installed per user, not per project. See `skills/global-agent-guardrails`. |

## Use in a project

Add this repo as a submodule at `.agents`:

```bash
git submodule add <this repo's URL> .agents
```

The `.agents/skills/` folder then serves Codex directly. For other agents, symlink each skill into the agent's own skills folder, for example `.claude/skills/<name> -> ../../.agents/skills/<name>`.

Hooks are wired per agent, in each project's own config (`.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`). Point the command at the script, for example:

```json
{ "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR:-.}/.agents/hooks/context-budget.sh\"" }
```

## Update

Edit here, commit, push. In each project: `git submodule update --remote .agents`, then commit the new pointer.
