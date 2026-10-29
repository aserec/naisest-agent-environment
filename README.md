# agent-config

Agent skills, plugins and hook scripts shared by my projects. Any agent that reads `SKILL.md` folders can use the skills: Claude Code, Codex, Cursor and others.

## Layout

| Path | What |
| --- | --- |
| `sync.sh` | Copies `skills/`, `plugins/`, `hooks/`, `install.sh`, `mcp.json` and `SETUP.md` into another project's `.agents/`. The copy is plain files, not a git submodule. It reads this clone on disk and does not fetch from a remote or from Origin. Test: `test-sync.sh`. |
| `install.sh` | Wires that copy into the project for Claude Code, Codex, Cursor, Gemini CLI, Copilot and OpenCode: skills, MCP servers, session-start hook. `install.sh guard` installs the global command guard. Test: `test-install.sh`. |
| `skills/` | One folder per skill. Static checks: `check-skills.sh`. |
| `plugins/` | One folder per plugin, when this repo has any. Cursor loads the copy from `.agents/plugins/` when the project opens. |
| `upstream/` | Skills copied from other repos. `upstream.json` lists each source, its pinned commit and the skills taken from it; `patches/` holds our edits to those skills; `sync.sh` copies them in. See [Upstream skills](#upstream-skills). |
| `.githooks/pre-commit` | Runs `check-skills.sh`, plus the install, sync and hook tests when their files change. |
| `hooks/context-budget.sh` | Context warning at 120K and 150K tokens. Claude Code only: it reads the Claude transcript format. Test: `hooks/test-context-budget.sh`. |
| `jev/`, `hooks/jev.sh` | Jev on Berget AI, levels 6 to 10 of [ten-levels-of-jev](https://github.com/disler/ten-levels-of-jev). Hooks: a bash gate, a credential write gate and an injection screen on tool output (L6), and `/clear` or `/compact` advice when a prompt switches task (L7). MCP server `jev`: `ask_jev_file_*` (L8), `ask_jev_files` and `pick_first_file` (L9), `ask_jev` (L10). Needs `BERGET_API_KEY` in the shell that starts the agent; without it the hooks pass everything. Test: `node --test "jev/tests/*.test.ts"`. |
| `hooks/load-structured-output.sh` | Session-start hook. Loads `skills/structured-output` into every session, in each harness that has hooks. |
| `hooks/load-plugins.sh` | Cursor `workspaceOpen` hook. Prints the absolute paths of `.agents/plugins/*`. |
| `mcp.json` | Shared MCP servers: Figma's hosted server (`https://mcp.figma.com/mcp`, log in once through `/mcp`; no desktop app) and graft. `install.sh` links or converts it for each harness. |
| `hooks/deny-dangerous.sh`, `hooks/dangerous-patterns.txt`, `hooks/test-guard.sh` | Global guard against catastrophic shell commands. The live copy is in `~/.agents/hooks/`, installed per user, not per project. See `skills/global-agent-guardrails`. |

## Use in a project

Clone this repo onto the machine from GitHub. Do not add it as a submodule, and do not fetch it from Origin. From the other project, run `bash /path/to/agent-config/sync.sh`. Steps, the global guard and checks: [SETUP.md](SETUP.md).

## Work on this repo

Enable the pre-commit hook once per clone:

```sh
git config core.hooksPath .githooks
```

## Upstream skills

Skills listed in `upstream/upstream.json` come from another repo. Do not edit them by hand without recording a patch, or the next sync drops the edit.

```sh
bash upstream/sync.sh update             # move to upstream's latest commit and copy the skills in
bash upstream/sync.sh                    # copy the skills in at the pinned commit
bash upstream/sync.sh check              # list drift and upstream skills not imported yet; changes nothing
bash upstream/sync.sh save-patch <skill> # keep a local edit to an upstream skill across syncs
```

To import a new upstream skill, add it to `upstream.json` and run `upstream/sync.sh`. To drop one, delete its folder and its `upstream.json` entry. Skills not in `upstream.json` are ours. After a sync, read `git diff` for renamed conventions (for example `CONTEXT.md` became `GLOSSARY.md`) and update our own skills to match.

## Update

Edit here, commit, push to GitHub. In each project, follow [SETUP.md#update](SETUP.md#update).
