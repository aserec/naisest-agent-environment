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

Use this when a skill is being added or revised. Write one directory that any agent harness can load. The description states when to activate the skill. The body is a sequence of steps an agent can run. Keep the skill when `skillevaluator validate` reports a quality score of 100 and zero findings, and every line of the [Checklist](#checklist) holds. Why both: validate does not check the steps, the reasons, the examples or the closing checklist of a skill.

## Instructions

Run this for every new skill and for every skill you edit. Before you say the skill is done, run the [Checklist](#checklist).

### 1. Name the job

Write one sentence a caller would recognize. State the outcome, then the situations that should activate the skill.

Done when that sentence names the outcome and each distinct activation case.

### 2. Place one directory

1. Write the skill in the project directory `.agents/skills`, inside a folder whose name matches `name` in the frontmatter. The file in that folder is `SKILL.md`. For a user-wide skill, use that same `.agents/skills` path under the home directory.
2. Use a different name for a skill that belongs only to this project. Why: a folder with the same name as a skill in the agent-config copy is replaced the next time that copy is synced.
3. Link the folder into `.claude/skills` with a relative link, from the project root. Why: Cursor, Codex, Gemini CLI, Copilot and OpenCode read `.agents/skills` directly, and Claude Code reads `.claude/skills`.

```bash
ln -s ../../.agents/skills/<name> .claude/skills/<name>
readlink .claude/skills/<name>
```

In the agent-config repo itself, the target is `../../skills/<name>`. For a user-wide skill, run the same `ln -s` with `~/.claude/skills/<name>` as the link. For any other harness, read its docs and link the same directory into the path it scans.

Done when `readlink` prints the target at the folder under `.agents/skills/` (or `skills/`), and the active harness lists the skill.

### 3. Write the description that activates

1. Set `description` in the frontmatter. Use third person. State what the skill does, then `Use when` and the activation cases.
2. Keep it between 50 and 150 characters. Why: every session loads it, and validate takes points off above 150.
3. Name concrete tasks. Why: the check fails on vague words such as something, things, stuff, various, and general, and on first or second person.
4. Add `version`. Under metadata, add author, version, and tags. Author is a display name, a space, and an email address inside angle brackets.

Done when the description alone lets an agent decide to load the skill, and those frontmatter fields are present.

### 4. Write the body an agent can run

1. Write the sections in this order:
   - Purpose. When to run the skill, and the rule that decides it is done.
   - Instructions. Numbered steps.
   - Examples.
   - Prerequisites, Limitations, and Troubleshooting.
   - Checklist. The last section, under the exact heading `## Checklist`.
2. Make each step one action. When a step needs more than one, write its actions as a numbered list inside the step. Give a number or a limit wherever an amount matters, such as a count of rounds or a length. Why: a model that reads three actions in one step tends to do the first and skip the rest.
3. End each step with `Done when` and a check the agent can observe. Update a step until its check is observable.
4. Give every rule its reason in one line, after `Why:`. Why: a model that knows the reason applies the rule to cases the text does not name.
5. Replace each word that needs judgement, such as good, clean, properly, short or relevant, with the test, the number or the definition it stands for. Why: a cheaper model cannot fill in what the word means.
6. Under Examples, show one finished output per outcome, with the input and the result, inside a fenced block. Take it from a real run or a real file. Why: a model copies the example, so a placeholder ends up in real output.
7. Under Checklist, write one line per check the agent runs before it says the work is done. Why: checks spread over the steps get skipped, and one list at the end catches them.
8. Move detail that only some steps need into a markdown file under a references directory, and link that file from the step that needs it.
9. Keep `SKILL.md` under 500 lines. Why: the whole file loads when the skill runs, and validate has a 500-line limit.
10. Use forward slashes in paths. Why: a backslash path fails on macOS and Linux.

Done when every step is one action or a numbered list of actions and ends with `Done when`, every rule has a `Why:`, each example is fenced and comes from a real run or a real file, and `## Checklist` is the last section.

### 5. Run the validator

Run `skillevaluator validate` on the skill directory with `--tiers 1 --external -c`.

Done when the command has printed its report.

### 6. Clear the findings

Read each finding in the report and edit the skill to clear it. Then run step 5 again. Stop after three rounds of edit and run, and report the findings that remain to the user. Why: a finding that three edits did not clear needs the user's decision.

Done when the command exits 0, the quality score is 100, and the report lists zero findings, or the user has the findings that remain after three rounds.

## Examples

### Finished skill

```text
Input. The user asks for a skill that runs the static skill checks of agent-config and fixes each failure.

Result. The folder check-skill-folders holds the SKILL.md below. Validate exits 0 with a quality score of 100 and zero findings.
```

````markdown
---
name: check-skill-folders
description: Run the static checks on skill folders and fix each failure. Use when adding, renaming, or deleting a skill in agent-config.
version: 1.0.0
metadata:
  author: Agent Config <agent-config@example.com>
  version: 1.0.0
  tags:
    - skills
---

# Check skill folders

## Purpose

Use this after a skill folder in agent-config is added, renamed, or deleted. The work is done when `bash check-skills.sh` prints `check-skills: ok`.

## Instructions

### 1. Run the check

From the repo root, run `bash check-skills.sh`.

Done when the command prints `check-skills: ok`, or one `FAIL` line for each problem.

### 2. Fix each failure

1. For each `FAIL` line, edit the file that the line names. Why: the line names the folder or the file that broke the check.
2. Run step 1 again, at most three times. Why: a failure that three edits did not clear needs the user's decision.

Done when the command prints `check-skills: ok`, or the user has the `FAIL` lines that remain.

## Examples

### Name that does not match the folder

```text
Input. In the folder check-skill-folders, line 2 of SKILL.md reads "name: check-skills".
Step 1 prints: FAIL check-skill-folders: SKILL.md name is 'check-skills'

Result. Line 2 reads "name: check-skill-folders", and step 1 prints: check-skills: ok
```

## Prerequisites

`jq` must be on PATH. The check reads the list of upstream skills with it.

## Limitations

This skill fixes what the check reports. It does not run the tests of the repo.

## Troubleshooting

**A `FAIL` line names a missing skill.** A file refers to a skill that has no folder. Correct the name in that file, or remove the reference.

## Checklist

Run this before you say the work is done.

- [ ] The last run of `bash check-skills.sh` printed `check-skills: ok`, or the user has the `FAIL` lines that remain.
- [ ] Each edit was made in a file that a `FAIL` line named.
````

The author in this example has a made-up address, because validate fails on a real address in the body of a file. Give your skill its real author.

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

**The score stays under 100.** Read the finding suggestion, edit that part of the skill, and run validate again, within the three rounds of step 6. An exit code of 0 with a score under 100 is unfinished.

**The harness does not list the skill.** The directory sits outside the paths that the harness scans. Link the directory into a scanned path and confirm the harness lists the skill name.

**Validate fails the author check.** Set the author under metadata to a display name, a space, and an email address inside angle brackets, then run validate again.

## Checklist

Run this before you say the skill is done.

- [ ] The folder name equals `name` in the frontmatter, and the file in it is `SKILL.md`.
- [ ] `readlink` prints the folder under `.agents/skills/` (or `skills/`), and the active harness lists the skill.
- [ ] The description is in third person, has `Use when` with the activation cases, and has 50 to 150 characters.
- [ ] The frontmatter has `version`, and `metadata` has author, version, and tags.
- [ ] The body has Purpose, Instructions, Examples, Prerequisites, Limitations, Troubleshooting, and Checklist, in that order, and `## Checklist` is the last section.
- [ ] Every step is one action or a numbered list of actions, has a number or a limit where an amount matters, and ends with `Done when` and a check the agent can observe.
- [ ] Every rule has its reason after `Why:`, and no instruction hangs on a word that needs judgement.
- [ ] Every example is in a fenced block and shows a finished output from a real run or a real file.
- [ ] `SKILL.md` has under 500 lines, and its paths use forward slashes.
- [ ] The last validate run exited 0 with a quality score of 100 and zero findings, or the user has the findings that remain after three rounds.
