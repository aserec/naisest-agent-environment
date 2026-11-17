#!/bin/bash
# Run sync.sh in every project on this machine that was synced before,
# that is every project with a .agents/sync.json, and commit the result.
# A project is skipped when it is not a git repo or its worktree is dirty,
# so the commit holds only what the sync changed.
#
# Usage:
#   bash sync-all.sh              # sync and commit every project under $HOME
#   bash sync-all.sh check        # report drift only, change nothing
#   bash sync-all.sh [check] DIR  # search DIR instead of $HOME
set -uo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
mode=sync
if [ "${1:-}" = check ]; then mode=check; shift; fi
root="${1:-$HOME}"
msg="chore: bump agent-config"

updated=()
current=()
skipped=()
while IFS= read -r marker; do
  project="${marker%/.agents/sync.json}"
  [ "$project" != "$src" ] || continue
  echo "== $project"
  if [ "$mode" = check ]; then
    bash "$src/sync.sh" check "$project" || skipped+=("$project: drift")
    continue
  fi
  if ! git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    skipped+=("$project: not a git repo"); continue
  fi
  if [ -n "$(git -C "$project" status --porcelain)" ]; then
    skipped+=("$project: uncommitted changes, commit or stash them first"); continue
  fi
  if ! bash "$src/sync.sh" "$project"; then
    skipped+=("$project: sync.sh failed, see the output above"); continue
  fi
  # The tree was clean before the sync, so every change here came from it.
  git -C "$project" add -A
  if git -C "$project" diff --cached --quiet; then
    current+=("$project"); continue
  fi
  if git -C "$project" commit -q -m "$msg"; then
    updated+=("$project ($(git -C "$project" rev-parse --short HEAD))")
  else
    skipped+=("$project: git commit failed, the sync changes are staged")
  fi
done < <(find "$root" -maxdepth 5 -path '*/.agents/sync.json' \
  -not -path '*/node_modules/*' -not -path '*/Library/*' 2>/dev/null | sort)

echo
list() { # $1 = title, rest = lines
  local title="$1"; shift
  [ $# -gt 0 ] || return 0
  echo "$title:"
  printf '  %s\n' "$@"
}
list "Updated and committed" "${updated[@]+"${updated[@]}"}"
list "Already up to date" "${current[@]+"${current[@]}"}"
list "Not updated" "${skipped[@]+"${skipped[@]}"}"
[ ${#skipped[@]} -eq 0 ]
