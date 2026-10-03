---
name: "All-in"
description: Minor changes in the current branch and worktree - Superpowers only, no staging
category: Workflow
tags: [workflow, superpowers, minor]
---

For small changes that do not deserve a spec cycle: a copy fix, a style tweak, a
rename, a narrow bugfix, a missing test.

**Input**: the argument after `/all-in` — what to change. If nothing was given, ask
with the AskUserQuestion tool before touching anything.

## Where the work happens

Wherever we already are. Do **not** create a git worktree. Do **not** create or
switch branches. Do **not** `git stash`. If the current checkout is on `master`, say
so once and continue — that is the user's call, not a blocker.

## What is skipped

- **No staging.** Never `git add`. Leave everything in the working tree.
- **No commits, pushes, merges or MRs** — denied by `.claude/settings.json` anyway.
- No verify, retrospective, or proposed commit message.

## What is used — Superpowers only

- **superpowers:test-driven-development** for any behaviour change: failing test
  first, then the code.
- **superpowers:systematic-debugging** whenever this starts from a bug, a failing
  test, or anything unexpected — before proposing a fix.
- **superpowers:brainstorming** only if the ask is genuinely ambiguous. For a truly
  minor change it usually is not; do not manufacture a design conversation.
- **superpowers:verification-before-completion** before claiming anything works.

Repo rules still hold: UI work follows `engineering-docs/01-ui/index.md`, data calls
and providers follow `app-conventions.md`.

## Loop

1. Make the change. Keep it minimal and scoped to what was asked.
2. Run the narrowest useful check — the affected test file, then `pnpm lint` and
   `pnpm test` if the change reaches beyond one file.
3. Report: what changed, the command output that proves it, and `git status --short`
   so the unstaged tree is visible.

Do not check in between edits. Finish the ask, then report.
