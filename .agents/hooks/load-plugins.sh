#!/bin/bash
# Cursor workspaceOpen hook. Prints absolute paths of the plugins copied under .agents/plugins.
# Registered by install.sh only when that folder has at least one plugin.
# Output: {"pluginPaths":["/abs/.../plugin", ...]}
plugins="$(cd "$(dirname "$0")/.." && pwd)/plugins"
[ -d "$plugins" ] || { echo '{"pluginPaths":[]}'; exit 0; }
set --
for d in "$plugins"/*/; do
  [ -d "$d" ] || continue
  set -- "$@" "$(cd "$d" && pwd -P)"
done
[ $# -gt 0 ] || { echo '{"pluginPaths":[]}'; exit 0; }
if command -v jq >/dev/null 2>&1; then
  jq -n --args '{pluginPaths: $ARGS.positional}' "$@"
else
  echo '{"pluginPaths":[]}'
fi
