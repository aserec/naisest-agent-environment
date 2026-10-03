#!/usr/bin/env bash
# Shared guard. Reads a hook payload (JSON) on stdin; blocks if the shell command
# matches a line of dangerous-patterns.txt. Exit 2 = block (Claude/Codex/Devin/Grok).
# Arg "cursor": print Cursor's deny JSON instead. Fails open on any internal error.
patterns="${GUARD_PATTERNS:-$HOME/.agents/hooks/dangerous-patterns.txt}"
payload=$(cat)
[ -r "$patterns" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // .toolInput.command // .command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

while IFS= read -r pat || [ -n "$pat" ]; do
  case "$pat" in ''|'#'*) continue ;; esac
  if printf '%s\n' "$cmd" | grep -Eq -- "$pat" 2>/dev/null; then
    reason="Blocked by global agent guardrail (~/.agents/hooks/dangerous-patterns.txt): $pat"
    if [ "${1:-}" = cursor ]; then
      jq -nc --arg r "$reason" '{permission:"deny",user_message:$r,agent_message:$r}'
      exit 0
    fi
    echo "$reason" >&2
    exit 2
  fi
done < "$patterns"
exit 0
