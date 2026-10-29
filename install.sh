#!/bin/bash
# Wires the agent-config copy at .agents/ into the project that contains it, for each harness.
# Usage, from the project root:
#   bash .agents/install.sh            # every harness
#   bash .agents/install.sh cursor codex   # some: claude cursor codex gemini copilot opencode
#   bash .agents/install.sh guard      # per-user command guard; writes under $HOME
# Safe to run again after each update. Merges into existing JSON and TOML, never overwrites them.
set -euo pipefail
command -v jq >/dev/null || { echo "install.sh needs jq" >&2; exit 1; }

here="$(cd "$(dirname "$0")" && pwd)"
root="$(pwd)"
rel="${here#"$root"/}"
[ "$rel" != "$here" ] || { echo "Run this from the root of the project that contains $(basename "$here")/." >&2; exit 1; }

# Hook commands resolve the project root at run time, so the committed config works in every clone.
PROJ='${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-${GEMINI_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}}'
hookcmd() { # $1 = script in hooks/, $2 = optional argument
  printf 'f="%s/%s/hooks/%s"; [ ! -f "$f" ] || bash "$f"%s' "$PROJ" "$rel" "$1" "${2:+ $2}"
}

merge() { # $1 = JSON file, $2 = jq filter, rest = jq args. Creates the file if missing.
  local f="$1" filter="$2" tmp; shift 2
  mkdir -p "$(dirname "$f")"
  [ -s "$f" ] || echo '{}' >"$f"
  tmp=$(mktemp)
  jq "$@" "$filter" "$f" >"$tmp" && mv "$tmp" "$f"
}

# Claude-style hook list (Claude, Codex, Gemini): drop old entries for the same script, then add the current one.
CLAUDE_HOOK='.hooks[$e] = ([(.hooks[$e] // [])[] | .hooks = [.hooks[]? | select((.command // "") | contains($s) | not)] | select(.hooks | length > 0)]
  + [{hooks: [{type: "command", command: $c} + (if $t == "" then {} else {timeout: ($t | tonumber)} end)]}
    + (if $m == "" then {} else {matcher: $m} end)])'
claude_hook() { # $1 = file, $2 = event, $3 = script, $4 = optional tool matcher, $5 = optional timeout in seconds
  merge "$1" "$CLAUDE_HOOK" --arg e "$2" --arg s "$rel/hooks/$3" --arg c "$(hookcmd "$3")" --arg m "${4:-}" --arg t "${5:-}"
}

servers() { jq -c '.mcpServers' "$here/mcp.json"; }

link_or_merge_mcp() { # $1 = path that reads {"mcpServers":{...}}. Links when free, merges into a project-owned file.
  local f="$1" up=""
  if [ -L "$f" ] || [ ! -e "$f" ]; then
    mkdir -p "$(dirname "$f")"
    case "$f" in */*) up="../" ;; esac # paths here are at most one folder deep
    ln -sfn "$up$rel/mcp.json" "$f"
  else
    merge "$f" '.mcpServers = $s + (.mcpServers // {})' --argjson s "$(servers)"
  fi
}

claude() {
  mkdir -p .claude/skills
  for d in "$here"/skills/*/; do
    n=$(basename "$d")
    ln -sfn "../../$rel/skills/$n" ".claude/skills/$n"
  done
  # Drop links to skills this repo no longer ships.
  find .claude/skills -maxdepth 1 -type l -lname "*$rel/skills/*" ! -exec test -e {} \; -delete
  claude_settings
}

claude_settings() { # Also read by Copilot CLI, and by VS Code with chat.useClaudeHooks.
  link_or_merge_mcp .mcp.json
  claude_hook .claude/settings.json SessionStart load-structured-output.sh
  claude_hook .claude/settings.json UserPromptSubmit context-budget.sh
  claude_hook .claude/settings.json PostToolUse context-budget.sh
  # Jev (Berget): guard tool calls, screen tool output, advise on compaction. Passes everything without BERGET_API_KEY.
  claude_hook .claude/settings.json PreToolUse jev.sh 'Bash|Write|Edit' 10
  claude_hook .claude/settings.json PostToolUse jev.sh 'Read|Bash|WebFetch' 10
  claude_hook .claude/settings.json UserPromptSubmit jev.sh '' 10
}

