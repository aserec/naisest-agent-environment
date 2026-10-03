---
name: global-agent-guardrails
description: "Configure the shared guard against catastrophic shell commands in local AI agents. Use when changing block patterns, adding an agent or machine, or investigating why a command was or wasn't blocked."
---

# Global Agent Guardrails

Block catastrophic shell commands before execution. One patterns file feeds a shared hook script or native adapter for each agent. This guards against accidents, not malicious agents (obfuscation like `python -c "shutil.rmtree(...)"` can slip past regex).

## File map

```
~/.agents/hooks/dangerous-patterns.txt   # THE denylist: one POSIX-ERE regex per line, # comments
~/.agents/hooks/deny-dangerous.sh        # shared guard: hook JSON on stdin -> exit 2 blocks
~/.agents/hooks/test-guard.sh            # test suite: run after ANY pattern change
~/.config/opencode/plugins/command-guard.ts   # OpenCode adapter (throws to block)
~/.pi/agent/extensions/command-guard.ts       # Pi adapter (returns {block:true})
~/.hermes/plugins/command-guard/              # Hermes plugin (returns {"action":"block"})
```

## Check installation

```bash
ls ~/.agents/hooks/deny-dangerous.sh ~/.agents/hooks/dangerous-patterns.txt
~/.agents/hooks/test-guard.sh   # must end "failed: 0"
```

If missing, rebuild from the wiring table.

## Add or tune a pattern

1. Edit `~/.agents/hooks/dangerous-patterns.txt`. Write POSIX ERE (`grep -E`). Use `[[:space:]]`, never `\s` — adapters auto-convert `[:space:]` to `\s` for JS/Python and compile in multiline mode.
2. Add block and allow cases to `test-guard.sh`, then run it; all must pass.
3. Verify the new pattern compiles in the adapter engines:

```bash
python3 -c 'import re,pathlib; [re.compile(l.strip().replace("[:space:]",r"\s"),re.M) for l in pathlib.Path.home().joinpath(".agents/hooks/dangerous-patterns.txt").read_text().splitlines() if l.strip() and not l.startswith("#")]; print("ok")'
```

4. Consumers re-read patterns for every command. Exception: Droid uses `commandBlocklist` in `~/.factory/settings.json` — mirror changes there manually.

Block only catastrophic commands (irreversible data loss, disk wipes, repo deletion, token exfiltration). Recoverable local commands (`git status`, `git clean -fdx`, `rm -rf node_modules`) stay allowed; avoid over-blocking.

## Per-agent wiring (user-global)

| Agent | Config | Event | Blocks via |
|---|---|---|---|
| Claude Code | `~/.claude/settings.json` | `PreToolUse` matcher `Bash` | shared script, exit 2 |
| Codex CLI/app/IDE | `~/.codex/hooks.json` | `PreToolUse` matcher `Bash` | shared script, exit 2 |
| Cursor IDE + CLI | `~/.cursor/hooks.json` | `beforeShellExecution` | shared script with `cursor` arg, deny JSON |
| Grok (xAI) | auto-loads Claude + Cursor hook files (compat on by default); native option `~/.grok/hooks/*.json` | `PreToolUse` | shared script (reads `.toolInput.command`) |
| OpenCode | `~/.config/opencode/plugins/command-guard.ts` | `tool.execute.before` | adapter throws Error |
| Pi | `~/.pi/agent/extensions/command-guard.ts` | `pi.on("tool_call")` | adapter returns `{block:true}` |
| Hermes | `~/.hermes/plugins/command-guard/` (`plugin.yaml` + `__init__.py`) | `pre_tool_call` hook | plugin returns `{"action":"block"}` |
| Droid (Factory) | `~/.factory/settings.json` | native `commandBlocklist` | hard-block, no approval possible |
| Devin CLI | `~/.config/devin/config.json` | `PreToolUse` matcher `^exec$` | shared script, exit 2 |

Claude/Codex hook entry; for Devin, replace `Bash` with `^exec$`. Merge into the existing `hooks` object; never overwrite it:

```json
{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "/ABSOLUTE/HOME/.agents/hooks/deny-dangerous.sh"}]}]}}
```

Cursor entry (payload has `.command`, so pass the `cursor` arg):

```json
{"beforeShellExecution": [{"command": "/ABSOLUTE/HOME/.agents/hooks/deny-dangerous.sh cursor", "failClosed": false}]}
```

Use absolute paths in configs (`~` expansion is inconsistent across agents).

## Gotchas

- **Codex trust is hash-pinned.** Any edit to the hook ENTRY in `hooks.json` (not the patterns file) invalidates trust; run `/hooks` in Codex and re-trust, else Codex silently skips the guard. Trust hashes live in `[hooks.state]` in `~/.codex/config.toml` and are shared by CLI, desktop app, and IDE extension.
- **Cursor `failClosed` must stay `false`.** Cursor background/worker hosts cannot execute hook scripts; fail-closed blocks EVERY command there. Trade-off: Cursor background agents run unguarded.
- **Hermes plugin manifest key is `provides_hooks`** (not `hooks`). Plugin must be enabled: `plugins.enabled` list in `~/.hermes/config.yaml` (the `hermes plugins enable` CLI prompts interactively and hangs non-interactive shells). Hermes hooks are fail-open on exceptions — keep the plugin trivial. Shell tool name is `terminal`.
- **Pi `tool_call` handler errors block the tool** (fail-safe) — adapter must catch its own errors and fail open, or a broken patterns file bricks every bash call.
- **Droid semantics:** `commandDenylist` = ask for confirmation; `commandBlocklist` = never runs, even at full autonomy with `--skip-permissions-unsafe`. Use blocklist for catastrophic entries.
- **Guard script payload detection:** command lives at `.tool_input.command` (Claude/Codex/Devin), `.toolInput.command` (Grok), `.command` (Cursor). Keep all three in the jq fallback chain.
- **Adapter regexes require multiline mode.** Keep JavaScript's `m` flag and Python's `re.M` so `^` matches each shell line like `grep`.
- **False-positive class:** a harmless command whose ARGUMENT text contains a dangerous-looking string (e.g. passing a prompt mentioning `git push --force` on a CLI) gets blocked. Workaround: put the text in a file and reference it.
- Some agents or execution environments may not provide a hook system, and some background or remote tasks may bypass local guards. Verify coverage for the agents and environments you use.

## E2E verification

Test each installed adapter with a harmless blocked-command probe in a disposable, non-git directory. Confirm that the guard blocks the probe, and use the test suite to check pattern behavior and adapter compatibility.

Direct script tests should use the installed guard script and verify that a known blocked command returns exit code 2.
