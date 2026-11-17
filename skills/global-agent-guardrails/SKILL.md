---
name: global-agent-guardrails
description: Configures the shared guard against catastrophic shell commands. Use when changing patterns, adding an agent or machine, or tracing a block or miss.
---

# Global Agent Guardrails

Block catastrophic shell commands before execution. One patterns file feeds a shared hook script or native adapter for each agent. This guards against accidents, not malicious agents (obfuscation like `python -c "shutil.rmtree(...)"` can slip past regex).

Pick the section for the task, run its steps in order, then run the [Checklist](#checklist): [Check installation](#check-installation) for a new machine, [Add or tune a pattern](#add-or-tune-a-pattern), [Wire an agent](#wire-an-agent), or [Trace a block or a miss](#trace-a-block-or-a-miss).

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

1. Run both commands:

```bash
ls ~/.agents/hooks/deny-dangerous.sh ~/.agents/hooks/dangerous-patterns.txt
~/.agents/hooks/test-guard.sh   # must end "failed: 0"
```

2. If a file is missing, run `bash .agents/install.sh guard` from the root of a project that has the agent-config copy at `.agents/`. It copies the three hook files to `~/.agents/hooks/`, merges the Claude Code, Codex and Cursor entries below, and runs the test suite.
3. Wire each other agent the user runs: [Wire an agent](#wire-an-agent).

## Add or tune a pattern

Block only catastrophic commands: irreversible data loss, disk wipes, repo deletion, token exfiltration. Recoverable local commands (`git status`, `git clean -fdx`, `rm -rf node_modules`) stay allowed. Why: a pattern that matches a recoverable command stops normal agent work.

1. Edit `~/.agents/hooks/dangerous-patterns.txt`. Write POSIX ERE (`grep -E`). Use `[[:space:]]`, never `\s` — adapters auto-convert `[:space:]` to `\s` for JS/Python and compile in multiline mode.
2. Add cases to `~/.agents/hooks/test-guard.sh`: at least one `check block` line for a command the pattern must stop, and at least one `check allow` line for a recoverable command that uses the same program (for `git gc --prune=now`: `git gc`).
3. Run `~/.agents/hooks/test-guard.sh`. It must end `failed: 0`. A failed `check allow` case, old or new, means the pattern over-blocks: narrow the pattern.
4. Verify the new pattern compiles in the adapter engines. The command must print `ok`:

```bash
python3 -c 'import re,pathlib; [re.compile(l.strip().replace("[:space:]",r"\s"),re.M) for l in pathlib.Path.home().joinpath(".agents/hooks/dangerous-patterns.txt").read_text().splitlines() if l.strip() and not l.startswith("#")]; print("ok")'
```

5. If the user runs Droid, mirror the change by hand into `commandBlocklist` in `~/.factory/settings.json`. Why: Droid is the exception; every other consumer re-reads the patterns file for every command.

## Wire an agent

Configs are user-global. Use absolute paths in configs (`~` expansion is inconsistent across agents).

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

Do the step of each agent the user runs. Then read that agent's lines under [Gotchas](#gotchas) and probe it with [E2E verification](#e2e-verification).

1. **Claude Code, Codex, Cursor.** Run `bash .agents/install.sh guard`: it merges the three entries. The Cursor entry (payload has `.command`, so pass the `cursor` arg):

```json
{"beforeShellExecution": [{"command": "/ABSOLUTE/HOME/.agents/hooks/deny-dangerous.sh cursor", "failClosed": false}]}
```

2. **Grok.** No step once the Claude Code or Cursor entry exists: Grok auto-loads both hook files.
3. **Devin.** Merge the entry into the existing config with jq (safe to re-run):

```bash
f=~/.config/devin/config.json
jq --arg c "$HOME/.agents/hooks/deny-dangerous.sh" '.hooks.PreToolUse = [(.hooks.PreToolUse // [])[] | select(any(.hooks[]?; .command == $c) | not)] + [{matcher: "^exec$", hooks: [{type: "command", command: $c}]}]' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
```

4. **Droid.** Put each catastrophic command in `commandBlocklist` in `~/.factory/settings.json`, by hand. Why: Droid does not read the patterns file.
5. **OpenCode, Pi, Hermes.** The adapter at the row's Config path does the blocking, and agent-config does not hold the adapters. If the file is missing, write it by hand so that it:
   - reads `~/.agents/hooks/dangerous-patterns.txt` again for every command, and skips blank lines and `#` lines;
   - replaces `[:space:]` with `\s` and compiles each line in multiline mode;
   - blocks in the way the row's "Blocks via" column names.

## Gotchas

- **Codex trust is hash-pinned.** Any edit to the hook ENTRY in `hooks.json` (not the patterns file) invalidates trust; run `/hooks` in Codex and re-trust, else Codex silently skips the guard. Trust hashes live in `[hooks.state]` in `~/.codex/config.toml` and are shared by CLI, desktop app, and IDE extension.
- **Cursor `failClosed` must stay `false`.** Cursor background/worker hosts cannot execute hook scripts; fail-closed blocks EVERY command there. Trade-off: Cursor background agents run unguarded.
- **Hermes plugin manifest key is `provides_hooks`** (not `hooks`). Plugin must be enabled: `plugins.enabled` list in `~/.hermes/config.yaml` (the `hermes plugins enable` CLI prompts interactively and hangs non-interactive shells). Hermes hooks are fail-open on exceptions, so the plugin does three things and no more: read the patterns file, match the command, return the block action. Why: an exception in the plugin lets every command through. Shell tool name is `terminal`.
- **Pi `tool_call` handler errors block the tool** (fail-safe) — adapter must catch its own errors and fail open, or a broken patterns file bricks every bash call.
- **Droid semantics:** `commandDenylist` = ask for confirmation; `commandBlocklist` = never runs, even at full autonomy with `--skip-permissions-unsafe`. Use blocklist for catastrophic entries.
- **Guard script payload detection:** command lives at `.tool_input.command` (Claude/Codex/Devin), `.toolInput.command` (Grok), `.command` (Cursor). Keep all three in the jq fallback chain.
- **Adapter regexes require multiline mode.** Keep JavaScript's `m` flag and Python's `re.M` so `^` matches each shell line like `grep`.
- **False-positive class:** a harmless command whose ARGUMENT text contains a dangerous-looking string (e.g. passing a prompt mentioning `git push --force` on a CLI) gets blocked. Workaround: put the text in a file and reference it.
- **Unguarded places.** Some agents or execution environments may not provide a hook system, and some background or remote tasks may bypass local guards. Run step 2 of [E2E verification](#e2e-verification) in each agent and environment the user runs, and tell the user each one where the push was not blocked.

## E2E verification

1. Probe the installed guard directly. The guard only reads the JSON, so the command never runs:

```bash
echo '{"tool_input":{"command":"rm -rf /"}}' | ~/.agents/hooks/deny-dangerous.sh; echo "exit=$?"   # expect "Blocked by ..." on stderr, exit=2
echo '{"command":"rm -rf /"}' | ~/.agents/hooks/deny-dangerous.sh cursor                         # expect {"permission":"deny",...}, exit 0
```

2. For each adapter, ask that agent to run `git push --force` from `mktemp -d` (a non-git directory, so the push fails harmlessly if the guard misses) and confirm the guard blocks it.

## Trace a block or a miss

1. Run the first probe of [E2E verification](#e2e-verification) with the command in question in place of `rm -rf /`. If the probe itself is blocked, save the JSON in a file and run `~/.agents/hooks/deny-dangerous.sh <FILE; echo "exit=$?"` (false-positive class above).
2. Read the result:
   - `exit=2`: the guard blocks the command, and stderr quotes the matched pattern. If the command is recoverable, narrow that pattern with [Add or tune a pattern](#add-or-tune-a-pattern).
   - `exit=0`: no pattern matches. If the command is catastrophic, add a pattern.
3. If the probe blocks the command but an agent ran it, that agent's wiring is at fault. Check its row in [Wire an agent](#wire-an-agent) and its lines under [Gotchas](#gotchas).

## Example

A finished pattern change: pattern 8 of the denylist with its cases, copied from `hooks/dangerous-patterns.txt` and `hooks/test-guard.sh` in agent-config, and the output of steps 3 and 4.

```text
Step 1. The line in dangerous-patterns.txt:
  # 8. destroying the reflog safety net (makes local history rewrites unrecoverable)
  (^|[;&|[:space:]])git[[:space:]]+gc[^;&|]*--prune(=|[[:space:]]+)(now|all)

Step 2. The cases in test-guard.sh:
  check block 'git gc --prune=now'
  check block 'git gc --aggressive --prune=now'
  check block 'cd /tmp && git gc --prune=all'
  check allow 'git gc'
  check allow 'git gc --aggressive'
  check allow 'git gc --prune=2.weeks.ago'

Step 3. test-guard.sh ends:
  passed: 302, failed: 0

Step 4. The compile check prints:
  ok
```

## Checklist

Run this before you say the work is done. Check the lines of the task you did.

- [ ] Any task: `~/.agents/hooks/test-guard.sh` ends `failed: 0`.
- [ ] Pattern change: the new line uses `[[:space:]]` and no `\s`.
- [ ] Pattern change: `test-guard.sh` has at least one new `check block` line and one new `check allow` line for it.
- [ ] Pattern change: the compile check printed `ok`, and Droid's `commandBlocklist` has the change if the user runs Droid.
- [ ] Wiring: every path in the config is absolute, and Cursor's `failClosed` is `false`.
- [ ] Wiring: after an edit to the Codex hook entry, `/hooks` was run in Codex and the entry trusted.
- [ ] Wiring: both direct probes gave the expected output, and each wired agent blocked `git push --force` in a `mktemp -d` folder.
- [ ] The reply names each agent or environment where the push was not blocked, or says there is none.
