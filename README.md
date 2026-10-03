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

Add this repo as a submodule at `.agents`:

```bash
git submodule add <this repo's URL> .agents
```

Commit a relative URL in `.gitmodules` (for example `../agent-config.git`) so it follows the project's remote. Each developer can point their own clone elsewhere, such as a local path, without a commit:

```bash
git config submodule..agents.url <URL or path>
git submodule update --init
```

Full checkout setup for a teammate, manual or by prompting an agent: `docs/agent-setup.md` in `react_frontend`.

The `.agents/skills/` folder then serves Codex directly. For other agents, symlink each skill into the agent's own skills folder, for example `.claude/skills/<name> -> ../../.agents/skills/<name>`.

Hooks are wired per agent, in each project's own config (`.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`). Point the command at the script, for example:

```json
{ "type": "command", "command": "f=\"${CLAUDE_PROJECT_DIR:-.}/.agents/hooks/context-budget.sh\"; [ ! -f \"$f\" ] || bash \"$f\"" }
```

The `[ ! -f ]` guard makes the hook a no-op when the submodule is not checked out, so a missing `.agents/` never fails a session.

## Update

Edit here, commit, push. In each project: `git submodule update --remote .agents`, then commit the new pointer.
