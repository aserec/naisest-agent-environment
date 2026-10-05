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

Use this when work has to be done in a system you do not own, such as a backend, another repo, or another team's service. The output is one Markdown document with two parts. Part 1 tells people why the change is needed, in plain words. Part 2 is a brief that an agent working in the other system can build from.

The handout is done when a person can read Part 1 and answer its questions, and when every term in Part 2 is defined in the handout itself. Every fact in Part 2 names the file where it was checked.

The format is fixed. Follow [references/template.md](references/template.md) section by section.

## Instructions

### 1. Name the change and the receiver

Write one sentence: what the other system must do, and what people gain from it. Name the receiving system, its repo, and the branch or ref you will read.

Done when that sentence and the receiver's repo and ref are written down.

### 2. Check every fact against the source

Read the receiver's code at that ref, and your own code where it matters. For each fact the brief depends on, record what is true and the file or endpoint that shows it. Record the date, the ref, and the head commit. Anything you could not read yourself goes into the list of names to verify, never into the facts table.

Done when each fact has a location, and the date, ref, and head commit are recorded.

### 3. Separate facts from decisions

List every choice that only the receiving team can make. Give each one an id (D1, D2, and so on) and a matching plain question for Part 1. If the receiver may already have another way to do this, make that the first question.

Done when each open choice has an id in Part 2 and a question in Part 1.

### 4. Write Part 1 for people

Follow the Part 1 section of the template. Use short sentences and everyday words. Make each heading a claim, not a label. Explain the current flow as numbered steps, then show where the new flow differs. Say what you are asking the receiver to build as a numbered list with no code names. End with the questions from step 3.

Done when Part 1 has no field names, file paths, or status codes except in the questions, and each heading states a claim.

### 5. Write Part 2 for agents

Follow the Part 2 section of the template. Include GOAL, the FACTS table, DECISIONS OPEN, each contract change with its field and error tables, the behaviour and its numbered rules, and the names to verify. Offer the approaches as a table when a decision changes the design. End with checkbox acceptance criteria that can be observed through the receiver's own interface, then the follow-up work that stays on your side.

Done when every contract change says what happens with no new input, every error case has a status and a code, and every acceptance criterion names something a test can check.

### 6. Save and check the handout

Save the handout to the path the user gives. With no path, save it in a temporary folder, never in the repo: the harness scratchpad if it has one, otherwise `$TMPDIR/handoffs/`. Name it by date and slug, such as `2026-09-27-call-agent-chat-turns`, and give the user the full path. Read it through once as the receiver. Check that each fact, decision, and criterion from Part 2 has a matching sentence in Part 1.

Done when the file exists at that path and the check in [references/template.md](references/template.md) passes.

## Examples

### A backend change for a frontend feature

```text
Input:  "The call agent's voice turns never show up in the chat. The backend has to save them."
Result: the handout 2026-09-27-call-agent-chat-turns in the temporary folder
        Part 1: why the old voice button saved text and the call agent does not,
                four things the backend should build, four questions.
        Part 2: GOAL, facts F1-F8 checked at backend-api origin/main a1b2c3d,
                decisions D1-D4, token contract change with field and error tables,
                approaches A and B, seven worker rules, nine acceptance criteria,
                frontend follow-up.
```

### A question the receiver has to answer first

```text
Input:  "Ask the platform team to expose tenant quotas to the web app."
Result: A handout whose first Part 1 question and D1 ask whether the existing
        admin quota endpoint is the intended source. The Part 2 contract change
        is marked as depending on D1.
```

## Prerequisites

You need read access to the receiving system's repo at a named ref. You also need the files on your side that the change touches. Diagrams are optional. When you draw one, give it a one-line caption under it.

## Limitations

This skill writes the handout. It does not open tickets, send the document, or make changes in the receiving repo. Decisions stay open until the receiving team answers them.

## Troubleshooting

**A fact cannot be checked.** You cannot read the receiver's code, or the name comes from docs for another version. Move it to the list of names to verify, and say which version it was named from.

**Part 1 keeps needing code names.** The sentence explains how the code works, not what people get from it. Rewrite it around what a person does and sees, and keep the name in Part 2.

**Someone reading the handout cannot tell what to build.** A decision is written as if it were a fact. Give it a D-id, add a Part 1 question, and offer both approaches in a table.
