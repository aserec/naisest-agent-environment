#!/bin/bash
# Test harness for install.sh. Installs twice into a throwaway project that already has its own config.
# Usage: ./test-install.sh
src="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP" && git init -q
mkdir .agents && cp -R "$src/skills" "$src/hooks" "$src/mcp.json" "$src/install.sh" .agents/
pass=0
fail=0
check() { # $1 = label, rest = command that must succeed
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $label"; fi
}

# Project-owned config the installer must keep.
mkdir -p .cursor .claude/skills
echo '{"mcpServers":{"own":{"command":"own-mcp"}}}' >.cursor/mcp.json
echo '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"f=\"${CLAUDE_PROJECT_DIR:-.}/.agents/hooks/load-structured-output.sh\"; [ ! -f \"$f\" ] || bash \"$f\""},{"type":"command","command":"echo mine"}]}]}}' >.claude/settings.json
ln -s ../../.agents/skills/removed-skill .claude/skills/removed-skill

bash .agents/install.sh >/dev/null && bash .agents/install.sh >/dev/null
check "install exits 0" test $? -eq 0

check "claude skill link resolves"   test -f .claude/skills/commit/SKILL.md
check "stale skill link removed"     test ! -L .claude/skills/removed-skill
check ".mcp.json links to mcp.json"  jq -e '.mcpServers.figma' .mcp.json
check "cursor keeps own server"      jq -e '.mcpServers.own and .mcpServers.figma' .cursor/mcp.json
check "one SessionStart loader"      jq -e '[.hooks.SessionStart[].hooks[] | select(.command | contains("load-structured-output"))] | length == 1' .claude/settings.json
check "own hook kept"                jq -e '[.hooks.SessionStart[].hooks[] | select(.command == "echo mine")] | length == 1' .claude/settings.json
check "jev hooks with matcher and timeout" jq -e '[.hooks.PreToolUse, .hooks.PostToolUse, .hooks.UserPromptSubmit | [.[] | select(.hooks[0].command | contains("jev.sh")) | {matcher, t: .hooks[0].timeout}]] == [[{matcher: "Bash|Write|Edit", t: 10}], [{matcher: "Read|Bash|WebFetch", t: 10}], [{matcher: null, t: 10}]]' .claude/settings.json
check "codex servers written once"   test "$(grep -c '^\[mcp_servers\.' .codex/config.toml)" -eq "$(jq '.mcpServers | length' .agents/mcp.json)"
check "codex figma url"              grep -q '^url = "https://mcp.figma.com/mcp"' .codex/config.toml
check "codex one loader"             jq -e '.hooks.SessionStart | length == 1' .codex/hooks.json
check "cursor one loader"            jq -e '.version == 1 and (.hooks.sessionStart | length == 1) and (.hooks.workspaceOpen // [] | length == 0)' .cursor/hooks.json
check "gemini http uses httpUrl"     jq -e '.mcpServers.figma.httpUrl and (.hooks.SessionStart | length == 1)' .gemini/settings.json
check "vscode servers key"           jq -e '.servers.figma.type == "http" and .servers.graft.type == "stdio"' .vscode/mcp.json
check "opencode mcp and instructions" jq -e '.mcp.graft.command == ["graft","mcp"] and (.instructions | length == 2)' opencode.json

# The committed commands must find the loader and print the shape each harness reads.
cmd=$(jq -r '.hooks.SessionStart[].hooks[] | select(.command | contains("load-structured")) | .command' .claude/settings.json)
check "claude loader output" sh -c "$cmd | jq -e '.hookSpecificOutput.additionalContext | contains(\"Structured output\")'"
cmd=$(jq -r '.hooks.sessionStart[0].command' .cursor/hooks.json)
check "cursor loader output" sh -c "cd /tmp && CURSOR_PROJECT_DIR='$TMP' sh -c '$cmd' | jq -e '.additional_context | length > 0'"

mkdir -p .agents/plugins/demo/.cursor-plugin
echo '{}' >.agents/plugins/demo/.cursor-plugin/plugin.json
bash .agents/install.sh cursor >/dev/null
check "cursor plugin hook" jq -e '[.hooks.workspaceOpen[] | select(.command | contains("load-plugins"))] | length == 1' .cursor/hooks.json
cmd=$(jq -r '.hooks.workspaceOpen[0].command' .cursor/hooks.json)
check "plugin paths" sh -c "$cmd | jq -e '.pluginPaths | length == 1 and (.[0] | endswith(\"/plugins/demo\"))'"
rm -rf .agents/plugins
bash .agents/install.sh cursor >/dev/null
check "plugin hook removed" jq -e '(.hooks.workspaceOpen // []) | length == 0' .cursor/hooks.json

check "outside project root fails" sh -c "cd .agents && ! bash install.sh claude"

echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
