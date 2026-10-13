# Judging a run

`score.py` counts. This file covers what needs judgment. Read `metrics.json`, `timeline.txt`, `diff.patch`, the `.audit/` phase files in `app/`, and `header.png`. Open `stream.jsonl` only to read the text around a call the timeline flags.

## Mistakes

Classify every entry in `tool_errors`:

| Class | Example | Counts as a mistake |
|---|---|---|
| expected | A test fails on purpose before the code exists (TDD red step) | no |
| environment | Port in use, network down, missing browser | no, but note it |
| agent | Wrong path, bad command, edit with a stale `old_string`, test failing on its own bug | yes |

## Repeated work

`identical_calls` and `redundant_reads` are the mechanical count. Add what the count misses:

- a failing command run again with no change in between
- a phase redone after its file was written
- a subagent that reads the same files the main agent already read, with no new question

Re-running tests after a fix is not a repeat.

## Routing

For each phase, compare `per_phase.<phase>.skills` with `skills_available`.

- **missed**: a listed skill matches the phase and was not used (for example a code review skill was listed and the review phase used none)
- **wrong**: a skill was used outside its purpose, or one skill was loaded more than once
- **late**: the matching skill was loaded after the phase work was already done

## Skipped steps

A phase is skipped when its file is missing or empty, or when the file claims work the timeline does not show. Typical case: `05-validation.md` reports passing Playwright tests but no `playwright`/`npm run e2e` call appears in that phase. Also flag `phases_in_order: false`.

`timeline.txt` cuts each call to one line, and the scorer assigns a whole call to one phase. One shell call can hold several phases, for example writing `04-implementation.md` and then running the tests. `phases_batched_in_one_call` lists those calls. Read the full command in `stream.jsonl` before you call a phase skipped. Batching phases into one call is itself a finding: report it under Skipped steps when a phase has no work of its own.

## Design and decisions

Check the diff against each line of `feature-spec.md`. `checks.json` covers the oracle, protected files, new dependencies, type check, and whether tests were added. By hand, check:

- the agent's tests assert the behavior (button present in the header, navigation to the profile), not only that the page renders
- nothing outside the feature changed
- `header.png` shows the button in the header, after the "Signed in as" text, with the secondary look

## Report

Write `report.md` in the run directory:

```markdown
# <label> — <model>

| Cost | Wall time | Turns | Tool calls | Output tokens | Phases | Oracle |
|---|---|---|---|---|---|---|

## Mistakes
<n agent mistakes>: one line each, call number and cause.

## Repeated work
One line each.

## Routing
Per phase: skills used, then missed/wrong/late.

## Skipped steps

## Design and decisions

## Verdict
One sentence: how this setup compares on quality per dollar.
```
