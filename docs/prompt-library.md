# Prompt library

These are the prompts I type again and again in coding chats, rewritten so that a smaller model also gets them right. They come from my chats between 2026-10-12 and 2026-11-16. A prompt is here only when I typed it at least twice, in at least two chats.

How to use it:

1. Copy the prompt.
2. Replace each part in [brackets] with your own text. A prompt with no brackets is ready to paste.
3. Paste it. Compare the reply with "A good answer". If it does not match, say which line is missing.

Each prompt tells the model four things: the goal, the limit, the form of the answer, and the check it runs before it answers. In each group, the prompt I typed most often comes first.

## Keep work moving

### Answer my questions

Use it when: the model asked numbered questions and you want it to go on.

Prompt:

```text
My answers to your questions:
1. [answer]
2. [answer]
For every question I did not answer, use the option you recommended.
Do not ask these questions again. If one of my answers conflicts with a fact in the code, stop and tell me which answer and which fact.
Start your reply with one line per question: the number and the choice you will apply. Then go on with the work.
```

A good answer:

- The first lines list every question number with the choice applied, and mark the ones that use the model's own recommendation.
- No question comes back a second time.

### Go ahead

Use it when: the model proposed a plan or a change and you agree with all of it.

Prompt:

```text
Yes. Do what you proposed in your last message: all of it, and nothing more.
If that message had several options and I did not pick one, use the one you recommended and say which one.
Do not change files that the proposal did not name. If you find more work, list it at the end under "Not done" and do not do it.
When you finish, list each file you changed, the command you ran to check the change, and its result.
```

A good answer:

- The list of changed files matches the proposal.
- It names the check command and shows its result.
- Extra ideas are under "Not done", with no code written for them.

### Continue

Use it when: the work stopped before the task was done (an interrupt, a usage limit, a new context).

Prompt:

```text
Continue the task you were on. Start at the first step that is not finished. Do not redo finished steps.
Before you start, write three lines: what is done, what you do next, what is left after that.
Keep the plan and the decisions we already made. Do not start work that is not in the plan.
Stop and ask me only if a step would delete data, push to a remote, or cost money.
When every step is done, write "All steps done" and list the checks you ran with their results.
```

A good answer:

- It opens with the three lines, and the "done" line matches the real state of the files.
- It ends with "All steps done" and the check results, or with one question about a risky step.

### I did my step

Use it when: you finished a step by hand that the model asked for (set a key, restarted a server, merged a pull request).

Prompt:

```text
I did this step: [what I did].
First check that it worked. Use a read-only command or read the file. Do not print secret values.
If the check fails, show me the output and tell me what to redo. Do not look for another way around it.
If the check passes, tell me which step of the plan comes next and do it.
```

A good answer:

- It shows the check command and its output before any new work.
- It names the next step.
- No key, token or password appears in the reply.

### Status

Use it when: a long task or several subagents are running and you want to know where things are.

Prompt:

```text
Give me a status. Do not start, stop or change anything while you check.
Answer with a table, one row per task or subagent: name, state, proof.
The state is one of: done, running, waiting for me, failed, stuck. A task is stuck when it has written no new output for [10] minutes.
The proof is the last output line, a test result or a commit hash that you read now, not one you remember.
Under the table write one line: what you need from me, or "Nothing needed".
```

A good answer:

- One table, and every row has a proof.
- The last line says what you must do, or "Nothing needed".

### Fix all findings

Use it when: a review or an audit listed problems and you want all of them fixed.

Prompt:

```text
Fix every finding in [where the findings are: your last message, or a file path].
Work through them one at a time, in the order of the list. Change only the code that each finding needs.
Do not edit, skip or delete a test to make it pass. If a finding is wrong, do not change code for it: tell me why it is wrong.
After the last fix, run [test and lint command].
Reply with a table: finding, status (fixed, not a real problem, could not fix), file and line. Then the result of the test command.
```

A good answer:

- The table has one row for each finding in the list.
- Every "fixed" row has a file and a line.
- The test command result is shown, not described.

### Undo the last change

Use it when: the last change made things worse and you want the earlier state back.

Prompt:

```text
Undo this: [what to undo: the last change you made, or a short description].
First show me what you will undo: the files, and the commits if it was committed.
If the undo would drop work that is not committed, wait for my "yes".
Keep every other change in the working tree. Do not run `git reset --hard`, `git checkout .` or `git clean`.
If the commit is already pushed, use `git revert`. Do not rewrite history.
After the undo, run `git status` and `git diff --stat` and show the output.
```

A good answer:

- It lists the files or commits before it undoes them.
- The `git status` output shows your other uncommitted work is still there.

### Work without asking

Use it when: you leave the keyboard and want the task done with no questions.

