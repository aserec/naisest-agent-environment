#!/bin/bash
# Test for sync-all.sh with a stub sync.sh: a clean project gets a commit,
# a dirty project and a folder outside git are skipped and named in the report.
# Usage: ./test-sync-all.sh
repo="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/agent-config-test.XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/clone"
cp "$repo/sync-all.sh" "$TMP/clone/"
printf '%s\n' '#!/bin/bash' 'echo "{\"commit\":\"new\"}" >"$1/.agents/sync.json"' >"$TMP/clone/sync.sh"

make_project() { # $1 = name
  mkdir -p "$TMP/$1/.agents"
  echo '{"commit":"old"}' >"$TMP/$1/.agents/sync.json"
  git -C "$TMP/$1" init -q
  git -C "$TMP/$1" -c user.email=t@example.com -c user.name=t add -A
  git -C "$TMP/$1" -c user.email=t@example.com -c user.name=t commit -q -m init
}
make_project clean
make_project dirty
echo wip >"$TMP/dirty/wip.txt"
mkdir -p "$TMP/nogit/.agents" && echo '{}' >"$TMP/nogit/.agents/sync.json"

out=$(GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com \
  bash "$TMP/clone/sync-all.sh" "$TMP" 2>&1)
status=$?

fail=0
check() { # $1 = label, rest = command that must succeed
  local label="$1"; shift
  "$@" >/dev/null 2>&1 || { echo "FAIL $label"; fail=1; }
}
check "exits non-zero when a project is skipped" test "$status" -ne 0
check "clean project committed" test "$(git -C "$TMP/clean" log -1 --format=%s)" = "chore: bump agent-config"
check "clean project left clean" test -z "$(git -C "$TMP/clean" status --porcelain)"
check "dirty project not synced" grep -q old "$TMP/dirty/.agents/sync.json"
check "dirty project not committed" test "$(git -C "$TMP/dirty" rev-list --count HEAD)" = 1
check "dirty project reported" grep -q "dirty: uncommitted changes" <<<"$out"
check "non-git folder reported" grep -q "nogit: not a git repo" <<<"$out"
[ "$fail" -eq 0 ] || { echo "$out"; exit 1; }
echo "test-sync-all: ok"
