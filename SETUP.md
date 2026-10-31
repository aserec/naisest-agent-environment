# Setup

Copy `agent-config` into a project, or set up a clone of a project that already has the copy.

**Goal:** the project has the shared skills, plugins and hooks, including the Jev hooks, and the shared MCP servers (`figma`, `graft`). Your machine has the global command guard.

The copy lives at `.agents/` as normal files. It is not a git submodule. Refresh it with `sync.sh` from a local clone of this repo. `sync.sh` does not fetch, pull or clone. Origin is not a source.

## Option A: ask an agent

Open Claude Code (or another agent) in the project folder and paste this prompt:

```text
Set up agent-config in this project by following .agents/SETUP.md
(or SETUP.md in my local agent-config clone if .agents/ is empty).
- Do not add a git submodule. Do not fetch or clone this repo from Origin.
- The agent-config repo must already be cloned on this machine. If you cannot find it, ask me for the path.
- If .gitmodules lists .agents, follow "Remove the submodule", then "Add to a new project".
- If .agents/sync.json is missing, follow "Add to a new project". If it exists, follow "Update".
- Ask me before you change anything global: ~/.gitconfig, ~/.claude, ~/.codex, ~/.cursor, ~/.agents/ (this includes `install.sh guard`).
- In existing JSON files, merge entries. Never overwrite them.
- Run every check in "Verify" and report each one as passed or failed, with the output of any failure.
- Tell me which steps need me (trusting the project and its hooks, MCP approval, the Figma login, /setup-matt-pocock-skills) and stop there.
```

## Prerequisites

- `git` and `jq`.
- A local clone of this repo, from GitHub (`git@github.com:aserec/agent-config.git` or the HTTPS URL). The repo is private: ask its owner for read access, then `gh auth login`. Sync does not clone it for you, and it does not pull from Origin.
- Optional: graft, a code index served over MCP.

  ```sh
  pnpm add -g @nanonets/graft
  graft build          # once per project; no API key needed
  ```

  `graft build --deep` also needs `GRAFT_API_KEY`. If the project has no graft index, do not use graft, or remove `graft` from your copy of the MCP config.

  The index is a local cache. Add `/graft/` to the project's `.gitignore`. The `graft` skill is linked with the others and tells agents to query the index before reading source.

## Add to a new project

From the project root, point `sync.sh` at this clone. The path must be a directory on disk.

```sh
bash /absolute/path/to/agent-config/sync.sh
```

It copies `skills/`, `plugins/` (when this repo has any), `hooks/`, `install.sh`, `mcp.json` and `SETUP.md` into `.agents/`, writes `.agents/sync.json`, then runs `install.sh`. It is safe to run again. A skill, plugin or hook that belongs only to the project stays. One that `sync.json` lists, and that this clone no longer has, is deleted.

To copy into a project that is not the current directory:

```sh
bash /absolute/path/to/agent-config/sync.sh /absolute/path/to/project
```

`bash /absolute/path/to/agent-config/sync.sh check` reports drift and changes nothing.

Commit the copy:

```sh
git add .agents .claude .mcp.json .cursor .codex .gemini .vscode/mcp.json opencode.json
git commit -m "chore: add agent-config"
```

## Remove the submodule

Projects that already have `.agents` as a git submodule must drop that submodule before the first sync. `sync.sh` stops if `.agents` is still a submodule, a nested checkout, or a link.

```sh
git submodule deinit -f .agents
git rm -f .agents
rm -rf .git/modules/.agents
```

