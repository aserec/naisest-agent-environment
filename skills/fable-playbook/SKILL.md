---
name: fable-playbook
description: Plans a task, proves each step and reports every claim with its proof. Use for every task, before the first tool call and before the final reply.
version: 1.0.0
metadata:
  author: Danel Ceresa <noreply@example.com>
  version: 1.0.0
  tags:
    - planning
    - verification
---

# Fable playbook

## Purpose

Use this on every task. Steps 1 to 5 run before the first edit. Steps 6 to 8 run during the work. Step 9 runs before the final reply. A question that changes no file runs steps 1, 2, 7 and 9. The task is done when every ask has a proof from this session or a named blocker, and the closing checklist passes.

Three words carry the method. An **ask** is one result, limit or reply item that the request names. A **proof** is a command or a file read whose output differs when the work is wrong. A **claim** is a statement with no proof yet, whether it is yours, a subagent's or a tool's.

## Instructions

### 1. List the asks

Before the first tool call, read the whole request and write the ask list as plain lines in the chat. Write one line per result that must exist at the end, one line per limit such as "do not commit", and one line per item the final reply must hold. Copy paths, numbers and names as the user wrote them. A one-line request gives a one-line list.

Why: a limit read once is the first fact lost on a long task, and a list kept only in your thinking is gone when step 9 needs it. Done when the chat shows the list, and every sentence of the request maps to a line or adds no ask.

### 2. Read until you can name the proof

Read each file an ask names, every caller of the code you will change, and the tests for that code. Find the callers with a search for the name. For a new file, read two existing files of the same kind and copy their format. Stop reading when you can state three facts: the lines you will change, each caller those lines affect, and the proof command for each result.

Why: an edit made before the callers are read fixes one path and breaks another. Done when you can state those three facts. Step 5 writes them down.

### 3. Draw the scope

Put in scope what an ask names, plus what must change for that ask to hold: callers, tests of the changed behavior, and a doc line that states the old behavior. Everything else is out of scope: a rename, a reformat, a refactor, a new option, a fallback for a case that cannot happen, a file nobody asked for, a second bug found on the way. Keep each out-of-scope finding as one line for step 5 and the report, and leave that code as it is.

Why: the user reviews every changed line and cannot tell an unasked change from a mistake. Done when every file you plan to touch maps to an ask.

### 4. Look it up, or ask once

Look up every fact that the repo, a command or the docs can give. Ask the user only when both of these hold: the answer is a choice only the user can make, and a wrong guess deletes, sends, publishes, spends money, or takes more than 10 minutes to redo. In every other case take the option that changes least and note it as an assumption for the report. Send all questions in one message, before step 5.

Why: a question the repo could answer costs the user a round trip, and a wrong guess on an action with no undo stays wrong. Done when no open question blocks the plan.

### 5. Plan steps that each have a proof

Make no edit until the chat shows one plan block: the three facts from step 2, each out-of-scope finding from step 3, and the plan as 1 to 7 numbered steps. Each step is one line: one change, its proof command, and the output you expect. Put the steps in this order. First the unknown that could change the plan, such as a bug not yet reproduced or an API not yet called. Second the failing check, so you see it red before the fix. Third the change. Last what depends on the change, such as other callers and docs. Split a step that needs two proofs. Past 7 steps, group them into phases and plan the next phase only when the phase before has its proofs.

Why: when one proof covers three changes, a red result does not say which change broke. Done when the chat shows the plan block, and each step names its proof and expected output.

### 6. Run one step, then its proof

Make the change for one step, run its proof, and read the output to its last line: the exit code, the number of tests that ran, and each warning. Start the next step only when the output matches what the plan expected. After a failure, read the whole error, change one thing, and run the proof again. After 2 failed tries on one step, stop editing, read the code under the error again, and rewrite the rest of the plan. When one change repeats across many files, make it in one file, prove it, then make the rest.

Why: ten edits before the first proof repeat one mistake ten times. Done when each step's proof ran after that step's last edit.

### 7. Check every claim you did not prove

A subagent's summary, a tool's success line, and your own memory of a file are claims. Before a claim enters your report or decides your next step, look at the thing itself: open the file it names, run `git status` and `git diff` when a subagent returns, and run again the command it says passed. A search with zero hits counts only after the same search finds a hit you know exists. A claim you did not check goes into the report as "Reported, not checked".

Why: a summary says what its writer meant to do, and only the files show what happened. Done when you saw, in this session, the proof of each claim your report rests on.

### 8. Stop on a blocker

Stop and report when one of these holds:

- The same proof still fails after 3 different fixes.
- The work needs what the session lacks: a credential, access, a tool, the network.
- The next action has no undo and the user did not ask for it by name: delete data, force-push, send, publish, deploy.
- Two asks conflict, or the only fix sits outside the scope from step 3.

