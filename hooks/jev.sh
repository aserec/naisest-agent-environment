#!/bin/bash
# Jev levels 6 and 7 for Claude Code: see jev/hook.ts. Registered by install.sh on
# PreToolUse, PostToolUse and UserPromptSubmit. Without a Jev key every hook passes.
# Provider order when several keys are set: DecisionModels, Berget, TypeSafe, OpenRouter.
[ -n "${DECISIONMODELS_API_KEY:-}${BERGET_API_KEY:-}${TYPESAFE_API_KEY:-}${OPENROUTER_API_KEY:-}" ] || exit 0
exec node "$(cd "$(dirname "$0")" && pwd)/../jev/hook.ts"
