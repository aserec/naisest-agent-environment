---
name: weekly-status-report
description: Writes a weekly report under 200 words from last week's commits and memory. Use when asked for a weekly update, status report, or standup summary.
disable-model-invocation: true
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - reporting
    - status
---

# Weekly status report

## Purpose

Use this when the user asks for a weekly update. The report answers four questions:

1. What you worked on and what is done
2. What you are planning to work on this week
3. Which days you are available this week and if there are times you are not available
4. Anything that might block or affect your work this week

The report is done when every item in the [Checklist](#checklist) at the end of this file holds. Nothing in it may be invented.

## Instructions

### 1. Read the invocation

Take from the prompt: this week's planned work, blockers, availability hours, and times the user is not available.

- Planned work and blockers come only from the prompt.
- Hours default to 30 hours this week.
- Leave out unavailable times unless the prompt names them.

Why: commits show only past work, so anything else taken from them is a guess.

Done when each of the four inputs has a value from the prompt, a default, or the note "not given".

### 2. Gather last week's work

The window is the last 7 days.

1. Run this from the repo root:

   ```bash
   git log --all --since="7 days ago" --author="$(git config user.name)" --no-merges --pretty='%ad %s' --date=short
   ```

2. Open your persistent memory directory, the one your session context names, and read the notes changed in the last 7 days.
3. When the folder `.scratch/` exists, read the `.scratch/*/` issue files changed in the last 7 days.

Done when you hold a list of commits and memory notes dated inside the window.

### 3. Group the work into outcomes

1. Merge the commits and notes into 3 to 6 outcomes. Name each outcome by its feature or result, such as "voice input in chat", not by a commit subject. Why: the reader is a teammate, who knows features and not commit subjects.
2. Mark each outcome done or in progress. An outcome is done when its commits landed and no memory note says a check is still open.

When the window holds fewer than 3 commits and notes in total, write one outcome for each. Why: a padded list breaks the rule that nothing is invented.

Done when every commit belongs to one outcome and each outcome is marked done or in progress.

### 4. Write the report

Fill this template:

```markdown
**What I worked on**
- <outcome> — done.
- <outcome> — in progress, <what is left>.

**This week**
- <planned item from the prompt>

**Availability**
<N> hours this week.

**Blockers**
<blockers from the prompt, or "Nothing blocking right now.">
```

- Write in first person, with the user as "I".
- Leave out commit hashes, file paths, and tool names unless the prompt asks for them. Why: the reader wants outcomes, not code details.
- Add the unavailable times to Availability, as "I'm not available <times>.", only when the prompt gives them.
- When the prompt gives no planned work, write "To be decided" under This week.
- Keep the whole report, headings included, under 200 words. Why: all four answers must fit on one screen.

Done when the report has all four headings, stays under 200 words, and every line traces to a commit, a memory note, a `.scratch` issue file, or the prompt.

## Examples

### Planned work and time off given

This report was built from this repo's commits and memory notes of 2026-11-10 to 2026-11-17.

```text
Input:  /weekly-status-report This week: finish rewriting the skills as numbered steps with a closing checklist. Off Friday afternoon.

Output:
**What I worked on**
- Two new skills: one splits a diff into commits by topic, one guides frontend design — done.
- Architecture reviews now save their findings to a file, so a lost session can pick them up — done.
- Tickets now list one blocker per line — done.
- The safety hooks moved to a new decision model provider — done.
- The installer keeps skill folders that a project owns — done.
- Checks run from a script at the end of a change, not from a commit hook — in progress, the install and sync tests still need a guard for when they get no temp folder.

**This week**
- Finish rewriting the skills as numbered steps with a closing checklist.

**Availability**
30 hours this week. I'm not available Friday afternoon.

**Blockers**
Nothing blocking right now.
```

The prompt names no hours and no blocker, so the report has the default 30 hours and "Nothing blocking right now." It has 142 words by `wc -w`.

## Prerequisites

Git history for the user in this repo, and the agent's persistent memory for this project. The report still runs without memory; it then uses commits alone.

## Limitations

The report covers this repo only. Work in other repos, meetings, and reviews is missing unless the prompt mentions it. The report is text in chat; sending it is left to the user.

## Troubleshooting

Handle these errors before you write the report, and validate the result against the step 4 check.

**Error: the git log is empty.** The author name may differ from `git config user.name`. Run `git log --all --since="7 days ago" --pretty='%an' | sort -u`, then use the matching name.

**No memory directory is named in the session.** Build the report from commits and `.scratch/` alone, and say so in one line to the user.

**The report has 200 words or more.** Merge outcomes that share a feature and cut any line that repeats another.

## Checklist

Run this before you show the report to the user.

- [ ] The report has the four headings of the template, in the template's order.
- [ ] The whole report, headings included, has fewer than 200 words.
- [ ] Every line traces to a commit, a memory note, a `.scratch` issue file, or the prompt.
- [ ] Every commit from step 2 belongs to one outcome, and each outcome is marked done or in progress.
- [ ] "What I worked on" has 3 to 6 outcomes, or one per commit or note when the window holds fewer than 3.
- [ ] "This week" and "Blockers" hold only what the prompt gave, or "To be decided" and "Nothing blocking right now."
- [ ] "Availability" shows the prompt's hours or 30, and unavailable times only when the prompt gave them.
- [ ] The report has no commit hash, file path, or tool name, unless the prompt asked for it.
