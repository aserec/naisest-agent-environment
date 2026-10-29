#!/bin/bash
# Runs the ground-truth feature through a headless Claude Code session in a fresh copy of the fixture app,
# then runs the agent's own tests, the design checks and the hidden oracle tests, then scores the run.
# Usage: run.sh [--label NAME] [--model MODEL] [--budget USD]
#               [--disable-plugin NAME@MARKET]... [--enable-plugin NAME@MARKET]... [--plugin-dir DIR]...
#               [--disable-skill NAME]... [--agent-config DIR | --no-agent-config]
# Prints the run directory on the last line.
set -eo pipefail
skill="$(cd "$(dirname "$0")/.." && pwd -P)"
label=current
model=""
budget=1
plugins='{}'
agent_config="${AGENT_CONFIG:-$(cd "$skill/../.." && pwd -P)}"
extra=()
deny=("Skill(audit-workflow)")
while [ $# -gt 0 ]; do
  case "$1" in
    --label) label=$2; shift 2 ;;
    --model) model=$2; shift 2 ;;
    --budget) budget=$2; shift 2 ;;
    --agent-config) agent_config=$(cd "$2" && pwd -P); shift 2 ;;
    --no-agent-config) agent_config=""; shift ;;
    --disable-plugin) plugins=$(echo "$plugins" | jq -c --arg p "$2" '.[$p] = false'); shift 2 ;;
    --enable-plugin) plugins=$(echo "$plugins" | jq -c --arg p "$2" '.[$p] = true'); shift 2 ;;
    --plugin-dir) extra+=(--plugin-dir "$(cd "$2" && pwd -P)"); shift 2 ;;
    --disable-skill) deny+=("Skill($2)"); shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[ -n "$model" ] && extra+=(--model "$model")

out="${AUDIT_RUNS:-$HOME/.cache/audit-workflow/runs}/$(date +%Y%m%d-%H%M%S)-$label"
app="$out/app"
mkdir -p "$out"
rsync -a --exclude node_modules "$skill/assets/fixture/" "$app/"
cp "$skill/references/feature-spec.md" "$app/FEATURE.md"
cd "$app"
npm ci --no-audit --no-fund >"$out/setup.log" 2>&1
node_modules/.bin/playwright install chromium >>"$out/setup.log" 2>&1

# The same wiring a real project gets: agent-config as .agents, then its installer.
if [ -n "$agent_config" ] && [ -f "$agent_config/install.sh" ]; then
  ln -s "$agent_config" .agents
  bash .agents/install.sh claude >>"$out/setup.log" 2>&1
fi
git init -q
git add -A
git -c user.name=audit -c user.email=audit@local commit -qm baseline
git tag baseline

jq -n --arg label "$label" --arg model "$model" --argjson plugins "$plugins" --arg agent_config "$agent_config" \
  '{label: $label, model: $model, plugin_overrides: $plugins, agent_config: $agent_config, denied: $ARGS.positional}' \
  --args "${deny[@]}" >"$out/setup.json"

# ponytail: one sequential run at a time; the fixture's dev server uses fixed port 5199.
settings=$(jq -cn --argjson p "$plugins" '{enabledPlugins: $p}')
# Billed: this starts a Claude Code session on the operator's own account, with the model the operator chose
# (--model, or their default). SKILL.md step 2 has the user approve each command line and its --budget cap first.
set +e # a session that fails or hits the budget cap is still checked and scored
claude -p --output-format stream-json --verbose --permission-mode bypassPermissions \
  --max-budget-usd "$budget" --settings "$settings" "${extra[@]}" --disallowedTools "${deny[@]}" \
  <"$skill/references/workflow-prompt.md" >"$out/stream.jsonl" 2>"$out/stderr.log"
set -e

free_port() { lsof -ti tcp:5199 | xargs kill 2>/dev/null || true; }
check() { # $1 = name, rest = command. Prints true or false and keeps the log.
  local name=$1
  shift
  if "$@" >"$out/$name.log" 2>&1; then echo true; else echo false; fi
}
changed_matches() { git diff --cached --name-only baseline | grep -qE "$1" && echo true || echo false; }
unchanged() { git diff --cached --quiet baseline -- "$@" && echo true || echo false; }

git add -A
git diff --cached baseline >"$out/diff.patch"
free_port
agent_unit=$(check agent-unit npm test)
agent_e2e=$(check agent-e2e npm run e2e)
typecheck=$(check typecheck npm run typecheck)
protected=$(unchanged src/components/Button.tsx src/pages/Profile.tsx src/styles.css)
deps=$(unchanged package.json package-lock.json)
added_unit=$(changed_matches '^src/.*\.test\.tsx$')
added_e2e=$(changed_matches '^e2e/.*\.spec\.ts$')

mkdir -p src/__oracle__
cp "$skill/assets/oracle/ProfileButton.oracle.test.tsx" src/__oracle__/
cp "$skill/assets/oracle/profile-button.oracle.spec.ts" e2e/
free_port
oracle_unit=$(check oracle-unit node_modules/.bin/vitest run src/__oracle__)
oracle_e2e=$(check oracle-e2e node_modules/.bin/playwright test e2e/profile-button.oracle.spec.ts)
free_port
find test-results -name header.png -exec cp {} "$out/" \; 2>/dev/null || true

jq -n --argjson agent_unit "$agent_unit" --argjson agent_e2e "$agent_e2e" --argjson typecheck "$typecheck" \
  --argjson protected_files_unchanged "$protected" --argjson no_new_deps "$deps" \
  --argjson oracle_unit "$oracle_unit" --argjson oracle_e2e "$oracle_e2e" \
  --argjson added_unit_test "$added_unit" --argjson added_e2e_test "$added_e2e" \
  '$ARGS.named' >"$out/checks.json"

python3 "$skill/scripts/score.py" "$out" >/dev/null
echo "$out"
