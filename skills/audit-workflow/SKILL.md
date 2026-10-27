---
name: audit-workflow
description: Runs a fixed React feature through the agent workflow and scores cost, time, calls, and mistakes. Use when comparing models, skills, or plugins.
version: 1.0.0
allowed-tools: Bash Read Write
metadata:
  author: Danel Ceresa <dceresa1988@gmail.com>
  version: 1.0.0
  tags:
    - evaluation
    - workflow
    - benchmarking
---

# Audit workflow

## Purpose

Use this to measure how well one agent setup (model, skills, plugins) builds a known feature. The feature is the same every run, so runs compare: a "View profile" button in the header of a small React dashboard, specified in [references/feature-spec.md](references/feature-spec.md).

Each run copies the fixture app from `assets/fixture/`, starts a headless Claude Code session in it, and asks for seven phases: research, spec, plan, implementation, validation, code review, final validation ([references/workflow-prompt.md](references/workflow-prompt.md)). Then it runs the agent's own tests, the design checks, and hidden oracle tests from `assets/oracle/`, and scores the session.

Each run calls `claude -p` (headless Claude Code) on the user's own account and bills that account at the chosen model's price, up to the `--budget` cap. Step 2 gets the user's approval before any run starts.

With no options, the run uses the current setup: the enabled plugins, the user skills, and the skills of this agent-config repo wired in by its `install.sh`. Options switch plugins and skills on or off for that run only. User settings are never edited.

The audit is done when every requested run has `metrics.json` and `report.md`, and the user has the comparison table.

## Instructions

### 1. Turn the request into run options

Map what the user asked for onto `scripts/run.sh` options. One setup is one run.

| User says | Option |
|---|---|
| nothing, or "current setup" | none |
| a model | `--model opus` (alias or full id) |
| turn off a plugin | `--disable-plugin superpowers@claude-plugins-official` |
| turn on an installed plugin | `--enable-plugin feature-dev@claude-plugins-official` |
| try a plugin from a folder | `--plugin-dir PATH` |
| turn off a skill | `--disable-skill NAME` (repeat for each) |
| try new or changed skills | `--agent-config PATH` (a checkout or worktree of this repo with those skills) |
| leave this repo's skills and hooks out | `--no-agent-config` |

Get plugin ids from `claude plugin list`. Give each run a `--label` that names the setup, such as `no-superpowers-sonnet`. Keep the default `--budget 1` (USD cap) unless the user sets one. The feature should cost well under that.

Done when every setup has one command line, and each plugin id appears in `claude plugin list` or is a folder path.

### 2. Run each setup

Each run starts a billed Claude Code session on the chosen model. Show the user every command line with its model and `--budget` cap, and start only after the user approves them.

Run each command in the background, one after another, never in parallel (the fixture dev server uses port 5199):

```bash
skills/audit-workflow/scripts/run.sh --label current
```

Harnesses with a `run_script()` tool can call `run_script("scripts/run.sh", ["--label", "current"])` instead. A run takes 1 to 40 minutes. The last line of the output is the run directory, under `~/.cache/audit-workflow/runs/`.

Done when the user approved the commands and each run directory holds `stream.jsonl` ending in a `result` event, `checks.json`, and `metrics.json`.

### 3. Judge each run

Follow [references/scoring.md](references/scoring.md). It covers what the counts in `metrics.json` miss: which errors were the agent's fault, repeated work, skill routing per phase, skipped phases, how closely the result matches the design, and code quality from a blind subagent judge, saved as `quality.json`. Open `header.png` to see the button. Write `report.md` in the run directory.

When `oracle_contamination` is not empty, the agent read the hidden tests. Mark the run invalid in the report.

Done when each run directory has a `quality.json` and a `report.md` with every section from the template in scoring.md filled in.

### 4. Compare the runs

Print one table across all runs of this audit, plus earlier runs the user names:

```bash
python3 skills/audit-workflow/scripts/score.py RUN_DIR [RUN_DIR...]
```

Reply with the table, then one line per run from its `report.md` verdict, and name the best setup for quality per dollar.

Done when the reply shows the table with one row per run and names the best setup.

## Examples

### Current setup

```text
Input:  /audit-workflow
Runs:   scripts/run.sh --label current
Result: | current | claude-opus-5-5 | 6.12 | 18.4 | 41 | 96 | 52310 | 2 | 3 | 7/7 | pass | pass | pass | pass | pass |
        Verdict: all phases done, oracle green, two agent errors in validation.
```

### Setup without a plugin, on another model

```text
Input:  audit without superpowers, on sonnet
Runs:   scripts/run.sh --label no-superpowers-sonnet --model sonnet \
          --disable-plugin superpowers@claude-plugins-official
Result: a second table row; the review phase used no review skill, which scoring.md marks as missed routing.
```

## Available scripts

| Script | Purpose | Arguments |
| --- | --- | --- |
| `scripts/run.sh` | Builds a fresh fixture copy, runs the headless session, runs every check, scores the run | Options from the table in step 1 |
| `scripts/score.py` | Writes `metrics.json` and `timeline.txt`; with several runs, prints the comparison table | `RUN_DIR [RUN_DIR...]` |

`run.sh` exits 2 on an unknown option and prints the run directory last. `score.py` exits 2 when a run directory has no `stream.jsonl`.

## Prerequisites

- `claude`, `node` 22+, `npm`, `jq`, `rsync`, `lsof`, and `python3` on PATH.
- Network access for `npm ci` and the Playwright Chromium download in the first run.
- The fixture pins every dependency version, so runs install the same code.

## Limitations

- The agent under test runs with `--permission-mode bypassPermissions` inside the run copy. It can still reach files outside that copy, so the global command guard stays the safety net.
- Nobody answers the agent during the run. Skills that stop to ask questions show up as stalls or as decisions written into the phase files.
- `cost_usd` is the list price Claude Code reports, not the amount billed on a subscription.
- The oracle files sit inside this skill. The run hides the skill from the agent and `score.py` flags any read of them, but it cannot block a read.
- Repeated work and routing are partly judged by the auditing agent, so two judges can differ on edge cases. The counts in `metrics.json` do not change.

## Troubleshooting

**`stream.jsonl` has no `result` event.** Read `stderr.log`. A budget stop or a crash ends the session early. Raise `--budget` or fix the error, then run again.

**Every oracle test fails, even on a good diff.** Read `oracle-e2e.log`. A process left on port 5199 blocks the dev server. Run `lsof -ti tcp:5199 | xargs kill` and rerun only the oracle step by hand from the run's `app/`.

**A disabled skill still shows in `skills_invoked`.** The call was denied, and `permission_denials` counts it. Count it as a routing mistake only when the agent kept trying.

**`npm ci` fails.** Read `setup.log`. Check the network, then delete the run directory and run again.
