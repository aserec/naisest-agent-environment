#!/bin/bash
# Copies the upstream skills listed in upstream/upstream.json into skills/, then applies upstream/patches/.
# Usage:
#   upstream/sync.sh                     sync every listed skill at its pinned ref
#   upstream/sync.sh update              move each source's ref to its default branch head, then sync
#   upstream/sync.sh check               report drift between skills/ and pinned upstream + patches; change nothing
#   upstream/sync.sh save-patch <skill>  record local edits to an upstream skill as upstream/patches/<skill>.patch
# Needs git, jq, patch.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$root/upstream/upstream.json"
patches="$root/upstream/patches"
mode="${1:-sync}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

case "$mode" in sync|update|check|save-patch) ;; *) sed -n '2,8p' "$0"; exit 2 ;; esac

src_dir() { echo "$tmp/src/$(echo "$1" | tr / _)"; }

# Clone each source at its ref (update: bump the ref in the manifest first).
for src in $(jq -r '.sources | keys[]' "$manifest"); do
  dir=$(src_dir "$src")
  git clone -q --filter=blob:none "$(jq -r --arg s "$src" '.sources[$s].repo' "$manifest")" "$dir"
  if [ "$mode" = update ]; then
    ref=$(git -C "$dir" rev-parse HEAD)
    jq --arg s "$src" --arg r "$ref" '.sources[$s].ref = $r' "$manifest" >"$tmp/manifest" && cat "$tmp/manifest" >"$manifest"
  fi
  git -C "$dir" -c advice.detachedHead=false checkout -q "$(jq -r --arg s "$src" '.sources[$s].ref' "$manifest")"
done

# Lines of "<source> <skill> <path in source>".
entries() { jq -r '.sources | to_entries[] | .key as $s | .value.skills | to_entries[] | "\($s) \(.key) \(.value)"' "$manifest"; }

# Stage the pinned upstream copy of every skill into $1/skills/.
stage_upstream() {
  mkdir -p "$1/skills"
  entries | while read -r src name path; do
    from="$(src_dir "$src")/$path"
    [ -f "$from/SKILL.md" ] || { echo "error: $name: $src has no $path at the pinned ref (removed upstream? drop it from upstream.json or keep it as a local skill)" >&2; exit 1; }
    cp -R "$from" "$1/skills/$name"
  done
}

if [ "$mode" = save-patch ]; then
  name="${2:?usage: upstream/sync.sh save-patch <skill>}"
  stage_upstream "$tmp/a"
  [ -d "$tmp/a/skills/$name" ] || { echo "error: $name is not in upstream.json" >&2; exit 1; }
  mkdir -p "$tmp/b/skills" && cp -R "$root/skills/$name" "$tmp/b/skills/$name"
  if (cd "$tmp" && diff -ruN -x .DS_Store "a/skills/$name" "b/skills/$name") >"$tmp/p"; then
    rm -f "$patches/$name.patch"; echo "$name matches upstream; no patch kept"
  else
    mkdir -p "$patches" && sed -E 's/^(---|\+\+\+) ([^	]+)	.*/\1 \2/' "$tmp/p" >"$patches/$name.patch"; echo "wrote upstream/patches/$name.patch"
  fi
  exit 0
fi

# Expected tree = pinned upstream + patches.
stage_upstream "$tmp/expected"
for p in "$patches"/*.patch; do
  [ -e "$p" ] || continue
  name=$(basename "$p" .patch)
  [ -d "$tmp/expected/skills/$name" ] || { echo "error: patch $name.patch has no skill in upstream.json" >&2; exit 1; }
  patch -s -p1 -d "$tmp/expected" <"$p" || { echo "error: $name.patch no longer applies; fix it, then run save-patch $name" >&2; exit 1; }
done

drift=0
for name in $(entries | awk '{print $2}'); do
  if [ "$mode" = check ]; then
    diff -rq -x .DS_Store "$tmp/expected/skills/$name" "$root/skills/$name" >/dev/null 2>&1 || { echo "drift: $name"; drift=1; }
  else
    rm -rf "$root/skills/$name" && cp -R "$tmp/expected/skills/$name" "$root/skills/$name"
  fi
done

# Upstream skills not imported yet.
for src in $(jq -r '.sources | keys[]' "$manifest"); do
  dir=$(src_dir "$src")
  (cd "$dir" && find . -name SKILL.md -not -path './.git/*' | sed 's|^\./||; s|/SKILL.md$||') | while read -r path; do
    jq -e --arg s "$src" --arg p "$path" '[.sources[$s].skills[]] | index($p)' "$manifest" >/dev/null || echo "not imported: $src $path"
  done
done

if [ "$mode" = check ]; then
  [ "$drift" = 0 ] && echo "no drift" || { echo "local edits to an upstream skill: run upstream/sync.sh save-patch <skill>"; exit 1; }
else
  echo "synced $(entries | wc -l | tr -d ' ') skills; review with git diff"
fi
