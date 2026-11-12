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

The work is done when `git status` shows none of the grouped paths left uncommitted, and `git log` shows one new commit per group, or the turn stopped on a check below.

## Instructions

### 1. Read the whole diff

Run these commands in parallel:

- `git status --short`
- `git diff` and `git diff --staged`
- `git log -15 --oneline`

Read the content of every untracked file that will go into a commit. Paths that another session or the user may still be working on stay out. When unsure who owns a path, ask.

Done when every changed path is either in a group candidate or listed as left out.

### 2. Group paths by topic

Put each path in exactly one group. A group is one reason to change: one feature, one fix, one refactor, one docs update, one tooling or config change. Keep a test with the code it tests. When one file holds two topics, write a patch with only the hunks of one topic and stage it with `git apply --cached <patch>`. When the hunks cannot be split cleanly, keep the file in the group of its larger change.

Order the groups so each commit builds on the commits before it: shared code and config first, then features that use it, then docs.

Write the plan as a numbered list. Each item has the draft message and its paths.

Done when the plan lists every path once and each group has one topic.

### 3. Draft a message per group

Follow the repo commit rules. When the repo has an engineering guide with a commit conventions section, read it. Otherwise use Conventional Commits, `type(scope): imperative summary`, at most 72 characters, no trailing period, and match the style of the last 15 subjects. Add a bullet body only for a reason the diff does not show.

Done when every group has a message that follows those rules.

### 4. Stop on unsafe content

Leave out any secret path: a dotenv file other than an example template, a credential file, or anything inside a secrets directory. Say which path you left out. Do not pass `--no-verify`. Do not change git config. Do not push.

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

When a hook fails, read its output, fix the cause for that group, and make a new commit. Never amend a commit made before this turn.

Done when each group has its own commit and `git diff --staged --name-only` listed only that group's paths before each commit.

### 6. Report

Run `git status --short` and `git log --oneline -<n>` with n equal to the number of groups.

Done when the reply lists each new commit subject and any path left uncommitted with the reason.

## Examples

### Mixed diff

```text
Input. git status shows the lint config, the HTTP client, its test, and the readme changed.

Result. Three commits in order:
1. chore: tighten lint rules            the lint config
2. fix(http): retry on 503              the HTTP client and its test
3. docs: describe retry behaviour       the readme
```

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
