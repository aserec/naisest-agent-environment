# Handoff template

## Contents

- Skeleton (Part 1: for people, Part 2: for agents)
- Style rules
- Final check

Copy this skeleton into `README.md`. Replace everything in angle brackets. Leave out a Part 2 section only when the feature has nothing for it.

````markdown
# <Short title: what the feature does>

<Mon D, YYYY> · @<author> · backend `<repo>` @ `<short sha>`

<One or two sentences: what the backend now does, and what users get once the frontend adapts.> Part 1 explains it in plain words. Part 2 is a brief a frontend agent can build from.

## Part 1: for people

### <Claim about what the backend does now>

1. <Step of the new flow, in everyday words.>
2. <Step.>

![<alt text: what the diagram shows>](<diagram>.svg)

<One-line caption.>

### What the frontend must do

1. <Outcome the user sees, no code names.>
2. <Outcome.>

<What keeps working unchanged. Any deadline, such as when an old field goes away.>

### Questions for the frontend team

1. <Only real choices left to the frontend. Leave the section out when there are none.>

## Part 2: for agents

### Goal and verified facts

GOAL: <one sentence, precise, observable in the UI.>

FACTS (checked <YYYY-MM-DD>; backend = `<repo>`, ref `<ref>`, head `<short sha>`):

| # | Fact | Where |
| --- | --- | --- |
| F1 | <What is true, with exact names and shapes> | `<file path>` (`<symbol>`) |

DECISIONS OPEN: D1 <short>. <Or "none".>

### Contract: <METHOD /path or event name> (<additive | breaking>)

Auth: <who may call it>. Feature flag: <name and default, or none>.

Request:

```json
<real example>
```

Response `<status>`:

```json
<real example>
```

| Field | Type | Required | Rule |
| --- | --- | --- | --- |

Errors (<error format>, branch on `code`):

| Case | Status | `code` | What the UI shows |
| --- | --- | --- | --- |

<For a breaking change: the old shape, the new shape, and the date the old one stops working.>

### Frontend files to change

| File | Change |
| --- | --- |
| `<path>` | <what changes> |

### Try it

<How to reach the feature: dev or staging URL, seed data, flag to switch on, a curl command.>

### Acceptance criteria

- [ ] <One observable criterion per "what the frontend must do" item.>
- [ ] <One criterion per error row.>
- [ ] <For a breaking change: no code reads the old shape.>

Verify <names> before using them. They come from <source>, and nobody checked them at the recorded ref.
````

## Style rules

- Part 1 uses short sentences and everyday words. It names no fields, paths, or status codes, except inside the questions.
- Each Part 1 heading in the first section is a claim, such as "Refunds can now cover part of an invoice". A label like "Background" is not a claim.
- Part 2 is dense and exact: backticked names, tables, and uppercase labels (GOAL, FACTS, DECISIONS OPEN).
- A fact is only something you read at the recorded ref. Unverified names go in the verify sentence.
- Examples are real payloads. Mark a payload built from the schema as "from schema, not observed".

## Final check

- [ ] Every Part 1 question has a D-id in Part 2, and every D-id has a Part 1 question.
- [ ] Every FACTS row has a Where.
- [ ] Every contract has a request and a response example, and an additive or breaking mark.
- [ ] Every error row has a "What the UI shows" cell and an acceptance criterion.
- [ ] Every "what the frontend must do" item has at least one acceptance criterion.
- [ ] Every diagram has alt text and a caption, and the SVG file sits next to the README.
