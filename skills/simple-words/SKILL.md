---
name: simple-words
description: Writes prose and code names in simple English for non-native readers. Use for every reply, doc, comment, and name, and to review naming in code.
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - writing
    - naming
    - code-review
---

# Simple words

## Purpose

Use this for everything you write: replies, docs, comments, commit messages, and every name in code. Also run it when the user asks to review naming in a file, a folder, or the whole codebase.

The reader learned English as a second language. Every word must be one they know without a dictionary. In code, every name must use the plain words that programmers use every day.

The test for a word: would a junior developer who is not a native speaker know it at first sight? When the answer is no, pick the plain word.

Writing is done when every word in the text and every new name passes that test. A review is done when the user has a table of every failing name with a plain replacement.

## Instructions

Pick the branch that fits the task. Writing runs on every task. Review runs only when the user asks for it.

### Writing

#### 1. Pick the plain word

Use the short, common word. Use one word for one meaning, and keep the same word every time that meaning comes back. Use short sentences in the active voice.

For a word you are not sure about, look it up in [references/word-swaps.md](references/word-swaps.md) and take the plain word it gives.

Done when every word in the text passes the test in Purpose.

#### 2. Name code with everyday programming words

Build each name from a plain verb and a plain noun: `get`, `set`, `load`, `save`, `find`, `check`, `build`, `merge`, `split`, `send`, `read`, `write`, `count`, `list`, `start`, `stop`, `clean`, `update`, `create`, `delete`, `parse`, `format`, `sort`, `filter`, `map`.

Name the thing by what it is or does for the caller. `mergeModelDifferences` beats `reconcileModelDeviations`. `recordDocumentAuthor` beats `recordDocumentProvenance`.

Keep these words as they are:

- Standard programming terms that appear in language and library docs: `cache`, `queue`, `token`, `schema`, `middleware`, `mutex`, `hash`, `async`.
- Domain words the product already uses with users, such as `invoice` or `tenant`.

Done when every new or changed name reads as plain verb plus plain noun, or is one of the kept terms.

### Review

#### 1. Set the scope

Use the files or folders the user named. When the user said "the whole codebase", list the source files with `git ls-files` and skip generated, vendored, and lock files.

Done when you have the file list.

#### 2. Collect the names

In each file, collect the names the code defines: functions, methods, classes, types, variables, constants, files, and folders. Skip names that come from outside the code, such as library APIs, database columns that other systems read, and public API fields.

Done when every file in scope has its names listed.

#### 3. Find the hard words

Split each name into words (`recordDocumentProvenance` gives `record`, `document`, `provenance`). Check each word with the test in Purpose and with [references/word-swaps.md](references/word-swaps.md).

Done when every name is marked pass or fail.

#### 4. Propose a plain name

For each failing name, write a plain name with the same meaning. Search the codebase for the new name so it does not clash with a name already in use. Count the places that use the old name.

Done when each failing name has a replacement with no clash and a usage count.

#### 5. Report and wait

Show one table, sorted by file:

```text
| File:line | Now | Proposed | Hard word | Uses |
```

Mark names that other systems read (public API, exported package members, stored keys) as "breaking". Ask the user which renames to apply. Do not rename before the user says yes.

When the user approves, rename every use, run the project's type check and tests, and report the result.

Done when the user has the table, or the approved renames are applied and the checks pass.

## Examples

### Function name

```text
Input. New code adds: function reconcileModelDeviations(a, b)

Result. The function is written as: function mergeModelDifferences(a, b)
"Reconcile" and "deviations" fail the test. "Merge" and "differences" pass.
```

### Field name in review

```text
Input. The user asks: review naming in src/documents/.
src/documents/store.ts:42 defines recordDocumentProvenance().

Result. The table has this row, and nothing is renamed yet:
| src/documents/store.ts:42 | recordDocumentProvenance | recordDocumentAuthor | provenance | 7 |
```

### Reply text

```text
Input. A draft reply says: "The scaffolding will reconcile the divergent states."

Result. The reply says: "The starter code will merge the two different states."
```

## Prerequisites

A git repo for the Review branch. No extra tools or keys.

## Limitations

The word list is a guide, not a full dictionary. Judge words that are not on it with the test in Purpose. This skill does not change names that other systems read until the user approves a breaking rename.

## Troubleshooting

**The plain word loses meaning.** Use two plain words instead of one hard word: `provenance` becomes `sourceAuthor` or `origin`, not a longer hard word.

**The hard word is the product's own term.** Keep it, and say so in the Review table with "kept: domain word".

**A rename breaks the build.** Read the error, rename the missed use, and run the checks again. Report any use you could not rename.
