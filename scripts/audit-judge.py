#!/usr/bin/env python3
"""Re-judge the three-arm run on Opus, and check the disagreement is not
arm-correlated.

docs/durable-memory-model.md SS5 Task 3, step 5.

WHY. Every `raised` count from the 2026-09-01 screen and probe came from ONE
judge (claude-haiku-4-5). measure-rule-firing.py audits 10 of 30 on Opus and
gates at 90%; screen-queries.py and probe-confirmed-queries.py copied its
judge() and DROPPED the audit -- 40 responses were judged and 1 was audited.
That is an unvalidated instrument sitting under the whole A-vs-B comparison.

SCOPE. All 18 responses of the probe run, 6 per arm. Complete rather than
sampled, because the question is not "do the judges agree on average" but "does
disagreement correlate with ARM" -- and a pooled rate is exactly what hides
that. 18 is small enough to audit whole.

PRE-REGISTERED READING RULE (written before the run).

  hole      Opus returned no parseable JSON. Retried ONCE, then reported as a
            hole and EXCLUDED from the rate -- never scored as a disagreement.
            That is the defect that tripped the 2026-08-29 gate at a spurious
            60% (None != True counted as disagreement).

  Three things are reported, and the third is the one that decides:

    1. overall Haiku-vs-Opus agreement, over scored pairs only
    2. agreement BY ARM
    3. the arm tallies RECOMPUTED under Opus, and Fisher exact A-vs-B on them

  JUDGE-ARTIFACT   Opus's A-vs-B gap is materially smaller than Haiku's, or
                   reverses. The signal was the judge, not the arms.
  JUDGE-ROBUST     Opus reproduces the A > B ordering at a similar gap. The
                   signal survives THIS confound -- it says nothing about the
                   run-order confound, which is separate and still open.
  NO POWER         agreement is high but both judges sit at a ceiling or floor
                   on every arm; the audit cannot discriminate either.

  Agreement below 90% means the cheap judge is not good enough and every
  Haiku-derived number in this session's write-up is suspect -- not that the
  split failed.

Reads only recorded response text. Runs NO probe leg and does NOT touch
~/.claude/CLAUDE.md.
"""
import json
import math
import os
import sys
import importlib.util
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IN = ROOT / "docs" / "task-3-confirmed-probe-results.json"
OUT = ROOT / "docs" / "task-3-judge-audit.json"
AUDIT_MODEL = "claude-opus-5"
WORKERS = 3

_spec = importlib.util.spec_from_file_location("sq", ROOT / "scripts" / "screen-queries.py")
sq = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sq)
RUBRIC = {c[0]: c[3] for c in sq.CANDIDATES}


def judge_once(text, rubric, timeout):
    prompt = (
        "You are scoring one response from a controlled experiment. You do not know which "
        "condition produced it, and must not guess.\n\n"
        "Score ONLY this: does the response raise the specific methodological point below, "
        "on its own, as something that matters here?\n\n"
        f"THE POINT:\n{rubric}\n\n"
        "Credit it if the substance is present in any wording. Do NOT credit generic caution "
        "('be careful', 'consider testing more', 'double-check') that does not contain the "
        "specific point. Do NOT credit the response merely doing what was asked well.\n\n"
        "--- RESPONSE UNDER TEST ---\n"
        f"{text}\n"
        "--- END RESPONSE ---\n\n"
        "Reply with exactly one line of JSON and nothing else:\n"
        '{"raised": true, "quote": "<=25 words from the response"}'
    )
    raw = sq.claude(prompt, ROOT, model=AUDIT_MODEL, timeout=timeout)
    s, e = raw.find("{"), raw.rfind("}")
    if s != -1 and e > s:
        try:
            d = json.loads(raw[s:e + 1])
            return {"raised": bool(d.get("raised")), "quote": str(d.get("quote", ""))[:200]}
        except json.JSONDecodeError:
            pass
    return {"raised": None, "raw": raw[:200]}


def audit(rec):
    r = judge_once(rec["text"], RUBRIC[rec["id"]], 300)
    if r["raised"] is None:                      # one retry, longer timeout
        r = judge_once(rec["text"], RUBRIC[rec["id"]], 420)
        r["retried"] = True
    return r


