/**
 * Claude Code hooks for Jev levels 6 and 7. One script, dispatched on the hook event.
 *
 *   PreToolUse   Bash          L6 A: bash gate, deny irreversible or destructive commands
 *   PreToolUse   Write, Edit   L6 B: write gate, deny a credential written inside the repo
 *   PostToolUse  Read, Bash, WebFetch   L6 C: result screen, mark injected instructions as data
 *   UserPromptSubmit           L7 A+C: /clear unrelated work, /compact related work, hand off after two compactions
 *
 * Every hook fails open: no key (BERGET_API_KEY, TYPESAFE_API_KEY or OPENROUTER_API_KEY), a Berget error or a timeout lets the call through.
 * hooks/deny-dangerous.sh stays the hard floor for catastrophic commands.
 */
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { hasJevKey, jev } from "./core/client.ts";
import type { ChoiceAnswer } from "./core/types.ts";
import { BLOCK_NOTICE, gateBashCommand, gateWriteCall, insideRepo, screenToolResult } from "./levels/level06/index.ts";
import {
  COMPACT_QUESTIONS, cutPointInstructions, cutPointQuestion,
  type CompactAnswers, type CompactState, type TurnSummary,
} from "./levels/level07/index.ts";

// Tools whose output can carry instructions planted by someone else.
export const SCREENED = ["Read", "Bash", "WebFetch"];

// Real Claude Code sessions, not the lab's demo lines. Unrelated work clears from 100K; related work
// compacts from 200K, and once two compactions are spent it hands off instead.
export const CLEAR_LINE = 100_000;
export const COMPACT_LINE = 200_000;
export const MAX_COMPACTIONS = 2;

type Input = {
  hook_event_name: string;
  cwd: string;
  tool_name?: string;
  tool_input?: Record<string, any>;
  tool_response?: unknown;
  prompt?: string;
  transcript_path?: string;
};
type Output = Record<string, unknown> | null;

const deny = (reason: string): Output => ({
  hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: `jev-guard: ${reason}. ${BLOCK_NOTICE}` },
});

/** The text a tool handed back, whatever shape Claude Code gives it. */
export function resultText(tool: string, r: any): string {
  if (typeof r === "string") return r;
  if (tool === "Bash") return [r?.stdout, r?.stderr].filter(Boolean).join("\n");
  if (tool === "Read") return r?.file?.content ?? "";
  return r?.result ?? r?.content ?? JSON.stringify(r ?? "");
}

const clip = (s: string, n: number) => (s.length > n ? s.slice(0, n) + "…" : s);

/** User prompts, the last assistant text, its tools, and the context size, read from the transcript in code. */
export function readSession(lines: string[]) {
  const prompts: string[] = [];
  let lastText = "";
  let tools: string[] = [];
  let tokens = 0;
  let compactions = 0;
  for (const line of lines) {
    let e: any;
    try { e = JSON.parse(line); } catch { continue; }
    const c = e.message?.content;
    if (e.type === "system" && e.subtype === "compact_boundary") compactions++;
    if (e.type === "user" && !e.isMeta && !e.isCompactSummary) {
      const text = typeof c === "string" ? c : Array.isArray(c) && !c.some((p: any) => p.type === "tool_result")
        ? c.filter((p: any) => p.type === "text").map((p: any) => p.text).join("\n") : "";
      // Slash command echoes and hook output are not requests.
      if (text && !text.startsWith("<")) { prompts.push(text); tools = []; }
    }
    if (e.type === "assistant" && Array.isArray(c)) {
      for (const p of c) {
        if (p.type === "text" && p.text) lastText = p.text;
        if (p.type === "tool_use") tools.push(p.name);
      }
      const u = e.message.usage;
      if (u) tokens = (u.input_tokens ?? 0) + (u.cache_read_input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0);
    }
  }
  return { prompts, lastText, tools, tokens, compactions };
}

export type Advice = "clear" | "compact" | "handoff" | null;

