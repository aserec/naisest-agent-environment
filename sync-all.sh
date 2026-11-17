#!/bin/bash
# Run sync.sh in every project on this machine that was synced before,
# that is every project with a .agents/sync.json. Projects never synced are skipped.
#
# Usage:
#   bash sync-all.sh              # sync every project under $HOME
#   bash sync-all.sh check        # report drift only, change nothing
#   bash sync-all.sh [check] DIR  # search DIR instead of $HOME
set -uo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
mode=sync
if [ "${1:-}" = check ]; then mode=check; shift; fi
root="${1:-$HOME}"

failed=()
while IFS= read -r marker; do
  project="${marker%/.agents/sync.json}"
  [ "$project" != "$src" ] || continue
  echo "== $project"
  bash "$src/sync.sh" "$mode" "$project" || failed+=("$project")
done < <(find "$root" -maxdepth 5 -path '*/.agents/sync.json' \
  -not -path '*/node_modules/*' -not -path '*/Library/*' 2>/dev/null | sort)

if [ ${#failed[@]} -gt 0 ]; then
  printf '%s failed:\n' "$mode" >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "$mode done"
