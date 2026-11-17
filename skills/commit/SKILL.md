---
name: commit
description: Makes one commit with a chat-proposed or drafted message. Use when asked to commit or reuse that message. Not for message-only or multi-commit asks.
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - git
    - commits
---

# Proposed commit

## Purpose

Use this when the user asked to create a commit. Commit with the message already proposed for the current diff. When no such message exists, draft one from that diff and the repo commit rules, then commit with the draft in the same turn.

The work is done when `git status` shows the new commit, or the turn stopped on a check below and no commit was created. Run the [Checklist](#checklist) at the end of this file before you say so.

## Instructions

### 1. Stage this session's changes first

Before anything else, stage the paths this session changed: every file you or a subagent you dispatched created, edited or deleted in this conversation. Name each path:

```bash
git add -- <path>...
git diff --staged --name-only
```

Never run `git add -A`, `git add .` or `git commit -a`. Leave every other path unstaged, even one that looks related. Another session or the user may own it and still be working on it. When none of this session's paths is uncommitted, say so and stop with no commit.

Done when `git diff --staged --name-only` lists only this session's paths, or the reply says none remain.

### 2. Take the proposed message

Search the current request, then earlier turns from newest to oldest. Copy a message only when it was offered as the commit message for the changes still in the worktree:

- The user wrote the message in this request.
- The user pointed at an earlier proposal ("commit that", "use that message").
- The latest proposal was offered for this diff and the user did not reject it.

Skip a proposal that describes a change already committed, or a diff the worktree no longer has. A summary that was never offered as the commit message does not count. Why: a message written for another diff misdescribes this commit.

Done when the message is copied verbatim, or the search records that none exists.

### 3. Draft a message when none exists

Skip this step when step 2 copied a message. Do not rewrite a copied message: the user already accepted its wording.

1. Run these three commands in parallel:
   - `git status`
   - `git diff --staged`, which is the diff the message describes
   - `git log -15 --oneline`
2. Read the Branch and commit conventions section of the repo engineering guide before writing the subject. In this repo that section is kivvo-git-workflow-summary.md under engineering-docs/05-development.
3. Write the draft in a fenced block. Apply the conventions:
   - Subject is `type(scope): imperative summary`, at most 72 characters, with no trailing period.
   - Types are `feat`, `fix`, `chore`, `docs`, `test`, `refactor`. Scope is one or more of `web`, `ui`, `auth`, `http`, `forms`, `i18n`, `observability`.
   - Add a bullet body only for a reason the diff does not show. Five bullets or fewer.
   - No `Co-Authored-By` trailer and no agent attribution. Why: the history credits the person who answers for the change.
   - When that file is absent, use the same Conventional Commits shape and match the last 15 subjects.

   Why these rules: they are the repo's conventions, and a commit hook can reject other shapes.
4. Go to step 4 in the same turn. Do not wait for approval: the user asked for a commit, not for a review of the message.

Done when that block is the message step 5 will commit, and it follows the rules above.

### 4. Decide whether the commit is allowed

Use the status from step 3, or run `git status` when step 3 was skipped.

A secret path is a dotenv file other than an example template, a credential file, or anything inside a secrets directory. A secret path among other staged paths does not stop the commit: step 5 unstages it. Why: a committed secret stays readable in the history.

Stop with no commit when either of these holds:

- Nothing is staged after step 1, or every staged path is a secret.
- The message and the staged diff name different changes, and no set of whole staged paths holds exactly the changes the message names. When such a set exists, step 5 commits only that set.

Follow these four rules:

- Do not update git config. Why: the change would stay for every later commit.
- Do not push. Why: the user asked for a commit only, and a push publishes it.
- Do not amend in this step. Why: an amend rewrites the commit before this one.
- Do not pass `--no-verify` or `--no-gpg-sign`. Why: they skip the repo's hooks and commit signing.

Done when the commit is allowed, or the reply names the check that stopped it.

### 5. Commit the staged changes

Commit what step 1 staged. Stage nothing that step 1 left out.

1. Unstage each secret path, and each path outside the set that step 4 chose: `git restore --staged -- <path>...`. Say in the reply which paths you left out.
2. Commit with the message from step 2 or step 3, in the form below. Pass it through a quoted heredoc so the body stays intact. Add no trailer.
3. Run `git status` after the command returns.

```bash
git commit -m "$(cat <<'EOF'
type(scope): imperative summary

- reason the diff does not show
EOF
)"
```

Done when `git status` shows the new commit and a clean result for the paths it included, or the command failed and step 6 runs.

### 6. Recover a failed commit

Read the hook or command output. Then apply the one case that matches:

- A proposed message that fails validation stays as written. Report the error and stop. Do not replace it. Why: the user already accepted that wording.
- A draft from this turn that fails validation gets one corrected draft, then a new `git commit`. When the corrected draft fails too, quote the error and stop. Do not amend a commit that failed. Why: no commit was made, so an amend would rewrite the one before it.
- When the harness blocks `git commit`, report the message and stop. Why: the block is a permission that only the user can change.
- When a hook edits files after a successful commit, amend only if the user asked to commit, HEAD was created in this turn, and the commit is not pushed. Otherwise leave the hook edits unstaged and say so. Why: under those three conditions the amend rewrites only this turn's own commit.

Done when `git status` shows one successful commit, or the reply quotes the error and states that nothing new was committed.

## Examples

### Message already proposed

```text
Input. An earlier turn fenced this message, and the user says "commit that":

feat(ui): add notification centre

- header bell opens the centre for the mock feed

Result. git commit uses that subject and bullet unchanged. No second message is drafted.
```

### No message yet

```text
Input. The user says "commit". The chat has no commit message. This session changed two paths, and git diff --staged --name-only lists them:

install.sh
test-install.sh

The staged diff makes the installer skip a skill folder that the project owns, and adds a test for that. The repo has no engineering guide, so the draft matches the last 15 subjects.

Result. The agent fences this draft, then commits with it:

fix(install): keep project-owned skill folders in .claude/skills

- ln -sfn into an existing real folder created a stray nested link

git status then prints "nothing to commit, working tree clean".
```

The diff and the subject are those of commit 86955ca of the agent-config repo. A scratch clone made the commit again with the commands of steps 1 and 5.

### Nothing to commit

```text
Input. The user says "commit". git status prints "nothing to commit, working tree clean".

Result. No git commit runs. The reply says the worktree is clean.
```

## Prerequisites

The directory is a git repo, and the user asked to commit. Read the Branch and commit conventions section of the repo engineering guide when drafting. No extra tools or keys.

## Limitations

This skill creates one new commit for the current diff. It does not push, open a merge request, or amend an older commit. A request to draft a message and stop stays with the message skill. When the harness blocks `git commit`, report the message and stop.

## Troubleshooting

**The commit command returns an error.** Follow step 6. A failed commit is never amended. Quote the hook output in the reply.

**A secret path is staged.** Unstage it, leave it out of the commit, and say which path was excluded. Do not commit that path.

**The proposed message fails validation.** Keep the user's message. Report the error. Do not silently rewrite a message the user already accepted.

**The draft no longer matches the diff.** Discard it and run step 3 again against the current `git diff --staged` before committing.

## Checklist

Run this before you say the work is done. Name in the reply any item that does not hold.

- [ ] Before the commit, `git diff --staged --name-only` listed only this session's paths.
- [ ] The message is the proposed one, copied verbatim, or a draft that follows every rule of step 3.
- [ ] The commit holds no secret path.
- [ ] Every path was staged by name, as in step 1.
- [ ] Git config is unchanged, nothing was pushed, and no hook or signing was skipped.
- [ ] No amend ran, except the one step 6 allows for hook edits.
- [ ] `git status` shows the new commit, or the reply names the check or quotes the error that stopped it and says that nothing was committed.
