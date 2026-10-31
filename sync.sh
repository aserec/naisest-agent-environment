#!/bin/bash
# Copy skills, plugins and hooks from this local clone into a project.
# The project gets a plain copy at .agents/. It is not a git submodule.
# This script only reads the clone on disk. It does not fetch, pull or clone.
# Do not point it at Origin or any other remote.
#
# Usage, from the project root (or pass the project path):
#   bash /path/to/agent-config/sync.sh
#   bash /path/to/agent-config/sync.sh /path/to/project
#   bash /path/to/agent-config/sync.sh check
#   bash /path/to/agent-config/sync.sh check /path/to/project
# check reports drift and changes nothing. A later sync deletes a skill, plugin
# or hook only when sync.json lists it and this clone no longer has it.
set -euo pipefail
command -v jq >/dev/null || { echo "sync.sh needs jq" >&2; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)"
mode=sync
if [ "${1:-}" = check ]; then mode=check; shift; fi
if [ "${1:-}" = sync ]; then shift; fi
[ $# -le 1 ] || { sed -n '2,12p' "$0" >&2; exit 2; }

case "${1:-}" in
  *://*|git@*|origin:*)
    echo "sync reads a local directory. It does not fetch from a remote or from Origin." >&2
    exit 1 ;;
esac

if [ $# -eq 1 ]; then
  [ -d "$1" ] || { echo "not a directory: $1" >&2; exit 1; }
  project="$(cd "$1" && pwd)"
else
  project="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

[ "$project" != "$src" ] || { echo "Run sync from the other project, not from the agent-config clone." >&2; exit 1; }
[ -d "$src/skills" ] && [ -d "$src/hooks" ] && [ -f "$src/install.sh" ] && [ -f "$src/mcp.json" ] && [ -f "$src/SETUP.md" ] \
  || { echo "This clone is missing skills/, hooks/, install.sh, mcp.json or SETUP.md." >&2; exit 1; }

agents="$project/.agents"
if [ -L "$agents" ]; then
  echo ".agents is a link. Remove it, then run sync again so the project gets a real copy." >&2
  exit 1
fi
if [ -e "$agents/.git" ]; then
  echo ".agents is its own git checkout. Remove the submodule, then run sync again." >&2
  exit 1
fi
if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  && git -C "$project" ls-files -s -- .agents | awk '$1 == "160000" && $4 == ".agents" { found=1 } END { exit found ? 0 : 1 }'; then
  echo ".agents is a git submodule. Remove it, then run sync again:" >&2
  echo "  git submodule deinit -f .agents && git rm -f .agents && rm -rf .git/modules/.agents" >&2
  exit 1
fi

dir_names() { # $1 = directory. One folder name per line.
  [ -d "$1" ] || return 0
  find "$1" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}
file_names() { # $1 = directory. One file or folder name per line, skipping .DS_Store.
  [ -d "$1" ] || return 0
  find "$1" -mindepth 1 -maxdepth 1 ! -name .DS_Store -exec basename {} \; | sort
}
as_json() { jq -R -s 'split("\n") | map(select(length > 0))'; }

skills_json=$(dir_names "$src/skills" | as_json)
plugins_json=$(dir_names "$src/plugins" | as_json)
hooks_json=$(file_names "$src/hooks" | as_json)
commit=""
if git -C "$src" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit=$(git -C "$src" rev-parse HEAD)
fi

same() { diff -rq -x .DS_Store "$1" "$2" >/dev/null 2>&1; }

if [ "$mode" = check ]; then
  drift=0
  note() { echo "$1"; drift=1; }
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    same "$src/skills/$name" "$agents/skills/$name" || note "drift: skills/$name"
  done < <(dir_names "$src/skills")
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    same "$src/plugins/$name" "$agents/plugins/$name" || note "drift: plugins/$name"
  done < <(dir_names "$src/plugins")
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    same "$src/hooks/$name" "$agents/hooks/$name" || note "drift: hooks/$name"
  done < <(file_names "$src/hooks")
  for f in install.sh mcp.json SETUP.md; do
    same "$src/$f" "$agents/$f" || note "drift: $f"
  done
  [ ! -d "$src/jev" ] || diff -rq -x .DS_Store -x tests "$src/jev" "$agents/jev" >/dev/null 2>&1 || note "drift: jev"
  if [ -f "$agents/sync.json" ]; then
    for key in skills plugins hooks; do
      while IFS= read -r name; do
        [ -n "$name" ] || continue
        case "$key" in
          skills) [ -d "$src/skills/$name" ] || note "would remove: skills/$name" ;;
          plugins) [ -d "$src/plugins/$name" ] || note "would remove: plugins/$name" ;;
          hooks) [ -e "$src/hooks/$name" ] || note "would remove: hooks/$name" ;;
        esac
      done < <(jq -r --arg k "$key" '.[$k][]?' "$agents/sync.json")
    done
  fi
  [ "$drift" -eq 0 ]
  exit
fi

mkdir -p "$agents/skills" "$agents/hooks"
old="$agents/sync.json"
drop_missing() { # $1 = sync.json key, $2 = dest dir, $3 = src dir
  [ -f "$old" ] || return 0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    [ -e "$3/$name" ] || rm -rf "$2/$name"
  done < <(jq -r --arg k "$1" '.[$k][]?' "$old")
}
copy_name() { # $1 = src dir, $2 = dest dir, $3 = name
  rm -rf "$2/$3"
  mkdir -p "$2"
  cp -R "$1/$3" "$2/$3"
  find "$2/$3" -name .DS_Store -delete
}

drop_missing skills "$agents/skills" "$src/skills"
drop_missing plugins "$agents/plugins" "$src/plugins"
drop_missing hooks "$agents/hooks" "$src/hooks"

while IFS= read -r name; do
  [ -n "$name" ] || continue
  copy_name "$src/skills" "$agents/skills" "$name"
done < <(dir_names "$src/skills")
while IFS= read -r name; do
  [ -n "$name" ] || continue
  mkdir -p "$agents/plugins"
  copy_name "$src/plugins" "$agents/plugins" "$name"
done < <(dir_names "$src/plugins")
while IFS= read -r name; do
  [ -n "$name" ] || continue
  copy_name "$src/hooks" "$agents/hooks" "$name"
done < <(file_names "$src/hooks")

cp "$src/install.sh" "$src/mcp.json" "$src/SETUP.md" "$agents/"
# Jev runtime only: the tests and their sandbox (with a planted injection) stay in the clone.
if [ -d "$src/jev" ]; then
  copy_name "$src" "$agents" jev
  rm -rf "$agents/jev/tests"
fi
chmod +x "$agents/install.sh" "$agents"/hooks/*.sh

jq -n --arg commit "$commit" --argjson skills "$skills_json" --argjson plugins "$plugins_json" --argjson hooks "$hooks_json" \
  '{commit: $commit, skills: $skills, plugins: $plugins, hooks: $hooks}' >"$agents/sync.json"

( cd "$project" && bash .agents/install.sh )
short=${commit:0:7}
[ -n "$short" ] || short=uncommitted
echo "synced $agents from $short"