/** Numbers in code: unrelated work clears early, related work compacts late, then hands off. */
export function pickAdvice(a: CompactAnswers, tokens: number, compactions: number): Advice {
  if (tokens < CLEAR_LINE) return null;
  if (a.switched_gears.noul > 0.7 && a.needs_history.score < 1) return "clear";
  if (tokens < COMPACT_LINE) return null;
  return compactions >= MAX_COMPACTIONS ? "handoff" : "compact";
}

const HANDOFF = "Finish only the step in progress, write a handoff file (a short file with the goal, the decisions made and the remaining steps), and relay the rest to a fresh subagent that reads it.";

/** Numbers in code, judgment in Jev: one call for the tier, one more for the cut point when it is worth it. */
async function compactAdvice(input: Input): Promise<Output> {
  if (!input.transcript_path || !input.prompt) return null;
  const s = readSession(readFileSync(input.transcript_path, "utf8").split("\n"));
  if (s.tokens < CLEAR_LINE || s.prompts.length === 0) return null;
  const state: CompactState = {
    current_request: clip(input.prompt, 2000),
    previous_work: clip(s.prompts.slice(-6).join("\n---\n"), 4000),
    recent_turn: clip(s.lastText, 2000),
    tools_this_turn: [...new Set(s.tools)],
  };
  const { answers } = await jev.systemOne(state as any, COMPACT_QUESTIONS);
  const a = answers as unknown as CompactAnswers;
  const advice = pickAdvice(a, s.tokens, s.compactions);
  if (!advice) return null;

  const k = `${Math.round(s.tokens / 1000)}K`;
  let message: string;
  if (advice === "clear") {
    message = `jev: The task changed and needs none of the earlier work. Context is ${k}. /clear and send the prompt again.`;
  } else if (advice === "handoff") {
    message = `jev: Context is ${k} after ${s.compactions} compactions. Hand off instead of compacting again. ${HANDOFF}`;
  } else {
    const turns: TurnSummary[] = s.prompts.slice(-20).map((p, i) => ({ index: i, request: clip(p.replace(/\s+/g, " "), 120) }));
    const pick = await jev.systemOne({ turns } as any, cutPointQuestion(turns));
    message = `jev: Compact before this runs. Context is ${k}, compaction ${s.compactions + 1} of ${MAX_COMPACTIONS}. /compact ${cutPointInstructions(turns, pick.answers.live_from as ChoiceAnswer).instructions}`;
  }
  return { systemMessage: message, hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: message } };
}

export async function handle(input: Input): Promise<Output> {
  const tool = input.tool_name ?? "";
  const ti = input.tool_input ?? {};
  switch (input.hook_event_name) {
    case "PreToolUse": {
      if (tool === "Bash") {
        const d = await gateBashCommand(String(ti.command ?? ""), input.cwd);
        return d.block ? deny(d.reason) : null;
      }
      if (tool === "Write" || tool === "Edit") {
        const path = String(ti.file_path ?? "");
        // Outside the repo is scratch, memory or config: Claude Code's own permissions cover it.
        if (!insideRepo(path, input.cwd)) return null;
        const d = await gateWriteCall(path, String(ti.content ?? ti.new_string ?? ""), input.cwd);
        return d.block ? deny(d.reason) : null;
      }
      return null;
    }
    case "PostToolUse": {
      if (!SCREENED.includes(tool)) return null;
      const d = await screenToolResult(tool, resultText(tool, input.tool_response));
      return d.flag ? { hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: d.banner } } : null;
    }
    case "UserPromptSubmit":
      return compactAdvice(input);
  }
  return null;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    if (!hasJevKey()) process.exit(0);
    const out = await handle(JSON.parse(readFileSync(0, "utf8")));
    if (out) process.stdout.write(JSON.stringify(out));
  } catch (err: any) {
    // Fail open. stderr on exit 0 reaches the debug log, not the model.
    process.stderr.write(`jev hook: ${err?.message ?? err}\n`);
  }
}
