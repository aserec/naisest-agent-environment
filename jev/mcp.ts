/**
 * MCP server (stdio) for Jev levels 8, 9 and 10. The agent gets typed answers, never the files or the output.
 *
 *   L8   ask_jev_file_bool, ask_jev_file_choice, ask_jev_file_score   one file, one judgment
 *   L9   ask_jev_files, pick_first_file                                many files in parallel, then one pick
 *   L10  ask_jev                                                       any state, paths and a command, the agent's own questions
 *
 * Hand-rolled JSON-RPC: three methods do not need an SDK.
 */
import { exec } from "node:child_process";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";
import { hasJevKey as hasKey, jev } from "./core/client.ts";
import { BLOCK_NOTICE, gateBashCommand } from "./levels/level06/index.ts";
import { askFileBool, askFileChoice, askFileScore, FileStateError } from "./levels/level08/index.ts";
import { askFiles, pickFirstFile } from "./levels/level09/index.ts";
import { ASK_JEV_DESCRIPTION, AskStateError, assembleState, parseQuestions, type CommandOutput } from "./levels/level10/index.ts";

// L10 option C: one short nudge, sent as the server's instructions, tells the agent the tools exist.
const INSTRUCTIONS =
  "You have ask_jev and the ask_jev_file tools. When you need a classification, a risk score, or a yes or no with a confidence, " +
  "prefer them over reasoning it out yourself or reading whole files into context. Give them paths or a command instead of pasting content. " +
  "They answer in about 300 ms and cost almost nothing. Read a file yourself only when you need its code, to edit or quote it.";

const WHEN =
  "Use this for a judgment about what a file does or contains, without reading it into your context. " +
  "Write the question against `content`, which is the file's text. Use Read instead when you need the code itself, to edit or quote it. " +
  "Exact lookups, does this string appear, how many lines, belong to grep, not here.";

const QUESTION_SCHEMA =
  'questions_json is a JSON object keyed by question id. Three types. ' +
  'noul: {"type":"noul","instructions":"Does `content` ...?","criteria":{"true":"...","false":"..."}} returns a probability of yes. ' +
  'choice: {"type":"choice","instructions":"Which ... is `content`?","criteria":{"option_a":"when it applies","option_b":"...","other":"none of the above"}} returns one of your keys plus confidence, up to 255 options. ' +
  'score: {"type":"score","instructions":"How ... is `content`?","criteria":["lowest situation","...","highest situation"]} returns a position on your levels, two to ten of them. ' +
  "Write every question against `content`, the file's text; `path` is also in the state. Ask every question you might need in one block, it is one call per file either way.";

const str = (description: string) => ({ type: "string", description });
const obj = (properties: Record<string, unknown>, required: string[]) => ({ type: "object", properties, required });
const path = str("File path, relative to the repo");

const COMMAND_TIMEOUT_MS = 60_000;
const MAX_OUTPUT_CHARS = 200_000;

/** Run a command for the state. The output is captured, never streamed to the agent. */
function runCommand(command: string, cwd: string): Promise<CommandOutput> {
  return new Promise((resolve) => {
    exec(command, { cwd, timeout: COMMAND_TIMEOUT_MS, maxBuffer: MAX_OUTPUT_CHARS * 4, env: { ...process.env, CI: "1" } }, (err, stdout, stderr) => {
      const code = err && typeof (err as any).code === "number" ? (err as any).code : err ? null : 0;
      resolve({ command, exit_code: code, stdout: String(stdout).slice(0, MAX_OUTPUT_CHARS), stderr: String(stderr).slice(0, MAX_OUTPUT_CHARS) });
    });
  });
}

/** An ask_jev command runs through the L6 bash gate first. */
async function gatedRun(command: string, cwd: string): Promise<CommandOutput> {
  const gate = await gateBashCommand(command, cwd);
  if (gate.block) throw new AskStateError(`ask_jev: the command was refused by the bash gate: ${gate.reason}. ${BLOCK_NOTICE} ask_jev commands should only read.`);
  return runCommand(command, cwd);
}

type Tool = { name: string; description: string; inputSchema: unknown; run: (p: any, cwd: string) => Promise<unknown> };

