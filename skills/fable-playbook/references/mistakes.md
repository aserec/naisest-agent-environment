# Mistakes to watch for

This table is part of the fable-playbook skill. Check your work against each row during steps 6 to 9 of the playbook.

| Mistake | How to notice it | Do this instead |
| --- | --- | --- |
| A green run that ran nothing | The output says 0 tests or "no tests found", or the new test's name is absent | Fix the filter until the count includes the new test |
| A test made to pass by changing the test | The diff changes an expected value, adds a skip, an empty catch, or an `if` that matches only the test input | Restore the test and fix the code. If the test is wrong, say why before you change it |
| A patch where the error shows | You edited the line the stack trace names and searched for no other caller | Follow the diagnosing-bugs skill and fix where all callers pass |
| The user's guess taken as fact | The request says "the bug is in X" and you have not reproduced the bug | Reproduce it first. If the guess is wrong, say so in the report |
| A name or fact written from memory | A flag, function, path, number, quote or link that no file or output in this session shows | Find it with `--help`, a search or the installed source, or cut it |
| An edit to a copy | The path is generated, vendored or synced, such as `dist/`, `node_modules/` or `.agents/` | Edit the source file and run the step that builds the copy |
| "It failed before my change" | You wrote "unrelated" about a failure and never ran that check on the unchanged code | Run it on the base commit in a scratch copy, or report "cause not checked" |
| A file described from a part of it | The read was cut off or had a line limit | Read the rest, or say which lines you read |
| The user's work undone | You are about to run `git checkout`, `git restore`, `git stash`, `git reset` or a delete on a path this session did not create or edit | Leave the path and tell the user |
| A plan sent as the result | The reply says "next you could" about work the request asked for | Do the work, or name the blocker from step 8 |
