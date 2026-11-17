---
name: diff-commit
description: Splits the uncommitted diff into several commits, one per change topic. Use when asked to commit the diff in multiple or grouped commits.
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - git
    - commits
---

# Diff commit

## Purpose

Use this when the user asks to commit the current changes as several commits grouped by content, instead of one commit. Each commit holds one topic: a feature, a fix, a docs change, a config change.

The work is done when `git status` shows none of the grouped paths left uncommitted, and `git log` shows one new commit per group, or the turn stopped on a check below. Run the [Checklist](#checklist) at the end of this file before you say so.

## Instructions

### 1. Read the whole diff

1. Run these commands in parallel:
   - `git status --short`
   - `git diff` and `git diff --staged`
   - `git log -15 --oneline`
2. Read the content of every untracked file that will go into a commit. Why: `git diff` does not show an untracked file.
3. Leave out each path that another session or the user may still be working on. When unsure who owns a path, ask.

Done when every changed path is either in a group candidate or listed as left out.

### 2. Group paths by topic

1. Put each path in exactly one group. A group is one reason to change: one feature, one fix, one refactor, one docs update, one tooling or config change. Keep a test with the code it tests. Why: a commit that holds the test without its code fails on its own.
2. Split a file that holds two topics. Write a patch with only the hunks of one topic; step 5 stages it with `git apply --cached <patch>`. The split works when `git apply --cached --check <patch>` exits 0. When it does not, or when one hunk holds both topics, keep the file in the group of its larger change: the topic with more changed lines in that file.
3. Order the groups so each commit builds on the commits before it: shared code and config first, then features that use it, then docs.
4. Write the plan as a numbered list. Each item has the draft message and its paths.

Done when the plan lists every path once and each group has one topic.

### 3. Draft a message per group

Follow the repo commit rules. When the repo has an engineering guide with a commit conventions section, read it. Otherwise use Conventional Commits, `type(scope): imperative summary`, at most 72 characters, no trailing period, and match the style of the last 15 subjects. Add a bullet body only for a reason the diff does not show.

Done when every group has a message that follows those rules.

### 4. Stop on unsafe content

Leave out any secret path: a dotenv file other than an example template, a credential file, or anything inside a secrets directory. Say which path you left out. Why: a committed secret stays readable in the history.

Follow these three rules:

- Do not pass `--no-verify`. Why: it skips the hooks, the repo's own checks on each commit.
- Do not change git config. Why: the change would stay for every later commit.
- Do not push. Why: the user asked for commits only, and a push publishes them.

Done when no secret path is in any group.

### 5. Commit each group in order

For each group, start from an empty index, stage only its paths, check, then commit:

```bash
git reset -q
git add -- <path>...
git diff --staged --name-only
git commit -m "$(cat <<'MSG'
type(scope): imperative summary
MSG
)"
```

For a file split in step 2, run `git apply --cached <patch>` in place of `git add` for that file. Commit only when `git diff --staged --name-only` lists that group's paths and no other.

When a hook fails, read its output, fix the cause for that group, and make a new commit. A second hook failure for the same group stops the run: see Troubleshooting. Never amend a commit made before this turn. Why: it may be pushed already, or hold the work of someone else.

Done when each group has its own commit and `git diff --staged --name-only` listed only that group's paths before each commit.

### 6. Report

Run `git status --short` and `git log --oneline -<n>` with n equal to the number of groups.

Done when the reply lists each new commit subject and any path left uncommitted with the reason.

## Examples

### Mixed diff

```text
Input. git status --short prints:

 D .githooks/pre-commit
 M README.md
 M check-skills.sh
 M install.sh
 M test-install.sh
?? AGENTS.md
?? CLAUDE.md
?? precommit.sh

Plan. Two groups, tooling first:

1. chore: replace the pre-commit hook with precommit.sh
   - the agent runs the checks when a change is complete, as in react_frontend
   - git commit runs no hook; AGENTS.md tells the agent to run the script
   Paths: .githooks/pre-commit, AGENTS.md, CLAUDE.md, README.md, check-skills.sh, precommit.sh
2. fix(install): keep project-owned skill folders in .claude/skills
   - ln -sfn into an existing real folder created a stray nested link
   Paths: install.sh, test-install.sh (the test stays with the code it tests)

Result. git log --oneline -2 prints:

cf21aaf fix(install): keep project-owned skill folders in .claude/skills
bbcc560 chore: replace the pre-commit hook with precommit.sh

git status --short prints nothing. The reply lists both subjects and says that no path was left uncommitted.
```

The diff and the subjects are those of commits 22806a4 and 86955ca of the agent-config repo. A scratch clone joined the two diffs and split them again with the commands of steps 1, 5 and 6.

### Clean worktree

```text
Input. git status prints "nothing to commit, working tree clean".

Result. No commit runs. The reply says the worktree is clean.
```

## Prerequisites

The directory is a git repo with uncommitted changes, and the user asked for several commits. No extra tools.

## Limitations

This skill commits only. It does not push, open a pull request, or rewrite commits that existed before the turn. For a single commit, use the commit skill instead.

## Troubleshooting

**A hand-made patch fails to apply.** Keep the whole file in the group of its larger change and say so in the report.

**A hook rewrites files after a commit.** Stage the hook edits into that commit with `git commit --amend --no-edit` only when the commit was made in this turn and is not pushed.

**One group fails its hook twice.** Stop, leave that group unstaged, and report the hook output.

## Checklist

Run this before you say the work is done. Name in the reply any item that does not hold.

- [ ] The plan listed every changed path once: in one group, or as left out with the reason.
- [ ] Each group has one topic, and each test is in the group of the code it tests.
- [ ] Every message follows the rules of step 3.
- [ ] No commit holds a secret path.
- [ ] Before each commit, `git diff --staged --name-only` listed that group's paths and no other.
- [ ] `--no-verify` was not passed, git config is unchanged, and nothing was pushed.
- [ ] No commit made before this turn was amended.
- [ ] `git log --oneline -<n>` shows one new commit per group, and the reply lists each subject and each path left uncommitted with the reason.
