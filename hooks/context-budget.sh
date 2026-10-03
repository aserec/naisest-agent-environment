#!/bin/bash
# Warns the main session or a subagent when its own context passes 120K and again at 150K.
# Registered on UserPromptSubmit and PostToolUse in .claude/settings.json.
# Context = the last assistant turn's input + cache_read + cache_creation tokens.
# Rule: engineering-docs/05-development/claude-code-workflow.md#context-budget
SOFT=120000
HARD=150000
STATE_DIR="${CONTEXT_BUDGET_STATE_DIR:-${TMPDIR:-/tmp}/claude-context-budget}"

input=$(cat)
session=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)
transcript=$(jq -r '.transcript_path // empty' <<<"$input" 2>/dev/null)
event=$(jq -r '.hook_event_name // "UserPromptSubmit"' <<<"$input" 2>/dev/null)
# Inside a subagent, session_id and transcript_path are the parent's; agent_id names the subagent,
# whose transcript sits at <parent transcript minus .jsonl>/subagents/agent-<agent_id>.jsonl.
agent=$(jq -r '.agent_id // empty' <<<"$input" 2>/dev/null)
if [ -n "$agent" ]; then
  transcript="${transcript%.jsonl}/subagents/agent-$agent.jsonl"
  session="$session-$agent"
fi
[ -n "$session" ] && [ -r "$transcript" ] || exit 0

# ponytail: tail -200 assumes the last assistant turn is within 200 lines; widen if huge tool dumps push it out.
tokens=$(tail -n 200 "$transcript" | jq -s '[.[] | select(.type == "assistant") | .message.usage // empty] | last
  | if . then (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0) else 0 end' 2>/dev/null)
[ -n "$tokens" ] || exit 0

mkdir -p "$STATE_DIR"
marker="$STATE_DIR/$session"
level=$(cat "$marker" 2>/dev/null)
k=$((tokens / 1000))

if [ "$tokens" -ge "$HARD" ] && [ "$level" != hard ]; then
  echo hard >"$marker"
  msg="Context is ${k}K, over the 150K ceiling. Hand off now: finish only the step in progress, write a small handoff file, and relay the rest to a fresh subagent (claude-code-workflow.md#context-budget)."
elif [ "$tokens" -ge "$SOFT" ] && [ -z "$level" ]; then
  echo soft >"$marker"
  msg="Context is ${k}K, past the 120K refresh point. At the next safe checkpoint, write a small handoff file and relay the rest to a fresh subagent (claude-code-workflow.md#context-budget)."
else
  exit 0
fi

jq -cn --arg e "$event" --arg m "$msg" '{hookSpecificOutput:{hookEventName:$e,additionalContext:$m}}'
