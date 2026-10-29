/**
 * Claude Code hooks for Jev levels 6 and 7. One script, dispatched on the hook event.
 *
 *   PreToolUse   Bash          L6 A: bash gate, deny irreversible or destructive commands
 *   PreToolUse   Write, Edit   L6 B: write gate, deny a credential written inside the repo
 *   PostToolUse  Read, Bash, WebFetch   L6 C: result screen, mark injected instructions as data
 *   UserPromptSubmit           L7 A+C: tell the user when to /clear or /compact, and with what focus
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
  COMPACT_QUESTIONS, cutPointInstructions, cutPointQuestion, decideTier,
  type CompactAnswers, type CompactState, type Lines, type TurnSummary,
} from "./levels/level07/index.ts";

// Tools whose output can carry instructions planted by someone else.
export const SCREENED = ["Read", "Bash", "WebFetch"];

// Real Claude Code sessions, not the lab's demo lines. hooks/context-budget.sh takes over at 120K.
export const LINES: Lines = { notice: 40_000, recommend: 70_000, request: 100_000 };

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
  for (const line of lines) {
    let e: any;
    try { e = JSON.parse(line); } catch { continue; }
    const c = e.message?.content;
    if (e.type === "user" && !e.isMeta) {
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
  return { prompts, lastText, tools, tokens };
}

/** Numbers in code, judgment in Jev: one call for the tier, one more for the cut point when it is worth it. */
async function compactAdvice(input: Input): Promise<Output> {
  if (!input.transcript_path || !input.prompt) return null;
  const s = readSession(readFileSync(input.transcript_path, "utf8").split("\n"));
  if (s.tokens < LINES.notice || s.prompts.length === 0) return null;
  const state: CompactState = {
    current_request: clip(input.prompt, 2000),
    previous_work: clip(s.prompts.slice(-6).join("\n---\n"), 4000),
    recent_turn: clip(s.lastText, 2000),
    tools_this_turn: [...new Set(s.tools)],
  };
  const { answers } = await jev.systemOne(state as any, COMPACT_QUESTIONS);
  const a = answers as unknown as CompactAnswers;
  const d = decideTier(a, { tokens: s.tokens, pct: 0 }, true, LINES, state);
  if (d.tier === "silent") return null;

  const k = `${Math.round(s.tokens / 1000)}K`;
  let advice: string;
  if (a.needs_history.score < 1) {
    advice = "The new work needs none of it: /clear and send the prompt again.";
  } else {
    const turns: TurnSummary[] = s.prompts.slice(-20).map((p, i) => ({ index: i, request: clip(p.replace(/\s+/g, " "), 120) }));
    const pick = await jev.systemOne({ turns } as any, cutPointQuestion(turns));
    advice = `/compact ${cutPointInstructions(turns, pick.answers.live_from as ChoiceAnswer).instructions}`;
  }
  const lead = d.tier === "request" ? "Compact before this runs" : d.tier === "recommend" ? "Compact recommended" : "Compact optional";
  return { systemMessage: `jev: ${lead}. Context is ${k}. ${d.reason} ${advice}` };
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
