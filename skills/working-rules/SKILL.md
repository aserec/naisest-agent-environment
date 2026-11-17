---
name: working-rules
description: Applies the user's standing rules, each taken from a past correction. Use for every task, before the first tool call and before the final reply.
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - rules
    - corrections
---

# Working rules

## Purpose

Use this on every task. Each rule below comes from a correction the user gave, so breaking one repeats a mistake the user already had to fix. Run step 1 before the first tool call and step 3 before the final reply. An instruction from the user in this chat, or a rule in the project's AGENTS.md or CLAUDE.md, wins over a rule here. The task is done when every line of the checklist holds or does not apply.

## Instructions

### 1. Match the rules to the task

Before the first tool call, read the 7 rules below. Note the number of each rule whose first sentence fits the task.

Done when you can list the matched rule numbers, or say that no rule fits.

### 2. Follow each matched rule during the work

Apply each matched rule at the point in the work that the rule names.

Done when no action in this session breaks a matched rule.

### 3. Run the checklist before the final reply

Run the checklist at the end of this file. Fix each line that fails, then run the list again.

Done when every line holds or does not apply to this task.

## Rules

1. **Prove it the way the user will use it.** Before you say a change is done, run it or open it the way the user will: run the script you wrote, open the page in a browser, click the control you changed. A note that says "not tested" does not replace the run. When this session cannot do the run, say so in the first line of the report and give the exact command the user should run. Why: the user found a break 8 times after a "done", from 2026-11-09 to 2026-11-16.
2. **Do the step yourself.** When this session has the tools and the permission for a step, do it. Do not hand the user a command to run or an edit to paste. Hand a step over only when the session lacks the access, and then give the exact command. Why: the user said "quiero que los ejecutes tu" and "change it yourself", 6 times from 2026-11-10 to 2026-11-15.
3. **"Factory: Ready" is a board column.** When the user asks for a ticket in "factory: ready", add the ticket to that repo's GitHub project board and set its Status field to "Factory: Ready". Do not use a label for it. Why: the software factory reads only the board column, so a ticket with only a label stays off the board. Said 5 times from 2026-11-14 to 2026-11-16.
4. **Epics never go to the factory.** When you set tickets Ready, move cards or restart runs, leave out every epic. An epic is an issue that has sub-issues. Why: the user said "las epicas nunca las trata el SF", and the sub-issues are the work. Said 4 times from 2026-11-09 to 2026-11-14.
5. **Checks run from a precommit script, not from a git hook.** When a change is complete and the repo has a precommit script, run that script yourself. Do not install or turn on a git hook that runs it. Why: the user said "no es un hook". The checks belong to the end of a change, not to the commit. Said 2 times on 2026-11-12.
6. **"All at once" means every item.** When the user tells you to apply a list "all at once", apply every item on it. Do not leave an item under "Not done". When one item is blocked, name it and its blocker before you report the others. Why: the user had to ask again for the 2 items that were left out. Said once, on 2026-11-14.
7. **Propose a current model.** Before you propose an AI model, read the provider's current model list in this session. Propose the newest model on that list that fits the task. Why: the user was offered an old model and asked "no hay mejores?". Said once, on 2026-11-15.

## Examples

### A fix proved the way the user runs it

Input. "Make test-install.sh and test-sync.sh stop when mktemp fails."

```text
Rules matched: 1 and 2.

Report, as the Answer section of the reply
1. Both tests now stop when they get no temp folder, and they make that folder under TMPDIR.
   Verified the way the user's agents run it: inside the sandbox, where a bare mktemp fails with
   "Operation not permitted", bash test-install.sh printed "passed=22 failed=0" and
   bash test-sync.sh printed "passed=23 failed=0".
2. git status after both runs listed no fixture file, so the tests no longer write into the repo.
```

Rule 1 holds because both tests ran in the place where they used to fail. Rule 2 holds because the report hands the user no command.

## Prerequisites

None. The rules need no tool and no key.

## Limitations

The list holds only rules that apply in every project. A rule for one project goes in that project's AGENTS.md, or in its memory folder when it has no AGENTS.md. Add a rule here only after the user approves it. Give it the next number, the user's own words, the count and the dates, and add its line to the checklist.

## Troubleshooting

**A rule here and a project rule disagree.** Follow the project rule and tell the user which two rules disagree.

**A rule cannot be followed in this session.** Name the rule and the reason in the first line of the report.

## Checklist

Run this list before the final reply. A line that does not apply to this task counts as held.

- [ ] Each change reported as done was run or opened the way the user will use it, or the first line of the report names the run this session could not do.
- [ ] The reply hands the user no command or edit that this session could have done.
- [ ] Each ticket asked for in "factory: ready" is on the board with that Status and has no label in its place. No epic was set Ready, moved or restarted.
- [ ] No git hook was installed or turned on to run checks.
- [ ] Every item of an "all at once" list is done, or the blocked item is named with its blocker.
- [ ] Each model proposed is on the provider's current list, read in this session.