Prompt:

```text
I am away. Do this task without asking me anything: [task].
When you would ask a question, choose the option that is easiest to undo and write the choice down.
Work only in [repo or folder]. Do not push, merge, deploy, delete branches or spend money.
If a step needs one of those, skip that step and go on with the rest.
End with three lists: what you did, each decision you made for me with its reason, what waits for me.
```

A good answer:

- The reply holds no question.
- Each decision has a reason.
- Nothing was pushed, merged or deleted.

## Start work

### Resume from a handoff

Use it when: you start a new chat from a handoff file that an earlier chat wrote.

Prompt:

```text
Read [path to the handoff file] before anything else. Read the files it links to when you need them.
Run `git status`. Tell me if the folder or the branch differs from the one the handoff names.
Reply in at most 10 lines: the goal, what is done, the next steps in order, and anything the handoff names that you could not find (a branch, a file, a commit).
Follow the decisions in the handoff. Do not redo finished work and do not change the plan.
Then: [wait for my go, or start with the first next step].
```

A good answer:

- The summary has 10 lines or fewer, and its next steps are the ones in the handoff.
- It states the folder and the branch it is on.
- Missing things are named, not skipped.

### Create missing tickets

Use it when: you want the model to find what an app still needs and write the tickets for it.

Prompt:

```text
Find what [app or repo] still needs and write tickets for it. Scope: [area, for example backend and frontend].
First read [docs or spec path] and the code. Then list the open and closed tickets in [tracker or board]. Skip every idea that already has a ticket.
Write at most [10] tickets. Each one is a single change that fits in one pull request. Write no epics.
Each ticket has: a title, why it is needed in one or two sentences, acceptance criteria as a checklist that a test or a person can check, and "Blocked by" with ticket numbers or "none".
If a ticket needs a person (a secret, an account, a payment), start its title with "HUMAN:".
Create them in the same tracker with status [status]. Reply with a table: link, title, status, blocked by.
```

A good answer:

- No more tickets than the number you set, and none repeats an existing ticket.
- Every ticket has a checklist of acceptance criteria.
- The table has a link for each ticket.

### Start a task in a new worktree

Use it when: a task must not touch the checkout you are working in.

Prompt:

```text
Do this task in a new git worktree: [task].
Run `git fetch`. Create the worktree from [base branch, for example origin/main] on a new branch named [branch name].
Make every change inside that worktree. Do not edit or commit in the main checkout.
Before your first edit, tell me the worktree path and the branch name.
When the task is done, run [test and lint command] inside the worktree and commit there. Do not push.
End with four lines: worktree path, branch, commit hash, test result.
```

A good answer:

- The path and the branch come before any edit.
- `git status` in the main checkout shows no change from this task.
- The reply ends with the four lines.

### Apply a backend change in the frontend

Use it when: the backend changed and you have its change notes or handoff.

Prompt:

```text
The backend changed. Update [frontend repo or app] to match. Backend branch: [branch]. The change notes:
[paste the handoff or the change notes]
First list each point of the notes with one of: needs a frontend change, needs no change, not clear. Ask me about the "not clear" points before you write code.
Change only what the notes need. If a backend part is not live yet, mock it behind [flag or mock setting] and tell me.
Work in [worktree or branch]. When you are done, run [test and lint command].
End with a table: point of the notes, files changed, how you checked it.
```

A good answer:

- Every point of the notes is in the first list and in the final table.
- Each mocked part is named.
- The test command result is shown.

## Git

### Rebase and merge a branch

Use it when: a branch is finished and must go into the base branch. To only bring the branch up to date, delete step 3.

Prompt:

```text
Merge a finished branch into its base. Branch: [branch]. Base: [base branch]. Do it locally, in this checkout.
1. Run `git fetch`. Rebase the branch on the base. If a conflict is not clear, stop and show it to me. Do not guess.
2. Run [test and lint command] on the rebased branch. If it fails, stop and do not merge.
3. Merge the branch into the base. Then: [push, or do not push]. Never force-push the base.
End with `git log --oneline -5` for the base, `git status`, and one line: can the branch be deleted now?
```

A good answer:

- The log shows the commits of the branch on top of the base branch.
- The test command ran after the rebase, and its result is shown.
- No force-push to the base branch.

### Find unmerged work and clean up

Use it when: you do not know which branches and worktrees still hold work.

Prompt:

```text
List every local branch, remote branch and git worktree of this repo that is not merged into [main branch].
For each one show: name, date of the last commit, number of commits ahead of the main branch, and whether it has uncommitted changes.
Mark each row as one of: safe to delete (0 commits ahead and no uncommitted changes), has work, in use by a worktree.
Do not delete anything yet. Show me the table and wait.
When I answer with the names to delete, delete only those. Then run `git worktree prune` and show `git branch -a` and `git worktree list`.
```

