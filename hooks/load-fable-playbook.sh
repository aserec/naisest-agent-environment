#!/bin/bash
# Session-start hook. Loads the steps and the closing checklist of the fable-playbook skill into every session.
# Registered by install.sh. Pass "cursor" for Cursor's output shape. See load-skill.sh.
s="$(cd "$(dirname "$0")/.." && pwd)/skills/fable-playbook"
exec bash "$(dirname "$0")/load-skill.sh" "${1:-}" \
  "Follow this playbook on every task in this session. Its worked example, limitations and troubleshooting are in $s/SKILL.md. Read them when a checklist line fails." \
  fable-playbook/SKILL.md
