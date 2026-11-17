---
name: handoff-feature-ready
description: Writes a frontend handoff for a finished backend feature on a branch in the frontend repo. Use when a backend change is ready and the UI must adapt.
disable-model-invocation: true
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - handoff
    - backend
    - frontend
    - documentation
---

# Handoff: feature ready

## Purpose

Use this when a backend feature is merged or ready to merge and the frontend must change to use it. The output is a branch `handoff/<slug>` in the frontend repo. It adds one folder to the docs folder: handoffs, then a subfolder named by date and slug, such as `2026-10-29-invoice-partial-refunds`. That subfolder holds a README and one or two SVG diagrams. Part 1 of the README tells people what changed and what the UI must do. Part 2 is a brief that a frontend agent can build from without reading the backend.

The handoff is done when every item in the [Checklist](#checklist) at the end of this file holds.

For the other direction, when you ask another team to build something, use `handoff-to-share` instead.

## Instructions

### 1. Name the feature and both repos

1. Write one sentence: what the backend now does, and what the user will see once the frontend adapts.
2. Record the backend repo, its ref, and its head commit. Why: every fact in Part 2 holds only for that commit.
3. Record the frontend repo and the base branch the handoff branch starts from.
4. Pick the slug for the branch and the folder: the feature in lowercase words joined by hyphens, such as `invoice-partial-refunds`.

Done when that sentence, both repos, the backend ref and head commit, the frontend base branch, and the slug are written down.

### 2. Read the backend contract

Read the backend at the recorded ref. For each endpoint, event, or field the frontend touches, do these in order:

1. Record the method and path, request and response shapes, auth, error status and `code`, feature flag, and pagination or limits. Note the file where you read each one.
2. Copy one request and one response from a test, a fixture, or a call to a dev server. Why: an example written from memory can differ from what the backend sends.
3. Mark the change additive or breaking.
4. Put every name you could not read at that ref into the list of names to verify. Why: the frontend agent treats every fact as already checked.

Done when each contract item has a file location, an example payload, and an additive or breaking mark.

### 3. Read the frontend side

1. In the frontend at the base branch, find the API client calls, types, stores, and screens that use the changed contract.
2. List each file the frontend agent must change and what changes in it.

Done when each breaking change maps to at least one frontend file, or you have noted for the README that the frontend has no code using it.

### 4. Draw the flow

1. Load the `diagram-design` skill.
2. Draw one sequence or data-flow diagram of the new flow, from the user action to the stored result, with 9 nodes or fewer.
3. Add a second diagram only when the feature has something a sequence or data-flow diagram cannot show, such as an architecture delta or a state machine.
4. Export each diagram to SVG with the SVG export procedure of `diagram-design`, into the handoff folder.
5. Delete the HTML source after the export. Why: the README shows only the SVG, and a leftover HTML copy can drift from it.

Done when one or two SVG files sit in the handoff folder and no HTML source is left there.

### 5. Write the README

1. Copy the skeleton from [references/template.md](references/template.md) into the README in the handoff folder.
2. Fill it section by section.
3. State the contract in Part 2 as final, not as a proposal. Why: the backend is already built, so the frontend builds against it as it is.
4. Put a question in Part 1 only for a choice that the contract leaves open and only the frontend team can make. Why: each question holds up the build until someone answers it.
5. Give each question a D-id in Part 2.
6. When a breaking change has an end date, open Part 1 with that date. Why: the date decides how soon the frontend must act.
7. Give each diagram an alt text and a one-line caption.

Done when every template section with content is filled, every Part 1 "what the frontend must do" item has an acceptance criterion in Part 2, and each diagram has an alt text and a one-line caption.

### 6. Humanize Part 1

1. Load the `humanizer` skill.
2. Run it on Part 1 only. Part 2 keeps its exact names, tables, and uppercase labels. Why: the frontend agent copies those names into code.

Done when the humanizer pass finds no pattern left in Part 1, and Part 2 is unchanged.

### 7. Commit to the handoff branch

1. In the frontend repo, create `handoff/<slug>` from the base branch.
2. Add the handoff folder and no other file. Why: this skill does not change frontend code.
3. Commit with the message `docs(handoff): <feature>`.
4. Show the user the branch and the file list.
5. Push only after the user says to. Why: a pushed branch is visible to the whole frontend team.

Done when `git log -1 --stat handoff/<slug>` lists the README and the SVG files, and the user has the branch name.

## Examples

### A backend change the UI should follow

This handoff was built from this repo at commit `09ad034`. Both sides live in one repo here: the backend is the hook in `jev/`, the frontend is the band in `mods/ribbon-ctx/`. Its paths start at the repo root.

```text
Input:  "Jev now advises /clear from 100K context tokens and /compact from 200K.
         The ribbon-ctx band should change colour at the same points."
Result: branch handoff/jev-context-lines, from main, with one commit, "docs(handoff): Jev context advice lines".
        The commit adds the folder 2026-11-17-jev-context-lines under docs/handoffs. The folder holds
        README.md (106 lines) and jev-advice-sequence.svg.
```

The README, cut to the parts that show the format:

```markdown
# Jev advises on context size from 100K tokens

[cut: date, author and backend commit line; summary]

## Part 1: for people

### Jev now speaks up at 100 and 200 thousand tokens

1. You send a prompt.
2. Jev reads how many tokens the session holds.
[cut: steps 3 to 5; the image line that links the SVG, with its alt text]

One prompt leads to Jev's advice for you and to a token count for the band.

### What the frontend must do

1. The context number turns yellow from 100 thousand tokens, where Jev can first speak.
[cut: item 2, what stays unchanged]

## Part 2: for agents

### Goal and verified facts

GOAL: the CTX number in the ribbon-ctx band is yellow from 100,000 context tokens and red from 200,000, the two lines where the Jev `UserPromptSubmit` hook starts to advise.

FACTS (checked 2026-11-17; backend = `agent-config`, ref `main`, head `09ad034`):

| # | Fact | Where |
| --- | --- | --- |
| F1 | `CLEAR_LINE = 100_000`, `COMPACT_LINE = 200_000`, `MAX_COMPACTIONS = 2`. | `/jev/hook.ts` (`CLEAR_LINE`, `COMPACT_LINE`, `MAX_COMPACTIONS`) |
[cut: F2 to F6]

DECISIONS OPEN: none.

### Contract: `UserPromptSubmit` hook advice (additive)

[cut: auth, feature flag, request and response examples with the test they were observed in, field table, the line that opens the errors]

| Case | Status | `code` | What the UI shows |
| --- | --- | --- | --- |
| No Jev key, provider error or timeout | exit 0, empty output | none | No advice. The band still colours the number by its token count. |

### Frontend files to change

| File | Change |
| --- | --- |
| `/mods/ribbon-ctx/hooks/register.tsx` | `ctxColor`: yellow from 100_000 tokens and red from 200_000 (today: yellow past 150_000, red past 250_000). Update its doc comment. `CTX_CAP` stays 300_000. |
[cut: two more files, Try it]

### Acceptance criteria

- [ ] `ctxColor(99_999)` is the cream text colour and `ctxColor(100_000)` is yellow.
[cut: two more criteria]
- [ ] With no Jev key set, the band draws the same colour for the same token count.

[cut: verify sentence]
```

## Prerequisites

You need read access to the backend repo at a named ref and write access to a local clone of the frontend repo. The `diagram-design` and `humanizer` skills must be installed.

## Limitations

This skill writes the handoff and commits it on a local branch. It pushes only after the user approves. It does not open a merge request or change frontend code.

## Troubleshooting

**No test or fixture holds a payload for the endpoint.** Call a dev server if one runs, or write the example from the schema and mark it "from schema, not observed".

**The diagram needs more than nine nodes.** It shows two things. Split it, or cut nodes the frontend never talks to.

**The frontend agent asks what to build.** A decision is written as a fact, or a contract item lacks an example. Add the D-id and Part 1 question, or add the payload.

## Checklist

Run this before you say the handoff is done.

- [ ] `git log -1 --stat handoff/<slug>` lists the README and one or two SVG files, and no other file.
- [ ] The handoff folder holds no HTML source.
- [ ] Every FACTS row names the backend file where the fact was read at the recorded ref.
- [ ] Every request and response example is copied from a test, a fixture, or a dev-server call, or is marked "from schema, not observed".
- [ ] Every name that was not read at the recorded ref is in the verify sentence, not in FACTS.
- [ ] Each breaking change has at least one row in "Frontend files to change", or the README says the frontend has no code using it.
- [ ] The humanizer pass finds no pattern left in Part 1, and it changed nothing in Part 2.
- [ ] Every item of the Final check in [references/template.md](references/template.md) holds.
- [ ] The user has the branch name and the file list, and nothing was pushed unless the user said to.
