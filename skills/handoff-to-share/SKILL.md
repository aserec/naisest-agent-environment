---
name: handoff-to-share
description: Writes a two-part handout another team's agent can apply and its people can read. Use when asking another system or team to build, change, or decide.
disable-model-invocation: true
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - handoff
    - cross-team
    - documentation
---

# Handoff to share

## Purpose

Use this when work has to be done in a system you do not own, such as a backend, another repo, or another team's service. The output is one Markdown document with two parts. Part 1 tells people why the change is needed, without code names. Part 2 is a brief that an agent working in the other system can build from.

The handout is done when every item in the [Checklist](#checklist) at the end of this file holds.

The format is fixed. Follow [references/template.md](references/template.md) section by section.

## Instructions

### 1. Name the change and the receiver

1. Write one sentence: what the other system must do, and what people gain from it.
2. Name the receiving system, its repo, and the branch or ref you will read.

Done when that sentence and the receiver's repo and ref are written down.

### 2. Check every fact against the source

1. Read the receiver's code at that ref, and the files on your side that the change touches.
2. For each fact the brief depends on, record what is true and the file or endpoint that shows it.
3. Record the date, the ref, and the head commit. Why: a fact holds only for the commit where it was read.
4. Put anything you could not read yourself into the list of names to verify, never into the facts table. Why: the receiver's agent treats every row of the facts table as already checked.

Done when each fact has a location, and the date, ref, and head commit are recorded.

### 3. Separate facts from decisions

1. List every choice that only the receiving team can make.
2. Give each one an id (D1, D2, and so on) and a matching question for Part 1 that a person can answer without reading Part 2.
3. If step 2 found something in the receiver that already does part of this, or you could not read enough to rule that out, ask about it in the first question. Why: if another way exists, the rest of the handout changes.

Done when each open choice has an id in Part 2 and a question in Part 1.

### 4. Write Part 1 for people

Follow the Part 1 section of the template. Keep every sentence to 25 words or fewer, and use no field names, file paths, or status codes except in the questions. Why: the people who answer may not know the code.

1. Write each `<Claim ...>` heading of the template as a full sentence that states the claim, not a label such as "Background". Why: a reader who reads only the headings still gets the argument.
2. Explain the current flow as numbered steps.
3. Show where the new flow differs.
4. Say what you are asking the receiver to build as a numbered list with no code names.
5. End with the questions from step 3.

Done when Part 1 has no field names, file paths, or status codes except in the questions, no sentence is over 25 words, and each claim heading is a full sentence.

### 5. Write Part 2 for agents

Follow the Part 2 section of the template. Write these parts in this order:

1. GOAL.
2. The FACTS table.
3. DECISIONS OPEN.
4. Each contract change, with its field table and its error table. Name the D-id of any open decision it depends on. Say what happens with no new input. Why: the receiver must see that today's callers keep working.
5. The behaviour and its numbered rules. When the answers to a decision need different builds, offer the approaches as a table, one row per answer.
6. The names to verify.
7. Checkbox acceptance criteria that can be observed through the receiver's own interface. Why: the receiving team can then test them without your system.
8. The follow-up work that stays on your side.

Done when every contract change says what happens with no new input, every error case has a status and a code, and every acceptance criterion names something a test can check.

### 6. Save and check the handout

1. Name the file by date and slug, such as `2026-09-27-call-agent-chat-turns`.
2. Save it to the path the user gives. With no path, save it in a temporary folder: the harness scratchpad if it has one, otherwise `$TMPDIR/handoffs/`. Never save it in the repo without a path from the user. Why: a handout left in the repo gets committed with unrelated work.
3. Give the user the full path.
4. Read it through once as the receiver.
5. Check that each fact, decision, and criterion from Part 2 has a matching sentence in Part 1.

Done when the file exists at that path and the check in [references/template.md](references/template.md) passes.

## Examples

### A change asked of an upstream repo

This handout was built from this repo's commit `09ad034`, which patched a skill that comes from another repo. Its paths start at the repo root.

```text
Input:  "Ask the mattpocock/skills repo to make its architecture review save the findings to a file."
Result: the handout 2026-11-17-architecture-review-findings-file.md in the harness scratchpad,
        and its full path given to the user.
```

The handout, cut to the parts that show the format:

```markdown
# Save the architecture review findings to a file

[cut: date and author line, summary]

## Part 1: for people

### The findings of a review live only in the conversation

A review runs in three steps.

1. The skill sends a helper agent to walk the codebase.
2. The helper reports what it found back into the conversation.
3. The skill turns that report into a web page in the temp folder.

[cut: which step matters; the second claim section, "A sleeping or cleared session loses the whole review"]

### What we ask the skills repo to build

1. The helper writes its full findings to a file in the temp folder before it reports back.
[cut: asks 2 to 4, what keeps working unchanged, what is ready on our side]

### Questions for the skills repo team

1. Do you already have a way to pick up a review after the session is lost? If so, where is it and what does it keep?
2. Should the findings be a Markdown file next to the page, or should the helper write the page itself?

## Part 2: for agents

### Goal and verified facts

GOAL: after step 1 of the `improve-codebase-architecture` skill, the sub-agent's full findings exist as a file in the temp dir, and step 2 builds the HTML report from that file.

FACTS (checked 2026-11-17; skills repo = `mattpocock/skills`, ref `6fd9479`, head `6fd9479`):

| # | Fact | Where |
| --- | --- | --- |
| F1 | Step 1 spawns a sub-agent to walk the codebase. It names no file for the findings, so they come back only as the sub-agent's reply. | `/skills/engineering/improve-codebase-architecture/SKILL.md` (`### 1. Explore`) |
[cut: F2, F3]

DECISIONS OPEN (resolve with the humans before coding; see Part 1 questions): D1 an existing way to resume a lost review; D2 who writes which file.

[cut: the behaviour section with the approach table for D2, four rules, and the verify sentence. The handout has no contract section, because the change adds no endpoint.]

### Acceptance criteria

[cut: four criteria]
- [ ] After a full run, `git status` in the reviewed repo lists no new file, and step 3 runs exactly as today (regression test).

Our side follow-up (not part of this skills repo task): once this lands, drop the two matching paragraphs from `/upstream/patches/improve-codebase-architecture.patch` and sync the upstream skills again.
```

## Prerequisites

You need read access to the receiving system's repo at a named ref. You also need the files on your side that the change touches. Diagrams are optional. When you draw one, give it a one-line caption under it.

## Limitations

This skill writes the handout. It does not open tickets, send the document, or make changes in the receiving repo. Decisions stay open until the receiving team answers them.

## Troubleshooting

**A fact cannot be checked.** You cannot read the receiver's code, or the name comes from docs for another version. Move it to the list of names to verify, and say which version it was named from.

**Part 1 keeps needing code names.** The sentence explains how the code works, not what people get from it. Rewrite it around what a person does and sees, and keep the name in Part 2.

**Someone reading the handout cannot tell what to build.** A decision is written as if it were a fact. Give it a D-id, add a Part 1 question, and offer both approaches in a table.

## Checklist

Run this before you say the handout is done.

- [ ] The file exists at the full path you gave the user, and it is not in the repo unless the user gave that path.
- [ ] Every FACTS row names the file or endpoint that shows it, and the FACTS line holds the date, the ref, and the head commit.
- [ ] Everything you could not read yourself is in the verify sentence, not in the FACTS table.
- [ ] Part 1 has no field names, file paths, or status codes except in the questions, and no sentence over 25 words.
- [ ] Each Part 1 question can be answered without reading Part 2.
- [ ] Every term in Part 2 is defined in the handout itself.
- [ ] Every error case has a status and a code, and every acceptance criterion names something a test can check through the receiver's own interface.
- [ ] Each fact, decision, and criterion from Part 2 has a matching sentence in Part 1.
- [ ] Every item of the Final check in [references/template.md](references/template.md) holds.
