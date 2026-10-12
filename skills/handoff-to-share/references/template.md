# Handout template

## Contents

- Skeleton (Part 1: for people, Part 2: for agents)
- Style rules
- Final check

Copy this skeleton. Replace everything in angle brackets. Leave out a Part 2 section only when the change has nothing for it. For example, a change with no new endpoint has no contract section.

````markdown
# <Short title: the change, not the ticket>

<Mon D, YYYY> · @<author>

<One or two sentences: what the receiver has to do, and what people gain.> Part 1 explains why in plain words. Part 2 is a brief a <receiver> agent can work from.

## Part 1: for people

### <Claim about how it works today>

<One sentence of context.>

1. <Step, in everyday words.>
2. <Step.>

<Which step matters, and why.>

### <Claim about why the new way breaks that>

<What is better about the new way. Then what it loses, and why your side cannot fix it alone.>

<Optional diagram of the old flow against the new one>

<One-line caption under the diagram.>

### What we ask the <receiver> to build

1. <Outcome, no code names.>
2. <Outcome.>

<What keeps working unchanged.>

<What is already ready on your side.>

### Questions for the <receiver> team

1. <If another path may already exist, ask about it first: which branches, and what it does.>
2. <One question per open decision.>

## Part 2: for agents

### Goal and verified facts

GOAL: <one sentence, precise, observable.>

FACTS (checked <YYYY-MM-DD>; <receiver> = `<repo>`, ref `<ref>`, head `<short sha>`):

| # | Fact | Where |
| --- | --- | --- |
| F1 | <What is true, with exact names and shapes> | `<file path>` (`<symbol>`) |

DECISIONS OPEN (resolve with the humans before coding; see Part 1 questions): D1 <short>; D2 <short>.

### Contract change: <name> (proposal, <additive | breaking>)

<Endpoint or message.> <What happens with no new input: today's behaviour, unchanged.>

```json
{ "<field>": "<type>" }
```

| Field | Type | Required | Rule |
| --- | --- | --- | --- |

Response: <unchanged, plus what is added>.

Validation and errors (<error format>, branch on `code`):

| Case | Status | `code` |
| --- | --- | --- |

<Who may write the new data, and who must never supply it.>

Changelog: <what the receiver commits alongside the change>.

### <Receiver component> behaviour

Applies only when <condition>. Without it, <component> behaves exactly as today.

Pick ONE approach from D<n>:

| Approach | When | How | Gains | Costs |
| --- | --- | --- | --- | --- |
| A. <name> | D<n> = <answer> | <how> | <gains> | <costs> |

Rules for both:

1. <Label>: <rule>.

Verify <names> against the version pinned in `<file>` before using them. They are named here from <source>, and nobody has checked them against this repo.

### Acceptance criteria

- [ ] <No new input behaves exactly as today (regression test).>
- [ ] <One observable criterion per behaviour, one test per error row.>

<Your side> follow-up (not part of this <receiver> task): <what you will do once this lands>.
````

## Style rules

- Part 1 uses short sentences and everyday words. It names no fields, paths, or status codes, except inside the questions.
- Each Part 1 heading is a full claim, such as "The call agent talks by itself, so the chat never sees it". A label like "Background" is not a claim.
- Part 2 is dense and exact: backticked names, tables, and uppercase labels (GOAL, FACTS, DECISIONS OPEN).
- A fact is only something you read at the recorded ref. Unverified names go in the verify sentence.
- Keep "proposal" in every contract heading until the receiver agrees to it.

## Final check

- [ ] Every Part 1 question has a D-id in Part 2, and every D-id has a Part 1 question.
- [ ] Every FACTS row has a Where.
- [ ] Every contract change says what happens with no new input, and has an acceptance criterion for it.
- [ ] Every error row has a matching acceptance criterion.
- [ ] Every Part 1 "what we ask" item has at least one acceptance criterion.
- [ ] The last line names the follow-up on your side as out of scope.
