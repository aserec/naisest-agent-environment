---
name: weekly-status-report
description: Writes a short weekly status report from last week's commits and memory. Use when asked for a weekly update, status report, or standup summary.
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

Use this when the user asks for a weekly update. The report answers four questions in plain, human prose:

1. What you worked on and what is done
2. What you are planning to work on this week
3. Which days you are available this week and if there are times you are not available
4. Anything that might block or affect your work this week

The report is done when all four answers are written, the whole report fits on one screen, and nothing in it was invented.

## Instructions

### 1. Read the invocation

Take from the prompt: this week's planned work, blockers, availability hours, and times the user is not available.

- Planned work and blockers come only from the prompt.
- Hours default to 30 hours this week.
- Leave out unavailable times unless the prompt names them.

Done when each of the four inputs has a value from the prompt, a default, or the note "not given".

### 2. Gather last week's work

Run these from the repo root. The window is the last 7 days.

```bash
git log --all --since="7 days ago" --author="$(git config user.name)" --no-merges --pretty='%ad %s' --date=short
```

Then open your persistent memory directory, the one your session context names, and read the notes changed in the last 7 days. Also read `.scratch/*/` issue files changed in the last 7 days, when that folder exists.

Done when you hold a list of commits and memory notes dated inside the window.

### 3. Group the work into outcomes

Merge commits and notes into 3 to 6 outcomes a teammate would recognize, such as "voice input in chat" rather than a commit subject. Mark each one done or in progress. An outcome is done when its commits landed and no memory note says a check is still open.

Done when every commit belongs to one outcome and each outcome is marked done or in progress.

### 4. Write the report

Use the template below. Write short, plain sentences in first person, as the user would say them. Leave out commit hashes, file paths, and tool names unless the prompt asks for them. Keep the report under 200 words.

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

Add the unavailable times to Availability only when the prompt gives them. When the prompt gives no planned work, write "To be decided" under This week.

Done when the report has all four headings, stays under 200 words, and every line traces to a commit, a memory note, or the prompt.

## Examples

### Default invocation

```text
Input:  /weekly-status-report This week: finish the search page. Blocker: search endpoint not deployed.

Output:
**What I worked on**
- Account settings page — done.
- Dark mode for the dashboard — done.
- Removed the old build scripts from the repo and CI — done.
- Search page — in progress, the live check still needs a running backend.

**This week**
- Finish the search page.

**Availability**
30 hours this week.

**Blockers**
The search endpoint is not deployed yet, so I can only test against mocks.
```

### Availability given

```text
Input:  /weekly-status-report 20h, off Friday afternoon. No blockers.

Output (Availability and Blockers only):
**Availability**
20 hours this week. I'm not available Friday afternoon.

**Blockers**
Nothing blocking right now.
```

## Prerequisites

Git history for the user in this repo, and the agent's persistent memory for this project. The report still runs without memory; it then uses commits alone.

## Limitations

The report covers this repo only. Work in other repos, meetings, and reviews is missing unless the prompt mentions it. The report is text in chat; sending it is left to the user.

## Troubleshooting

Handle these errors before you write the report, and validate the result against the step 4 check.

**Error: the git log is empty.** The author name may differ from `git config user.name`. Run `git log --all --since="7 days ago" --pretty='%an' | sort -u`, then use the matching name.

**No memory directory is named in the session.** Build the report from commits and `.scratch/` alone, and say so in one line to the user.

**The report runs long.** Merge outcomes that share a feature and cut any line that repeats another.