Report what you tried, the exact error text, and the one decision or item you need. Keep every check as it was: the test, its expected value, the hook, the type check. A failing check is the finding to report.

Why: a weakened check shows green on broken work, and the user finds the break later. Done when no blocker holds, or the reply names the blocker.

### 9. Prove each ask, then report

1. Run `git status` and read the full `git diff`. Remove each line no ask needs: debug output, commented-out code, an extra file.
2. For each result on the ask list, run its proof after your last edit. A run from before the last edit does not count.
   - Code, script or config: the test or the real command was red before the change and is green after it. With no test, run the real path by hand and quote its output.
   - Doc, skill or other prose: you read the saved file once from top to bottom against each ask, and each path, command and name in it exists. Mark a claim that no command can prove as "Judgement".
   - Answer to a question: you can name the file and line, or the command output, that it rests on.
3. For each limit on the ask list, run the check that shows it held. For "do not commit", `git log -1` still shows the commit from the start.
4. Write the report inside the sentence limit that `/structured-output` sets for Answer. Give one item per result: what changed, then "Verified" with the proof output, "Not verified" with the reason, "Judgement", or "Reported, not checked". Give one item for all the limits and the checks that showed they held. Then name what is undone, each out-of-scope finding and each assumption.

Why: the user acts on the word "done", and a claim with no proof hands your checking work to the user. Done when the closing checklist passes.

## Skills that own part of the work

Load each skill when its line applies. This playbook adds no rules in these areas.

- Every reply: `/structured-output` and `/simple-words`. Every name in code: `/simple-words`.
- A test you add, edit or review: `/useful-tests`.
- A bug, a failing behavior or a slow path: `/diagnosing-bugs`, before step 5.
- A commit, only when the user asks for one: `/commit`.

## Mistakes to watch for

The table of 10 mistakes is in [references/mistakes.md](references/mistakes.md). Each row gives the mistake, how to notice it and what to do instead. The session-start hook `load-working-rules.sh` loads the table. If the table is not in your context, read that file before step 6.

Why a separate file: Claude Code swaps a hook string over 10,000 characters for a file path, and the steps with the table are longer than that.

## Examples

### A bug fix, replayed from commit 86955ca

Input. "install.sh makes an extra link .claude/skills/impeccable/impeccable when the project has its own impeccable folder. Fix it."

```text
Ask list
1. Result: install.sh leaves a real folder in .claude/skills as it is, with no nested link inside it.
2. Limit, from AGENTS.md: run bash precommit.sh before a commit.

Plan block
- Lines: the ln -sfn loop in claude() in install.sh.
- Callers: a search finds one other ln -sfn, and that one already tests for a link.
- Proof: bash test-install.sh, which prints passed=21 failed=0 before any edit.
- Out of scope: nested links that old installs already made.
1. Add a project-owned .claude/skills/commit folder and the check "project-owned skill kept" to test-install.sh. Proof: bash test-install.sh prints FAIL for that check.
2. In install.sh, skip a skill whose path is a real folder. Proof: the same command prints failed=0.
3. Read git diff. Proof: 2 files, and each hunk maps to ask 1.

Report, as the Answer section of the reply
1. install.sh now skips a skill when .claude/skills/<name> is a real folder, so the project's copy stays and no nested link is made. Verified: bash test-install.sh printed "FAIL project-owned skill kept" and "passed=21 failed=1" before the fix, and "passed=22 failed=0" after it.
2. Limit. Not verified: bash precommit.sh did not run, because no commit was asked for.
3. Out of scope: a project that ran the old installer keeps its nested link, which I confirmed in a scratch project. Delete that link by hand.
```

## Prerequisites

A shell and git. No keys or extra tools.

## Limitations

A user instruction or a project rule wins over any line here. The numbers are defaults: 7 steps, 2 tries, 3 fixes, 10 minutes.

## Troubleshooting

**A proof is red for a cause outside your change.** A sandbox, a missing tool or the network can fail a proof. Read the first error line. When you cannot remove the cause, report it under step 8.

## Checklist

Run this list on the final reply. Fix each line that fails, then run the list again.

- [ ] Each result and each limit on the ask list has a proof that ran after the last edit.
- [ ] `git status` and `git diff` show only changes that map to an ask.
- [ ] Every test, expected value, hook and type check is as strict as it was at the start.
- [ ] Each result in the reply carries "Verified" with the proof output, "Not verified", "Judgement" or "Reported, not checked".
- [ ] The reply names what is undone, each blocker, each assumption and each out-of-scope finding.
- [ ] The reply holds every item the request asked for, within the layout and the sentence limit of `/structured-output`.
