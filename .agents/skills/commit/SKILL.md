---
name: commit
description: Commit with a chat-proposed message. Use when asked to commit, reuse that message, or draft one and commit. Do not use for a message-only ask.
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

The work is done when `git status` shows the new commit, or the turn stopped on a check below and no commit was created.

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

Skip a proposal that describes a change already committed, or a diff the worktree no longer has. A summary that was never offered as the commit message does not count.

Done when the message is copied verbatim, or the search records that none exists.

### 3. Draft a message when none exists

Skip this step when step 2 copied a message. Do not rewrite a copied message.

Run these commands in parallel:

- `git status`
- `git diff --staged`, which is the diff the message describes
- `git log -15 --oneline`

Read the Branch and commit conventions section of the repo engineering guide before writing the subject. In this repo that section is kivvo-git-workflow-summary.md under engineering-docs/05-development. Apply them:

- Subject is `type(scope): imperative summary`, at most 72 characters, with no trailing period.
- Types are `feat`, `fix`, `chore`, `docs`, `test`, `refactor`. Scope is one or more of `web`, `ui`, `auth`, `http`, `forms`, `i18n`, `observability`.
- Add a bullet body only for a reason the diff does not show. Five bullets or fewer. No Tuleap id. No `Co-Authored-By` trailer and no agent attribution.
- When that file is absent, use the same Conventional Commits shape and match the last 15 subjects.

Write the draft in a fenced block, then go to step 4 in the same turn. Do not wait for approval.

Done when that block is the message step 5 will commit, and it follows the rules above.

### 4. Decide whether the commit is allowed

Use the status from step 3, or run `git status` when step 3 was skipped.

Stop with no commit when any of these hold:

- Nothing is staged after step 1.
- A path is a secret: a dotenv file other than an example template, a credential file, or anything inside a secrets directory.
- The message and the diff name different changes, and no path subset is clear.

Do not update git config. Do not push. Do not amend in this step. Do not pass `--no-verify` or `--no-gpg-sign`.

Done when the commit is allowed, or the reply names the check that stopped it.

### 5. Commit the staged changes

Commit what step 1 staged. Unstage any secret path first. Stage nothing that step 1 left out.

Commit with the message from step 2 or step 3. Pass it through a quoted heredoc so the body stays intact. Add no trailer.

```bash
git commit -m "$(cat <<'EOF'
type(scope): imperative summary

- reason the diff does not show
EOF
)"
```

Run `git status` after the command returns.

Done when `git status` shows the new commit and a clean result for the paths it included, or the command failed and step 6 runs.

### 6. Recover a failed commit

Read the hook or command output.

- A proposed message that fails validation stays as written. Report the error and stop. Do not replace it.
- A draft from this turn that fails validation gets one corrected draft, then a new `git commit`. Do not amend a commit that failed.
- When the harness blocks `git commit`, report the message and stop.
- When a hook edits files after a successful commit, amend only if the user asked to commit, HEAD was created in this turn, and the commit is not pushed. Otherwise leave the hook edits unstaged and say so.

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
Input. The user says "commit". The chat has no commit message. git diff adds a logout button on the account page.

Result. The agent fences a draft, then commits with it:

feat(web): add account logout

- click clears the local session and returns to login
```

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