A good answer:

- One table, and nothing is deleted before your reply.
- "Safe to delete" is only on rows with 0 commits ahead.

### Merge open pull requests

Use it when: several pull requests wait and you want them merged one at a time.

Prompt:

```text
Go through the open pull requests of [repo] one at a time, oldest first. Skip these: [PR numbers to leave alone, or none].
For each one, read the diff and the CI result. Merge it only when CI passed and the diff does what the title says. Merge with: [squash, merge or rebase].
If it conflicts with the base branch, rebase it and resolve the conflicts (use the resolving-merge-conflicts skill if you have it), run [test command], then merge.
After each merge, update the next pull request from the base branch before you read it.
Do not close a pull request that you did not merge.
End with a table: PR link, decision (merged or left open), reason, merge commit.
```

A good answer:

- The table has one row for each open pull request.
- Each "left open" row has a reason.
- No pull request is closed without a merge.

## Fix and check

### Fix the UI from a screenshot

Use it when: you see a small visual problem and can show it in a screenshot.

Prompt:

```text
Screenshot: [attach the image]. Screen or route: [where this is in the app].
What is wrong: [what I see]. What I want: [what it must look like, with sizes or positions if I know them].
Change only [component or element]. Use the components and tokens that the repo's design system already has. Add no new library.
Before you edit, tell me in one line which file and component you will change. If the screenshot fits more than one place, ask me which one.
After the edit, open the page in a headless browser, take a screenshot at [widths, for example 1280 and 390 px], and compare it with what I asked.
Reply with: the file you changed, the new screenshot, and each part of my request that you did not do.
```

A good answer:

- It names one file and one component before the edit.
- It includes a screenshot taken after the edit.
- Nothing outside the named element moved or changed size.

### Why did it stop?

Use it when: a run, a ticket, a pull request or a CI job stopped or looks stuck.

Prompt:

```text
This stopped or is stuck: [link or id of the run, ticket, pull request or CI job].
What I expected: [what had to happen]. Where its logs are: [log path or command, or "find them"].
Find the cause. Read the logs, the events and the status of this item. Do not guess from its title. Change nothing while you look.
Answer with four lines: 1) the step where it stopped and the time, 2) the log line or event that shows why, quoted, 3) the cause in one sentence, 4) who must act: me, the author of the ticket, or the code or config of the tool that ran it.
Then propose one fix and wait for my "yes". If the logs do not show the cause, write "Cause not found" and list what you read.
```

A good answer:

- It quotes a real log line or event.
- It gives one cause in one sentence.
- Nothing is restarted or changed before your "yes".

### Stop dev servers

Use it when: old dev servers hold ports and you want to start again.

Prompt:

```text
Stop the [Next.js, Vite or other tool] dev server processes on this machine. Keep the one on this port: [port to keep, or none].
First list them: PID, port, command, working folder. Use `lsof -iTCP -sTCP:LISTEN -P` and `ps`.
Stop only the processes in that list whose command is a dev server. Do not stop databases, Docker, editors or browsers.
Send `kill` first. Use `kill -9` only for a process that is still alive after 5 seconds.
Then list the listening ports again and show me what is left.
```

A good answer:

- It shows the list before and the list after.
- The port you asked to keep is still listening.
- Only dev servers were stopped.

### Run all checks and fix what fails

Use it when: you want the whole repo green before a commit or a release.

Prompt:

```text
Run these checks of [repo]: [lint, type check, unit tests, build, end-to-end tests].
Take the commands from package.json, the Makefile or the README. Do not invent a command.
For each failure, first find out if the code is wrong or the test is wrong. When the code is wrong, fix the code.
Change a test only when it checks behaviour that was removed on purpose, and tell me which test and why. Never skip a test, delete a test or make a test check less.
Run a failing end-to-end test [3] more times before you call it flaky.
Repeat until every check passes or you have done [3] rounds. Do not commit.
End with a table: check, command, result, what you fixed.
```

A good answer:

- The table shows the real commands and a pass or fail for each.
- Every changed test has a reason.
- `git diff` adds no `skip`, `only` or `fixme` to a test.

### Test it yourself

Use it when: the model says something works and you want proof from the running app.

Prompt:

```text
Do not tell me it works. Prove it: test [feature or fix] yourself in the running app.
Start the app with the project's own command. Open [URL or route] in headless Chromium with Playwright, not in my own browser.
Log in with [test user, or how to get one]. Do these steps: [steps]. Expected result: [what I must see].
Take a screenshot after the last step and read the browser console.
Reply with: each step and what happened, the screenshot, the console errors or "none".
If you could not run a step, say which one and why. Do not mark it as passed.
```

