#!/bin/bash
# Session-start hook. Loads the structured-output skill and its unslop rules into every session.
# Registered by install.sh. Pass "cursor" for Cursor's output shape. See load-skill.sh.
s="$(cd "$(dirname "$0")/.." && pwd)/skills/structured-output"
exec bash "$(dirname "$0")/load-skill.sh" "${1:-}" \
  "Follow this skill for every chat reply in this session. Its folder is $s. Read Examples, Limitations and Troubleshooting in its SKILL.md when a check fails." \
  structured-output/SKILL.md structured-output/references/unslop-rules.md
