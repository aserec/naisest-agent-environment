# agent-config

Agent skills and hook scripts shared by my projects. Any agent that reads `SKILL.md` folders can use the skills: Claude Code, Codex, Cursor and others.

## Layout

| Path | What |
| --- | --- |
| `skills/` | One folder per skill. Upstream skills are pinned in the project's own `skills-lock.json`. |
| `hooks/context-budget.sh` | Context warning at 120K and 150K tokens. Claude Code only: it reads the Claude transcript format. Test: `hooks/test-context-budget.sh`. |
| `mcp.json` | Shared MCP servers: Figma's hosted server (`https://mcp.figma.com/mcp`, log in once through `/mcp`; no desktop app) and graft. Claude Code reads it through a `.mcp.json -> .agents/mcp.json` symlink at the project root. |
| `hooks/deny-dangerous.sh`, `hooks/dangerous-patterns.txt`, `hooks/test-guard.sh` | Global guard against catastrophic shell commands. The live copy is in `~/.agents/hooks/`, installed per user, not per project. See `skills/global-agent-guardrails`. |

## Use in a project

Add it as a git submodule at `.agents`. Steps for a new project, for joining one, the global guard and checks: [SETUP.md](SETUP.md).

## Update

Edit here, commit, push. In each project, follow [SETUP.md#update](SETUP.md#update).
