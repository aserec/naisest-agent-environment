#!/bin/bash
# Test harness for sync.sh. Copies a tiny fixture clone into a throwaway project.
# Usage: ./test-sync.sh
repo="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
src="$TMP/agent-config"
proj="$TMP/project"
mkdir -p "$src/skills/alpha" "$src/skills/beta" "$src/plugins/demo/.cursor-plugin" "$src/hooks" "$TMP/bin"
printf '%s\n' '---' 'name: alpha' '---' >"$src/skills/alpha/SKILL.md"
printf '%s\n' '---' 'name: beta' '---' >"$src/skills/beta/SKILL.md"
echo '{}' >"$src/plugins/demo/.cursor-plugin/plugin.json"
echo 'echo hook' >"$src/hooks/demo.sh"
echo '{}' >"$src/mcp.json"
echo '# Setup' >"$src/SETUP.md"
printf '%s\n' '#!/bin/bash' 'touch "$(pwd)/.install-ran"' >"$src/install.sh"
chmod +x "$src/install.sh" "$src/hooks/demo.sh"
cp "$repo/sync.sh" "$src/sync.sh"
chmod +x "$src/sync.sh"

git init -q "$proj"
git -C "$proj" config user.email test@example.com
git -C "$proj" config user.name test
real_git=$(command -v git)
cat >"$TMP/bin/git" <<EOF
#!/bin/bash
case " \$* " in
  *fetch*|*pull*|*clone*|*ls-remote*) echo "blocked git \$*" >&2; exit 99 ;;
esac
exec "$real_git" "\$@"
EOF
chmod +x "$TMP/bin/git"
export PATH="$TMP/bin:$PATH"

pass=0
fail=0
check() { # $1 = label, rest = command that must succeed
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $label"; fi
}

check "url is refused" sh -c "! bash '$src/sync.sh' 'https://origin.cursor.com/agent-config'"
check "clone as target is refused" sh -c "! bash '$src/sync.sh' '$src'"

bash "$src/sync.sh" "$proj" >/dev/null
check "sync exits 0" test $? -eq 0
check "skill copied" test -f "$proj/.agents/skills/alpha/SKILL.md"
check "plugin copied" test -f "$proj/.agents/plugins/demo/.cursor-plugin/plugin.json"
check "hook copied" test -f "$proj/.agents/hooks/demo.sh"
check "install ran" test -f "$proj/.install-ran"
check "sync.json lists both skills" jq -e '.skills == ["alpha","beta"]' "$proj/.agents/sync.json"
check "not a submodule" sh -c "! git -C '$proj' ls-files -s -- .agents | awk '\$1 == \"160000\" && \$4 == \".agents\" { found=1 } END { exit found ? 0 : 1 }'"

mkdir -p "$proj/.agents/skills/mine" "$proj/.agents/plugins/mine"
echo mine >"$proj/.agents/skills/mine/SKILL.md"
echo mine >"$proj/.agents/plugins/mine/plugin.json"
echo extra >"$proj/.agents/hooks/extra.sh"
rm -rf "$src/skills/alpha" "$src/plugins/demo" "$src/hooks/demo.sh"
mkdir -p "$src/skills/gamma"
printf '%s\n' '---' 'name: gamma' '---' >"$src/skills/gamma/SKILL.md"
echo other >"$src/hooks/other.sh"
rm -f "$proj/.install-ran"
echo drift >>"$proj/.agents/skills/beta/SKILL.md"
check "check reports drift" sh -c "! bash '$src/sync.sh' check '$proj'"
check "check does not install" test ! -f "$proj/.install-ran"
check "check leaves the drift" grep -q drift "$proj/.agents/skills/beta/SKILL.md"

bash "$src/sync.sh" "$proj" >/dev/null
check "removed skill is gone" test ! -e "$proj/.agents/skills/alpha"
check "new skill copied" test -f "$proj/.agents/skills/gamma/SKILL.md"
check "project skill kept" test -f "$proj/.agents/skills/mine/SKILL.md"
check "removed plugin is gone" test ! -e "$proj/.agents/plugins/demo"
check "project plugin kept" test -f "$proj/.agents/plugins/mine/plugin.json"
check "removed hook is gone" test ! -e "$proj/.agents/hooks/demo.sh"
check "project hook kept" test -f "$proj/.agents/hooks/extra.sh"
check "new hook copied" test -f "$proj/.agents/hooks/other.sh"
check "drift replaced" sh -c "! grep -q drift '$proj/.agents/skills/beta/SKILL.md'"
check "second check is clean" bash "$src/sync.sh" check "$proj"

link="$TMP/linked"
git init -q "$link"
git -C "$link" config user.email test@example.com
git -C "$link" config user.name test
echo a >"$link/a"
git -C "$link" add a
git -C "$link" commit -q -m a
git -C "$link" update-index --add --cacheinfo "160000,$(git -C "$link" rev-parse HEAD),.agents"
check "submodule is refused" sh -c "! bash '$src/sync.sh' '$link'"

echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
