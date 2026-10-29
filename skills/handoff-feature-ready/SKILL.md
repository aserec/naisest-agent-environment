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

The handoff is done when the branch exists, every fact in Part 2 names the backend file where it was checked, every request and response has a real example, and the check in [references/template.md](references/template.md) passes.

For the other direction, when you ask another team to build something, use `handoff-to-share` instead.

## Instructions

### 1. Name the feature and both repos

Write one sentence: what the backend now does, and what the user will see once the frontend adapts. Record the backend repo, its ref, and its head commit. Record the frontend repo and the base branch the handoff branch starts from.

Done when that sentence, both repos, the backend ref and head commit, and the frontend base branch are written down.

### 2. Read the backend contract

Read the backend at the recorded ref. For each endpoint, event, or field the frontend touches, record the method and path, request and response shapes, auth, error status and `code`, feature flag, and pagination or limits. Copy a real request and response from a test, fixture, or a call to a dev server. Mark each change additive or breaking. Anything you could not read goes into the list of names to verify.

Done when each contract item has a file location, an example payload, and an additive or breaking mark.

### 3. Read the frontend side

Read the frontend at the base branch. Find the API client calls, types, stores, and screens that use the changed contract. List each file the frontend agent must change and what changes in it.

Done when each breaking change maps to at least one frontend file, or the README states that the frontend has no code using it.

### 4. Draw the flow

Load the `diagram-design` skill. Draw one sequence or data-flow diagram of the new flow, from the user action to the stored result. Add a second diagram only when it shows something the first cannot, such as an architecture delta or a state machine. Export each to SVG with the SVG export procedure of `diagram-design`, into the handoff folder. Delete the HTML source after the export.

Done when one or two SVG files sit in the handoff folder and each has an alt text and a one-line caption in the README.

### 5. Write the README

Follow [references/template.md](references/template.md) section by section. Part 2 states the contract as final, not as a proposal. Put questions in Part 1 only when the frontend team has a real choice, and give each one a D-id in Part 2.

Done when every template section with content is filled, and every Part 1 "what the frontend must do" item has an acceptance criterion in Part 2.

### 6. Humanize Part 1

Load the `humanizer` skill and run it on Part 1 only. Part 2 keeps its exact names, tables, and uppercase labels.

Done when the humanizer pass finds no pattern left in Part 1, and Part 2 is unchanged.

### 7. Commit to the handoff branch

In the frontend repo, create `handoff/<slug>` from the base branch, add the handoff folder, and commit with the message `docs(handoff): <feature>`. Show the user the branch and the file list. Push only after the user says to.

Done when `git log -1 --stat handoff/<slug>` lists the README and the SVG files, and the user has the branch name.

## Examples

### A new endpoint the UI must call

```text
Input:  "Invoices now support partial refunds on the backend. The frontend needs a refund dialog."
Result: branch handoff/invoice-partial-refunds in web-app, from main
        handoff folder 2026-10-29-invoice-partial-refunds with README and refund-sequence.svg
        Part 1: what a refund looks like now, four things the UI must do, no questions.
        Part 2: facts F1-F6 at backend-api main 9f3c2e1, POST /invoices/{id}/refunds
                with request, response, and five error rows, files to change, eight
                acceptance criteria.
```

### A breaking field rename

```text
Input:  "The user endpoint renamed full_name to display_name. Old field goes away on Dec 1."
Result: A handoff whose Part 1 opens with the deadline. Part 2 marks the change breaking,
        lists every frontend file that reads full_name, and adds a criterion that no
        code reads the old field.
```

## Prerequisites

You need read access to the backend repo at a named ref and write access to a local clone of the frontend repo. The `diagram-design` and `humanizer` skills must be installed.

## Limitations

This skill writes the handoff and commits it on a local branch. It pushes only after the user approves. It does not open a merge request or change frontend code.

## Troubleshooting

**No real example payload exists.** The backend has no test or fixture for the endpoint. Call a dev server if one runs, or write the example from the schema and mark it "from schema, not observed".

**The diagram needs more than nine nodes.** It shows two things. Split it, or cut nodes the frontend never talks to.

**The frontend agent asks what to build.** A decision is written as a fact, or a contract item lacks an example. Add the D-id and Part 1 question, or add the payload.