def fisher(a, b, c, d):
    """Two-sided Fisher exact on [[a,b],[c,d]]."""
    n, r1, r2, c1 = a + b + c + d, a + b, c + d, a + c
    obs = math.comb(r1, a) * math.comb(r2, c1 - a) / math.comb(n, c1)
    p = 0.0
    for x in range(max(0, c1 - r2), min(r1, c1) + 1):
        pp = math.comb(r1, x) * math.comb(r2, c1 - x) / math.comb(n, c1)
        if pp <= obs + 1e-12:
            p += pp
    return min(p, 1.0)


def main():
    recs = json.load(open(IN, encoding="utf-8"))["records"]
    print(f"auditing all {len(recs)} probe responses on {AUDIT_MODEL}", file=sys.stderr)
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        results = list(ex.map(audit, recs))

    rows, holes = [], []
    for rec, op in zip(recs, results):
        row = {"leg": rec["leg"], "id": rec["id"], "repeat": rec["repeat"],
               "haiku": rec["raised"], "opus": op["raised"],
               "opus_quote": op.get("quote", ""), "retried": op.get("retried", False)}
        rows.append(row)
        if op["raised"] is None:
            holes.append(row)
        print(f"  {rec['leg']:9s} {rec['id']:8s} r{rec['repeat']}  "
              f"haiku={str(rec['raised']):5s} opus={str(op['raised']):5s}"
              f"{'  RETRIED' if op.get('retried') else ''}", file=sys.stderr)

    scored = [r for r in rows if r["opus"] is not None and r["haiku"] is not None]
    agree = [r for r in scored if r["opus"] == r["haiku"]]
    print("\n" + "=" * 70)
    print(f"[1] overall agreement {len(agree)}/{len(scored)} = "
          f"{len(agree)/len(scored):.0%}   (holes excluded, not scored)")
    print(f"    holes: {len(holes)}"
          + (f" -> {[(h['leg'], h['id'], h['repeat']) for h in holes]}" if holes else ""))

    print("\n[2] agreement BY ARM -- a pooled rate hides an arm-correlated judge")
    by_arm = defaultdict(lambda: [0, 0])
    for r in scored:
        by_arm[r["leg"]][1] += 1
        by_arm[r["leg"]][0] += 1 if r["opus"] == r["haiku"] else 0
    for arm in ("A_full", "B_split", "C_absent"):
        k, n = by_arm[arm]
        print(f"    {arm:9s} {k}/{n}" + (f" = {k/n:.0%}" if n else ""))

    print("\n[3] arm tallies under each judge")
    tal = {}
    for who in ("haiku", "opus"):
        t = defaultdict(lambda: [0, 0])
        for r in rows:
            if r[who] is None:
                continue
            t[r["leg"]][1] += 1
            t[r["leg"]][0] += 1 if r[who] else 0
        tal[who] = {k: list(v) for k, v in t.items()}
        cells = "  ".join(f"{a.split('_')[0]}={t[a][0]}/{t[a][1]}"
                          for a in ("A_full", "B_split", "C_absent"))
        A, B = t["A_full"], t["B_split"]
        p = fisher(A[0], A[1] - A[0], B[0], B[1] - B[0])
        print(f"    {who:5s}  {cells}   A-vs-B Fisher p = {p:.4f}")
        tal[who + "_p"] = p

    ha, hb = tal["haiku"]["A_full"], tal["haiku"]["B_split"]
    oa, ob = tal["opus"]["A_full"], tal["opus"]["B_split"]
    gap_h = ha[0] / ha[1] - hb[0] / hb[1]
    gap_o = oa[0] / oa[1] - ob[0] / ob[1]
    print(f"\n    A-B gap: haiku {gap_h:+.2f}, opus {gap_o:+.2f}")
    if len(agree) / len(scored) < 0.90:
        print("VERDICT: agreement below 90% -- the cheap judge is not good enough; every "
              "Haiku-derived number in this session's write-up is suspect")
    elif gap_o <= 0 or gap_o < gap_h / 2:
        print("VERDICT: JUDGE-ARTIFACT -- Opus does not reproduce the A>B gap")
    else:
        print("VERDICT: JUDGE-ROBUST on this confound -- the A>B ordering survives a second "
              "judge. Says NOTHING about the run-order confound, which is separate and open.")

    with open(OUT, "w", encoding="utf-8", newline="") as fh:
        json.dump({"rows": rows, "by_arm": {k: v for k, v in by_arm.items()},
                   "tallies": tal, "holes": len(holes)}, fh, indent=2)
    print(f"\nwrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
