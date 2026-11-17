---
name: vercel-react-best-practices
description: React and Next.js performance rules. Use when writing, reviewing, refactoring, or speeding up React or Next.js code, data fetching, or bundles.
version: 1.0.0
license: MIT
metadata:
  author: vercel
  version: "1.0.0"
  tags:
    - react
    - nextjs
    - performance
---

# Vercel React Best Practices

## Purpose

Use this skill for any of these tasks:

- Writing new React components or Next.js pages
- Implementing data fetching (client or server-side)
- Reviewing code for performance issues
- Refactoring existing React/Next.js code
- Optimizing bundle size or load times

The skill holds 70 performance rules in 8 categories. Each rule has its own file at `rules/<id>.md`. You match rules to the code, read the files of the matched rules, and make the code follow them.

The work is done when every item in the [Checklist](#checklist) at the end of this file holds.

## Instructions

### 1. Match rules to the code

Go through the 8 categories under [Quick Reference](#quick-reference) in priority order, 1 to 8. In each category, pick every rule whose line names a pattern, an API, or a situation that the code of this task has or will have. When a line leaves you unsure, for example because it says "heavy" or "expensive", pick the rule: its file decides in step 3.

List the picked ids, one line per category, and write "none" for a category with no match. Keep the list for step 2. It is a working list, so it does not have to go in the reply.

Why this order: the categories are ranked by impact, so the rules that save the most are found first.

Done when the list has 8 lines, one per category.

### 2. Read the file of each matched rule

Read `rules/<id>.md` for every id on the list. Read only those files. Why: the 70 rule files hold about 3,900 lines, and a rule that does not match adds nothing to this task.

Done when every id on the list has had its file read in this session.

### 3. Make the code follow each rule

Take the matched rules in category order, 1 to 8. Why: when two rules change the same lines, the rule from the higher category goes in first.

In 64 of the 70 rule files, `Incorrect` marks the pattern to remove and `Correct` marks the pattern to use. The other 6 files show the pattern to use under `Example`, `Usage` or `Implementation`.

- When writing or refactoring: write the code with the pattern to use.
- When reviewing: report each place that has the pattern to remove, with the rule id, and leave the code unchanged. Why: a review reports, and the author decides what to change.

When a rule file shows that the rule does not fit the code after all, take its id off the list.

Done when the code has the pattern to use for every rule left on the list, or the review names each place with its rule id.

### 4. Run the checklist

Run the [Checklist](#checklist) at the end of this file. Fix every item that fails, then run it again.

Done when every item holds.

## Examples

### One rule matches

```text
Input. The code of this task runs three awaits in a row:

  const user = await fetchUser()
  const posts = await fetchPosts()
  const comments = await fetchComments()

Step 1. The list:
  1 async-      async-parallel (the three awaits do not depend on each other)
  2 bundle-     none
  3 server-     none
  4 client-     none
  5 rerender-   none
  6 rendering-  none
  7 js-         none
  8 advanced-   none

Step 2. Read rules/async-parallel.md. No other rule file is read.

Step 3. Result. The code now has the Correct pattern of that file:

  const [user, posts, comments] = await Promise.all([
    fetchUser(),
    fetchPosts(),
    fetchComments()
  ])
```

Both code blocks are copied from `rules/async-parallel.md`.

## Prerequisites

The `rules/` folder next to this file, with its 70 rule files. No tools, keys, or network access.

## Limitations

- The gains after `Why:` are the estimates of the rule files. This skill measures nothing in the project, so quote a gain as the rule's estimate.
- A line in Quick Reference is a summary. The rule file is the rule: when the two differ, follow the file.

## Troubleshooting

**No rule matches.** The code has none of the patterns in Quick Reference. Make no change for this skill, carry on with the task, and say that no rule matched.

**Two matched rules change the same lines.** Apply the rule from the higher category first. Then look again for the lower rule's pattern to remove, and apply the lower rule only when that pattern is still in the code.

## Rule Categories by Priority

| Priority | Category | Impact | Prefix | Why it ranks here |
|----------|----------|--------|--------|-------------------|
| 1 | Eliminating Waterfalls | CRITICAL | `async-` | Each sequential await adds full network latency |
| 2 | Bundle Size Optimization | CRITICAL | `bundle-` | A smaller initial bundle improves Time to Interactive and Largest Contentful Paint |
| 3 | Server-Side Performance | HIGH | `server-` | Removes server-side waterfalls and reduces response times |
| 4 | Client-Side Data Fetching | MEDIUM-HIGH | `client-` | Reduces redundant network requests |
| 5 | Re-render Optimization | MEDIUM | `rerender-` | Fewer re-renders mean less wasted computation and a more responsive UI |
| 6 | Rendering Performance | MEDIUM | `rendering-` | Reduces the work the browser needs to do |
| 7 | JavaScript Performance | LOW-MEDIUM | `js-` | Micro-optimizations that add up on hot paths |
| 8 | Advanced Patterns | LOW | `advanced-` | For specific cases that need careful implementation |

## Quick Reference

Rule `<id>` lives at `rules/<id>.md`. Each line gives the rule id, what to do, and why.

### 1. Eliminating Waterfalls (CRITICAL)

- `async-cheap-condition-before-await` - Check cheap sync conditions before awaiting flags or remote values. Why: avoids unnecessary async work when a synchronous guard already fails.
- `async-defer-await` - Move await into branches where actually used. Why: avoids blocking unused code paths.
- `async-parallel` - Use Promise.all() for independent operations. Why: 2-10× improvement.
- `async-dependencies` - Use better-all for partial dependencies. Why: 2-10× improvement.
- `async-api-routes` - Start promises early, await late in API routes. Why: 2-10× improvement.
- `async-suspense-boundaries` - Use Suspense to stream content. Why: faster initial paint.

### 2. Bundle Size Optimization (CRITICAL)

- `bundle-barrel-imports` - Import directly, avoid barrel files. Why: a barrel import can take 200-800ms and slows builds.
- `bundle-analyzable-paths` - Prefer statically analyzable import and file-system paths to avoid broad bundles and traces. Why: avoids accidental broad bundles and file traces.
- `bundle-dynamic-imports` - Use next/dynamic for heavy components. Why: directly affects TTI and LCP.
- `bundle-defer-third-party` - Load analytics/logging after hydration. Why: they do not block user interaction, so they can stay out of the initial bundle.
- `bundle-conditional` - Load modules only when feature is activated. Why: loads large data only when needed.
- `bundle-preload` - Preload on hover/focus for perceived speed. Why: reduces perceived latency.

### 3. Server-Side Performance (HIGH)

- `server-auth-actions` - Authenticate server actions like API routes. Why: prevents unauthorized access to server mutations.
- `server-cache-react` - Use React.cache() for per-request deduplication. Why: deduplicates within request.
- `server-cache-lru` - Use LRU cache for cross-request caching. Why: caches across requests.
- `server-dedup-props` - Avoid duplicate serialization in RSC props. Why: reduces network payload by avoiding duplicate serialization.
- `server-hoist-static-io` - Hoist static I/O (fonts, logos) to module level. Why: avoids repeated file/network I/O per request.
- `server-no-shared-module-state` - Avoid module-level mutable request state in RSC/SSR. Why: prevents concurrency bugs and request data leaks.
- `server-serialization` - Minimize data passed to client components. Why: reduces data transfer size.
- `server-parallel-fetching` - Restructure components to parallelize fetches. Why: eliminates server-side waterfalls.
- `server-parallel-nested-fetching` - Chain nested fetches per item in Promise.all. Why: eliminates server-side waterfalls.
- `server-after-nonblocking` - Use after() for non-blocking operations. Why: faster response times.

### 4. Client-Side Data Fetching (MEDIUM-HIGH)

- `client-swr-dedup` - Use SWR for automatic request deduplication. Why: automatic deduplication.
- `client-event-listeners` - Deduplicate global event listeners. Why: single listener for N components.
- `client-passive-event-listeners` - Use passive listeners for scroll. Why: eliminates scroll delay caused by event listeners.
- `client-localstorage-schema` - Version and minimize localStorage data. Why: prevents schema conflicts, reduces storage size.

### 5. Re-render Optimization (MEDIUM)

- `rerender-defer-reads` - Don't subscribe to state only used in callbacks. Why: avoids unnecessary subscriptions.
- `rerender-memo` - Extract expensive work into memoized components. Why: enables early returns.
- `rerender-memo-with-default-value` - Hoist default non-primitive props. Why: restores memoization by using a constant for default value.
- `rerender-dependencies` - Use primitive dependencies in effects. Why: minimizes effect re-runs.
- `rerender-derived-state` - Subscribe to derived booleans, not raw values. Why: reduces re-render frequency.
- `rerender-derived-state-no-effect` - Derive state during render, not effects. Why: avoids redundant renders and state drift.
- `rerender-functional-setstate` - Use functional setState for stable callbacks. Why: prevents stale closures and unnecessary callback recreations.
- `rerender-lazy-state-init` - Pass function to useState for expensive values. Why: without the function form, the initializer runs on every render.
- `rerender-simple-expression-in-memo` - Avoid memo for simple primitives. Why: the useMemo call can cost more than the expression itself.
- `rerender-split-combined-hooks` - Split hooks with independent dependencies. Why: avoids recomputing independent steps.
- `rerender-move-effect-to-event` - Put interaction logic in event handlers. Why: avoids effect re-runs and duplicate side effects.
- `rerender-transitions` - Use startTransition for non-urgent updates. Why: maintains UI responsiveness.
- `rerender-use-deferred-value` - Defer expensive renders to keep input responsive. Why: keeps input responsive during heavy computation.
- `rerender-use-ref-transient-values` - Use refs for transient frequent values. Why: avoids unnecessary re-renders on frequent updates.
- `rerender-no-inline-components` - Don't define components inside components. Why: prevents remount on every render.

### 6. Rendering Performance (MEDIUM)

- `rendering-animate-svg-wrapper` - Animate div wrapper, not SVG element. Why: enables hardware acceleration.
- `rendering-content-visibility` - Use content-visibility for long lists. Why: faster initial render.
- `rendering-hoist-jsx` - Extract static JSX outside components. Why: avoids re-creation.
- `rendering-svg-precision` - Reduce SVG coordinate precision. Why: reduces file size.
- `rendering-hydration-no-flicker` - Use inline script for client-only data. Why: avoids visual flicker and hydration errors.
- `rendering-hydration-suppress-warning` - Suppress expected mismatches. Why: avoids noisy hydration warnings for known differences.
- `rendering-activity` - Use Activity component for show/hide. Why: preserves state/DOM.
- `rendering-conditional-render` - Use ternary, not && for conditionals. Why: prevents rendering 0 or NaN.
- `rendering-usetransition-loading` - Prefer useTransition for loading state. Why: reduces re-renders and improves code clarity.
- `rendering-resource-hints` - Use React DOM resource hints for preloading. Why: reduces load time for critical resources.
- `rendering-script-defer-async` - Use defer or async on script tags. Why: eliminates render-blocking.

### 7. JavaScript Performance (LOW-MEDIUM)

- `js-batch-dom-css` - Group CSS changes via classes or cssText. Why: prevents forced synchronous layouts and reduces performance bottlenecks.
- `js-index-maps` - Build Map for repeated lookups. Why: 1M ops to 2K ops.
- `js-cache-property-access` - Cache object properties in loops. Why: reduces lookups.
- `js-cache-function-results` - Cache function results in module-level Map. Why: avoid redundant computation.
- `js-cache-storage` - Cache localStorage/sessionStorage reads. Why: reduces expensive I/O.
- `js-combine-iterations` - Combine multiple filter/map into one loop. Why: reduces iterations.
- `js-length-check-first` - Check array length before expensive comparison. Why: avoids expensive operations when lengths differ.
- `js-early-exit` - Return early from functions. Why: avoids unnecessary computation.
- `js-hoist-regexp` - Hoist RegExp creation outside loops. Why: avoids recreation.
- `js-min-max-loop` - Use loop for min/max instead of sort. Why: O(n) instead of O(n log n).
- `js-set-map-lookups` - Use Set/Map for O(1) lookups. Why: O(n) to O(1).
- `js-tosorted-immutable` - Use toSorted() for immutability. Why: prevents mutation bugs in React state.
- `js-flatmap-filter` - Use flatMap to map and filter in one pass. Why: eliminates intermediate array.
- `js-request-idle-callback` - Defer non-critical work to browser idle time. Why: keeps UI responsive during background tasks.

### 8. Advanced Patterns (LOW)

- `advanced-effect-event-deps` - Don't put `useEffectEvent` results in effect deps. Why: avoids unnecessary effect re-runs and lint errors.
- `advanced-event-handler-refs` - Store event handlers in refs. Why: stable subscriptions.
- `advanced-init-once` - Initialize app once per app load. Why: avoids duplicate init in development.
- `advanced-use-latest` - useLatest for stable callback refs. Why: prevents effect re-runs.

## Checklist

Run this before you say the work is done.

- [ ] The step 1 list has 8 lines, one per category, each with rule ids or "none".
- [ ] Every id on the list had its file `rules/<id>.md` read in this session, and no other rule file was read.
- [ ] Rules were applied in category order, 1 to 8.
- [ ] Writing or refactoring: for every rule on the list, the code has the pattern to use and no longer has the pattern to remove.
- [ ] Reviewing: every finding names the rule id and the place in the code, and the code is unchanged.
- [ ] Every gain quoted in the reply is called the rule's estimate.
