#!/usr/bin/env python3
"""Re-judge step 5's 30 responses on Opus -- docs/durable-memory-model.md SS5 Task 3.

Runs when measure-rule-firing.py's audit gate trips: "agreement below 90% means
stop and re-judge everything on the audit model before reading any arm
difference". It does not re-run the probe leg -- the 30 responses are already
recorded and are the expensive part. Only the judgment is redone.

WHY THE GATE TRIPPED ON THE 2026-08-29 RUN, which is a fault in the gate rather
than in the judge. judge() returns raised=None when the model's output has no
parseable JSON in it, and the audit compares `a["raised"] == records[i]["raised"]`
-- so None != True scores as a DISAGREEMENT. The first run's 6/10 was 6 agreements,
0 disagreements, and 4 unreadable Opus replies. "The judges disagree" and "one
judge did not answer" are different failures with different fixes, and the gate
reported the second as the first.

Two changes here, both aimed at that: the judge call gets a longer timeout (Opus
is slower than Haiku and 240s is a plausible cause of an empty reply), and any
record still unparseable is retried once and then reported as a hole rather than
silently folded into a rate.

Everything else is held identical to the original run by importing it: the same
judge() -- so the same prompt, rubric and parse -- and the same condition of the
global CLAUDE.md moved aside, restored in a finally and verified by hash.
"""
import argparse
import hashlib
import importlib.util
import json
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

spec = importlib.util.spec_from_file_location(
    "mrf", str(ROOT / "scripts" / "measure-rule-firing.py"))
mrf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mrf)

JUDGE_TIMEOUT = 600

_orig_claude = mrf.claude


def _patient_claude(prompt, cwd, model=None, timeout=None):
    """Same call, longer ceiling. Patched in rather than copied, so the judge
    prompt and parser stay byte-identical to the run being corrected."""
    return _orig_claude(prompt, cwd, model=model, timeout=JUDGE_TIMEOUT)


mrf.claude = _patient_claude


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--results", default=str(ROOT / "docs" / "task-3-firing-results.json"))
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--workdir", default=str(ROOT / ".task3-probe"))
    args = ap.parse_args()

    workdir = Path(args.workdir)
    workdir.mkdir(parents=True, exist_ok=True)
    results = Path(args.results)
    records = json.loads(mrf.rd(results))
    print(f"{len(records)} recorded responses from {results.name}", file=sys.stderr)

    live_sha = mrf.sha(mrf.rd(mrf.LIVE))
    print(f"live CLAUDE.md {mrf.LIVE.stat().st_size} B, sha {live_sha[:12]} "
          f"-- moving aside for judging", file=sys.stderr)

    aside = workdir / "CLAUDE.md.aside-for-rejudge"
    shutil.move(str(mrf.LIVE), str(aside))
    try:
        def one(i):
            r = mrf.judge(records[i]["text"], records[i]["rubric"],
                          workdir, mrf.AUDIT_MODEL)
            if r["raised"] is None:
                print(f"  retry {records[i]['arm']:9s} {records[i]['qid']:16s} "
                      f"rep{records[i]['rep']} (unparseable)", file=sys.stderr)
                r = mrf.judge(records[i]["text"], records[i]["rubric"],
                              workdir, mrf.AUDIT_MODEL)
            return r

        idx = list(range(len(records)))
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            verdicts = list(pool.map(one, idx))
    finally:
        shutil.move(str(aside), str(mrf.LIVE))
        back = mrf.sha(mrf.rd(mrf.LIVE))
        print(f"{'RESTORED OK' if back == live_sha else '!! RESTORE MISMATCH'}: "
              f"{mrf.LIVE} is {mrf.LIVE.stat().st_size} B, sha {back[:12]}",
              file=sys.stderr)

    holes = 0
    for i, v in zip(idx, verdicts):
        records[i]["opus_raised"] = v["raised"]
        records[i]["opus_quote"] = v.get("quote", "")
        if v["raised"] is None:
            holes += 1
            records[i]["opus_raw"] = v.get("judge_raw", "")

    # mrf.wr, not Path.write_text: text mode translates LF to CRLF on Windows, and
    # core.autocrlf=input normalises it away on commit -- so the working tree carries
    # CR bytes that the diff never shows. mrf.wr passes newline='' on both legs.
    mrf.wr(results, json.dumps(records, indent=2))

    # Haiku-vs-Opus over every record that BOTH judges scored -- the rate the
    # first run meant to report. Unreadable replies are counted separately and
    # never folded into it.
    both = [r for r in records
            if r.get("opus_raised") is not None and r.get("raised") is not None]
    agree = sum(1 for r in both if r["opus_raised"] == r["raised"])
    print(f"\nOpus judged {len(records) - holes}/{len(records)}, "
          f"{holes} unreadable after one retry", file=sys.stderr)
    if both:
        print(f"Haiku-vs-Opus over the {len(both)} both judges scored: "
              f"{agree}/{len(both)} = {agree / len(both):.0%}", file=sys.stderr)

    arms = ["A_full", "B_split", "C_absent"]
    print("\n=== firing rate by arm, OPUS judge ===", file=sys.stderr)
    print(f"{'query':18s} " + "".join(f"{a:>10s}" for a in arms), file=sys.stderr)
    for qid in [q[0] for q in mrf.QUERIES]:
        row = f"{qid:18s} "
        for arm in arms:
            cell = [r for r in records if r["arm"] == arm and r["qid"] == qid]
            hits = sum(1 for r in cell if r.get("opus_raised") is True)
            row += f"{hits:>5d}/{len(cell):<4d}"
        print(row, file=sys.stderr)
    for arm in arms:
        cell = [r for r in records if r["arm"] == arm and "CONTROL" not in r["qid"]]
        hits = sum(1 for r in cell if r.get("opus_raised") is True)
        print(f"arm {arm:9s} (probes only, control excluded): {hits}/{len(cell)}",
              file=sys.stderr)
    print("\nRead against measure-rule-firing.py's docstring before concluding.",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
