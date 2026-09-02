#!/usr/bin/env python3
"""Run a skill's trigger_eval.json against the *installed* skill set.

Why this exists rather than skill-creator's scripts/run_eval.py:

  1. That runner calls select.select() on a subprocess pipe. On Windows select
     accepts sockets only, so it raises WinError 10093 -- and run_eval() catches
     the exception per-future and records False. Every query then scores as "did
     not trigger" and the suite reports a plausible-looking pass count made
     entirely of should_trigger=false cases. A broken instrument with a number.

  2. That runner installs the description as a temporary slash command and asks
     "was *that* invoked". Here the real plugins are installed, so the temp
     command and the real skill carry the same description and split the vote.
     This records which skill actually fired instead, which is also the question
     worth asking of four siblings that share a subject.

What it measures: given everything loaded in this environment -- the installed
plugins, ~/.claude/CLAUDE.md, the project CLAUDE.md -- which skill, if any, does
the model reach for first. Both CLAUDE.md files name these skills, so this is a
measurement of the live setup, not of the descriptions in isolation.

  python scripts/run-trigger-evals.py --eval-set <trigger_eval.json> \
      --expect <skill-name> [--runs 1] [--workers 6] [--out results.json]

Exit status is 0 whether or not queries fail; read the report.
"""

import argparse
import json
import os
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


def run_query(query: str, timeout: int, cwd: str) -> dict:
    """Run one `claude -p` and report the first skill it reached for.

    Returns {skill, tool, tokens, ms, error}. `skill` is None when the turn
    ended with no Skill call. The process is killed as soon as the first tool
    call is decided, so the skill body is never read -- that keeps the cost to
    one turn's input, which is the dominant term anyway.
    """
    # CLAUDECODE trips the nesting guard, which is for interactive terminals.
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    proc = subprocess.Popen(
        ["claude", "-p", query, "--output-format", "stream-json",
         "--verbose", "--include-partial-messages"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=cwd, env=env,
    )

    out = {"query": query, "skill": None, "tool": None, "model": None,
           "usage": None, "ms": None, "error": None, "stopped": None}
    started = time.time()

    # No select() on Windows pipes -- enforce the timeout with a watchdog that
    # kills the child, which makes the blocking readline below return.
    killer = threading.Timer(timeout, proc.kill)
    killer.start()

    tool_name = None
    partial = ""
    try:
        for raw in proc.stdout:
            try:
                event = json.loads(raw.decode("utf-8", "replace").strip())
            except json.JSONDecodeError:
                continue
            if event.get("type") != "stream_event":
                continue
            se = event.get("event", {})
            kind = se.get("type", "")

            if kind == "message_start":
                msg = se.get("message", {})
                out["model"] = msg.get("model")
                out["usage"] = msg.get("usage")

            elif kind == "content_block_start":
                block = se.get("content_block", {})
                if block.get("type") == "tool_use":
                    tool_name = block.get("name", "")
                    partial = ""

            elif kind == "content_block_delta" and tool_name:
                delta = se.get("delta", {})
                if delta.get("type") == "input_json_delta":
                    partial += delta.get("partial_json", "")

            elif kind in ("content_block_stop", "message_stop"):
                if tool_name:
                    out["tool"] = tool_name
                    out["skill"] = skill_from(tool_name, partial)
                    out["stopped"] = "tool-call"
                    break
                if kind == "message_stop":
                    out["stopped"] = "message-stop-no-tool"
                    break
        else:
            # Stream ended without a decision: the child died or was killed.
            out["stopped"] = "stream-exhausted"
            out["error"] = "no decision before stream end (timeout or crash)"
    finally:
        killer.cancel()
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        proc.stdout.close()

    out["ms"] = int((time.time() - started) * 1000)
    return out


def skill_from(tool_name: str, partial_json: str) -> str | None:
    """Pull the skill name out of a partially-streamed tool input."""
    if tool_name != "Skill":
        return None
    try:
        return json.loads(partial_json).get("skill")
    except json.JSONDecodeError:
        # The stream can stop mid-object; the name is still recoverable.
        marker = '"skill"'
        if marker in partial_json:
            tail = partial_json.split(marker, 1)[1].lstrip(': "')
            return tail.split('"')[0] or None
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--eval-set", required=True)
    ap.add_argument("--expect", required=True,
                    help="skill name a should_trigger=true query must invoke")
    ap.add_argument("--runs", type=int, default=1)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--only", default=None,
                    help="path to a JSON list of queries to restrict the run to")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    cases = json.loads(Path(args.eval_set).read_text(encoding="utf-8"))
    if args.only:
        keep = set(json.loads(Path(args.only).read_text(encoding="utf-8")))
        cases = [c for c in cases if c["query"] in keep]
        if len(keep) != len(cases):
            print(f"warning: --only named {len(keep)} queries, matched {len(cases)}",
                  file=sys.stderr)

    root = str(Path(__file__).resolve().parent.parent)
    jobs = [(c, i) for c in cases for i in range(args.runs)]
    print(f"{len(cases)} queries x {args.runs} run(s) = {len(jobs)} invocations, "
          f"{args.workers} workers", file=sys.stderr)

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        raw = list(pool.map(
            lambda job: run_query(job[0]["query"], args.timeout, root), jobs))

    by_query: dict[str, list[dict]] = {}
    for (case, _), result in zip(jobs, raw):
        by_query.setdefault(case["query"], []).append(result)

    results = []
    for case in cases:
        runs = by_query[case["query"]]
        fired = [r["skill"] for r in runs]
        # Installed skills are namespaced `plugin:skill`; the eval sets name the
        # bare skill. Compare on the part after the last colon.
        hits = sum(1 for s in fired if s and s.rsplit(":", 1)[-1] == args.expect)
        rate = hits / len(runs)
        # A should_trigger=false query passes when the expected skill stays out
        # of it -- a *sibling* firing is not a failure of this suite, so it is
        # reported separately rather than folded into the pass count.
        ok = rate >= 0.5 if case["should_trigger"] else rate < 0.5
        results.append({
            "query": case["query"],
            "should_trigger": case["should_trigger"],
            "fired": fired,
            "tools": [r["tool"] for r in runs],
            "hit_rate": rate,
            "pass": ok,
            "stopped": [r["stopped"] for r in runs],
            "errors": [r["error"] for r in runs if r["error"]],
        })

    errored = sum(1 for r in results if r["errors"])
    report = {
        "eval_set": args.eval_set,
        "expect": args.expect,
        "runs_per_query": args.runs,
        "model": next((r["model"] for r in raw if r["model"]), None),
        "usage_samples": [r["usage"] for r in raw if r["usage"]],
        "total_ms": sum(r["ms"] for r in raw if r["ms"]),
        "summary": {
            "queries": len(results),
            "passed": sum(1 for r in results if r["pass"]),
            "failed": sum(1 for r in results if not r["pass"]),
            "errored_runs": errored,
        },
        "results": results,
    }

    for r in results:
        mark = "PASS" if r["pass"] else "FAIL"
        want = args.expect if r["should_trigger"] else f"not {args.expect}"
        got = ", ".join(str(s) for s in r["fired"])
        print(f"  [{mark}] want={want:<16} got={got:<20} {r['query'][:60]}",
              file=sys.stderr)
    s = report["summary"]
    print(f"{s['passed']}/{s['queries']} passed, {s['errored_runs']} errored runs",
          file=sys.stderr)
    if errored:
        print("errored runs make the counts above unreliable -- investigate first",
              file=sys.stderr)

    text = json.dumps(report, indent=2)
    if args.out:
        Path(args.out).write_text(text, encoding="utf-8", newline="")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
