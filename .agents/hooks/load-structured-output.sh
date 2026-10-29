#!/bin/bash
# Loads the structured-output skill into every session. Registered on session start by install.sh.
# Finds the skill next to this script, so it works here and under .agents/.
# Output: {"hookSpecificOutput":{"additionalContext":...}} for Claude Code, Codex, Gemini and Copilot;
#         {"additional_context":...} with the "cursor" argument. Plain text when jq is missing.
skill="$(cd "$(dirname "$0")/.." && pwd)/skills/structured-output"
[ -f "$skill/SKILL.md" ] || exit 0
text=$(
  echo "Follow this skill for every chat reply in this session. Its references/ folder is at $skill/references."
  echo "Examples, limitations and troubleshooting are in $skill/SKILL.md. Read them when a check fails."
  echo
  # Only the rules load every session; the sections from Examples on stay in the file.
  sed '/^## Examples$/,$d' "$skill/SKILL.md"
  echo
  cat "$skill/references/unslop-rules.md"
)
command -v jq >/dev/null 2>&1 || { printf '%s\n' "$text"; exit 0; }
if [ "${1:-}" = cursor ]; then
  jq -n --arg t "$text" '{additional_context: $t}'
else
  jq -n --arg t "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $t}}'
fi
