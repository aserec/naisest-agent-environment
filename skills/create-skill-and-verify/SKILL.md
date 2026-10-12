---
name: create-skill-and-verify
description: Write a portable agent skill with a trigger description and steps an agent can run. Use when creating, editing, or validating a skill.
version: 1.0.0
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - skills
    - agents
---

# Author skills

## Purpose

Use this when a skill is being added or revised. Write one directory that any agent harness can load. The description states when to activate the skill. The body is a sequence of steps an agent can run. Keep the skill when `skillevaluator validate` reports a quality score of 100 and zero findings.

## Instructions

Run this for every new skill and for every skill you edit.

### 1. Name the job

Write one sentence a caller would recognize. State the outcome, then the situations that should activate the skill.

Done when that sentence names the outcome and each distinct activation case.

### 2. Place one directory

Write the skill in the project directory `.agents/skills`, inside a folder whose name matches `name` in the frontmatter. The file in that folder is `SKILL.md`. For a user-wide skill, use that same `.agents/skills` path under the home directory.

Cursor, Codex, Gemini CLI, Copilot and OpenCode read `.agents/skills` directly. Claude Code reads `.claude/skills`, so link the folder there with a relative link, from the project root:

```bash
ln -s ../../.agents/skills/<name> .claude/skills/<name>
readlink .claude/skills/<name>
```

In the agent-config repo itself, the target is `../../skills/<name>`. For a user-wide skill, run the same `ln -s` with `~/.claude/skills/<name>` as the link. For any other harness, read its docs and link the same directory into the path it scans.

Done when `readlink` prints the target at the folder under `.agents/skills/` (or `skills/`), and the active harness lists the skill.

### 3. Write the description that activates

Set `description` in the frontmatter. Use third person. State what the skill does, then `Use when` and the activation cases. Keep it between 50 and 150 characters. Name concrete tasks. The check fails on vague words such as something, things, stuff, various, and general, and on first or second person.

Add `version`. Under metadata, add author, version, and tags. Author is a display name, a space, and an email address inside angle brackets.

Done when the description alone lets an agent decide to load the skill, and those frontmatter fields are present.

### 4. Write the body an agent can run

Use this order.

- Purpose. When to run the skill, and the rule that decides it is done.
- Instructions. Numbered steps. Each step ends with `Done when` and a check the agent can observe.
- Examples. One concrete case per outcome, with the input and the result, inside a fenced block.
- Prerequisites, Limitations, and Troubleshooting.

Update a step until its check is observable. Move detail that only some steps need into a markdown file under a references directory, and link that file from the step that needs it. Keep `SKILL.md` under 500 lines. Use forward slashes in paths.

Done when every step has a completion check, the examples are fenced, and those sections are present.

### 5. Loop until the run is clean

Run `skillevaluator validate` on the skill directory with `--tiers 1 --external -c`. Read each finding. Edit the skill to clear it. Run the same command again.

Done when the command exits 0, the quality score is 100, and the report lists zero findings.

## Examples

### Description that activates

```yaml
description: Prove each test fails when one caller-visible behavior breaks. Use when writing tests, reviewing tests, adding coverage, or deciding whether a test is useful.
```

An agent loads this for writing tests, reviewing tests, adding coverage, or deciding whether a test is useful. The sentence names the outcome and the activation cases.

### Description to rewrite

```yaml
description: I can help you create Cursor skills.
```

This is first person, names one harness, and lists no activation cases. Rewrite it in third person, name the outcome, and add `Use when` with the cases.

## Prerequisites

`skillevaluator` must be on PATH. The frontmatter needs an author made of a display name, a space, and an email address inside angle brackets. When the harness is absent from the list in step 2, read the docs for that harness and find the directory it scans.

## Limitations

This skill writes the skill and runs Tier 1 validation. It leaves commits and publishing to the person who runs it. Deduplication and live evaluation are outside this skill.

## Troubleshooting

**The score stays under 100.** Read the finding suggestion, edit that part of the skill, and run validate again. An exit code of 0 with a score under 100 is unfinished.

**The harness does not list the skill.** The directory sits outside the paths that the harness scans. Link the directory into a scanned path and confirm the harness lists the skill name.

**Validate fails the author check.** Set the author under metadata to a display name, a space, and an email address inside angle brackets, then run validate again.
