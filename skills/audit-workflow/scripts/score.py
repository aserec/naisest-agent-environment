#!/usr/bin/env python3
"""Score audit-workflow runs.

score.py RUN_DIR             writes RUN_DIR/metrics.json and RUN_DIR/timeline.txt, prints the metrics
score.py RUN_DIR RUN_DIR...  also prints a markdown table that compares the runs
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

PHASES = ["research", "spec", "plan", "implementation", "validation", "review", "final-validation"]
FILES = [f".audit/{n}-{p}.md" for n, p in zip(["01", "02", "03", "04", "05", "06", "07"], PHASES)]
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
MS_PER_MINUTE = 60_000
MINUTE_DECIMALS = 2
JSON_INDENT = 2
EXIT_BAD_INPUT = 2
# Characters kept when a long value is shortened.
CALL_TEXT = 110
ERROR_TEXT = 160
KEY_TEXT = 80
TEST_FILE = re.compile(r"\.(test|spec)\.|(^|/)e2e/")
NOT_CODE = re.compile(r"^(\.audit/|graft/|\.gitignore$)")
QUALITY_MAX = 30  # six rubric criteria scored 1-5 (references/scoring.md)
SHELL_WRITE = re.compile(r"(?:>>?|tee(?:\s+-a)?)\s*['\"]?(?:\S*/)?0([1-7])-[a-z-]+\.md")  # also after `cd .audit`


def short(value, n=CALL_TEXT):
    text = value if isinstance(value, str) else json.dumps(value, sort_keys=True)
    return " ".join(text.split())[:n]


def target(call):
    i = call["input"]
    return i.get("file_path") or i.get("notebook_path") or i.get("path") or ""


def phases_written(call):
    """Indexes (0-6) of the phase files this call writes, through a file tool or a shell redirect."""
    if call["name"] in WRITE_TOOLS:
        return [j for j, f in enumerate(FILES) if target(call).endswith(f)]
    if call["name"] == "Bash":
        return sorted({int(n) - 1 for n in SHELL_WRITE.findall(call["input"].get("command", ""))})
    return []


def diff_size(run: Path) -> dict:
    """Lines added in diff.patch, split into product code and tests. Phase files and tool caches are left out."""
    size, path = {"src_added": 0, "test_added": 0, "files": 0}, None
    patch = run / "diff.patch"
    for line in patch.read_text(errors="replace").splitlines() if patch.exists() else []:
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else None
            size["files"] += bool(path and not NOT_CODE.match(path))
        elif line.startswith("+") and path and not NOT_CODE.match(path):
            size["test_added" if TEST_FILE.search(path) else "src_added"] += 1
    return size


def score(run: Path) -> dict:
    try:
        events = [json.loads(line) for line in open(run / "stream.jsonl") if line.strip()]
    except (OSError, json.JSONDecodeError) as e:
        print(f"{run}: cannot read stream.jsonl: {e}", file=sys.stderr)
        sys.exit(EXIT_BAD_INPUT)
    init = next((e for e in events if e.get("subtype") == "init"), {})
    result = next((e for e in reversed(events) if e.get("type") == "result"), {})

    calls, results = [], {}
    phase = 0
    for e in events:
        msg = e.get("message") or {}
        content = msg.get("content") if isinstance(msg.get("content"), list) else []
        if e.get("type") == "assistant":
            for block in content:
                if block.get("type") != "tool_use":
                    continue
                call = {"id": block["id"], "name": block["name"], "input": block.get("input") or {},
                        "subagent": bool(e.get("parent_tool_use_id")),
                        "phase": PHASES[phase] if phase < len(PHASES) else "after"}
                calls.append(call)
                # Writing phase file j ends phase j, even when earlier ones were skipped.
                phase = max([phase] + [j + 1 for j in phases_written(call)])
        elif e.get("type") == "user":
            for block in content:
                if block.get("type") == "tool_result":
                    results[block["tool_use_id"]] = block

    # First write of each phase file, in call order.
    first_write = {}
    for n, c in enumerate(calls):
        for j in phases_written(c):
            first_write.setdefault(FILES[j], n)
    app = run / "app"
    phases = {
        f: {"exists": (app / f).is_file(), "words": len((app / f).read_text().split()) if (app / f).is_file() else 0,
            "first_write_call": first_write.get(f)}
        for f in FILES
    }
    written = [first_write[f] for f in FILES if f in first_write]

    # Repeats: identical calls, and reads of a file that has not changed since the last read.
    keys = Counter((c["name"], json.dumps(c["input"], sort_keys=True)) for c in calls)
    identical = {f"{name} {short(json.loads(inp), KEY_TEXT)}": n - 1 for (name, inp), n in keys.items() if n > 1}
    version, last_read, redundant_reads = Counter(), {}, []
    for c in calls:
        path = target(c)
        if c["name"] in WRITE_TOOLS:
            version[path] += 1
        elif c["name"] == "Read" and path:
            if last_read.get(path) == version[path]:
                redundant_reads.append(path)
            last_read[path] = version[path]
    edits = Counter(target(c) for c in calls if c["name"] in WRITE_TOOLS and ".audit/" not in target(c))

    errors = [{"call": n, "phase": c["phase"], "tool": c["name"], "input": short(c["input"], KEY_TEXT),
               "error": short(results[c["id"]].get("content"), ERROR_TEXT)}
              for n, c in enumerate(calls) if results.get(c["id"], {}).get("is_error")]
    contamination = [short(c["input"]) for c in calls if "__oracle__" in json.dumps(c["input"])
                     or "oracle" in json.dumps(c["input"]) and "audit-workflow" in json.dumps(c["input"])]

    # Token counts stay run-level: the stream reports partial usage per message.
    per_phase = {p: {"calls": 0, "skills": [], "errors": 0} for p in PHASES + ["after"]}
    for c in calls:
        per_phase[c["phase"]]["calls"] += 1
        if c["name"] == "Skill":
            per_phase[c["phase"]]["skills"].append(c["input"].get("skill"))
    for err in errors:
        per_phase[err["phase"]]["errors"] += 1

    usage = result.get("usage") or {}
    checks = json.loads((run / "checks.json").read_text()) if (run / "checks.json").exists() else {}
    setup = json.loads((run / "setup.json").read_text()) if (run / "setup.json").exists() else {}
    metrics = {
        "label": setup.get("label", run.name),
        "setup": setup,
        "model": init.get("model"),
        "plugins": [p["source"] for p in init.get("plugins", [])],
        "skills_available": init.get("skills", []),
        "finished": result.get("subtype"),
        "cost_usd": result.get("total_cost_usd"),
        "cost_by_model": {m: u.get("costUSD") for m, u in (result.get("modelUsage") or {}).items()},
        "wall_minutes": round(result.get("duration_ms", 0) / MS_PER_MINUTE, MINUTE_DECIMALS),
        "api_minutes": round(result.get("duration_api_ms", 0) / MS_PER_MINUTE, MINUTE_DECIMALS),
        "turns": result.get("num_turns"),
        "tokens": {k: usage.get(k, 0) for k in
                   ("input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")},
        "tool_calls": len(calls),
        "tool_calls_by_name": dict(Counter(c["name"] for c in calls).most_common()),
        "subagent_tool_calls": sum(c["subagent"] for c in calls),
        "subagents_spawned": (result.get("subagent_stats") or {}).get("spawned", 0),
        "skills_invoked": [c["input"].get("skill") for c in calls if c["name"] == "Skill"],
        "tool_errors": errors,
        "identical_calls": identical,
        "redundant_reads": dict(Counter(redundant_reads)),
        "files_edited_more_than_once": {f: n for f, n in edits.items() if n > 1},
        "permission_denials": len(result.get("permission_denials") or []),
        "phases": phases,
        "phases_done": sum(p["exists"] and p["words"] > 0 for p in phases.values()),
        "phases_with_work": sum(per_phase[p]["calls"] > 0 for p in PHASES),
        "phases_in_order": written == sorted(written),
        "phases_batched_in_one_call": [js for c in calls if len(js := phases_written(c)) > 1],
        "per_phase": per_phase,
        "oracle_contamination": contamination,
        "checks": checks,
        "diff": diff_size(run),
        "quality": json.loads((run / "quality.json").read_text()) if (run / "quality.json").exists() else None,
    }
    (run / "metrics.json").write_text(json.dumps(metrics, indent=JSON_INDENT))
    with open(run / "timeline.txt", "w") as t:
        for n, c in enumerate(calls):
            flag = " ERROR" if results.get(c["id"], {}).get("is_error") else ""
            sub = " [sub]" if c["subagent"] else ""
            t.write(f"{n}\t{c['phase']}\t{c['name']}{sub}\t{short(c['input'])}{flag}\n")
    return metrics


def table(rows):
    def yes(v):
        return {True: "pass", False: "FAIL"}.get(v, "-")
    head = ["run", "model", "USD", "min", "turns", "calls", "out tok", "errors", "repeats",
            "phase files", "phases worked", "in order", "oracle unit", "oracle e2e", "own tests", "design rules",
            "src+/test+", "quality"]
    lines = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for m in rows:
        c = m["checks"]
        repeats = sum(m["identical_calls"].values()) + sum(m["redundant_reads"].values())
        own = c.get("agent_unit") and c.get("agent_e2e") and c.get("added_unit_test") and c.get("added_e2e_test")
        rules = c.get("protected_files_unchanged") and c.get("no_new_deps") and c.get("typecheck")
        cost = m["cost_usd"]
        q = m.get("quality")
        lines.append("| " + " | ".join(str(x) for x in [
            m["label"], m["model"], f"{cost:.2f}" if cost is not None else "-", m["wall_minutes"], m["turns"],
            m["tool_calls"], m["tokens"]["output_tokens"], len(m["tool_errors"]), repeats,
            f"{m['phases_done']}/{len(PHASES)}", f"{m['phases_with_work']}/{len(PHASES)}", yes(m["phases_in_order"]), yes(c.get("oracle_unit")),
            yes(c.get("oracle_e2e")), yes(own if c else None), yes(rules if c else None),
            f"{m['diff']['src_added']}/{m['diff']['test_added']}", f"{q['total']}/{QUALITY_MAX}" if q else "-"]) + " |")
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    runs = [score(Path(a)) for a in sys.argv[1:]]
    if len(runs) == 1:
        print(json.dumps({k: v for k, v in runs[0].items() if k != "skills_available"}, indent=JSON_INDENT))
    print(table(runs))
