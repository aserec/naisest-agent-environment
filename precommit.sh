#!/bin/bash
# Checks to run when a change is complete, before committing. Not a git hook: run it yourself.
cd "$(dirname "$0")" || exit 1
fail=0
run() { # $1 = label, rest = command
  local label="$1" out; shift
  if out=$("$@" 2>&1); then echo "precommit: $label ok"; else echo "precommit: $label FAILED"; echo "$out"; fail=1; fi
}
run check-skills bash check-skills.sh
run test-install bash test-install.sh
run test-sync bash test-sync.sh
run test-guard bash hooks/test-guard.sh
run jev node --test "jev/tests/*.test.ts"
exit "$fail"
