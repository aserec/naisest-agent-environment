---
name: graft
description: Get code context from the repo's graft index. Use when the repo has a graft/ folder, for any task, before grepping or reading source files.
---

# graft

## Purpose

Use this skill for ANY task in a repo that has a `graft/` index: understanding
how a part works, finding where code lives, tracing what calls a symbol or what
a change breaks, or scoping an edit. Get the context from graft before grepping
or reading source files.

`graft/` holds a graph of this repo: small markdown nodes that each explain one
part in prose and name the exact `file:line` spans they cover, plus a wiring
graph of who-calls-what. Querying a node costs a few hundred tokens; rebuilding
that understanding by reading source costs thousands, and misses the edges.

Every command below is `$0`, needs no API key, and returns in under a second.

The work is done when every item in the [Checklist](#checklist) at the end of
this file holds.

## Instructions

### 1. Check that the index exists

Look for a `graft/` directory at the repo root. If there is none, run
`graft build` once. If the `graft` command is not installed, skip this skill.

Done when `graft/` exists at the repo root, or the skill is skipped.

### 2. Pick one command

Find the row of [Scenarios](#scenarios-the-shortest-path-through-a-coding-task)
that names the task, and take its command. When no row names it, take
`graft ask "<question>" --source`, the default. When the task already names
the file or symbol to change, the row is "Editing a symbol you can already
name": an `ask` round-trip is wasted on a target you can already name. The
flags of each command are under [The tools](#the-tools).

Why one: most tasks need one call; chaining tools hoping for more adds calls,
not context.

Done when you have one command to run.

### 3. Run it whole

Run the command. **Never pipe a graft command through `head`, `tail`, or
`sed -n`.** Every tool is already capped and states what it dropped. Why:
clipping loses hits you asked for and the savings line the statusline parses.

Done when the full output is in the session.

### 4. Act on the answer

Cite or edit at the `file:line` spans that graft printed. A node's `covers:`
list already gives exact `file:line` for every symbol, so cite straight from
it. Do not re-open or re-grep files to "double-check". Why: the spans are
generated from source and authoritative.

Make another graft call only when the Scenarios row lists one, or when a case
under [Troubleshooting](#troubleshooting) applies. In every other case, trust
the answer and act.

Done when the reply or the edit uses spans from the output, and every call
after the first has one of those two reasons.

### 5. Close the reply with the savings tally

Each retrieval tool **opens** its output with a `[graft] tokens saved ≈ N` line:
the estimated tokens that call saved versus reading the files it covers whole.
In every turn where you used any graft tool:

1. Sum N across every graft call you made. A call with no such line (tiny
   files, where the pointers cost as much as the source) saved nothing, so
   skip it.
2. Close your reply with a one-line tally, e.g.
   `🌱 graft saved ~12,400 tokens this turn (3 calls)`.
3. Once a turn has been billed, each line also states what that call was worth
   in dollars, at the rate this session is actually paying for input tokens.
   Include that total alongside the tokens, e.g.
   `🌱 graft saved ~12,400 tokens (~$0.04) this turn`. When a line carries no
   dollar figure, report tokens alone. Why: a price you work out yourself is a
   guess, not what the session paid.

This is the per-turn figure; the statusline carries the running session total.

Done when the tally is the last line of the reply, or no call of the turn
printed a savings line.

### 6. Run the checklist

Run the [Checklist](#checklist) at the end of this file. Fix every item that
fails, then run it again.

Done when every item holds.

## Examples

### One call answers

A real run in the agent-config repo on 2026-11-17. The numbers differ in every
run.

```text
Task. "Which provider key does jev use first?"

Step 1. graft/ exists at the repo root.
Step 2. Scenarios row "Understanding a flow": graft ask "<flow>" --source
Step 3. Ran: graft ask "which provider key does jev use first" --source
        The output opens with:
          [graft] tokens saved ≈ 169,588 (99%) — this pack ≈ 1,067 tok vs reading the 8 source file(s) whole ≈ 170,655 tok.
        The same line says: This call is worth $0.35
        Hit 1 of 8 is:
          1. selectProvider · function  [symbol]
             jev/core/client.ts:L250-L264
        with the code of that function under it.
Step 4. Hit 1 holds the answer, so there is no second call.
Step 5. The reply:

  jev uses the first key that is set, in this order: CELERIS_API_KEY,
  BERGET_API_KEY, TYPESAFE_API_KEY, OPENROUTER_API_KEY. JEV_BACKEND overrides
  the order. See selectProvider, jev/core/client.ts:L250-L264.

  🌱 graft saved ~169,588 tokens (~$0.35) this turn (1 call)
```

## Prerequisites

The `graft` command on the PATH. No API key.

When the graft MCP server is connected, these are exposed as tools too:
`graft_find_code` (ask), `graft_find_all` (grep), `graft_file_api` (skeleton),
`graft_trace_calls` (callers, with `direction` / `depth`), `graft_repo_map`
(map), `graft_check_freshness` (check). Use whichever surface is available; the
guidance is identical.

## Limitations

- Raw `grep -rn` is only for files graft doesn't index (docs, configs,
  brand-new files).
- You may also grep / ls / cat inside `graft/` directly (plain markdown;
  `graft/INDEX.md` indexes the nodes), but the tools are faster and
  `graft grep` is exhaustive, so reach for them first. Those cards are a projection,
  rebuilt at the end of the turn rather than on each query, so after an edit
  they can lag. The tools never do. Treat a card's spans as stale if you have
  edited that file this turn.

## Troubleshooting

These are the only cases for a graft call after the first one.

| What you see | What to do |
|---|---|
| A `graft ask` gives few or weak hits: graft prints `only N hits`, or no hit names the symbol or behaviour you asked about | Switch tool (grep / skeleton / callers). Do not re-ask the question reworded. Why: a reworded ask is another ranked guess; grep is exhaustive and callers is exact. |
| The question has several distinct parts | One ask per distinct part, never the same question reworded. |
| You need every occurrence | `graft grep "<literal>"`. |
| The crux does not show the lines the task needs | Run the same ask again with `--full`. |
| A span is truncated ("+N more lines") | Open the file at that exact range. |
| A node lacks a detail | Ask a more specific question. Only then read source at the exact `file:line`, never a whole file to rebuild understanding graft gives. |
| A `graft grep` finds no hits | **Loosen it** (drop the receiver and signature, keep the bare name) and retry `graft grep`. Do NOT switch to raw `grep -rn`, which is slower and unranked. |
| graft names a path that isn't on disk | Its index is ahead of your checkout (a branch switch or unpulled move). Don't read the missing file. `graft grep` the symbol to find where it lives now, or run `graft build` to refresh. |

## The tools

There are six of them.

### 1 · `graft ask "<question>" --source`: locate + understand (the default)
Ranked retrieval over the graph, routed automatically between prose nodes and
the wiring graph, returning the top hits with exact `file:line`.
- `--source` inlines the code at each hit, the ≤8-line **crux** of each
  definition, so the result IS the code you need, no follow-up file read.
  `--full` inlines whole definitions instead of the crux.
- `--in <path>` narrows to a subtree before ranking; `-n N` caps results (default 8).
- **Use it when** the question is conceptual or locational: "how does auth
  work", "where is rate-limiting handled", "what assembles the request pipeline".

### 2 · `graft grep "<pattern>"`: exhaustive find
Regex (or `--fixed` for a literal) over every indexed file, hits **grouped by
enclosing symbol** and ranked by coupling; it also reports files it couldn't read.
- **Use it when** you need every occurrence: all call sites, all uses of a
  constant, all providers. `ask` is ranked top-N and *will* miss instances;
  grep won't. One grep replaces a spray of asks.
- Search a **short symbol name or literal**, not a full guessed signature: an
  over-specific regex (`func (s *Server) GenerateHandler`) returns nothing even
  when the code is indexed.
- `-i` case-insensitive; `--in <path>` scopes to a subtree.

### 3 · `graft skeleton <file>`: a file's API at a glance
Signatures-only view of one file (every function / method / type with its span)
in ~200 tokens, ~10x cheaper than reading the file.
- **Use it when** you need "what's in this file / what can I call here" before
  editing or wiring into it. One skeleton is the whole answer for a file; don't
  re-skeleton the same file, and don't skeleton every file `map` already named.

### 4 · `graft callers <symbol>`: the exact edges
Precomputed call/reference edges, not a text search. Symbol can be bare
(`Foo`), qualified (`Class.method`), or package-qualified (`pkg.Fn`).
- default `--direction in`: **who calls/references** this; run before you
  rename, delete, or change its signature.
- `--direction out`: **what this symbol itself calls/depends on** (the old `callees`).
- `--depth N`: walk transitively N hops for the **full blast radius** (the old
  `impact`); `--depth 2` is the usual "what breaks if I touch this".
- `--depth all`: the **entire connected closure** — every source reachable
  through the edges. Reach for this before a **refactor, rename, or any
  multi-file change**: it surfaces the sibling and downstream files (platform
  variants, a module you must split out) that a single-file edit would miss.

### 5 · `graft map`: orientation for an unfamiliar repo or area
A token-budgeted tour: directory clusters, per-directory hubs, and global
hotspots, straight from the wiring graph.
- **Use it when** you land in a repo cold or are asked for "the architecture".
  `map` alone is the answer: read the hub cards it names; do NOT then skeleton
  or ask your way through every subsystem it lists. `--max-dirs N` widens it.

### 6 · Lifecycle: `graft build` / `graft check`
Every tool above refreshes the graph itself before answering, so what those tools
return always describes the code as it is right now — including edits you just made
and have not committed. You do **not** need to run `build` after editing.

`build` is for the LLM layer (`--deep` adds a concept map; skip unless asked);
`check` fails when `graft/` is stale, for CI.

## Scenarios: the shortest path through a coding task

| When you're… | Reach for | Calls |
|---|---|---|
| Onboarding / "explain this codebase" | `graft map`, then read the named hub cards | 1 |
| Understanding a flow ("how does X work") | `graft ask "<flow>" --source` | 1 |
| Finding where a change belongs | `graft ask "where is <behavior>" --source` | 1 |
| Editing a symbol you can already name | `graft grep "<symbol>"`, edit at the `file:line` (skip `ask` — you know where it is) | 1 |
| Renaming / deleting / changing a signature | `graft callers <sym> --depth 2` first | 1 |
| Refactor / multi-file change (before editing) | `graft callers <sym> --depth all` — map every connected file, don't stop at the first | 1 |
| "What does this depend on?" | `graft callers <sym> --direction out` | 1 |
| Finding every occurrence of a pattern | `graft grep "<literal>"` | 1 |
| "What's the API of this file?" | `graft skeleton <file>` | 1 |
| Debugging a failure in area X | `graft ask "<symptom>" --source`, then `callers` on the suspect | 1–2 |
| Judging a diff's risk before merge | `graft callers <changed sym> --depth 2` | 1 / symbol |
| Working inside one repo of a monorepo | add `--in <scope>/` to ask / grep / callers | n/a |

In a multi-repo workspace, graft ranks fairly so the biggest repo can't drown
the rest, and every hit carries a `[scope/]` label naming its sub-project; when
you already know where you're working, narrow with `graft ask "<task>" --in <scope>/`.

## Checklist

Run this before you say the work is done.

- [ ] `graft/` exists at the repo root, or the skill was skipped because `graft` is not installed.
- [ ] The first command came from the Scenarios row that names the task, or was `graft ask "<question>" --source` when no row named it.
- [ ] Every graft call after the first is listed in that Scenarios row or matches a case under Troubleshooting.
- [ ] No graft command was piped through `head`, `tail`, or `sed -n`.
- [ ] Source was read only at an exact `file:line` range that graft printed, or in a file graft does not index.
- [ ] The reply ends with the tally line: tokens summed over the turn's graft calls, with dollars only when graft printed them.
