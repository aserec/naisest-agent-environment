#!/bin/bash
# Prints skill text as session-start context. The load-*.sh scripts next to this one call it, one per hook entry.
# Usage: load-skill.sh "<harness>" "<first line>" <file under skills/>...
# Finds skills/ next to this script's folder, so it works here and under .agents/.
# Output: {"hookSpecificOutput":{"additionalContext":...}} for Claude Code, Codex, Gemini and Copilot;
#         {"additional_context":...} when <harness> is "cursor". Plain text when jq is missing.
# Claude Code swaps a hook string over 10,000 characters for a file path and a short preview,
# so each load-*.sh must print less than that. test-install.sh checks it.
skills="$(cd "$(dirname "$0")/.." && pwd)/skills"
harness="${1:-}" first="${2:-}"
shift 2
[ -f "$skills/$1" ] || exit 0
text=$(
  echo "$first"
  for f in "$@"; do
    [ -f "$skills/$f" ] || continue
    echo
    # Drop the frontmatter and the sections from Examples up to Checklist: those stay in the file.
    awk 'NR == 1 && /^---$/ { fm = 1; next }
         fm { if (/^---$/) fm = 0; next }
         /^## Examples$/ { skip = 1 }
         /^## Checklist$/ { skip = 0 }
         !skip' "$skills/$f"
  done
)
command -v jq >/dev/null 2>&1 || { printf '%s\n' "$text"; exit 0; }
if [ "$harness" = cursor ]; then
  jq -n --arg t "$text" '{additional_context: $t}'
else
  jq -n --arg t "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $t}}'
fi
