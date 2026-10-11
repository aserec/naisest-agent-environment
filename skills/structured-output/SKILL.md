---
name: structured-output
description: Lay out each chat reply under fixed rendered headings and cut AI tells. Use when answering the user or summarizing completed work.
version: 3.1.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 3.1.0
  tags:
    - writing
    - replies
---

# Structured output

## Purpose

Use this on every chat message you send the user. Apply the rules in [references/unslop-rules.md](references/unslop-rules.md) to the prose, then lay the message out under markdown headings.

The layout is rendered markup only. The terminal draws a heading as styled text and hides its `#` marks, so a reader who selects and copies the reply gets the words and nothing else. Drawn borders, bars and rules are characters that the copy picks up.

The message is done when the headings below are the whole reply, the checks in the steps hold, and no pattern from those rules remains.

## Brevity

- Open with the title. Skip the preamble ("Let me...", "Now I'll...") and the narration of each step you took.
- Answer a simple question in one to three sentences under Answer.
- When the user asks for an explanation or detail, give it in full. Brevity never withholds what was asked for.
- Error reports, failing test output, security warnings and confirmations for destructive actions keep their full content.

## Instructions

Run this before you send a chat reply. The section labels are fixed. Write them in this order.

1. Title
2. Answer
3. Steps, only when the reader must open a URL
4. Questions, only when you still need a decision from the reader
5. Request
6. Summary

### 1. Name the thread

Write a short title that names the whole conversation.

Done when the title names the thread.

### 2. Write the outcome

Write Answer. State what you did, what you left undone, and any problem that stopped the work. Keep a sentence only when it changes what the reader does or decides next. Number the items when there is more than one.

Done when Answer states the outcome and any blocker in at most eight sentences.

### 3. Cut AI tells

Rewrite every sentence in the reply with the rules in [references/unslop-rules.md](references/unslop-rules.md). Then delete any sentence that still adds no fact, decision, or next action.

Done when a pass over those rules finds no banned pattern in the reply.

### 4. List steps that need a link

Add Steps only when the reader must open a URL. Each item is one number, one action, and one absolute URL. The URL may be a localhost address or an external address. Omit the whole section when no such action exists.

Done when every Steps item has one absolute URL, or the section is absent.

### 5. Ask what you cannot decide

Add Questions only for decisions you cannot make from the request, the code, or a project rule. Number each question. Omit the whole section when none remain.

Done when every question is numbered and needs the reader, or the section is absent.

### 6. Restate the ask

Write Request as one line with no heading: the bold label, then a short title that names the ask. Example: `**💬 Request:** Change the font color`.

Done when Request is that single line.

### 7. Summarize in one sentence

Write Summary as one sentence that states what was done.

Done when Summary is that single sentence.

### 8. Lay out the reply

Build the reply from markdown headings, which the terminal renders as styled text:

- The first line is the thread title as a level-2 heading with its icon: `## 📌 Thread title`.
- Each section opens with a level-3 heading: `### ✅ Answer`, `### 🔗 Steps`, `### ❓ Questions`, `### 📝 Summary`.
- Request is a single bold line, not a heading: `**💬 Request:** Title of the ask`.
- Under each heading, write plain paragraphs or a numbered list, with one blank line between blocks.
- Send the headings and their content only, with no text before the title or after Summary.
- Keep text upright and plain: the headings carry the structure. Bold `**...**` is fine inside a line.

The first example below is the full reply. When Steps or Questions is absent, omit that heading and its content. The second example shows that shorter reply.

Done when the reply opens with the title heading, every section except Request sits under its own heading, Request and Summary close it, and the reply holds no drawn border, bar, rule or `>` prefix.

## Examples

### Reply with a link and an open question

Input. "Add logout to the account page."

```markdown
## 📌 Logout on the account page

### ✅ Answer

1. The account page now has a Logout button.
2. A click clears the local session and opens the login page.
3. I did not revoke the remote session, because the request did not say to.

### 🔗 Steps

1. Open http://localhost:3000/account and click Logout.

### ❓ Questions

1. Should logout also revoke the identity provider session?

**💬 Request:** Add logout to the account page

### 📝 Summary

Logout is on the account page and ends the local session.
```

### Reply with nothing left open

Input. "Rename the Save label to Apply."

```markdown
## 📌 Rename Save to Apply

### ✅ Answer

The settings form button now reads Apply.

**💬 Request:** Rename Save to Apply

### 📝 Summary

The settings button label is Apply.
```

## Prerequisites

Read [references/unslop-rules.md](references/unslop-rules.md) while rewriting the reply. This skill adds no tools, keys, or services.

## Limitations

This skill shapes chat replies. File edits, commits, and document rewrites stay with the task that owns them. Apply the same rules to those edits, and keep a file's own format. Steps and Questions are omitted when empty. The reply lists a command the reader must run. It does not run that command.

A terminal renders only text and its styling, so headings are the whole visual layout here. A background panel or a border that stays out of a copy needs a graphical client.

## Troubleshooting

**A check fails.** Name the failed check, fix that section, and run steps 1 to 8 again. Send the reply only after every check passes. If the same check fails a second time, stop and ask the reader which fact to keep.

**The reply is still a long paragraph.** Answer grew past eight sentences. Delete any sentence that does not change the next action.

**A link sits inside Answer.** Move that action to Steps with its absolute URL.

**A copy picks up stray characters.** A line starts with `│`, `>` or `---`, or ends with `\`. Remove the marker and let the heading carry the structure.

**The reply renders in italics.** Text sits inside `*...*` or `_..._`, or a line starts with `>`. Remove the marker so the text is upright.

**A banned pattern remains after the rewrite.** Open [references/unslop-rules.md](references/unslop-rules.md), apply the matching rule, and send the reply only after a second pass finds none.
