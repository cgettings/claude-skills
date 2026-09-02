#!/usr/bin/env python3
"""Route (a) proper: does the SPLIT preserve firing on rules that are actually
load-bearing?

docs/durable-memory-model.md SS5 Task 3, step 5 -- second attempt.

WHAT THE FIRST ATTEMPT GOT WRONG. measure-rule-firing.py (2026-08-29) scored
five queries whose points a frontier model already raises unprompted. With the
whole section DELETED it still answered 30/30, so no arm could differ and the
run licensed nothing. The sample was the fault, not the design.

WHAT CHANGED. screen-queries.py (2026-09-01) pre-tested eight candidates
against arm C and kept only the three the model could NOT answer without the
rule. Five of eight saturated, reproducing the old ceiling; three did not.
This script runs the real three-arm comparison on those three.

  A  full section    -- today's text, evidence inline
  B  split section   -- recognition + action + [[pointer]], evidence moved out
  C  section deleted -- floor

A vs C is known from the screen (2/2 vs 0/2 on each query) and is re-run here
rather than reused: the screen's arms were measured in a different process, so
re-running makes the comparison within-run and turns the screen's numbers into
an independent replication instead of a shared dependency.

PRE-REGISTERED READING RULE (written before the run; do not amend afterwards).

  raised   judge returns true. hole = no parseable JSON: reported SEPARATELY,
           never folded into a rate.

  REPLICATION GATE, applied first and per query. The screen found A=2/2 and
  C=0/2 for each. If a query comes back A<2/2 or C>0/2 here, that query is
  VOID for this run -- its screen result did not replicate, and reading a B
  value against an A or C that moved measures nothing. Report voids; do not
  quietly drop them.

  Then, over the queries that replicate:

    PRESERVED   every query has B >= 1/2, with A = 2/2 and C = 0/2
    BROKEN      any query has B = 0/2 while A = 2/2
    MIXED       neither -- report per query, do not average

  B at 1/2 on a single query is AMBIGUOUS at 2 repeats and is stated as such.
  Two repeats can separate 0 from 2; they cannot resolve a partial. A MIXED or
  a lone 1/2 is a call for more repeats on that query, not a verdict.

  WHAT THIS CANNOT ANSWER. Arm B keeps a [[pointer]] to the evidence and the
  prompt suffix forbids tool use, so B cannot follow it. This measures whether
  the trimmed rule still fires from recognition + action ALONE -- the harder
  condition. It does NOT measure route (b), whether a model that CAN follow
  the pointer recovers the evidence; that needs a tool-enabled harness.

RESULT, 2026-09-01 -- appended after the run. The rule above is UNAMENDED.

  Two of three queries VOID. Arm C came back 1/2, 1/2, 0/2 against the screen's
  0/2, 0/2, 0/2. Arm C is a low NONZERO rate, not zero, and two repeats cannot
  tell those apart: at a true rate of 0.25 a 0/2 screen fires 56% of the time.
  The screen's "three of eight discriminate" is retracted, and so is the
  sentence in WHAT CHANGED above that repeats it.

KNOWN DEFECT, present in this script and in measure-rule-firing.py, unfixed
here because fixing it invalidates nothing already recorded and a silent fix
would make the recorded runs unreproducible: main() loops ARM BY ARM, so an
arm's position in the run is a perfect alias for the arm. Pooled post-hoc the
runs read A 12/12, B 2/6, C 2/12 (A-vs-B Fisher exact p = 0.0049) -- the shape
that would stop SS3b -- and a monotone drift over the ~10 minutes a run takes
produces the same pattern with no arm effect at all. ANY FURTHER RUN MUST
INTERLEAVE THE ARMS IN ONE RANDOMIZED JOB LIST. Until then, no arm difference
measured by this script is readable.

MUTATES ~/.claude/CLAUDE.md in place, one arm at a time, and restores it in a
finally, verifying by sha256. Read RESTORED OK / !! RESTORE MISMATCH.
"""
import hashlib
import json
import os
import shutil
import sys
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = Path(os.path.expanduser("~"))
LIVE = HOME / ".claude" / "CLAUDE.md"
BEFORE = ROOT / "docs" / "task-3-section-before.md"
AFTER = ROOT / "docs" / "task-3-section-after.md"
OUT = ROOT / "docs" / "task-3-confirmed-probe-results.json"

