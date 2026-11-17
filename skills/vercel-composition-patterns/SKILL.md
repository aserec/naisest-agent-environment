---
name: vercel-composition-patterns
description: React composition rules. Use when refactoring boolean props or designing component APIs, compound components, render props, or context providers.
version: 1.0.0
license: MIT
metadata:
  author: vercel
  version: '1.0.0'
  tags:
    - react
    - composition
    - components
---

# React Composition Patterns

## Purpose

Use this skill for any of these tasks:

- Refactoring components whose boolean props choose what they render, such as `isThread` or `isEditing`
- Building component libraries
- Designing component APIs
- Reviewing component architecture
- Working with compound components or context providers

The skill holds 8 composition rules in 4 categories. Each rule has its own file at `rules/<id>.md`. You match rules to the code, read the files of the matched rules, and make the code follow them.

The work is done when every item in the [Checklist](#checklist) at the end of this file holds.

## Instructions

### 1. Match rules to the code

Go through the 4 categories under [Quick Reference](#quick-reference) in priority order, 1 to 4. In each category, pick every rule whose line names a pattern, an API, or a situation that the code of this task has or will have. When a line leaves you unsure, pick the rule: its file decides in step 3.

List the picked ids, one line per category, and write "none" for a category with no match. Keep the list for step 2. It is a working list, so it does not have to go in the reply.

Why this order: the categories are ranked by impact, so the highest-impact rules are matched first.

Done when the list has 4 lines, one per category.

### 2. Read the file of each matched rule

Read `rules/<id>.md` for every id on the list. Read only those files. Why: the 8 rule files hold about 900 lines, and unmatched rules add nothing.

Done when every id on the list has had its file read in this session.

### 3. Make the code follow each rule

Take the matched rules in category order, 1 to 4. Why: when two rules change the same lines, the higher category goes in first.

In all 8 rule files, `Incorrect` marks the pattern to remove and `Correct` marks the pattern to use.

- When writing or refactoring: write the code with the pattern to use.
- When reviewing: report each place that has the pattern to remove, with the rule id, and leave the code unchanged. Why: a review reports, and the author decides what to change.

When a rule file shows that the rule does not fit the code after all, take its id off the list.

Done when the code has the pattern to use for every rule left on the list, or the review names each place with its rule id.

### 4. Run the checklist

Run the [Checklist](#checklist) at the end of this file. Fix every item that fails, then run it again.

Done when every item holds.

## Examples

### One rule matches

```text
Input. The project's package.json has react 19. The code of this task wraps a
component in forwardRef:

  const ComposerInput = forwardRef<TextInput, Props>((props, ref) => {
    return <TextInput ref={ref} {...props} />
  })

Step 1. The list:
  1 architecture-  none
  2 state-         none
  3 patterns-      none
  4 react19-       react19-no-forwardref (react is 19, and the code uses forwardRef)

Step 2. Read rules/react19-no-forwardref.md. No other rule file is read.

Step 3. Result. The code now has the Correct pattern of that file:

  function ComposerInput({ ref, ...props }: Props & { ref?: React.Ref<TextInput> }) {
    return <TextInput ref={ref} {...props} />
  }
```

Both code blocks are copied from `rules/react19-no-forwardref.md`.

## Prerequisites

The `rules/` folder next to this file, with its 8 rule files. No tools, keys, or network access.

## Limitations

- A line in Quick Reference is a summary. The rule file is the rule: when the two differ, follow the file.

## Troubleshooting

**No rule matches.** The code has none of the patterns in Quick Reference. Make no change for this skill, carry on with the task, and say that no rule matched.

**Two matched rules change the same lines.** Apply the rule from the higher category first. Then look again for the lower rule's pattern to remove, and apply the lower rule only when that pattern is still in the code.

## Rule Categories by Priority

| Priority | Category                | Impact | Prefix          | Why it ranks here |
| -------- | ----------------------- | ------ | --------------- | ----------------- |
| 1        | Component Architecture  | HIGH   | `architecture-` | Structures components to avoid prop proliferation |
| 2        | State Management        | MEDIUM | `state-`        | Lifts state and shares context across composed components |
| 3        | Implementation Patterns | MEDIUM | `patterns-`     | Techniques for building compound components and context providers |
| 4        | React 19 APIs           | MEDIUM | `react19-`      | Applies to React 19 or later only |

## Quick Reference

Rule `<id>` lives at `rules/<id>.md`. Each line gives the rule id, what to do, and why.

### 1. Component Architecture (HIGH)

- `architecture-avoid-boolean-props` - Don't add boolean props to customize behavior; use composition. Why: each boolean doubles the possible states and adds conditional logic.
- `architecture-compound-components` - Structure components that switch their parts through `renderX` or `showX` props as compound components with shared context. Why: consumers compose the parts they need, without prop drilling.

### 2. State Management (MEDIUM)

- `state-decouple-implementation` - Provider is the only place that knows how state is managed. Why: the state implementation can then be swapped without changing the UI.
- `state-context-interface` - Define generic interface with state, actions, meta for dependency injection. Why: the same UI components then work with any provider that implements it.
- `state-lift-state` - Move state into provider components. Why: sibling components outside the main UI can then read and change it.

### 3. Implementation Patterns (MEDIUM)

- `patterns-explicit-variants` - Create explicit variant components instead of boolean modes. Why: each variant shows what it renders, with no boolean combinations to reason about.
- `patterns-children-over-render-props` - Use children for composition instead of renderX props. Why: children compose naturally and need no callback signatures.

### 4. React 19 APIs (MEDIUM)

> **⚠️ React 19+ only.** Skip this section if using React 18 or earlier. Read the `react` version in the project's `package.json`, and skip the section too when you cannot find it. Why: on React 18, `ref` is not a regular prop and `use()` does not exist.

- `react19-no-forwardref` - Don't use `forwardRef`; use `use()` instead of `useContext()`. Why: in React 19 `ref` is a regular prop, and `use()` can be called conditionally.

## Checklist

Run this before you say the work is done.

- [ ] The step 1 list has 4 lines, one per category, each with rule ids or "none".
- [ ] Line 4 has a rule id only when the project's `package.json` shows `react` 19 or later.
- [ ] Every id on the list had its file `rules/<id>.md` read in this session, and no other rule file was read.
- [ ] Rules were applied in category order, 1 to 4.
- [ ] Writing or refactoring: for every rule on the list, the code has the pattern to use and no longer has the pattern to remove.
- [ ] Reviewing: every finding names the rule id and the place in the code, and the code is unchanged.
