# Setup

Add `agent-config` to any project, or set up a clone of a project that already uses it.

**Goal:** the project has the shared skills, the context-budget hook and the shared MCP servers (`figma`, `graft`). Your machine has the global command guard.

## Option A: ask an agent

Open Claude Code (or another agent) in the project folder and paste this prompt:

```text
Set up agent-config in this project by following .agents/SETUP.md
(or https://github.com/aserec/agent-config/blob/main/SETUP.md if .agents/ is empty).
- If .gitmodules already lists .agents, follow "Join an existing project". Otherwise follow "Add to a new project".
- Ask me before you change anything global: ~/.gitconfig, ~/.claude, ~/.codex, ~/.cursor, ~/.agents/ (this includes `install.sh guard`).
- In existing JSON files, merge entries. Never overwrite them.
- If the clone fails with an access error, stop and tell me to request access to github.com/aserec/agent-config.
- Run every check in "Verify" and report each one as passed or failed, with the output of any failure.
- Tell me which steps need me (trusting the project and its hooks, MCP approval, the Figma login, /setup-matt-pocock-skills) and stop there.
```

## Prerequisites

- `git` and `jq`.
- `gh` (GitHub CLI), because the repo is private.
- Optional: graft, a code index served over MCP.

  ```sh
  pnpm add -g @nanonets/graft
  graft build          # once per project; no API key needed
  ```

  `graft build --deep` also needs `GRAFT_API_KEY`. If the project has no graft index, do not use graft, or remove `graft` from your copy of the MCP config.

  The index is a local cache. Add `/graft/` to the project's `.gitignore`. The `graft` skill is linked with the others and tells agents to query the index before reading source.

## Access

The repo is private. Ask its owner for read access. Then pick one way to log in:

```sh
gh auth login
gh auth setup-git    # changes your global ~/.gitconfig
```

Or use the SSH URL `git@github.com:aserec/agent-config.git` instead of the HTTPS URL below.

## Add to a new project

1. Add the submodule. Use the absolute URL. Use a relative URL only when both repos share the same host and namespace.

   ```sh
   git submodule add https://github.com/aserec/agent-config.git .agents
   ```

2. Run the installer from the project root. With no arguments it sets up every harness. To set up only some, name them: `claude cursor codex gemini copilot opencode`.

   ```sh
   bash .agents/install.sh
   ```

   It is safe to run again. It merges into config files that already exist, keeps your own entries, and replaces only its own older entries. What it writes is in [What the installer writes](#what-the-installer-writes).

3. Commit what it wrote:

   ```sh
   git add .gitmodules .agents .claude .mcp.json .cursor .codex .gemini .vscode/mcp.json opencode.json
   git commit -m "chore: add agent-config"
   ```

## What the installer writes

The submodule sits at `.agents/`, so `.agents/skills/` is already the skill folder that Codex, Cursor, Gemini CLI, Copilot and OpenCode scan. Only Claude Code needs links. The installer adds the MCP servers and the hook that loads `structured-output` at the start of each session.

| Harness | Skills | MCP servers | `structured-output` at session start |
| --- | --- | --- | --- |
| Claude Code | links in `.claude/skills/` | `.mcp.json` link | `SessionStart` in `.claude/settings.json` |
| Codex | native | `[mcp_servers.*]` in `.codex/config.toml` | `SessionStart` in `.codex/hooks.json` |
| Cursor (IDE and CLI) | native | `.cursor/mcp.json` link | `sessionStart` in `.cursor/hooks.json` |
| Gemini CLI | native | `mcpServers` in `.gemini/settings.json` | `SessionStart` in `.gemini/settings.json` |
| Copilot CLI | native | reads `.mcp.json` | reads `.claude/settings.json` hooks |
| Copilot in VS Code | native | `.vscode/mcp.json` | reads `.claude/settings.json` hooks when `chat.useClaudeHooks` is on |
| OpenCode | native | `mcp` in `opencode.json` | `instructions` in `opencode.json` (OpenCode has no shell hooks) |

The context-budget hook runs only in Claude Code. It reads the Claude transcript format. In Copilot it finds no Claude session and does nothing.

When a project already has its own `.mcp.json` or `.cursor/mcp.json` as a regular file, the installer merges the servers into it instead of linking. Rerun the installer after each update so the copies stay current.

Hook commands find the project root through `CLAUDE_PROJECT_DIR`, `CURSOR_PROJECT_DIR` or `GEMINI_PROJECT_DIR`, else `git rev-parse --show-toplevel`. They do nothing when `.agents/` is not checked out.

For any other harness: if it reads `.agents/skills/`, the skills work as they are. If it reads `AGENTS.md`, add this line to the project's `AGENTS.md` to load the reply format:

```text
Follow .agents/skills/structured-output/SKILL.md for every chat reply.
```

## Join an existing project

Clone with the submodule:

```sh
git clone --recurse-submodules <project URL>
```

If you already cloned without it:

```sh
git submodule update --init
```

Recommended, so that `pull` and `checkout` also update the submodule:

```sh
git config --global submodule.recurse true
```

If you forget the submodule, nothing warns you. The `.claude/skills/*` links point nowhere and no MCP servers load.

## Use another URL for your clone only

Use this for a fork, a mirror or a local path. The setting lives in `.git/config` and is never committed.

```sh
git config submodule..agents.url <URL or absolute path>
git submodule update --init
```

For a local path, git 2.38 and later block the file transport. Allow it for each command:

```sh
git -c protocol.file.allow=always submodule update --init
git -c protocol.file.allow=always submodule update --remote .agents
```

`git submodule sync` copies the `.gitmodules` URL over your setting. If you run it, run the `git config` line again.

## Matt Pocock skills

The skills from [mattpocock/skills](https://github.com/mattpocock/skills) are listed, with the pinned commit, in [`upstream/upstream.json`](upstream/upstream.json). Start with `/ask-matt` for which one to use when. Most need a one-time setup per project. Run this in Claude Code:

```text
/setup-matt-pocock-skills
```

Projects that used these skills before the `GLOSSARY.md` rename: rename `CONTEXT.md` to `GLOSSARY.md` and `CONTEXT-MAP.md` to `GLOSSARY-MAP.md`.

## First run in each harness

- **Claude Code:** start `claude`, trust the folder, approve the project MCP servers, then run `/mcp`, select `figma` and log in once in the browser.
- **Codex:** trust the project. Codex loads `.codex/config.toml` and `.codex/hooks.json` only in trusted projects. Run `/hooks` and trust the `SessionStart` entry. Codex caps hook context at about 2,500 tokens, so it may cut the end of `structured-output`.
- **Cursor:** approve the MCP servers in Settings, then log in to `figma`. Leave Settings, Agents, Third-Party Imports off. If it is on, Cursor also runs the Claude hooks and loads the skill twice.
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
git submodule status .agents                  # no leading "-"
find .claude/skills .mcp.json .cursor/mcp.json -maxdepth 1 -type l ! -exec test -e {} \; -print   # no output
bash .agents/test-install.sh                  # ends "failed=0"
bash .agents/hooks/test-context-budget.sh     # ends "failed=0"
bash .agents/hooks/test-guard.sh              # ends "failed: 0"
~/.agents/hooks/test-guard.sh                 # ends "failed: 0"
claude mcp list                               # lists figma and graft
```

## Update

```sh
git submodule update --remote .agents
bash .agents/install.sh
git add -A .agents .claude .mcp.json .cursor .codex .gemini .vscode/mcp.json opencode.json
git commit -m "chore: bump agent-config"
```

The installer links new skills, removes links to skills that are gone, and replaces its older hook entries. Then run the drift check above.
