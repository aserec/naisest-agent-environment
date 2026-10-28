# Kivvo software factory: design

Status: draft for review, 2026-10-28.
Diagram of the flow: https://claude.ai/artifact/Dwm4GQbm4PYNMVf8ugCs9J

This file moves into the factory repo once that repo exists.

## Open questions

The team must answer these before planning. They came from checking the design against the three product repos.

1. **Ticket source. Answered.** Tickets move to GitLab work items. Tuleap is no longer used. Today only `react_frontend` has GitLab work items. Call made: each target repo uses its own work items, and turning them on in `fastapi_backend` and `ai_gateway` is a phase 3 step. Factory branches use `factory/<work item id>-<short title>`.
2. **Runner. Answered.** The team will set up a server used only by the factory, in its own hosting. The product repos' shell runners would let factory jobs reach other projects' files and the Docker daemon. The spec is in [section 12](#runner-server).
3. **Merge rights. Answered.** The team will change the KIVVO Git workflow guide so the factory's bot may merge low risk changes. GitLab is self-managed and the edition is unknown. Call made: the builder checks the license under Admin > License. On Premium, the bot gets merge rights by name on the protected branch. On Free, the bot is a Maintainer, and its token stays in the scripts and never reaches an agent job.
4. **Model providers. Open, research running.** `react_frontend`'s AGENTS.md allows hosted agents for generic code, and keeps know-how and customer data away from them. The team requires GDPR compliance and European sovereignty, so OpenRouter is out. Options for Jev or a Jev-like model, the reviewer, and Claude itself: [docs/research/2026-10-28-eu-sovereign-model-options.md](../../research/2026-10-28-eu-sovereign-model-options.md).

## 1. Why

The team has four developers. They want routine work to happen between their check-ins, as in the reference picture: the factory handles the event, the triage and the patch while people are away. People step in for decisions, and the factory then applies, verifies and saves the result.

People should only do three things:

1. Start work, by adding a label, or by letting the watcher start it.
2. Answer questions the factory asks.
3. Approve changes that are not low risk.

## 2. Goals

1. A person adds the `factory_ready` label to a GitLab work item, and the factory takes the ticket from there.
2. Every run moves through the same named steps: event, triage, prepare patch, code review, precommit-gate, risk check, decision, apply, verify, result saved. Each step leaves a record.
3. A change merges without a person only when every condition in [6.7](#67-decision) holds.
4. A watcher finds escalating errors and starts the same flow on its own. It is off by default.
5. People can steer a running agent from GitLab comments, from Microsoft Teams, and from their phone.
6. The factory picks the models for each ticket with Jev. The code reviewer always uses a model from a different company than the author.
7. The factory repo stands alone. It works on `react_frontend`, `fastapi_backend` and `ai_gateway`. Adding a repo needs no change to factory code.
8. The ticket source can change later without changing the flow. Local markdown tickets, one file per ticket with a folder per state, were discussed as a later option.

## 3. Non-goals

- No deploys. The factory merges to the main branch and checks it. Deploys stay with people.
- No Anthropic-hosted cloud sessions or routines. They only work with GitHub repos, and the code lives on a self-managed GitLab.
- No GitHub.
- No new service or database for state in phase 1. State lives in GitLab: labels, comments, merge requests and pipeline artifacts. The Teams inbound bridge in phase 2 is the only small service.
- Not a product for other companies. It is for this team's own use.

## 4. Anti-goals

The factory has failed, even if it runs, when any of these happen:

- A change that a person should have seen merges without one.
- A test gets weaker, skipped, removed or changed only to turn the build green.
- Text from a ticket, a log line or a comment makes an agent do something nobody asked for.
- A stuck loop or a flood of watcher tickets uses up Kirill's plan limits and blocks Kirill's own work.
- A ticket gets stuck and nobody hears about it.
- People spend more time watching the factory than it saves them.

## 5. Constraints and facts

### GitLab

- Self-managed at `https://falkenruh.ki-partner-deutschland.de`.
- Product repos live under the `kivvo` group. Example: `kivvo/applications/web/frontend/react_frontend`. The builder finds the paths of `fastapi_backend` and `ai_gateway`.
- Tickets are GitLab work items.
- The edition (Free or Premium) is unknown. Use only Free features.

### Claude

- Team plan with four seats.
- The factory signs in with a one-year token that Kirill creates with `claude setup-token`. It goes into the masked CI variable `CLAUDE_CODE_OAUTH_TOKEN`. Every factory run counts against Kirill's seat limits.
- Do not set `ANTHROPIC_API_KEY` in the runner. It takes priority over the OAuth token.
- Do not use `--bare`. Bare mode does not read `CLAUDE_CODE_OAUTH_TOKEN`. Pass the factory settings with `--settings` instead, so a run does not depend on what is on the machine.
- The token can only make model requests. It cannot open Remote Control sessions.
- Before the factory goes live, someone sends Anthropic sales a short description of the factory and keeps the answer in writing. Anthropic's legal page invites this. If the answer is no, set `ANTHROPIC_API_KEY` instead and nothing else changes.
- The token expires after one year. Put a reminder in the team calendar.
- Do not depend on Claude Code features marked research preview or experimental, such as agent teams, routines or channels.

### Jev

- Jev is TypeSafe's decision model. It answers yes/no, choice and score questions about a JSON state in about 300 ms, with a probability for each answer.
- Use it through OpenRouter with `OPENROUTER_API_KEY`. Pin a version, for example `typesafe/jev-1.14`. Check the live model list first.
- Price: $0.042 per million input tokens, and output is free. OpenRouter adds 5.5% when you buy credits. A triage call costs about a hundredth of a cent. Check the live price before buying credits.
- Use the client from the `hyper-jev` skill in `disler/ten-levels-of-jev`. Import that skill into agent-config through `upstream/upstream.json`.
- Rules from that skill: one provider per client; never fall back to the mock without saying so; keep keys out of logs; do not use Jev for arithmetic or dates; never use Jev as the only security gate.

### Other tools

- The code reviewer is a non-Claude model through OpenRouter, run in OpenCode. agent-config already wires its skills for OpenCode.
- Chat is Microsoft Teams.
- The factory repo gets a copy of agent-config at `.agents/` with `sync.sh`, like any project. The factory uses these skills: `tdd`, `implement`, `useful-tests`, `code-review`, `diagnosing-bugs`, `playwright-cli`, and the guard hook from `global-agent-guardrails`.
- The technology behind the server logs is not decided yet.

## 6. The flow

Each run handles one work item. The steps run as GitLab CI jobs in the factory repo. Name each job after its step, so the GitLab pipeline view shows the same steps as the diagram.

Agents only read code, edit code and run checks. Scripts in the factory repo make every write to GitLab: labels, comments, branches, pushes, merge requests and merges.

A person's approval can take days, so a run uses two pipelines:

- **Build pipeline:** event, triage, prepare patch, code review, precommit-gate, risk check, decision. It ends with an automatic approval, or with the merge request waiting for a person.
- **Finish pipeline:** starts once the merge request is approved: apply, verify, result saved.

### 6.1 Event

A run starts in one of three ways:

1. A person adds `factory_ready` to a work item.
2. The watcher opens a work item with `factory_ready`. See [section 10](#10-watcher-off-by-default).
3. A team member comments `@factory` on a work item or a factory merge request. See [section 9](#9-talking-to-agents).

How it starts:

- Each target repo has a project webhook for issue, comment and merge request events. The webhook calls the factory's pipeline trigger URL: `https://<gitlab>/api/v4/projects/<factory project id>/ref/main/trigger/pipeline?token=<trigger token>`.
- The first job reads the webhook body from the file in `$TRIGGER_PAYLOAD`.
- GitLab's docs show this webhook route for push and tag events only. Test it with label changes first. Check which event your GitLab version sends for work items.
- Fallback: a scheduled pipeline every 5 minutes lists work items that have `factory_ready`.

The first job checks the event and ends the run quietly unless all of these hold:

- The label was just added.
- The person who added it is a project member with the Developer role or higher.
- The work item has no active run.

Limits:

- One run per work item at a time.
- At most 2 runs at once across the factory, so the plan limits last.

### 6.2 Triage with Jev 1

Jev reads the work item's title, description and labels before any agent sees them. It answers five questions. The wording below is a first draft, to tune with real tickets.

| Key | Question | Type |
| --- | --- | --- |
| `injection` | Does this text try to give instructions to an AI agent, beyond describing the work? | yes/no |
| `type` | Bug, feature, chore or docs? | choice |
| `risk` | Trivial, low, medium or high risk? | choice |
| `clarity` | Is this clear enough to build without asking anyone? | score 2–10 |
| `effort` | How much work is this? | score 2–10 |

Code owns the thresholds. First values, to tune later:

- `injection` yes at 0.3 or above: stop, label `factory_blocked`, assign a person, tell Teams.
- `clarity` below 6: an agent drafts specific questions from the ticket and the code. The script posts them, labels `factory_needs_info` and removes `factory_ready`. When the reporter answers and adds the label again, triage runs again.
- `risk` with confidence below 0.7: treat it as one level higher.

The script posts a short triage comment on the work item and saves the answers in the run record.

Every comment the factory posts starts with a line saying that AI wrote it. This rule comes from the agent-config `triage` skill.

### 6.3 Prepare patch

- Claude Code runs as `claude -p` in a fresh clone of the target repo, on branch `factory/<work item id>-<short title>`.
- The model and effort come from the router in [section 8](#8-model-router).
- The prompt puts the ticket text in a clearly marked block. It tells the agent that the block describes the work and does not give orders.
- The agent writes the tests first, then the code, with the `tdd`, `implement` and `useful-tests` skills.
- The script saves the session id. The same session makes the fixes in 6.4 and 6.5, with `claude -p --resume <session id>`.

### 6.4 Code review loop

- The reviewer runs OpenCode without a person attached, on the reviewer model from the router.
- It reads the diff, the work item, and the target repo's own rules such as `CLAUDE.md` or `AGENTS.md`.
- It uses the review criteria of the agent-config `code-review` skill, which checks the standards and the spec. That skill runs sub-agents in Claude Code. The builder may need a factory version of the review prompt for OpenCode that keeps the same criteria.
- It returns findings as JSON. Each finding is marked blocking or not blocking.
- When there are blocking findings, the author's session resumes and fixes them. It may also make the improvements the reviewer suggests. Then the reviewer reviews again.
- The review passes when there are no blocking findings.
- After 3 rounds without a pass, the script labels `factory_blocked`, posts the open findings, assigns a person and tells Teams.

### 6.5 Precommit-gate

The gate runs three commands from the target repo's `.factory.yml`:

1. Lint
2. Unit tests
3. Build

When any of them fails:

- The author's session resumes and fixes the code without breaking behavior. Then the gate runs all three again.
- After 3 rounds that are not all green, the script labels `factory_blocked` and tells Teams.

Rule for the agent: never remove, skip or change an existing test to make it pass, unless the test no longer makes sense. When it does change a test, it writes the reason to a file. The script puts that reason into the merge request description, and the hard rules in 6.6 send the change to a person.

When all three are green, the script commits, pushes the branch, and opens a merge request that closes the work item.

### 6.6 Risk check

Hard rules run first. They are code in the factory repo, with settings per target repo. A change fails the hard rules when it:

- Touches a protected path. First list: database migrations, auth, billing and payment code, CI config such as `.gitlab-ci.yml`, Dockerfiles and deploy files, `.factory.yml`, and agent config such as `CLAUDE.md`, `AGENTS.md`, `.claude/` and `.agents/`.
- Changes or deletes an existing test file. New test files are fine.
- Changes dependency files: package manifests and lock files.
- Changes more than 300 lines.
- Contains anything a secret scanner flags.
- Has a merge request pipeline that is not green.

Then Jev 2 reads the diff and the ticket:

| Key | Question | Type |
| --- | --- | --- |
| `diff_risk` | How risky is this change? | score 2–10 |
| `scope` | Does this diff do only what the ticket asks? | yes/no |
| `sensitive` | Does this diff touch user data, security or money? | yes/no |

First thresholds for a pass: `diff_risk` at 4 or below with confidence 0.9 or above, `scope` yes at 0.9 or above, and `sensitive` no at 0.9 or above.

### 6.7 Decision

A change merges without a person only when all four hold:

1. Jev 1 rated the ticket trivial or low.
2. The code review passed and the precommit-gate is green.
3. Every hard rule passes.
4. Jev 2 passed its thresholds.

Otherwise:

- The script labels `factory_needs_approval` and assigns the merge request to a person: the work item's assignee, or a default person from the target's config.
- It posts the reasons: which rule failed or which Jev answer missed its threshold.
- It tells Teams.

Medium and high risk tickets are still built. They always end here.

A person approves with GitLab's Approve button. The merge request "approved" webhook starts the finish pipeline. A person may also merge by hand; the finish pipeline then starts from the merge event and skips apply.

### 6.8 Apply

The script merges the merge request once its pipeline passes. It follows the target repo's squash setting.

### 6.9 Verify

- Wait for the target repo's main branch pipeline after the merge. It must pass. In `react_frontend` and `fastapi_backend` that pipeline already deploys to the shared dev environment. That deploy belongs to the repo's own CI, so it fits "no deploys" for the factory.
- A smoke test runs only when the target's `.factory.yml` names one. No target repo has one today, and writing smoke tests is not part of phase 1.
- When either fails, the script opens a revert merge request, labels `factory_blocked` and tells Teams. A person merges the revert.

### 6.10 Result saved

- A comment on the work item lists what changed, the merge request and pipeline links, the Jev answers, the models used, the number of rounds, the token use and estimated cost from the Claude Code JSON output, and the time taken.
- The script closes the work item and labels `factory_done`.
- The full run record is a pipeline artifact, kept for 90 days. It holds every Jev question and answer, the hard rule results, the agent transcripts and the reviewer findings.
- Teams gets the same summary.

## 7. Ticket states

Factory labels start with `factory_`. A work item has at most one state label at a time.

| Label | Meaning | Set by |
| --- | --- | --- |
| `factory_ready` | Start a run, or run again | A person or the watcher |
| `factory_running` | A run is active | Script |
| `factory_needs_info` | The factory asked questions on the ticket | Script |
| `factory_needs_approval` | The merge request waits for a person | Script |
| `factory_waiting` | Kirill's plan limit was hit; a scheduled job retries later | Script |
| `factory_paused` | Someone commented `stop` | Script |
| `factory_blocked` | The factory stopped and a person must look | Script |
| `factory_done` | Merged and verified | Script |

The label `factory_watcher` also marks tickets that the watcher opened.

The script removes `factory_ready` when a run starts. Adding it again means "run again".

## 8. Model router

Claude Code does not pick a model per task on its own. Its only automatic switches are `opusplan`, which plans with Opus and builds with Sonnet, and fallbacks when a model is unavailable. So the factory picks.

Jev 1's `risk` and `effort` answers select a row in `router.yml`:

| Jev 1 risk | Writes the code | Reviews the code | Can merge alone |
| --- | --- | --- | --- |
| trivial or low | `claude-sonnet-5-5`, effort medium | a smaller non-Claude model through OpenRouter | Yes, when 6.7 holds |
| medium or high | `claude-opus-5-5`, effort high | a frontier non-Claude model through OpenRouter | No |

- An `effort` score of 8 or more moves a ticket to the second row.
- Use full model IDs, not aliases, so runs repeat the same way.
- The builder picks the current reviewer model IDs on OpenRouter.
- The reviewer is never a Claude model while the author is Claude.

## 9. Talking to agents

The work item's comment thread is the one inbox. The factory posts its questions, progress and results there, and reads replies there.

### `@factory` comments

Only comments from project members with the Developer role or higher count. The factory ignores its own comments. Comment text goes through the Jev 1 `injection` question before an agent reads it.

| Where the comment is | What happens |
| --- | --- |
| Work item with no active run | Starts a run, like `factory_ready`, with the comment as extra context |
| Work item with an active run | Goes to the running agent, see below |
| Factory merge request | Starts a fix round at the code review step, with the comment as a blocking finding |

### During a run

- A `PostToolUse` hook in the factory's Claude settings checks the work item for new member comments, at most once a minute. It adds new comments to the agent's context.
- A comment that says `@factory stop` pauses the run. The hook stops the agent, and the script labels `factory_paused` and saves the session id.
- `@factory continue` resumes the saved session.

### Teams

- **Out, phase 1:** factory scripts post Adaptive Cards to a Teams Workflows webhook. The URL is a masked CI variable. Cards go out for: needs info, needs approval, blocked, done, and new watcher tickets. Do not use GitLab's built-in Teams integration. It sends the old connector card format, which Workflows webhooks may not accept.
- **In, phase 2:** a Teams outgoing webhook, which needs an @mention and signs each message with HMAC, or a Teams bot, sends messages to a small bridge. The bridge checks the signature and posts the text as a comment on the work item the message names, for example `#123`. Microsoft's servers must be able to reach the bridge. The builder picks the hosting.

### Phone

People use Teams on their phone and GitLab in the phone's browser. There is no separate app.

### Working with your own agent

Anyone can work on a ticket with their own Claude Code, on desktop, in the terminal, or in the Claude mobile app through Remote Control, with the same agent-config skills. That is normal use of each person's own seat.

## 10. Watcher, off by default

The watcher is off by default. The factory repo's docs must say so, and must list what is needed to turn it on:

- `FACTORY_WATCHER_ENABLED=true`.
- For GlitchTip: `GLITCHTIP_URL`, `GLITCHTIP_TOKEN`, and the organization and project slugs.
- For server logs: the log technology, how a runner reaches it, its credentials, and a small adapter script for it. None of this is decided yet. Until it is, the server log source stays off even when the watcher is on.

Each source is turned on by itself.

How it works:

- A scheduled pipeline runs every 10 minutes.
- For each source, it fetches error groups that are new or changed since the last run.
- Code decides from the counts whether an error is escalating, for example events in the last hour against the hourly average of the last 24 hours, or a new error after a deploy. Jev does not do this arithmetic.
- For an escalating error, Jev answers `severity` (choice: low, medium, high, critical) and `fixable` (yes/no: can a code change fix this?).
- It skips errors that already have an open work item. It matches on the GlitchTip issue id or the log fingerprint, which it stores in each work item it opens.
- It opens a work item with the evidence as quoted data: counts, first and last seen, the stack trace, and sample log lines with secrets removed. It adds `factory_watcher` and `factory_ready`, and tells Teams.
- At most 5 watcher tickets a day get `factory_ready`. After that, the watcher still opens tickets without the label and says so in Teams.
- Log text is untrusted. It goes through the Jev 1 `injection` question like any ticket text.
- Error data and log lines can hold customer data, and `react_frontend`'s AGENTS.md says anything from customer projects never touches a hosted agent. A script removes customer data before the watcher sends anything to Jev or Claude. Turning the watcher on needs the team's sign-off on what it may send.

## 11. Repos and config

- The factory repo is `kivvo/software-factory`. It holds the pipelines, the scripts, one prompt per agent step, the Jev question sets, the hard rules and router overrides per target repo, the agent-config copy, the hooks, and the docs.
- Each target repo has `.factory.yml` at its root, which the agent may not change:

  ```yaml
  lint: pnpm lint
  test: pnpm test:unit
  build: pnpm build
  smoke: pnpm test:smoke   # optional
  ```

- The factory repo has one file per target repo, `targets/<name>.yml`: the GitLab project path, protected paths, the diff size limit, the default person for approvals, and router overrides.
- To add a target repo: add the webhook, add `.factory.yml`, add `targets/<name>.yml`, and give the factory's GitLab bot access. No factory code changes.
- Order: `react_frontend` first, then `fastapi_backend` and `ai_gateway`.

Suggested layout:

```text
software-factory/
  .gitlab-ci.yml          build, finish, watcher and poller pipelines
  .agents/                agent-config copy from sync.sh
  .claude/settings.json   settings for agent runs: hooks and permissions
  factory/                one script per step, plus GitLab, Teams and Jev helpers
  prompts/                one prompt per agent step
  jev/                    question sets for Jev 1, Jev 2 and the watcher
  targets/                one file per target repo
  router.yml              the model table
  docs/                   how it works, how to add a repo, how to turn on the watcher
```

## 12. Runtime, sign-in and limits

### Runner server

The team sets up a server used only by the factory, in its own hosting. Each job runs in a fresh container, and the container is the security boundary.

| Item | Value |
| --- | --- |
| Machine | A VM used only by the factory, in the team's own EU hosting |
| Size for 2 runs at once | 8 vCPU, 32 GB RAM, 200 GB SSD |
| Smallest size | 4 vCPU, 16 GB RAM, 100 GB SSD, with 1 run at a time |
| GPU | None |
| Operating system | Ubuntu 24.04 LTS with automatic security updates |
| Software | Docker Engine, and GitLab Runner with the Docker executor |
| Container runtime | Kata Containers, so each job runs in its own small VM. It needs hardware virtualization: bare metal, or a VM with nested virtualization turned on by the hosting provider. Without it, use gVisor |
| Egress proxy | Smokescreen or Squid, with a host allow list |

Isolation comes in three layers, all open source and self-hosted:

1. **Kata Containers** runs each job in its own small VM with its own kernel, so code in a job never touches the server's kernel. GitLab Runner selects it with the `runtime` setting in `[runners.docker]`. The builder tests the exact value with the installed Docker and Kata versions. Without hardware virtualization, use gVisor instead with `runtime = "runsc"`. gVisor gives each container its own kernel in user space, and file-heavy work such as installs and builds runs slower.
2. **The egress proxy and firewall** let jobs reach only the allowed hosts. Kata does not filter traffic by host name, so this layer stays. Without it, an agent tricked by a ticket could send code anywhere.
3. **The dedicated server** holds nothing else, so the worst case is losing one server that can be rebuilt.

Optional inner layer: Claude Code's own sandbox, built on the open source `@anthropic-ai/sandbox-runtime`, runs each shell command the agent starts with limited file access and only allowed hosts. It adds little on top of Kata and more on top of gVisor. When used, set `sandbox.enabled`, `failIfUnavailable: true`, `allowUnsandboxedCommands: false` and `strictAllowlist: true`. Add `enableWeakerNestedSandbox: true` if the sandbox cannot mount `/proc` inside the job container.

Kata has no fixed limit on jobs at once. Each job's VM takes its own memory and CPU, so the server's size sets the ceiling. The factory still starts with 2 runs at once, because every run draws on Kirill's plan limits, and those usually run out before the server does.

Sandbox platforms such as E2B are built to run many sandboxes at once and are not needed here.

- Register the runner only to the factory project, with `concurrent = 2`.
- Job containers are not privileged, and the Docker socket is never mounted into a job.
- Each `targets/<name>.yml` names the job image with that repo's tools: Node and pnpm for `react_frontend`, Python for the other two. The images also hold a pinned Claude Code version, OpenCode, `glab`, `git`, `jq` and the agent-config guard hook `deny-dangerous.sh`.
- Outbound traffic goes only through an egress proxy with an allow list: the GitLab host, `api.anthropic.com`, the chosen provider for Jev and the reviewer, package registries, the container registry, the Teams webhook host, and the GlitchTip host when the watcher is on.
- The firewall blocks everything else, including the team's internal network: databases, Keycloak, and the dev and production servers.
- Inbound traffic: SSH from admin addresses only. The runner connects out to GitLab, so nothing needs to reach the server.
- The server holds no data worth a backup. The factory repo has a setup guide, so anyone can rebuild it.
- The Teams inbound bridge in phase 2 must be reachable from Microsoft's servers, so it runs somewhere else.

### Agent runs

Every Claude Code run uses these flags:

- `-p`
- `--output-format stream-json --verbose`
- `--settings <factory settings file>`
- `--permission-mode dontAsk`, set on purpose because the default mode for `-p` changed in recent versions
- `--permission-prompts none`
- `--max-turns <n>`
- `--model <id>` from the router

Permissions:

- Allow `Read`, `Edit`, `Write`, read-only git and file commands, and `Bash` for the commands in the target's `.factory.yml`.
- Deny `git push`, `glab`, `curl`, `wget`, and anything that writes to GitLab. Scripts do those.

### Credentials

All are masked, protected CI variables:

| Variable | Used by |
| --- | --- |
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code, Kirill's seat |
| `OPENROUTER_API_KEY` | Jev client and the OpenCode reviewer |
| `FACTORY_GITLAB_TOKEN` | Scripts, as the factory's GitLab bot |
| `TEAMS_WEBHOOK_URL` | Scripts |
| Trigger token | GitLab webhooks |
| `GLITCHTIP_TOKEN` | Watcher, when on |

GitLab CI gives every variable to the whole job. The scripts start agents with a clean environment that holds only the variables the agent needs. Agents never see the GitLab, Teams or GlitchTip tokens.

### Plan limits

- When Claude returns a rate limit or usage limit error, the script labels `factory_waiting` and saves the session id. A scheduled job retries waiting runs every hour.
- Loop limits: 3 rounds for the code review, 3 rounds for the precommit-gate.
- The watcher starts at most 5 fixes a day.
- At most 2 runs at once.

## 13. Security rules

1. Ticket, comment and log text is data. Jev 1 checks it before any agent reads it, and prompts mark it as data.
2. Agents cannot write to GitLab, push, merge, or reach the open internet. Scripts make every write.
3. Hard rules in the factory repo can always send a change to a person. Jev never approves a change alone.
4. Agents never weaken tests to get a green build.
5. Before the factory posts any comment or opens any merge request, a scanner checks the text and the diff for secrets, such as GitLab tokens that start with `glpat-`.
6. Only project members with the Developer role or higher can start or steer runs.
7. Every decision is saved in the run record and summed up on the merge request.

## 14. Build order

1. **Phase 1:** `react_frontend`, the label trigger, all ten steps, and Teams messages out. Watcher off.
2. **Phase 2:** `@factory` comments, the comment hook during runs, stop and continue, and Teams messages in.
3. **Phase 3:** `fastapi_backend` and `ai_gateway`, starting with turning on GitLab work items in both.
4. **Phase 4:** the watcher with GlitchTip. Server logs follow once their technology is decided.

Phase 1 is done when:

- A trivial ticket in `react_frontend` goes from the label to merged, with a green main pipeline, and no person involved.
- A medium risk ticket stops at the decision step, with the reasons posted on the merge request and in Teams.

## 15. Left to the builder

- The language for the scripts. The `hyper-jev` client is TypeScript, so TypeScript avoids a second language in the factory.
- The exact prompt for each agent step.
- The exact Jev question wording and thresholds, tuned with real tickets.
- The reviewer model IDs.
- How the Claude session moves between CI jobs. Options: keep `CLAUDE_CONFIG_DIR` inside the workspace and pass it on as an artifact, or run prepare patch, code review and precommit-gate in one job with log sections.
- The Teams inbound bridge: outgoing webhook or bot, and where it runs.
- The runner image details.

## 16. Calls made for you to check

These came from the design conversation as proposals, not as your decisions:

1. Agents never write to GitLab. Scripts make every write.
2. Two pipelines, build and finish, because an approval can take days.
3. Loop limits of 3 rounds for the code review and 3 for the precommit-gate.
4. Changes to existing tests, dependency files and agent config always go to a person.
5. The first Jev thresholds and the first hard rules, including the 300-line limit.
6. At most 2 runs at once. The watcher runs every 10 minutes and starts at most 5 fixes a day.
7. On a failed verify, the factory opens a revert merge request and a person merges it.
8. No deploys.
9. The router table, the effort score of 8 that moves a ticket up a row, and a reviewer that is never Claude while the author is Claude.
10. The label names in section 7.
11. The names `kivvo/software-factory`, `.factory.yml` and `targets/`.
12. Teams messages go out through a Workflows webhook with Adaptive Cards, not through GitLab's built-in Teams integration.
13. No research preview features.
14. Run records are kept for 90 days.
15. "Verified" means the target's main pipeline passed. Smoke tests are optional, and writing them is not part of phase 1.
16. The watcher removes customer data before it sends anything to a model.
17. The runner uses Kata Containers, or gVisor where the server has no hardware virtualization, with Smokescreen or Squid as the egress proxy. Claude Code's own sandbox inside each job is optional.

## 17. Sources

- Jev: [ten-levels-of-jev](https://github.com/disler/ten-levels-of-jev) and its `hyper-jev` skill.
- Claude Code Ultimate Guide, commit `09a68b5`: `guide/workflows/agentic-software-factories.md`, `guide/workflows/event-driven-agents.md`, `guide/workflows/monitor-event-delegation.md`, `guide/core/loop-graph-engineering.md`, `guide/security/sandbox-isolation.md`.
- Claude Code docs: [headless runs](https://code.claude.com/docs/en/headless.md), [authentication and `setup-token`](https://code.claude.com/docs/en/authentication.md), [legal and compliance](https://code.claude.com/docs/en/legal-and-compliance.md), [model config](https://code.claude.com/docs/en/model-config.md), [hooks](https://code.claude.com/docs/en/hooks.md), [permission modes](https://code.claude.com/docs/en/permission-modes.md), [GitLab CI/CD](https://code.claude.com/docs/en/gitlab-ci-cd.md).
- GitLab docs: [pipeline triggers and `TRIGGER_PAYLOAD`](https://docs.gitlab.com/ci/triggers/), [Microsoft Teams notifications](https://docs.gitlab.com/user/project/integrations/microsoft_teams/), [issue 472032](https://gitlab.com/gitlab-org/gitlab/-/issues/472032).
- OpenRouter: [TypeSafe models](https://openrouter.ai/typesafe), [pricing](https://openrouter.ai/pricing).
- Microsoft: [outgoing webhooks](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-outgoing-webhook).
