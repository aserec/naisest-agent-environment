---
name: figma-visual-check
description: Diffs a Figma node against a browser screenshot of the built UI. Use after get_design_context, Code Connect, or any Figma-driven UI change.
version: 1.0.0
allowed-tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_resize, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_hover
metadata:
  author: Danel Ceresa <danel@kivvo.ai>
  version: 1.0.0
  tags: [figma, visual-regression, playwright, ui]
---

# Figma visual check

## Purpose

Run this after every Figma MCP call that produced or changed UI, next to `figma:figma-design-to-code` and `figma:figma-code-connect`. Tests run in jsdom, which applies no CSS, so only a rendered comparison proves the code matches the board.

The check is done when `scripts/diff.py` exits 0 for every node you built, and you have looked at both images yourself.

## Instructions

### 1. Pick one node per rendered state

Take the node id from the prompt, from `get_design_context`, or from the project's node map, if it keeps one. Use the node of one variant, such as `Hierarchy=Primary, Size=md, State=Default`, not the whole component set. The rendered UI must show that same variant, state and text.

Done when each state you changed has one variant node id and one URL that renders it.

### 2. Render it in a real browser

Open the story in Storybook (`pnpm storybook`, then `http://localhost:6006/iframe.html?id=<story-id>`) or the page in the web app (`pnpm --filter web dev -p 3000`). Use the Playwright MCP, not the claude-in-chrome extension. Set the viewport to the width of the Figma frame, then call `browser_take_screenshot` on the element with a `filename` inside the scratchpad directory.

Done when a PNG of that element exists on disk.

### 3. Download the Figma render

Ask the Figma REST images endpoint for a PNG of the node at scale 1, then save the returned URL to disk. The file key is `VC1VLXG1eePGmd88xXr9fz`, and the node id uses a colon.

```bash
curl -s -H "X-Figma-Token: $FIGMA_ACCESS_TOKEN" \
  "https://api.figma.com/v1/images/VC1VLXG1eePGmd88xXr9fz?ids=<node-id>&format=png&scale=1" \
  -o <scratchpad>/visual/<slug>/figma.json
curl -s -o <scratchpad>/visual/<slug>/figma.png "$(jq -r '.images[]' <scratchpad>/visual/<slug>/figma.json)"
```

Done when `figma.png` opens as an image of the node.

### 4. Diff it

```bash
python3 -B .agents/skills/figma-visual-check/scripts/diff.py <scratchpad>/visual/<slug>/figma.png <screenshot.png> --out <scratchpad>/visual/<slug>
```

Harnesses with a `run_script()` tool can call `run_script("scripts/diff.py", [figma_png, screenshot_png, "--out", out_dir])` instead. The script compares sizes and writes `diff.png`, where red marks the pixels that differ.

Done when the script prints the size line and the percentage of pixels that differ.

### 5. Read both images

Open `figma.png`, the screenshot and `diff.png` with the Read tool. Name each difference, such as a colour, a gap, a radius, a shadow, a font weight or a missing icon. Font antialiasing alone is not a difference.

Done when you have a list of concrete differences, or you have confirmed there are none.

### 6. Fix and repeat

Fix each difference in code, taking the value from `get_design_context`. Then run steps 2, 4 and 5 again. If the board itself is ambiguous, stop and ask. Do not tune `--max-mismatch` to make a diff pass.

Done when the script exits 0 and step 5 finds no difference.

### 7. Report

In the reply, list the node, the final mismatch percentage, and any difference you left in place, with the reason.

Done when the report lists every checked node.

## Examples

### Button matches after one fix

```text
Input:  Button primary md, node 6210:1901, story ui-button--primary
Run 1:  size ok, pixels 7.80% differ -> diff.png shows the shadow missing
Fix:    add shadow-sm to the primary variant
Run 2:  size ok, pixels 0.40% differ, exit 0
Report: 6210:1901 primary md, 0.40%, no differences left
```

### Size mismatch

```text
Input:  QuickActionCard, node 6360:6753
Run 1:  figma 320x96, actual 320x104, size MISMATCH
Fix:    padding was py-5, the board draws 16px, so py-4
Run 2:  size ok, pixels 1.10% differ, exit 0
```

## Available scripts

| Script | Purpose | Arguments |
| --- | --- | --- |
| `scripts/diff.py` | Compares a Figma PNG with a screenshot and writes `diff.png` | `FIGMA_PNG ACTUAL_PNG [--max-mismatch PCT] [--out DIR]` |

`diff.py` exits 0 on a match, 1 on a size or pixel mismatch, and 2 when it cannot read an input file.

## Error handling

| Signal | Meaning | Action |
| --- | --- | --- |
| `diff.py` exit 2 | An input path is wrong or not a PNG | Check both paths, then run the step again |
| `curl` returns `"err"` or `null` images | The token is missing or the node id is wrong | Check the id with `get_metadata` |
| `size MISMATCH` | Padding, border or line height differs | Fix the value from `get_design_context` |

## Prerequisites

- `FIGMA_ACCESS_TOKEN` in the environment, a Figma personal token with file read scope. Never paste its value into chat.
- `python3` with Pillow (`pip install pillow`).
- The Playwright MCP server, and Storybook or the web app running locally.

## Limitations

The Figma render uses the fonts installed on Figma's servers, so text may differ by a pixel or two. Hover, focus and motion need the Playwright mouse or keyboard to reach the state before the screenshot. A single frame cannot verify motion.

## Troubleshooting

**Everything differs.** The screenshot is at a different device scale or includes page chrome. Take the screenshot of the element, not the page, at scale 1.

**The size is off by a few pixels.** Treat it as a real difference. Padding, border or line height is usually wrong.