Then follow [Add to a new project](#add-to-a-new-project).

## What the installer writes

The copy sits at `.agents/`, so `.agents/skills/` is already the skill folder that Codex, Cursor, Gemini CLI, Copilot and OpenCode scan. Only Claude Code needs links. The installer adds the MCP servers and the hook that loads `structured-output` at the start of each session. When `.agents/plugins/` has a folder, Cursor also gets a `workspaceOpen` hook that loads those plugins for this project.

| Harness | Skills | MCP servers | `structured-output` at session start |
| --- | --- | --- | --- |
| Claude Code | links in `.claude/skills/` | `.mcp.json` link | `SessionStart` in `.claude/settings.json` |
| Codex | native | `[mcp_servers.*]` in `.codex/config.toml` | `SessionStart` in `.codex/hooks.json` |
| Cursor (IDE and CLI) | native | `.cursor/mcp.json` link | `sessionStart` in `.cursor/hooks.json` |
| Gemini CLI | native | `mcpServers` in `.gemini/settings.json` | `SessionStart` in `.gemini/settings.json` |
| Copilot CLI | native | reads `.mcp.json` | reads `.claude/settings.json` hooks |
| Copilot in VS Code | native | `.vscode/mcp.json` | reads `.claude/settings.json` hooks when `chat.useClaudeHooks` is on |
| OpenCode | native | `mcp` in `opencode.json` | `instructions` in `opencode.json` (OpenCode has no shell hooks) |

The Jev context advice runs only in Claude Code. It reads the Claude transcript format. In Copilot it finds no Claude session and does nothing.

When a project already has its own `.mcp.json` or `.cursor/mcp.json` as a regular file, the installer merges the servers into it instead of linking. `sync.sh` reruns the installer, so the copies stay current.

Hook commands find the project root through `CLAUDE_PROJECT_DIR`, `CURSOR_PROJECT_DIR` or `GEMINI_PROJECT_DIR`, else `git rev-parse --show-toplevel`. They do nothing when `.agents/` is missing.

For any other harness: if it reads `.agents/skills/`, the skills work as they are. If it reads `AGENTS.md`, add this line to the project's `AGENTS.md` to load the reply format:

```text
Follow .agents/skills/structured-output/SKILL.md for every chat reply.
```

## Join an existing project

Clone the project. The copy is already in the files. You do not init a submodule.

To refresh the copy you need this repo cloned on the machine. Then follow [Update](#update).

## Matt Pocock skills

The skills from [mattpocock/skills](https://github.com/mattpocock/skills) are listed, with the pinned commit, in [`upstream/upstream.json`](upstream/upstream.json). Start with `/ask-matt` for which one to use when. Most need a one-time setup per project. Run this in Claude Code:

```text
/setup-matt-pocock-skills
```

Projects that used these skills before the `GLOSSARY.md` rename: rename `CONTEXT.md` to `GLOSSARY.md` and `CONTEXT-MAP.md` to `GLOSSARY-MAP.md`.

## First run in each harness

- **Claude Code:** start `claude`, trust the folder, approve the project MCP servers, then run `/mcp`, select `figma` and log in once in the browser.
- **Codex:** trust the project. Codex loads `.codex/config.toml` and `.codex/hooks.json` only in trusted projects. Run `/hooks` and trust the `SessionStart` entry. Codex caps hook context at about 2,500 tokens, so it may cut the end of `structured-output`.
- **Cursor:** approve the MCP servers in Settings, then log in to `figma`. Leave Settings, Agents, Third-Party Imports off. If it is on, Cursor also runs the Claude hooks and loads the skill twice. After a sync that adds plugins, reload the window so `workspaceOpen` loads them.
- **Gemini CLI:** trust the project hooks when Gemini asks. It asks again after each change to the hook entries.
- **Copilot in VS Code:** turn on `chat.useClaudeHooks` to load the skill at session start.
- **OpenCode:** nothing more.

## Global command guard (once per machine)

The guard blocks catastrophic shell commands in every project. This writes under your home folder: it copies the guard to `~/.agents/hooks/` and adds it to Claude Code, Codex and Cursor, for each of them that has a folder in your home folder.

```sh
bash .agents/install.sh guard    # ends "failed: 0"
```

In Codex, run `/hooks` and trust the guard entry. For OpenCode, Pi, Hermes, Droid and Devin, see `skills/global-agent-guardrails/SKILL.md`.

Check for drift after each update of `.agents`. If `cmp` prints a difference, run the `guard` line again:

```sh
cmp .agents/hooks/deny-dangerous.sh ~/.agents/hooks/deny-dangerous.sh && cmp .agents/hooks/dangerous-patterns.txt ~/.agents/hooks/dangerous-patterns.txt
```

## Verify

```sh
test -f .agents/sync.json                     # the copy recorded a sync
git ls-files -s -- .agents | awk '$1 == "160000" && $4 == ".agents" { exit 1 }'
find .claude/skills .mcp.json .cursor/mcp.json -maxdepth 1 -type l ! -exec test -e {} \; -print   # no output
bash .agents/hooks/test-guard.sh              # ends "failed: 0"
~/.agents/hooks/test-guard.sh                 # ends "failed: 0"
claude mcp list                               # lists figma and graft
```

In this repo, `bash test-install.sh` and `bash test-sync.sh` both end `failed=0`.

## Update

Update the local clone from GitHub yourself. `sync.sh` will not pull, and it will not use Origin. Then, from the project:

```sh
bash /absolute/path/to/agent-config/sync.sh
git add -A .agents .claude .mcp.json .cursor .codex .gemini .vscode/mcp.json opencode.json
git commit -m "chore: bump agent-config"
```

The sync replaces skills, plugins and hooks that came from this repo, leaves project-owned ones, and reruns the installer. The installer links new skills, removes links to skills that are gone, and replaces its older hook entries. Then run the drift check above.