export const TOOLS: Tool[] = [
  {
    name: "ask_jev_file_bool",
    description: `Yes or no about one file. Returns { path, answer, noul } where noul is the probability of yes, 0 to 1. ${WHEN}`,
    inputSchema: obj({
      path,
      question: str("A yes or no question about `content`, for example: Does `content` validate authentication tokens?"),
      yes: str("What counts as yes"),
      no: str("What counts as no"),
    }, ["path", "question"]),
    run: (p, cwd) => askFileBool(p.path, p.question, cwd, { yes: p.yes, no: p.no }),
  },
  {
    name: "ask_jev_file_choice",
    description: `Pick one option about one file. Returns { path, choice, confidence, probabilities }. The choice is always one of your options; an "other" option is added if you leave none. ${WHEN}`,
    inputSchema: obj({
      path,
      question: str("The question, for example: Which layer is `content`?"),
      options: { type: "object", additionalProperties: { type: "string" }, description: "Option name to a one line description of when it applies. Up to 255." },
    }, ["path", "question", "options"]),
    run: (p, cwd) => askFileChoice(p.path, p.question, p.options, cwd),
  },
  {
    name: "ask_jev_file_score",
    description: `A position on a scale you define, about one file. Returns { path, score, top, nearest, confidence, legend }. Levels are ordered low to high, two to ten of them, each a described situation. ${WHEN}`,
    inputSchema: obj({
      path,
      question: str("The question, for example: How risky is a refactor of `content`?"),
      levels: { type: "array", items: { type: "string" }, description: "Ordered low to high, each level a situation, for example: Isolated and well tested" },
    }, ["path", "question", "levels"]),
    run: (p, cwd) => askFileScore(p.path, p.question, p.levels, cwd),
  },
  {
    name: "ask_jev_files",
    description:
      "Ask the same typed questions of many files at once without reading any of them. Code expands globs and directories, " +
      "drops node_modules, .git, binaries, and files over the budget, caps the list at 255, then makes one Jev call per file in parallel. " +
      "Returns { results: [{ path, answers }], skipped: [{ path, reason }], calls }. " + QUESTION_SCHEMA +
      " Use Read when you need a file's code; use grep for exact strings.",
    inputSchema: obj({
      paths_or_globs: { type: "array", items: { type: "string" }, description: 'Files, directories, or globs, relative to the repo, for example ["src/**/*.ts"] or ["src/http"]' },
      questions_json: str("The question block as a JSON string"),
      recursive: { type: "boolean", description: "For directories: include every file below them. Default false." },
    }, ["paths_or_globs", "questions_json"]),
    run: (p, cwd) => askFiles(p.paths_or_globs, p.questions_json, cwd, { recursive: p.recursive ?? false }),
  },
  {
    name: "pick_first_file",
    description:
      "After ask_jev_files, choose which of a list of files to open first for a goal. One Choice keyed by path, so the pick is always a real file. " +
      "Returns { path | null, confidence, probabilities }. Pass a short note per path if you have one, for example the answers you already got.",
    inputSchema: obj({
      question: str("The goal, for example: Which file should I open first to fix the proration bug?"),
      candidates: {
        type: "array",
        items: obj({ path: str("File path"), note: str("Optional one line note") }, ["path"]),
        description: "Paths, with an optional one line note each",
      },
    }, ["question", "candidates"]),
    run: (p) => pickFirstFile(p.question, p.candidates),
  },
  {
    name: "ask_jev",
    description: ASK_JEV_DESCRIPTION,
    inputSchema: obj({
      questions_json: str("The question block, a JSON object keyed by question id"),
      state: str("Your own state: plain text, or a JSON object as a string. Short. Not for pasting files or output."),
      paths: { type: "array", items: { type: "string" }, description: 'Files or globs for code to read into files["path"]. Up to 20 files.' },
      command: str("A command for code to run in the repo; its result goes into output. Runs through the bash gate."),
    }, ["questions_json"]),
    async run(p, cwd) {
      const questions = parseQuestions(p.questions_json);
      const { state, summary } = await assembleState({ state: p.state, paths: p.paths, command: p.command }, cwd, gatedRun);
      const r = await jev.systemOne(state as any, questions);
      return { answers: r.answers, state_summary: summary, usage: r.usage, model: r.model };
    },
  },
];

const text = (t: string, isError = false) => ({ content: [{ type: "text", text: t }], ...(isError ? { isError } : {}) });

export async function callTool(name: string, args: unknown, cwd: string) {
  const tool = TOOLS.find((t) => t.name === name);
  if (!tool) return text(`unknown tool: ${name}`, true);
  try {
    return text(JSON.stringify(await tool.run(args ?? {}, cwd), null, 2));
  } catch (err: any) {
    const known = err instanceof FileStateError || err instanceof AskStateError;
    return text(known ? err.message : `jev error: ${err?.message ?? err}`, true);
  }
}

export async function respond(msg: any, cwd: string): Promise<unknown | null> {
  const ok = (result: unknown) => ({ jsonrpc: "2.0", id: msg.id, result });
  switch (msg.method) {
    case "initialize":
      return ok({
        protocolVersion: msg.params?.protocolVersion ?? "2025-06-18",
        capabilities: { tools: {} },
        serverInfo: { name: "jev", version: "1.0.0" },
        // No key: no nudge and no tools, so the agent works as it did before Jev.
        ...(hasKey() ? { instructions: INSTRUCTIONS } : {}),
      });
    case "ping":
      return ok({});
    case "tools/list":
      return ok({ tools: hasKey() ? TOOLS.map(({ run: _run, ...t }) => t) : [] });
    case "tools/call":
      return ok(await callTool(msg.params?.name, msg.params?.arguments, cwd));
  }
  if (msg.id === undefined) return null; // a notification
  return { jsonrpc: "2.0", id: msg.id, error: { code: -32601, message: `method not found: ${msg.method}` } };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  // Claude Code starts stdio servers in the project root, which is the repo the tools read.
  const cwd = process.cwd();
  createInterface({ input: process.stdin }).on("line", async (line) => {
    if (!line.trim()) return;
    let msg: any;
    try { msg = JSON.parse(line); } catch { return; }
    const out = await respond(msg, cwd);
    if (out) process.stdout.write(JSON.stringify(out) + "\n");
  });
}