A good answer:

- Each step has an observed result next to it.
- It includes a screenshot and the console errors, or "none".
- No step is called passed when it was not run.

### Remove every mention

Use it when: a tool, a feature or a name is gone and must leave the repo fully.

Prompt:

```text
Remove [name or term] from [repo or folder]: code, config, docs, tests, comments and file names.
First search for it, ignoring upper and lower case. Search also for these spellings: [other spellings, or none]. Show me the number of matches per file.
Do not edit lock files, generated files, vendored code or git history. Keep these: [exceptions, or none].
Where code used the removed thing, delete that code too. Leave no empty function and no unused import.
Then run the search again and run [test and lint command].
Reply with: the files changed, the output of the last search, and the test result. The search must show 0 matches, or you list each match you kept and why.
```

A good answer:

- The last search shows 0 matches, or a short list of kept matches with reasons.
- The test command result is shown.

## Think and record

### Save this decision

Use it when: you agreed on a rule or a decision and later chats must follow it.

Prompt:

```text
Write this decision down so that later sessions follow it: [the decision, or "what we just agreed"].
Put it in [file, for example docs/decisions.md or AGENTS.md]. If that file does not exist, ask me where to put it. Do not create a new place.
Write: the date, the decision in one sentence, the reason in one or two sentences, and what it replaces, if anything.
Use the language and the format of the entries that the file already has.
Add only this entry. Change no code and no other entry. Show me the lines you added.
```

A good answer:

- One new entry, in the file you named, in the same format as the entries around it.
- The reply shows the added lines and no other change.

### Give me options

Use it when: you want to choose between ideas before anything is built.

Prompt:

```text
Give me [3] options for [problem, name or design to decide]. Do not build anything yet.
Every option must meet these limits: [limits, for example "no new dependency"].
Answer with a table: option, how it works in one sentence, what is better, what is worse, effort (small, medium, large).
The options must differ in approach, not in small details.
Under the table, name the one you would pick and give the reason in two sentences. Then wait for my choice.
```

A good answer:

- The table has the number of rows you asked for, and each option meets the limits.
- One pick with a reason.
- No file changed.

### Find where we left it

Use it when: you remember a branch, a feature, a file or a decision but not where it is.

Prompt:

```text
I am looking for [what: a branch, a feature, a file, a project folder, a past decision]. What I remember: [words, dates, names].
Search in this order and stop when you find it:
1. branches and worktrees (`git branch -a`, `git worktree list`)
2. git history (`git log --all --grep`, `git log --all -S`)
3. stashes and the reflog
4. files under [folders to search]
5. past chat logs under [folder with chat logs]
Only read. Do not check out, restore, merge or delete anything.
Reply with: where it is (path, branch or commit), the proof (the matching line or commit message), and the command I can run to get it back.
If you do not find it, list each place you searched and the words you searched for.
```

A good answer:

- A place, a proof line and a command to get it back.
- Or a list of every place searched with the search words.

## Already a skill

For these jobs I do not keep a prompt. A skill already does the job, so I type the skill name with my details after it. "Typed" counts the times I wrote the request in my own words. "Command" counts the times I used the slash command.

| What I typed | Skill | Typed | Command |
| --- | --- | --- | --- |
| "commit", "commit current diff", "commit with the proposed message" | /commit | 24 | 268 |
| pasted error output, "still fails", "investigate why this happens" | /diagnosing-bugs | about 66 | 0 |
| a ticket link with "let's solve it here", or the pasted text of a ticket | /implement | 10 | 0 |
| "run this project", "how do I run the app?" | /run (built in to Claude Code) | 9 | 0 |
| a plan file with "subagent driven" or "execute" | superpowers:subagent-driven-development (plugin) | 9 | 0 |
| "what steps do I follow?", "steps to create the account" | /wizard | 8 | 0 |
| "improve the UI", "redesign this app", "critique the design" | /impeccable | 7 | 8 |
| "investigate whether A is better than B", "compare our project with this repo" | /research | 7 | 0 |
| "run a code review and fix what you find" | /code-review | 6 | 10 |
| "resolve the conflicts" on one branch or one pull request | /resolving-merge-conflicts | 6 | 13 |
| "what?", "rephrase please", "which are the questions?" | /wait-what | 6 | 2 |
| "create MR", "push it and open a PR" | /pr | 6 | 0 |
| "create a prototype", "show me variants" | /prototype | 3 | 4 |
| "one commit per topic" | /diff-commit | 2 | 12 |
| "show me a diagram of the workflow" | /diagram-design | 2 | 1 |
| "write a handoff for another agent" | /handoff | 1 | 6 |
