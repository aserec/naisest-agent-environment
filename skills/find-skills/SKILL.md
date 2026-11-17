---
name: find-skills
description: Find, check and install agent skills from skills.sh. Use when the user asks how to do X, asks for a skill for X, or wants to extend the agent.
---

# Find Skills

## Purpose

Use this skill when the user asks "how do I do X", "find a skill for X" or "is there a skill that can...", or wants to extend what the agent can do. It finds a skill in the open agent skills ecosystem, checks its install count, source and stars, presents it, and installs it after the user says yes.

The work is done when every item in the [Checklist](#checklist) at the end of this file holds.

## Instructions

### 1. Understand what they need

Write down three things:

1. The domain (e.g., React, testing, design, deployment)
2. The specific task (e.g., writing tests, creating animations, reviewing PRs)
3. A keyword query made of the two, such as `react performance`

Done when all three are written.

### 2. Check the leaderboard first

Open the [skills.sh leaderboard](https://skills.sh/). Take the highest-ranked skill whose name or source contains the domain as the candidate. Why first: the leaderboard ranks skills by total installs, so the most-installed one needs no search.

For example, top skills for web development include:
- `vercel-labs/agent-skills` — React, Next.js, web design (100K+ installs each)
- `anthropics/skills` — Frontend design, document processing (100K+ installs)

Done when you have one candidate (go to step 4), or the leaderboard has none or cannot be opened (go to step 3).

### 3. Search for skills

Run the find command with the query from step 1:

```bash
npx skills find [query] [--owner <owner>]
```

For example:

- User asks "how do I make my React app faster?" → `npx skills find react performance`
- User asks "can you help me with PR reviews?" → `npx skills find pr review`
- User asks "I need to create a changelog" → `npx skills find changelog`

Each result is a line `<owner/repo@skill> <N> installs` with its skills.sh link on the next line. Keep at most 3 results as candidates: those whose skill name (the part after `@`) contains a word of the query, highest install count first. Why 3: a search can print 100 results, and each candidate costs a page read.

Done when you have 1 to 3 candidates, or no skill name contains a word of the query (go to [When No Skills Are Found](#when-no-skills-are-found)).

### 4. Verify quality before recommending

**Do not recommend a skill based solely on search results.** Why: search matches keywords, not quality, and anyone can publish a skill.

Open the skills.sh page of each candidate, `https://skills.sh/<owner>/<repo>/<skill>`, and read four values:

1. **Description** — what the skill does.
2. **Install count** — `Installs` on the page.
3. **Source reputation** — the `<owner>`. Official sources are the owners listed at `https://skills.sh/official`, such as `vercel-labs`, `anthropics`, `microsoft`.
4. **GitHub stars** — `GitHub Stars` on the page: the star count of the source repository.

Write `not checked` for a value you cannot read. Why: an estimated count reads like a checked one.

Drop each candidate whose description was read and does not name both the domain and the task from step 1. Why: a name can match one word and be about another subject.

Done when every candidate left has its four values. When none is left, run step 3 if it has not run yet; otherwise go to [When No Skills Are Found](#when-no-skills-are-found).

### 5. Order the candidates and mark warnings

Apply these rules in order:

1. Put candidates with 1K+ installs before the others. Why: more installs mean more people have already run the skill.
2. Within each group, put official sources first. Why: they are the companies that build the technology the skill covers.
3. Mark a warning on each candidate with under 100 installs, or from a repository with under 100 stars. Why: too few people have run the skill or read its source.

Done when the candidates are in order and each one under 100 installs or 100 stars has a warning.

### 6. Present options to the user

Present the candidates in the order from step 5. For each one, give:

1. The skill name and what it does, from the description on its skills.sh page
2. The install count and source
3. The install command they can run
4. A link to learn more at skills.sh
5. Its warning from step 5, with the number, such as `Warning: 26 installs.`

End the reply with an offer to install.

Done when the reply has items 1 to 4 for every candidate, every warning, and the offer.

### 7. Install after the user says yes

If the user wants to proceed, install the skill for them:

```bash
npx skills add <owner/repo@skill> -g -y
```

The `-g` flag installs globally (user-level) and `-y` skips confirmation prompts. Run it only after the user says yes. Why: with `-y` the CLI asks nothing, so the user's yes is the only confirmation.

Then run `npx skills list -g`.

Done when that list shows the skill, or the user declined and nothing was installed.

### 8. Run the checklist

Run the [Checklist](#checklist) at the end of this file. Fix every item that fails, then run it again.

Done when every item holds.

## When No Skills Are Found

When steps 2 to 4 leave no candidate:

1. Acknowledge that no existing skill was found
2. Offer to help with the task directly using your general capabilities
3. Suggest the user could create their own skill with `npx skills init`

## Examples

Both examples are real runs from 2026-11-17. Counts change, so read them again in every run.

### A skill is found

```text
Input. The user asks: "how do I make my React app faster?"

Step 1. Domain: React. Task: performance. Query: react performance.
Step 2. The highest-ranked leaderboard skill with "react" in its name is
        vercel-react-best-practices (row 57), from vercel-labs/agent-skills.
        It is the candidate, so step 3 is skipped.
Step 4. Description: "React and Next.js performance optimization guidelines
        from Vercel Engineering." It names React and performance.
        Installs: 906.0K. Source: vercel-labs. GitHub Stars: 34.2K.
Step 5. One candidate: 1K+ installs, official source. Rule 3 does not apply.
Step 6. The reply:

  I found a skill that might help! The "vercel-react-best-practices" skill provides
  React and Next.js performance optimization guidelines from Vercel Engineering.
  (906K installs, source vercel-labs/agent-skills)

  To install it:
  npx skills add vercel-labs/agent-skills@vercel-react-best-practices

  Learn more: https://skills.sh/vercel-labs/agent-skills/vercel-react-best-practices

  Want me to install it for you?
```

### No skill is found

```text
Input. The user asks: "is there a skill that can help with carillon bell-ringing?"

Step 1. Domain: carillon. Task: bell-ringing. Query: carillon bellringing.
Step 2. No leaderboard skill has "carillon" in its name or source.
Step 3. npx skills find carillon bellringing prints:
          No skills matched every term in "carillon bellringing". Partial matches:
        and 25 results. No skill name contains carillon or bellringing.
The reply:

  I searched for skills related to "carillon bellringing" but didn't find any matches.
  I can still help you with this task directly! Would you like me to proceed?

  If this is something you do often, you could create your own skill:
  npx skills init my-carillon-skill
```

## Prerequisites

`npx` (Node.js) and network access to `skills.sh`. No API key.

## Limitations

- Install count, source and stars are signals of use. This skill does not read the skill it recommends, so present them as counts, not as proof that the skill is safe.

## Troubleshooting

**`npx skills find` prints `No skills found` for a query that should match.** The CLI prints the same line when it cannot reach skills.sh. Open `https://skills.sh/` to test the connection, then run the search once more.

**The skill is missing from `npx skills list -g` after the install.** Show the user the output of both commands. Do not say the skill is installed. Why: the list is the only proof of the install.

## Commands

- `npx skills find [query] [--owner <owner>]` - Search for skills interactively or by keyword, optionally scoped to a GitHub owner
- `npx skills add <package>` - Install a skill from GitHub or other sources
- `npx skills update` - Update all installed skills

**Browse skills at:** https://skills.sh/

## Checklist

Run this before you say the work is done.

- [ ] Every skill, install count and star count in the reply was read from skills.sh or `npx skills find` output in this session. A value not read says `not checked`.
- [ ] Every skill in the reply has a skills.sh description that names the domain and the task, or `not checked` in its place.
- [ ] Every skill in the reply has its name, what it does, install count, source, install command and skills.sh link.
- [ ] Every skill with under 100 installs or under 100 stars carries a warning with the number.
- [ ] `npx skills add` ran only after the user said yes.
- [ ] After an install, `npx skills list -g` shows the skill.
- [ ] When no candidate was left, the reply says so, offers direct help, and names `npx skills init`.
