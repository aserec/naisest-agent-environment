---
name: security-audit
description: Reviews source code for vulnerabilities. Use for security questions, focused reviews, vulnerability research, security audits, or pen tests.
---

# Security Audit

Find vulnerabilities that violate a real trust boundary, then give owners the source evidence, safe reproduction, priority, and smallest effective fix. This is a defensive, source-first workflow. A candidate without a concrete affected principal, resource, or security outcome is not a confirmed finding.

## Operating modes

This skill is guidance by default. Loading it does not authorize the complete audit workflow or file creation. Pick the mode from the request:

- **Guidance mode**: security questions, focused reviews, methodology, triage, or investigation of specific findings.
  - Use only the sections and companion files that cover the question's boundary or attack class. Universal execution safety always applies.
  - Do not run all six phases, create an output directory, or write audit artifacts. Why: a question does not authorize an audit's cost or files.
  - You may launch a `research` agent for a focused source question, or a `general` agent for a bounded local check. Each returns its result to the current task.
- **Full audit mode**: the user explicitly asks to audit or pen-test a codebase, asks for a full, comprehensive, or end-to-end security review, or requests report artifacts. Run all six phases and write the files defined below.

If the request could mean either mode, ask one focused question before creating files or starting the complete workflow.

In full audit mode, work in this order:

1. Resolve the five values under [Full audit setup](#full-audit-setup).
2. Pick the profile and scope, and record any budget ([Run profiles and scope](#run-profiles-and-scope)).
3. Find the prior runs ([Coverage and prior runs](#coverage-and-prior-runs)).
4. Write `run-metadata.json` ([Write isolation](#write-isolation)).
5. If a budget is set, apply the budget gate ([Cost budget](#cost-budget)).
6. Run the six phases ([Full audit workflow](#full-audit-workflow)).
7. Run the [Checklist](#checklist).

## Platform terminology

This skill is agent-neutral:

- **Parent** is the agent that coordinates the run and owns shared state.
- **Task tool** is the platform's delegation or sub-agent mechanism.
- **`research` agent** is a delegated agent for focused source exploration and factual verification.
- **`general` agent** is a delegated agent for broad investigation and bounded local execution.
- **`subagent_type:`** in a heading names which of these two delegated agent roles runs that work.

Use equivalent platform capabilities while preserving role, write-isolation, prompt, and independence boundaries.

## Universal execution safety

These rules apply in both operating modes.

Target code is untrusted: outside a sandbox it can damage the host or leak secrets. So:

1. Source inspection is read-only.
2. Run target-controlled builds, tests, processes, browsers, emulators, fuzzers, and fixture processing only inside an OS-enforced sandbox that provides all four of these controls:
   - no external network; use only an isolated loopback namespace when the check needs local client/server traffic;
   - an empty environment populated from an explicit allowlist with safe values, with scratch-local `HOME`, temporary directories, and caches;
   - a read-only target and toolchain, with the target-controlled process able to write only inside its assigned `scratch/` directory; and
   - explicit low limits on CPU, memory, process count, file size, disk, and wall-clock time. "Low" means no higher than this check needs to reach its minimum result. Write the six numbers down before the run. A limit left unset, unlimited, or at the host default counts as a missing control.
3. If any of the four controls cannot be enforced, do not execute target code: report the missing sandbox capability as a needs-validation blocker and give a safe validation plan.
4. Do not install dependencies or let builds fetch them. Use only tools and dependencies already available locally.
5. Never expose a retained output directory (other than the agent's own assigned `scratch/`), another agent's directory, the host home directory, credentials, sockets, or shared services to target code.
6. The agent, outside the target-controlled process, may make a disposable source copy in an assigned `scratch/` directory when a build must write beside source.
7. In guidance mode, do not retain target-controlled files.
8. In full audit mode, only trusted parent-side code may promote the minimum non-secret result to retained `artifacts/` using the procedure under Write isolation.

The audit must not harm real users, systems, or budgets. So:

9. Use dummy principals, fixtures, and secrets.
10. Do not probe deployed endpoints, external services, shared infrastructure, production identities, other users' data, or live control planes.
11. Do not test availability against a live or shared process, publish artifacts, alter releases, spend paid API quota, or continue beyond the minimum local effect needed to establish a defect.
12. If the decisive fact is outside source or the sandboxed fixture, report it as needing validation.

## Full audit setup

In full audit mode, resolve these five values before reconnaissance:

- **Skill directory**: the absolute directory containing this `SKILL.md`.
- **Target**: the absolute repository root under review.
- **Repo name**: a stable repository identifier from the directory or local Git remote.
- **Output directory**: a new writable directory outside the target, defaulting to `~/security-audit-skill/<repo-name>/run-<N>`, where `<N>` is the next unused integer. Use a directory inside the target only when the user explicitly selects it and the parent verifies that version control ignores the whole directory. Otherwise stop and request an external path. Why: output inside the target can be committed with it or reached by target code.
- **Source ref**: the reviewed commit and whether the worktree is dirty. Do not treat unreviewed generated or modified files as another revision. Why: the report must name exactly the source that was reviewed.

### Write isolation

The parent creates and is the only writer of shared run files. Why: one writer keeps the ledger and the findings consistent.

- `run-metadata.json`
- `architecture.md`
- `coverage-ledger.json`
- `findings.json`
- `REPORT.md`
- `FINDINGS-DETAIL.md`
- `NEEDS-VALIDATION.md`

Each hunter or verifier receives a unique root under `<output-dir>/agents/<agent-id>/`, with separate `scratch/` and `artifacts/` directories. Canonical agent IDs match `^[a-z0-9][a-z0-9_-]{0,63}$` and must not equal a Windows device name such as `con`, `prn`, `aux`, `nul`, `com1` through `com9`, or `lpt1` through `lpt9`. Lowercase IDs prevent case-fold collisions.

Everything in `scratch/` stays target-controlled after a run. So:

- The agent and every target-controlled process may write only to `scratch/`.
- Retained `artifacts/` is parent-owned, is never exposed to the sandbox, and is writable only by trusted parent-side promotion code.
- Agents may not change shared files, target source, retained artifacts, or another agent's directory.
- Do not use `/tmp` or the host home directory as a writable fallback.

Promotion moves a scratch file into `artifacts/`. Why each check below: a scratch file can be a link, a device, or a file swapped during the copy.

- Before execution, the parent opens and retains trusted, non-inheritable directory descriptors for the agent's `scratch/` and `artifacts/` roots.
- Before execution, the parent records an allowlist of expected scratch-relative artifact files plus explicit per-file and cumulative byte limits.
- Never pass those descriptors to the agent or sandbox.
- After the sandbox and all its processes terminate, trusted parent-side code promotes each allowlisted file separately:

1. Validate the declared relative path: reject absolute, empty, `.`, `..`, or symlinked components.
2. Walk each parent component from the retained scratch-root descriptor with no-follow directory-relative operations; never reopen by path.
3. Open the leaf no-follow and nonblocking.
4. Verify with `fstat` that it is a regular file with link count exactly one and within the recorded per-file and cumulative byte limits.
5. Enforce those limits again while reading from that descriptor.
6. Copy exactly the verified size, repeat `fstat`, and reject a changed identity, type, link count, or size.
7. For the destination, walk every parent component from the retained artifacts-root descriptor with no-follow directory-relative operations; require each existing component to be a real directory, and create any missing directory exclusively before reopening and verifying it no-follow.
8. Create the leaf exclusively without following links, verify that the opened destination is a regular file with link count exactly one, and copy from the verified source descriptor without reopening either path.
9. Use equivalent race-safe APIs on non-POSIX systems.
10. Never recursively copy or glob scratch, extract an archive into artifacts, or open or promote a symlink, FIFO, socket, device, directory, hard-linked file, changing file, or file that exceeds its bound.
11. If any check is unavailable, cannot be enforced, or fails, discard the scratch entry; if it is decisive evidence, retain `needs_validation` with the exact promotion blocker.

[HUNTING.md](HUNTING.md) and [VALIDATION-AND-REPORTING.md](VALIDATION-AND-REPORTING.md) carry this procedure as one identical fenced block for hunter and verifier prompts; it states the same rules in the same order as this list.

For a reproduced check:

- Record the command, exact test input, sandbox limits, and only the allowlisted environment variable names plus safe non-secret values needed to reproduce it.
- Never capture or copy the ambient environment, inherited variables, credential values, authentication state, or unrelated host paths. Why: a captured environment can carry secrets into the report.
- Launch from an empty environment rather than trying to redact one after execution.

Before delegation, the parent writes `run-metadata.json` with at least `run_id`, `repo`, `target`, `source_ref`, `profile`, `scope_paths`, `budget` (null if unset), `execution_policy: "sandboxed-source-and-local-only"`, selected companion files, prior-run paths, shared-file owners, and `run_status: "in_progress"`. Update metadata only when those facts change; candidate state belongs in the coverage ledger and `findings.json`.

## Full audit planning

The coverage, prior-run, profile, and budget requirements in this section apply only in full audit mode.

### Coverage and prior runs

No one pass is complete. Build a deterministic coverage plan before hunting and update it after every agent result. [RECONNAISSANCE.md](RECONNAISSANCE.md) defines the stable coverage units and [HUNTING.md](HUNTING.md) defines coverage-critic waves. The parent alone updates the ledger.

If prior runs exist, read every compatible `coverage-ledger.json` and `findings.json` before planning the current run. Why: a prior verdict holds only for the source it was checked against.

1. Compare the relevant current source with each prior record and unit. A prior source ref alone is not evidence that a path is unchanged.
2. **Prior `confirmed`, source unchanged.** Carry the record into the current candidate set only when its relevant source and conditions are unchanged and its evidence still meets the current contract. Then:
   1. Link it to a current ledger unit seeded `planned`.
   2. Preserve its fingerprint.
   3. Exclude only that carried root cause from hunters.
   4. Send the carried record through the current final verification path.
   5. The Phase 3 verifier that re-checks it becomes that unit's assignment owner and moves it to `candidate`.
3. **Prior `confirmed`, source changed.** Create a current planned revalidation unit. Do not put that record on the hunter exclusion list. It remains confirmed only if current independent validation establishes the current path and result.
4. **Prior `needs_validation`, `deferred`, `blocked`, `out_of_scope`, and any changed-source unit.** Make each one current work. These prior states never suppress a current unit.
5. **Still-external `needs_validation` record.** It may be carried only after the current source trace is checked and linked by fingerprint to a current `planned` unit whose verifier re-check supplies its owner and evidence. The record keeps the unresolved blocker.
6. **Prior same-source covered unit.** It may inform priority, but it remains visible in the current ledger.
7. **Prior `rejected` record.** It suppresses only the unchanged failed claim, not coverage of its unit. Changed evidence creates current work.
8. Read the prior profile and scope. A prior `quick` or scoped ledger contributes only its recorded evidence and gaps, never an implied "rest is fine."

If no prior ledger exists, say so in the final coverage statement. Never imply that one run exhausts the target.

### Run profiles and scope

During full audit setup, pick the profile in this order:

1. The request names a profile, or asks for what one profile is for (a fast first look is `quick`): use that profile.
2. Otherwise use `standard`, the default.
3. To use `quick` or `deep` where the request does not ask for it, propose it to the user with the fact behind it: the number of in-scope source files, a prior run, or the resources at stake. Switch only when the user agrees. Why: this skill sets no size or stakes threshold, so the user decides.

Record the profile in `run-metadata.json` (`profile`, `scope_paths`) and state it in the report.

- **`quick`** — a bounded pass for small targets, re-runs, or a fast first look.
  - Coarsen ledger units to surface × boundary × attack class (subsystem uses the fixed canonical `profile/quick/all-in-scope-subsystems` identifier).
  - Run exactly one hunter wave followed by exactly one final coverage-critic pass.
  - Use one fresh verifier per candidate for both candidate validation and final record verification.
  - Do not launch a follow-up hunter wave: record the critic's accepted discoveries and reassignments as `deferred`.
- **`standard`** — the workflow as written.
- **`deep`** — for high-stakes or large targets.
  - Split ledger units per subsystem and lifecycle mode.
  - Run critic waves to a clean pass.
  - Keep candidate validation and final record verification as separate fresh agents.
  - Give `prior_covered_same_source` units an independent second pass.

A **scoped run** audits a subset: named paths, one subsystem, one companion domain, or the diff between two source refs. Seed ledger units only for in-scope surfaces and record everything else as `out_of_scope` — never as `covered`. A scoped or `quick` run must present itself as partial coverage. Why: a surface nobody reviewed must not read as reviewed.

Profiles change breadth and redundancy, never the evidence bar. Do not scale away the candidate gate, the source/local execution boundary, `needs_validation` discipline, schema validation, or independent verification of `confirmed` records.

#### Cost budget

The ledger makes spend countable: one unit is roughly one hunter assignment, and one surviving candidate is one verifier assignment in `quick` and two in `standard` or `deep`. When the user sets a budget, or the parent proposes one, record `budget` in `run-metadata.json` as a maximum number of agent invocations across all phases.

**Budget gate.** Apply the strict budget gate before launching any reconnaissance agent:

1. Reserve the four baseline reconnaissance calls.
2. Reserve the critics: one final post-wave critic for `quick`, or one post-wave plus one distinct final-clean critic for `standard`/`deep`.
3. Reserve at least one verifier call. The minimum is then 6 invocations for `quick` and 7 for `standard`/`deep`.
4. If the requested budget cannot fund that minimum, launch no agent: ask for a larger budget, narrower scope, or different profile.
5. If the request remains unchanged, set `run_status: "incomplete"` with `incomplete_reason: "budget_cannot_fund_reconnaissance_and_reserves"` and report that no audit pass ran.
6. Add focused reconnaissance only after repeating this gate for each extra call.

Spend it in this order:

1. Count reconnaissance, every post-wave critic, and the separate final-clean critic as agent invocations.
2. **Reserve critics and validation before hunting.** Never assign hunters into either reserve.
   - `quick`: reserve its one post-wave final critic.
   - `standard` or `deep`: before every hunter wave, reserve one immediate post-wave critic plus one distinct final-clean critic.
   - Reserve verifier cost from the profile: 1 agent per expected candidate in `quick`, 2 in `standard` or `deep`. When you have no estimate of the candidate count, reserve 30% of the balance after critic reservation.
3. Assign hunters to units in priority order until the hunting allowance is spent. Spend the reserved post-wave critic immediately after that wave; keep the final-clean and validation reserves intact.
4. Before a later wave, reserve its new post-wave critic again. If the remaining budget cannot cover the required critic calls and validation reserve, launch no hunters from that wave, mark its planned units `deferred` with reason `budget_cannot_reserve_critics_and_validation`, and use the retained final-clean critic to record the resulting gap.

Before wave 1:

1. Update the pre-recon estimate with seeded units, implied hunter count, mandatory critic calls, validation reserve, and whether the remaining budget covers the plan.
2. If the remaining budget is below that plan, say so and propose either a tighter scope or a coarser profile instead of silently thinning evidence.
3. If later facts consume the required final-critic reserve, launch no hunters, mark all planned work deferred, set the run incomplete with reason `critic_budget_exhausted`, and make no complete-coverage claim.

**Incomplete-run rule.** A strict total-agent budget can still be exceeded by a candidate set larger than the validation reserve or by a material Phase 5 replacement that needs another independent verifier. If the remaining budget cannot validate every candidate:

1. Stop hunting.
2. Validate candidates in fingerprint order while the budget permits.
3. Set `run_status: "incomplete"` plus `incomplete_reason: "validation_budget_exhausted"`.
4. Keep each unvalidated fingerprint linked to a `candidate` ledger unit with that unresolved reason.
5. Do not put an unvalidated candidate in `findings.json`, relabel it `needs_validation`, or report the run as complete. Why: an unvalidated candidate is not a finding.
6. Phase 6 may produce a partial report only if its first section states that candidate validation is incomplete and lists the affected fingerprints and units.

Never exceed a user-set strict budget silently.

## Core principles

### Require a boundary and result

For every candidate, name the lower-trust principal, accepted input or action, intended control, crossed boundary, affected principal or resource, and concrete observed or owner-observable result. Do not elevate a missing best practice, guessed deployment behavior, generic parser crash, or self-impact into a security finding. Why: without all six there is no victim and no damage to report.

### Use bounded local evidence

Static analysis establishes the source path. Sandboxed local tests resolve behavior when all execution controls are available: a minimal function harness, existing unit test, small parser fixture, dummy-tenant integration test, locally rendered configuration, or bounded isolated-loopback client. Stop at a wrong return value, unauthorized dummy record, sanitizer finding, policy difference, or other minimum effect. Do not extend the local check beyond the minimum boundary result or produce persistence, post-fault, or concealment material. Why: local execution confirms a defect; it does not expand impact.

### Respect source visibility

Deployment controls, proxy behavior, provider settings, browser headers, identity policy, broker ACLs, packaging, and topology are real controls. If they are required and absent from the repository, do not assume either presence or absence. Use `needs_validation` with the exact missing fact and a safe owner-observed or local plan.

### Separate priority from certainty

Only `confirmed` records receive severity. Likelihood and impact must reflect the demonstrated conditions and result; overall severity cannot exceed demonstrated impact. `needs_validation` means a specific source-grounded boundary hypothesis is blocked, not a low-confidence confirmed vulnerability, and it has no severity.

Calibrate overall severity with these anchors:

- **critical** — an unauthenticated actor gains code execution, full data-store access, or takeover of arbitrary accounts.
- **high** — an actor fully defeats an explicit security control with real consequences: authentication bypass, cross-tenant read or write, stored script execution affecting other users, authenticated code execution, or an unauthenticated remote stop of a shared service.
- **medium** — a real boundary violation with limited blast radius, uncommon preconditions, or consequences confined to a narrow resource set.
- **low** — disclosure of non-secret internals, or an effect requiring sustained effort for minimal gain.
- **informational** — a confirmed but minimal-impact observation, useful mainly as a prerequisite inside a larger finding.

The high/medium discriminator: does the demonstrated result fully defeat an explicit control for an action with real consequences, or only weaken it? If you cannot state the concrete damage, rate it at least one level below your first estimate.

### Recommend the smallest effective source fix

For each confirmed finding, identify the invariant the code must enforce and the narrowest source change that enforces it at the last trusted decision point. Prefer specific repository-relative changes and regression tests over generic hardening advice. The audit describes fixes; it does not modify target source.

## Full audit workflow

In full audit mode, follow all six phases in order:

1. **Reconnaissance** — map the source, trust boundaries, local build paths, companion selections, prior evidence, and initial deterministic coverage ledger with [RECONNAISSANCE.md](RECONNAISSANCE.md).
2. **Coverage-led hunting waves** — assign isolated hunters from the ledger and collect structured candidate results with [HUNTING.md](HUNTING.md), [ATTACK-CLASSES.md](ATTACK-CLASSES.md), and the selected domain companions.
3. **Candidate validation** — consolidate fingerprints and give every candidate to a fresh source verifier as defined in [VALIDATION-AND-REPORTING.md](VALIDATION-AND-REPORTING.md).
4. **Structured output** — write all final `confirmed`, `needs_validation`, and `rejected` records to `findings.json`; validate it with `report-schema.json` and `validate-findings.cjs`, and validate the coverage claim with `validate-coverage-ledger.cjs`.
5. **Independent record verification** — use fresh agents to verify final source claims and reconcile corrections or state changes.
6. **Target-neutral report** — derive `REPORT.md`, `FINDINGS-DETAIL.md`, and `NEEDS-VALIDATION.md` from the final records, with no live-probe instructions.

Do not end the run before one of exactly two terminal states: (a) all Phase 6 artifacts are written and both validators pass, or (b) `run_status: "incomplete"` is recorded with its exact reason and the gap is disclosed in the report. Never stop mid-phase. Why: a run that stops anywhere else leaves candidates without a verdict.

## Anti-patterns

Each line ends with the rule it breaks.

1. Checklist deviations presented as vulnerabilities. Breaks: boundary and result.
2. Defense-in-depth advice with no reachable boundary violation. Breaks: boundary and result.
3. Live or shared-environment testing where bounded local evidence is insufficient. Breaks: execution safety; use `needs_validation`.
4. Guessing provider, proxy, browser, identity, or deployment behavior not present in source. Breaks: source visibility.
5. Treating intended same-principal authority or self-impact as a cross-boundary result. Breaks: boundary and result.
6. Reporting a parser or runtime effect stronger than the observed effect. Breaks: severity cannot exceed demonstrated impact.
7. Emitting prose-only hunter results that cannot be deduplicated or verified.
8. Re-reporting carried same-source prior confirmed records or using them as exemplars that anchor the hunt. Breaks: prior-run rule 2.
9. Assigning severity to `needs_validation` records. Breaks: only `confirmed` records receive severity.
10. Writing the report before independent verification or letting prose and JSON disagree. Breaks: Phase 6 derives the report from verified records.

## Example

One finished `findings.json` with one `confirmed` record, and the validator's answer. The record is the `confirmed()` fixture of `validate-findings.test.cjs`.

```json
[
  {
    "verdict": "confirmed",
    "fingerprint": "src-handler-missing-check",
    "title": "Missing ownership check",
    "description": "An attacker can reach an operation without the intended ownership check.",
    "root_cause": "handle omits the ownership check before changing the object.",
    "intended_behavior": "Only the object's owner can change it.",
    "trace": [
      {"kind": "entrypoint", "file": "src/handler.c", "line": 10, "scope": "handle", "description": "Attacker data reaches the operation."},
      {"kind": "propagation", "file": "src/model.c", "line": 20, "scope": "handle", "description": "Attacker data reaches the operation."},
      {"kind": "sink", "file": "src/store.c", "line": 30, "scope": "handle", "description": "Attacker data reaches the operation."}
    ],
    "evidence": [
      {"file": "src/handler.c", "line": 10, "description": "The source performs the operation without the required check."}
    ],
    "conditions": [],
    "execution": {
      "attacker_perspective": "An unprivileged remote user with their own account.",
      "payloads": ["An object identifier owned by another user."],
      "instructions": ["Submit the identifier through the public operation."],
      "observed_result": "The other user's object changes."
    },
    "remediation": {"strategy": "Check ownership before the state change."},
    "severity": {
      "likelihood": {"score": "medium", "reason": "The operation is directly reachable."},
      "impact": {"score": "medium", "reason": "The attacker changes one protected object."},
      "overall_severity": "medium"
    },
    "confidence": {"score": "high", "reason": "The source path and result were reproduced."}
  }
]
```

```text
$ node <skill-dir>/validate-findings.cjs <output-dir>/findings.json
PASS: 1 findings valid
```

## Checklist

Run this before you say the work is done.

Both modes:

- [ ] No target code ran outside a sandbox with all four controls. Each missing control is reported as a needs-validation blocker with a safe validation plan.
- [ ] Nothing deployed, external, shared, or paid was contacted, and no dependency was installed or fetched.
- [ ] Every finding called confirmed names all six items of "Require a boundary and result".
- [ ] Only `confirmed` findings have a severity, and no severity is above the demonstrated impact.
- [ ] No reported item matches one of the 10 anti-patterns.

Guidance mode:

- [ ] No output directory and no audit artifact was created, and no target-controlled file was kept.

Full audit mode:

- [ ] The output directory is outside the target, or the user selected it and version control ignores all of it.
- [ ] The run is in one of the two terminal states: (a) the three Phase 6 files are written and both validators print `PASS`, or (b) `run-metadata.json` has `run_status: "incomplete"` with its exact reason and the report discloses the gap.
- [ ] `findings.json` holds no unvalidated candidate.
- [ ] The report states the profile and scope, says so if no prior ledger existed, and calls a `quick` or scoped run partial coverage.
- [ ] Agent invocations stayed within the budget, or the report says where they did not.