cursor() { # Skills: reads .agents/skills natively. Plugins: workspaceOpen loads .agents/plugins when that folder has any.
  link_or_merge_mcp .cursor/mcp.json
  merge .cursor/hooks.json '.version //= 1
    | .hooks.sessionStart = [(.hooks.sessionStart // [])[] | select((.command // "") | contains($s) | not)] + [{command: $c}]' \
    --arg s "$rel/hooks/load-structured-output.sh" --arg c "$(hookcmd load-structured-output.sh cursor)"
  if [ -n "$(find "$here/plugins" -mindepth 1 -maxdepth 1 -type d -print -quit 2>/dev/null)" ]; then
    merge .cursor/hooks.json '.version //= 1
      | .hooks.workspaceOpen = [(.hooks.workspaceOpen // [])[] | select((.command // "") | contains($s) | not)] + [{command: $c}]' \
      --arg s "$rel/hooks/load-plugins.sh" --arg c "$(hookcmd load-plugins.sh)"
  else
    merge .cursor/hooks.json '.hooks.workspaceOpen = [(.hooks.workspaceOpen // [])[] | select((.command // "") | contains($s) | not)]
      | if (.hooks.workspaceOpen | length) == 0 then del(.hooks.workspaceOpen) else . end' \
      --arg s "$rel/hooks/load-plugins.sh"
  fi
}

codex() { # Skills: reads .agents/skills natively. Config and hooks load only in trusted projects.
  local f=.codex/config.toml name
  mkdir -p .codex
  touch "$f"
  for name in $(jq -r '.mcpServers | keys[]' "$here/mcp.json"); do
    grep -q "^\[mcp_servers\.$name\]" "$f" && continue
    { echo; echo "[mcp_servers.$name]"
      jq -r --arg n "$name" '.mcpServers[$n] | if .url then "url = \(.url | @json)"
        else "command = \(.command | @json)\nargs = \((.args // []) | @json)" end' "$here/mcp.json"
    } >>"$f"
  done
  claude_hook .codex/hooks.json SessionStart load-structured-output.sh
}

gemini() { # Skills: reads .agents/skills natively. Project hooks must be trusted again after a change.
  merge .gemini/settings.json '.mcpServers = ($s | map_values(if .url then {httpUrl: .url} else del(.type) end)) + (.mcpServers // {})' \
    --argjson s "$(servers)"
  claude_hook .gemini/settings.json SessionStart load-structured-output.sh
}

copilot() { # Skills: reads .agents/skills natively. CLI reads .mcp.json and .claude/settings.json hooks.
  claude_settings
  merge .vscode/mcp.json '.servers = ($s | map_values(if .url then {type: "http", url: .url} else {type: "stdio"} + del(.type) end)) + (.servers // {})' \
    --argjson s "$(servers)"
}

opencode() { # Skills: reads .agents/skills natively. No shell hooks, so the skill loads through instructions.
  merge opencode.json '."$schema" //= "https://opencode.ai/config.json"
    | .mcp = ($s | map_values(if .url then {type: "remote", url: .url} else {type: "local", command: ([.command] + (.args // []))} end)) + (.mcp // {})
    | .instructions = ((.instructions // []) | . + ($i - .))' \
    --argjson s "$(servers)" \
    --argjson i "$(jq -cn --arg r "$rel" '[$r + "/skills/structured-output/SKILL.md", $r + "/skills/structured-output/references/unslop-rules.md"]')"
}

guard() {
  local g="$HOME/.agents/hooks/deny-dangerous.sh"
  mkdir -p "$HOME/.agents/hooks"
  cp "$here"/hooks/deny-dangerous.sh "$here"/hooks/dangerous-patterns.txt "$here"/hooks/test-guard.sh "$HOME/.agents/hooks/"
  chmod +x "$HOME"/.agents/hooks/*.sh
  local entry='.hooks.PreToolUse = [(.hooks.PreToolUse // [])[] | select(any(.hooks[]?; .command == $c) | not)] + [{matcher: "Bash", hooks: [{type: "command", command: $c}]}]'
  [ ! -d "$HOME/.claude" ] || { merge "$HOME/.claude/settings.json" "$entry" --arg c "$g"; echo "guard: Claude Code"; }
  [ ! -d "$HOME/.codex" ] || { merge "$HOME/.codex/hooks.json" "$entry" --arg c "$g"; echo "guard: Codex (run /hooks in Codex and trust the entry)"; }
  [ ! -d "$HOME/.cursor" ] || {
    merge "$HOME/.cursor/hooks.json" '.version //= 1
      | .hooks.beforeShellExecution = [(.hooks.beforeShellExecution // [])[] | select(.command != $c)] + [{command: $c, failClosed: false}]' \
      --arg c "$g cursor"
    echo "guard: Cursor"
  }
  echo "Other agents: see $rel/skills/global-agent-guardrails/SKILL.md"
  "$HOME/.agents/hooks/test-guard.sh" | tail -n 1
}

[ $# -gt 0 ] || set -- claude cursor codex gemini copilot opencode
for h in "$@"; do
  case "$h" in
    claude|cursor|codex|gemini|copilot|opencode|guard) "$h"; echo "done: $h" ;;
    *) echo "unknown harness: $h (use claude cursor codex gemini copilot opencode guard)" >&2; exit 1 ;;
  esac
done
