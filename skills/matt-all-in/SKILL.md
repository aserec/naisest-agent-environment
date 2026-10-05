---
name: matt-all-in
description: Runs to-spec, to-tickets and implement in one pass on recommended options. Use when a grilling session is done and the whole chain should run.
disable-model-invocation: true
version: 1.0.0
metadata:
  author: Danel Ceresa <danel@kivvo.ai>
  version: 1.0.0
  tags:
    - workflow
    - planning
    - implementation
---

# Matt all in

## Purpose

Run this after a `/grill-with-docs` session, when the user wants the rest of the chain in one run: spec, tickets, then implementation. The user's invocation of this skill is their written approval for every gate in that chain. At each approval, quiz or seam check, take the **recommended** option, record it in the spec, and keep going.

The run is done when every ticket of the feature is resolved with a commit, the project's precommit or check command (as `AGENTS.md` or `package.json` names it) is green, the confirmed review findings are fixed, and the report is delivered.

`to-spec`, `to-tickets` and `implement` are user-invoked-only, so the Skill tool refuses them. Read each one's SKILL.md from the project skill folder and follow it in place.

Paths below are relative to the repo root; `<slug>` is the feature slug from step 1. Repo rules come from the pointer table in AGENTS.md: follow its row for the work in front of you.

Two rules hold for the whole run:

- **Relay at the context budget.** From about 120K context, stop at the next safe checkpoint (a finished ticket or a green test) and write .scratch/<slug>/handoff-NN.md with the next free number: done, remaining, rules, gotchas. A fresh subagent reads it and continues. A subagent that cannot spawn agents returns `HANDOFF: <path>`. The procedure is the context-budget row of AGENTS.md.
- **A human pushes.** Commit to the current branch; leave push, tag and merge requests to the user.

## Instructions

### 1. Fix the slug and the sources

Pick the feature slug: reuse the .scratch/<slug>/ directory the grilling wrote to, or the one the user named. Read every decision source in full: the grilling in this conversation, each handoff file in that directory, the glossary in GLOSSARY.md, and any new ADR under docs/decisions. When a later decision supersedes an earlier one, the later one wins; note which.

Done when the slug is named and every decision source is read in full.

### 2. Write the spec

Read the SKILL.md of `to-spec` and follow it, with the local markdown tracker that CLAUDE.md names under "Issue tracker". At its seam check, take the recommended seams: the highest existing seam, fewest seams overall. Record them under Testing Decisions, and write "Seams: recommended option, taken by /matt-all-in" in Further Notes.

Write .scratch/<slug>/spec.md with `Status: ready-for-agent` and a `Branch:` line naming the current branch. Use the glossary terms.

Done when the spec file exists, fills every section of the to-spec template, and names its seams.

### 3. Write the tickets

Read the SKILL.md of `to-tickets` and follow it. At its quiz, take the recommended granularity and blocking edges, then append the breakdown and "Quiz: recommended option, taken by /matt-all-in" to the spec's Further Notes. Put prefactors first.

Write one file per ticket at .scratch/<slug>/issues/NN-<ticket-slug>.md, each with a `Blocked by:` line and `Status: ready-for-agent`.

Done when every ticket file exists, each carries both lines, and no ticket is blocked by a higher number.

### 4. Implement ticket by ticket

Read the SKILL.md of `implement` and follow it through `superpowers:subagent-driven-development`, with the project's overrides from its `AGENTS.md`, if any; by default no worktree, no check-in between tickets. Dispatch **one fresh subagent per ticket**, working the frontier in number order. Brief each implementer to:

- invoke the stack's best-practice skill (such as `vercel-react-best-practices` for React) before its first edit, and use `/tdd` at the spec's seams;
- follow the project's UI rules in `AGENTS.md`, if it has them;
- run the project's test and build commands until both pass, then commit per the project's git rules;
- set the ticket's `Status:` to resolved and append a short note under `## Comments`;
- report its commit SHA, or `HANDOFF: <path>` at the context budget.

Fix a review defect with a fresh subagent that gets the findings. Stop only on a BLOCKED status you cannot resolve.

Done when every ticket file reads resolved and names its commit.

### 5. Verify and report

Run the project's precommit or check command once. Run `/code-review` over the branch against the default branch and fix what it confirms with a fresh subagent. Do a browser check when the project defines one.

Report to the user: each ticket with its commit SHA, the test and precommit output, the review findings and their fixes, anything skipped, and each subagent's tokens, tool uses and duration from its completion notice.

Done when the precommit or check command exits 0, every confirmed finding is fixed, and the report is delivered.

## Examples

```text
Input:  /matt-all-in  (after /grill-with-docs on slug <slug>)
Result: .scratch/<slug>/spec.md with the recommended seams under Testing Decisions
        and the quiz outcome under Further Notes; ticket files 01 to 07 under
        .scratch/<slug>/issues/, all resolved; one commit per ticket on the
        current branch; precommit green; report delivered.
```

```text
Input:  context reaches 125K right after ticket 04 commits
Result: .scratch/<slug>/handoff-03.md (done: 01 to 04 with SHAs; remaining: 05 to 07
        and step 5; rules; gotchas), then a fresh subagent resumes at ticket 05.
```

## Prerequisites

- A finished grilling: decisions in the conversation or in a handoff file under .scratch/<slug>/.
- The local markdown tracker. If CLAUDE.md names none, tell the user to run `/setup-matt-pocock-skills`.
- An agent tool that can dispatch subagents.

## Limitations

- It runs no interview. A gap the grilling left open gets the recommended answer, recorded in the spec, and the user reviews it afterwards.
- It commits locally; publishing the branch stays with the user.

## Troubleshooting

**The Skill tool refuses `to-spec`, `to-tickets` or `implement`.** They are user-invoked-only. Read their SKILL.md from the project skill folder and follow it in place.

**A test, build or precommit error persists.** Dispatch a fresh fixer subagent with the failing output. The ticket stays open until the checks pass; after two failed fixes, mark it BLOCKED and report the error.

**A handoff and the spec disagree.** The later decision wins. Fix the spec, then note the change in Further Notes.

**An implementer returns BLOCKED.** Supply the missing context and dispatch a fresh subagent. If it stays blocked, stop and report the ticket and the blocker to the user.
