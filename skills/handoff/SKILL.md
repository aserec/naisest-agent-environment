---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Name the file `handoff-<YYYY-MM-DD>-<slug>.md`, where the slug is a few words on the task.

Use this template. Drop a section only when it would be empty.

```md
# Handoff: <task>

## Goal
<What the work is for, in one or two sentences.>

## Current state
<What is done, what is in progress, what is broken.>

## Next steps
1. <First thing the next agent should do.>

## References
- <Path or URL to each spec, plan, ADR, issue, commit, or diff.>

## Suggested skills
- <skill>: <why the next agent should call the Skill tool for it>
```

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
