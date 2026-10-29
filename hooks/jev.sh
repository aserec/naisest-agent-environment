#!/bin/bash
# Jev levels 6 and 7 for Claude Code: see jev/hook.ts. Registered by install.sh on
# PreToolUse, PostToolUse and UserPromptSubmit. Without BERGET_API_KEY every hook passes.
[ -n "${BERGET_API_KEY:-}" ] || exit 0
exec node "$(cd "$(dirname "$0")" && pwd)/../jev/hook.ts"
