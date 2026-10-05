#!/bin/bash
# Static checks on skills/. Run by the pre-commit hook; no network.
# - every skills/<dir> has a SKILL.md whose name: matches <dir>
# - every `/skill` in a SKILL.md and every "Skill tool with <skill>" reference names a skill that exists (or a built-in command)
# - every skill in upstream/upstream.json exists, and every upstream/patches/<skill>.patch names one
# Usage: ./check-skills.sh   (prints failures; exit 1 on any)
cd "$(dirname "$0")"
builtins=" clear compact hooks mcp tmp help init model config context agents "
fail=0
err() { echo "FAIL $*"; fail=1; }

for d in skills/*/; do
  n=$(basename "$d")
  [ -f "$d/SKILL.md" ] || { err "$n: no SKILL.md"; continue; }
  name=$(sed -n '2,10s/^name: *//p' "$d/SKILL.md" | head -1 | tr -d '"'"'")
  [ "$name" = "$n" ] || err "$n: SKILL.md name is '$name'"
done

{
  grep -rhoE '`/[a-z][a-z0-9-]*`' --include=SKILL.md skills | tr -d '`/'
  grep -rhoE 'Skill tool with [`"][a-z][a-z0-9-]*[`"]' --include='*.md' skills | sed -E 's/.*[`"]([a-z0-9-]+)[`"]$/\1/'
} | sort -u | while read -r ref; do
  case "$builtins" in *" $ref "*) continue ;; esac
  [ -d "skills/$ref" ] || { echo "FAIL reference to missing skill: $ref ($(grep -rlE "(\`/$ref\`|Skill tool with [\`\"]$ref[\`\"])" --include='*.md' skills | tr '\n' ' '))"; echo x >>"${TMPDIR:-/tmp}/check-skills.$$"; }
done
[ -f "${TMPDIR:-/tmp}/check-skills.$$" ] && { fail=1; rm -f "${TMPDIR:-/tmp}/check-skills.$$"; }

for n in $(jq -r '.sources[].skills | keys[]' upstream/upstream.json); do
  [ -d "skills/$n" ] || err "upstream.json lists $n but skills/$n is missing"
done
for p in upstream/patches/*.patch; do
  [ -e "$p" ] || continue
  n=$(basename "$p" .patch)
  jq -e --arg n "$n" '[.sources[].skills | keys[]] | index($n)' upstream/upstream.json >/dev/null || err "$p: $n is not in upstream.json"
done

[ "$fail" = 0 ] && echo "check-skills: ok"
exit "$fail"
