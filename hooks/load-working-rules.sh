#!/bin/bash
# Session-start hook. Loads what to watch for into every session: the user's working rules, then the
# playbook's table of mistakes. The table rides here because the playbook's own hook string has no room for it.
# Registered by install.sh. Pass "cursor" for Cursor's output shape. See load-skill.sh.
s="$(cd "$(dirname "$0")/.." && pwd)/skills"
exec bash "$(dirname "$0")/load-skill.sh" "${1:-}" \
  "Follow these working rules on every task in this session, and watch for the mistakes in the table after them. The full files are $s/working-rules/SKILL.md and $s/fable-playbook/references/mistakes.md." \
  working-rules/SKILL.md fable-playbook/references/mistakes.md
