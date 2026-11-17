---
name: resolving-merge-conflicts
description: "Resolves the conflicts of a git merge or rebase and finishes it. Use when a merge or rebase in progress has stopped on conflicts."
---

# Resolving merge conflicts

## Purpose

Use this when a git merge or rebase has stopped on conflicts. Resolve every conflict from what each side meant to do, run the project's checks, and finish the merge or rebase.

The work is done when every item in the [Checklist](#checklist) at the end of this file holds.

## Instructions

### 1. See the current state

Run these three commands:

```bash
git status
git diff --name-only --diff-filter=U
git log --oneline --left-right --merge
```

The first names the operation: a merge or a rebase. The second lists the conflicting files. The third lists the commits of both sides that touch those files: `<` marks the `HEAD` side, `>` the side coming in.

Done when you have the operation, the conflicting files, and the commits of each side.

### 2. Find the primary sources of each conflict

For each commit that step 1 listed, read these in order:

1. Its message: `git show --no-patch <sha>`.
2. The PR that holds it. On GitHub: `gh pr list --state all --search <sha>`, then `gh pr view <number>`.
3. Each issue or ticket that the message or the PR names. On GitHub: `gh issue view <number>`.

When a commit has no PR or ticket, its message is the source.

Then write two lines per conflict, one for each side: what that side changes, why, and the source that says why. These are working notes for step 3. Why: a resolution made from the text alone can break what one side was for.

Done when every conflict has its two lines, and each line names a commit, PR or ticket.

### 3. Resolve each hunk

Edit every conflicting hunk until no conflict marker (`<<<<<<<`, `=======`, `>>>>>>>`) is left. Follow these rules:

- Keep both intents when the resolved code can do what both lines from step 2 say. Why: the merge exists to join both changes.
- When one intent rules out the other, keep the one that matches the stated goal of the merge: what the user's request or the PR says it is for. Note the trade-off in the reply: the intent you dropped, and why. Why: the user must be able to see the loss and reverse it.
- Add no behaviour that neither side has. Why: it would enter the branch with no commit, PR or review behind it.
- Always resolve. Never run `git merge --abort` or `git rebase --abort`. Why: `--abort` discards every resolution made so far and leaves the conflict open.

Done when `git diff --check` prints no `leftover conflict marker` line.

### 4. Run the project's automated checks

1. Find the check commands the project defines. Look in AGENTS.md or CLAUDE.md, the README, the scripts of package.json or the Makefile, and the CI config.
2. Run them in this order: typecheck, tests, format, then any other. Skip a kind the project does not define. Why: format runs after the fixes for the first two, so it covers them.
3. Fix each failure, then run that check again. Leave a failure only when the same check fails the same way on the branch before the merge: the merge did not break it.
4. When the same failure is still there after two fixes, stop before step 5 and report the output of the check. Why: a third try without new facts repeats the same fix.

Done when every check exits 0, or the reply names each check that still fails and says which case it is: not broken by the merge, or not fixed in two tries.

### 5. Finish the merge or rebase

1. Stage, by path, each file you resolved in step 3 or changed in step 4: `git add -- <path>...`. Why: staging by path keeps files from outside the merge out of the commit.
2. For a merge, run `git commit --no-edit`. For a rebase, run `GIT_EDITOR=true git rebase --continue`. Both forms keep git from waiting on an editor.
3. When the rebase stops on the conflicts of its next commit, run steps 1 to 5 again. Repeat until all commits are rebased.

Done when `git status` mentions no merge, no rebase and no unmerged paths.

## Examples

### Both intents kept

```text
Input. git merge status-builtin stopped. git status lists check-skills.sh under "Unmerged paths" as "both modified".

Step 1. git log --oneline --left-right --merge prints:
  < 56c3bf4 chore(skills): accept /resume as a built-in command
  > 38a0cf5 chore(skills): accept /status as a built-in command

Step 2. The repo has no PR or ticket, so each commit message is the source:
  HEAD side    adds `resume` to builtins, because a skill that points at /resume failed the reference check. Source: 56c3bf4.
  Other side   adds `status` to builtins, because a skill that points at /status failed the reference check. Source: 38a0cf5.

Step 3. The hunk

  <<<<<<< HEAD
  builtins=" clear compact hooks mcp tmp help init model config context agents resume "
  =======
  builtins=" clear compact hooks mcp tmp help init model config context agents status "
  >>>>>>> status-builtin

becomes one line that keeps both intents:

  builtins=" clear compact hooks mcp tmp help init model config context agents resume status "

git diff --check prints nothing.

Step 4. bash check-skills.sh prints "check-skills: ok".

Step 5. git add -- check-skills.sh, then git commit --no-edit prints "[main 93093bc] Merge branch 'status-builtin'".
git status prints "nothing to commit, working tree clean".
```

This output comes from running the steps on a scratch clone of the agent-config repo, with two test branches that each add one word to the builtins list of its skills check script.

## Checklist

Run this before you say the work is done. Fix every item that fails, then run it again. Name in the reply any item you cannot fix.

- [ ] Every conflict has its two lines from step 2, and each line names a commit, PR or ticket.
- [ ] No file that was in conflict holds a conflict marker.
- [ ] Each resolved hunk keeps both intents, or the reply notes the intent that was dropped and why.
- [ ] The resolved code has no behaviour that neither side had.
- [ ] `--abort` was not run.
- [ ] Every project check exits 0, or the reply names each check that still fails and which case of step 4 it is.
- [ ] `git status` mentions no merge, no rebase and no unmerged paths.
