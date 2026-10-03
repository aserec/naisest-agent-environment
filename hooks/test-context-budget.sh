#!/bin/bash
# Test harness for context-budget.sh.
# Usage: .agents/hooks/test-context-budget.sh
cd "$(dirname "$0")" || exit 1
HOOK="$PWD/context-budget.sh"
TMP=$(mktemp -d)
export CONTEXT_BUDGET_STATE_DIR="$TMP/state"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

transcript() { # $1 = file, $2 = context tokens of the last assistant turn
  {
    echo '{"type":"assistant","message":{"usage":{"input_tokens":1,"cache_read_input_tokens":10,"cache_creation_input_tokens":0}}}'
    echo '{"type":"user","message":{"content":"hi"}}'
    jq -cn --argjson n "$2" '{type:"assistant",message:{usage:{input_tokens:2,cache_read_input_tokens:($n-2),cache_creation_input_tokens:0}}}'
  } >"$1"
}

check() { # $1 = label, $2 = session, $3 = tokens, $4 = expected: none|soft|hard
  local f="$TMP/$2.jsonl" out got
  transcript "$f" "$3"
  out=$(jq -cn --arg p "$f" --arg s "$2" '{session_id:$s,transcript_path:$p,hook_event_name:"UserPromptSubmit"}' | "$HOOK")
  case "$out" in
    *"over the 150K"*) got=hard ;;
    *"refresh point"*) got=soft ;;
    "") got=none ;;
    *) got="invalid:$out" ;;
  esac
  if [ "$got" = "$4" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: expected=$4 got=$got"; fi
}

check "below threshold"        a 119999 none
check "at 120K warns"          b 120000 soft
check "soft warning once"      b 130000 none
check "at 150K escalates"      b 150000 hard
check "hard warning once"      b 170000 none
check "straight to hard"       c 155000 hard
check "sessions are separate"  d 125000 soft

# A subagent's hook input carries the parent's session_id and transcript_path plus agent_id;
# its own transcript is <session dir>/subagents/agent-<agent_id>.jsonl.
subagent() { # $1 = label, $2 = session, $3 = agent_id, $4 = subagent tokens, $5 = expected
  local main="$TMP/$2.jsonl" out got
  mkdir -p "$TMP/$2/subagents"
  transcript "$main" 10000
  transcript "$TMP/$2/subagents/agent-$3.jsonl" "$4"
  out=$(jq -cn --arg p "$main" --arg s "$2" --arg a "$3" '{session_id:$s,transcript_path:$p,agent_id:$a,hook_event_name:"PostToolUse"}' | "$HOOK")
  case "$out" in
    *"over the 150K"*) got=hard ;;
    *"refresh point"*) got=soft ;;
    "") got=none ;;
    *) got="invalid:$out" ;;
  esac
  if [ "$got" = "$5" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: expected=$5 got=$got"; fi
}

check    "main already at hard"       f 160000 hard
subagent "subagent measured itself"   f x1 125000 soft
subagent "subagent escalates"         f x1 276000 hard
subagent "subagents are separate"     f x2 155000 hard

# Missing or unreadable transcript must never break the prompt.
out=$(echo '{"session_id":"e","transcript_path":"/nonexistent"}' | "$HOOK"); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL missing transcript: rc=$rc out=$out"; fi

echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
