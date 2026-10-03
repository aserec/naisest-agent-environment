# Setup

Add `agent-config` to any project, or set up a clone of a project that already uses it.

**Goal:** the project has the shared skills, the context-budget hook and the shared MCP servers (`figma`, `graft`). Your machine has the global command guard.

## Option A: ask an agent

Open Claude Code (or another agent) in the project folder and paste this prompt:

```text
Set up agent-config in this project by following .agents/SETUP.md
(or https://github.com/aserec/agent-config/blob/main/SETUP.md if .agents/ is empty).
- If .gitmodules already lists .agents, follow "Join an existing project". Otherwise follow "Add to a new project".
- Ask me before you change anything global: ~/.gitconfig, ~/.claude/settings.json, ~/.agents/.
- In existing JSON files, merge entries. Never overwrite them.
- If the clone fails with an access error, stop and tell me to request access to github.com/aserec/agent-config.
- Run every check in "Verify" and report each one as passed or failed, with the output of any failure.
- Tell me which steps need me (MCP approval, /mcp Figma login, /setup-matt-pocock-skills) and stop there.
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

2. Link every skill for Claude Code:

   ```sh
   mkdir -p .claude/skills
   for d in .agents/skills/*/; do n=$(basename "$d"); ln -sfn "../../.agents/skills/$n" ".claude/skills/$n"; done
   ```

3. Link the MCP config:

   ```sh
   ln -s .agents/mcp.json .mcp.json
   ```

4. Add the context-budget hook to `.claude/settings.json`. If the file exists, merge the `hooks` object into it.

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "hooks": [{ "type": "command", "command": "f=\"${CLAUDE_PROJECT_DIR:-.}/.agents/hooks/context-budget.sh\"; [ ! -f \"$f\" ] || bash \"$f\"" }] }
       ],
       "PostToolUse": [
         { "hooks": [{ "type": "command", "command": "f=\"${CLAUDE_PROJECT_DIR:-.}/.agents/hooks/context-budget.sh\"; [ ! -f \"$f\" ] || bash \"$f\"" }] }
       ]
     }
   }
   ```

   The `[ ! -f ]` guard makes the hook do nothing when `.agents/` is not checked out.

5. Codex reads `.agents/skills` directly. It needs no links.

6. Commit:

   ```sh
   git add .gitmodules .agents .claude/skills .claude/settings.json .mcp.json
   git commit -m "chore: add agent-config"
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

`code-review`, `to-tickets`, `triage`, `domain-modeling`, `tdd`, `ask-matt` and related skills need a one-time setup per project. Run this in Claude Code:

```text
/setup-matt-pocock-skills
```

## First Claude Code run

1. Start `claude` in the project and trust the folder.
2. Approve the project MCP servers when it asks.
3. Run `/mcp`, select `figma` and log in once in the browser.

## Global command guard (once per machine)

The guard blocks catastrophic shell commands in every project. Install it:

```sh
mkdir -p ~/.agents/hooks
cp .agents/hooks/deny-dangerous.sh .agents/hooks/dangerous-patterns.txt .agents/hooks/test-guard.sh ~/.agents/hooks/
chmod +x ~/.agents/hooks/*.sh
```

Merge this entry into `hooks.PreToolUse` in `~/.claude/settings.json`. Keep the entries that are already there:

```json
{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "$HOME/.agents/hooks/deny-dangerous.sh" }] }
```

Other agents (Codex, Cursor and others): see `skills/global-agent-guardrails/SKILL.md`.

Check for drift after each update of `.agents`. If `cmp` prints a difference, run the `cp` line again:

```sh
cmp .agents/hooks/deny-dangerous.sh ~/.agents/hooks/deny-dangerous.sh && cmp .agents/hooks/dangerous-patterns.txt ~/.agents/hooks/dangerous-patterns.txt
```

## Verify

```sh
git submodule status .agents                  # no leading "-"
find .claude/skills .mcp.json -maxdepth 1 -type l ! -exec test -e {} \; -print   # no output
bash .agents/hooks/test-context-budget.sh     # ends "failed=0"
bash .agents/hooks/test-guard.sh              # ends "failed: 0"
~/.agents/hooks/test-guard.sh                 # ends "failed: 0"
claude mcp list                               # lists figma and graft
```

## Update

```sh
git submodule update --remote .agents
git add .agents
git commit -m "chore: bump agent-config"
```

Then run the drift check above.