_spec = importlib.util.spec_from_file_location("sq", ROOT / "scripts" / "screen-queries.py")
sq = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sq)

CONFIRMED_IDS = ["S2-B4", "S5-B17", "S8-B6"]
QUERIES = [c for c in sq.CANDIDATES if c[0] in CONFIRMED_IDS]
REPEATS = 2


def main():
    assert len(QUERIES) == len(CONFIRMED_IDS), "confirmed id not found in CANDIDATES"
    workdir = ROOT / ".task3-probe"
    workdir.mkdir(parents=True, exist_ok=True)

    live, before, after = sq.rd(LIVE), sq.rd(BEFORE), sq.rd(AFTER)
    if live.count(before) != 1:
        raise SystemExit(
            f"pilot section appears {live.count(before)}x in {LIVE}, expected exactly 1.\n"
            "Re-cut docs/task-3-section-before.md before running.")

    backup = workdir / "CLAUDE.md.confirmed-backup"
    shutil.copy2(LIVE, backup)
    live_sha = sq.sha(live)
    arms = {"A_full": live,
            "B_split": live.replace(before, after),
            "C_absent": live.replace(before, "")}
    for name, text in arms.items():
        sq.wr(workdir / f"arm-{name}.md", text)
        print(f"  arm {name:9s} {len(text.encode('utf-8')):6d} B", file=sys.stderr)
    print(f"live {LIVE.stat().st_size} B sha {live_sha[:12]}", file=sys.stderr)

    records = []
    try:
        for name, text in arms.items():
            sq.wr(LIVE, text)
            sq.leg(name, QUERIES, ROOT, records)
    finally:
        shutil.copy2(backup, LIVE)
        ok = sq.sha(sq.rd(LIVE)) == live_sha
        print("RESTORED OK" if ok else "!! RESTORE MISMATCH", file=sys.stderr)
        with open(OUT, "w", encoding="utf-8", newline="") as fh:
            json.dump({"records": records}, fh, indent=2)
        if not ok:
            return 2

    tal = {a: sq.tally(records, a, QUERIES) for a in arms}
    holes = sum(1 for r in records if r["raised"] is None)

    void, live_q = [], []
    for c in QUERIES:
        a, cc = tal["A_full"][c[0]], tal["C_absent"][c[0]]
        (void if (a["raised"] != REPEATS or cc["raised"] != 0) else live_q).append(c)

    print("\n" + "=" * 74)
    print(f"{'id':10s} {'A':>5s} {'B':>5s} {'C':>5s}  note")
    for c in QUERIES:
        cells = {k: tal[k][c[0]] for k in arms}
        row = "  ".join(f"{cells[k]['raised']}/{cells[k]['n']}" for k in ("A_full", "B_split", "C_absent"))
        note = "VOID -- screen result did not replicate" if c in void else (
            "B ambiguous at 2 repeats" if cells["B_split"]["raised"] == 1 else "")
        print(f"{c[0]:10s} {row}  {note}")
    print(f"\nholes: {holes} -- reported separately, not scored")
    print(f"replicated: {len(live_q)}/{len(QUERIES)}; void: {[c[0] for c in void]}")

    if not live_q:
        print("VERDICT: every query void -- the screen did not replicate; nothing readable here")
    elif any(tal["B_split"][c[0]]["raised"] == 0 for c in live_q):
        broke = [c[0] for c in live_q if tal["B_split"][c[0]]["raised"] == 0]
        print(f"VERDICT: BROKEN on {broke} -- SS3b is wrong; Tasks 5-6 stop")
    elif all(tal["B_split"][c[0]]["raised"] >= 1 for c in live_q):
        partial = [c[0] for c in live_q if tal["B_split"][c[0]]["raised"] == 1]
        tail = f" (ambiguous on {partial}; more repeats needed there)" if partial else ""
        print(f"VERDICT: PRESERVED on {len(live_q)} replicating queries{tail}")
    else:
        print("VERDICT: MIXED -- read per query above, do not average")

    with open(OUT, "w", encoding="utf-8", newline="") as fh:
        json.dump({"records": records, "tally": tal,
                   "void": [c[0] for c in void], "holes": holes}, fh, indent=2)
    print(f"\nwrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
