---
name: audit-workflow
description: Runs a fixed React feature through the agent workflow and scores cost, time, calls, and mistakes. Use when comparing models, skills, or plugins.
version: 1.0.0
allowed-tools: Bash Read Write
metadata:
  author: Danel Ceresa <noreply@example.com>
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

The audit is done when every requested run has `metrics.json` and `report.md`, and the user has the comparison table. Run the [Checklist](#checklist) before you say so.

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

1. Write one `scripts/run.sh` command line per setup, with the options from the table.
2. Get plugin ids from `claude plugin list`. Why: the plugin options take the full `name@marketplace` id.
3. Give each run a `--label` that names the setup, such as `no-superpowers-sonnet`. Why: the label is the run's row name in the comparison table.
4. Keep the default `--budget 1` (USD cap) unless the user sets one. Why: the cap limits the bill; the two Opus runs in the example cost 0.52 and 0.38 USD.

Done when every setup has one command line, and each plugin id appears in `claude plugin list` or is a folder path.

### 2. Run each setup

Each run starts a billed Claude Code session on the chosen model.

1. Show the user every command line with its model and `--budget` cap.
2. Start only after the user approves them. Why: each run bills the user's account.
3. Run each command in the background, one after another, never in parallel (the fixture dev server uses port 5199):

```bash
skills/audit-workflow/scripts/run.sh --label current
```

4. Wait for each run to end. A run takes 1 to 40 minutes. The last line of the output is the run directory, under `~/.cache/audit-workflow/runs/`.

Harnesses with a `run_script()` tool can call `run_script("scripts/run.sh", ["--label", "current"])` instead.

Done when the user approved the commands and each run directory holds `stream.jsonl` ending in a `result` event, `checks.json`, and `metrics.json`.

### 3. Judge each run

1. Read [references/scoring.md](references/scoring.md). It covers what the counts in `metrics.json` miss.
2. Judge the run section by section, in the order of scoring.md: which errors were the agent's fault, repeated work, skill routing per phase, skipped phases, and how closely the result matches the design.
3. Open `header.png` to see the button.
4. Get the code quality score from a blind subagent judge, as scoring.md describes, and save it as `quality.json`.
5. Write `report.md` in the run directory, from the template in scoring.md.
6. When `oracle_contamination` is not empty, the agent read the hidden tests. Mark the run invalid in the report.

Done when each run directory has a `quality.json` and a `report.md` with every section from the template in scoring.md filled in.

### 4. Compare the runs

1. Print one table across all runs of this audit, plus earlier runs the user names:

```bash
python3 skills/audit-workflow/scripts/score.py RUN_DIR [RUN_DIR...]
```

2. Reply with the table.
3. Under the table, write one line per run: its label and the Verdict of its `report.md`.
4. Take the runs that are not marked invalid and pass both `oracle unit` and `oracle e2e`. For each, divide `quality.total` by `cost_usd`, both from `metrics.json`.
5. Name the run with the highest figure as the best setup for quality per dollar, and give the figure of each run from step 4. When no run qualifies, say so and name none.

Done when the reply shows the table with one row per run, one verdict line per run, and the best setup with its figure.

## Examples

### Current setup against a bare one

```text
Input:  audit the current setup against a bare one: no plugins, no agent-config, no user skills

Step 1. One command line per setup:
  scripts/run.sh --label current
  scripts/run.sh --label bare --no-agent-config \
    --disable-plugin superpowers@claude-plugins-official \
    --disable-skill humanizer
  (the bare command had 8 --disable-plugin and 20 --disable-skill options; one of each is shown)

Step 4. The reply:
  | run | model | USD | min | turns | calls | out tok | errors | repeats | phase files | phases worked | in order | oracle unit | oracle e2e | own tests | design rules | src+/test+ | quality |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  | current | claude-opus-5-5 | 0.52 | 0.95 | 9 | 8 | 5076 | 0 | 0 | 7/7 | 4/7 | pass | pass | pass | pass | pass | 5/24 | 28/30 |
  | bare | claude-opus-5-5 | 0.38 | 1.22 | 14 | 13 | 6972 | 1 | 0 | 7/7 | 6/7 | pass | pass | pass | pass | pass | 6/30 | 28/30 |

  current: Correct result at $0.52, but 35% more than bare for the same code. The extra cost is setup context (skill listing, hooks), and none of it was used.
  bare: Same quality as current at 74% of the cost. Best quality per dollar in this audit.

  Best setup: bare, 72.8 quality points per USD (28 / 0.3847). current has 53.8 (28 / 0.5205).
```

The rows and the verdict lines come from two real runs of this feature.

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

**`stream.jsonl` has no `result` event.** Read `stderr.log`. A budget stop or a crash ends the session early. Raise `--budget` or fix the error, then run again from step 2, so the user approves the new command line.

**Every oracle test fails.** Read `oracle-e2e.log`. When it shows that the dev server did not start, a process left on port 5199 blocks it. Run `lsof -ti tcp:5199 | xargs kill` and rerun only the oracle step by hand from the run's `app/`: the `oracle_unit` and `oracle_e2e` commands in `scripts/run.sh`.

**A disabled skill still shows in `skills_invoked`.** The call was denied, and `permission_denials` counts it. Count it as a routing mistake only when that skill appears 2 or more times in `skills_invoked`: the agent called it again after the denial.

**`npm ci` fails.** Read `setup.log`. Check the network, then delete the run directory and run again.

## Checklist

Run this before you say the work is done.

- [ ] The user saw every command line with its model and `--budget` cap, and approved it before it ran.
- [ ] No two runs ran at the same time.
- [ ] Each run directory holds `stream.jsonl` ending in a `result` event, `checks.json`, `metrics.json`, `quality.json` and `report.md`.
- [ ] Each `report.md` has every section of the scoring.md template filled in, and a run with a non-empty `oracle_contamination` is marked invalid in it.
- [ ] The reply shows the table with one row per run, then one verdict line per run.
- [ ] The reply names the best setup with its `quality.total` divided by `cost_usd` figure, or says that no run qualified.
