#!/usr/bin/env python
"""Task 7, second follow-up: do the blind markers mark events the classifier already catches?

Two of the blind shapes are structural rather than prose -- an `attachment` whose `hookName` is
`SessionStart:compact`, and a `queue-operation` whose content is `/compact`. Blind is only a gap if
they mark compactions the two visible shapes miss, so pair them up per session and count the
compactions each shape alone would find.

Also prints, as a clearly secondary observation, what survived in cache at the nine
`messages_changed` events -- the constructive half of the null, and NOT a tested result.
"""
import glob
import importlib.util
import io
import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "sweep", os.path.join(HERE, "sweep-cache-rewrites.py"))
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)

ROOT = os.path.expanduser("~/.claude/projects")
PROBE = os.path.join(os.path.dirname(HERE), ".task3-probe")
JOIN = os.path.join(PROBE, "cache-miss-reason-join.txt")

if sys.argv[1:]:
    sys.exit("unknown argument %r; this script takes no arguments" % sys.argv[1])

SHAPES = ("compact_boundary", "isCompactSummary", "SessionStart:compact", "/compact")
per_session = defaultdict(lambda: defaultdict(list))
example = None

for path in sorted(glob.glob(os.path.join(ROOT, "*", "*.jsonl"))):
    for rec in sweep.records(path):
        ts = rec.get("timestamp")
        att = rec.get("attachment") or {}
        if rec.get("type") == "system" and "compact" in str(rec.get("subtype", "")).lower():
            per_session[path]["compact_boundary"].append(ts)
        if rec.get("isCompactSummary") is True:
            per_session[path]["isCompactSummary"].append(ts)
        if isinstance(att, dict):
            if str(att.get("hookName", "")) == "SessionStart:compact":
                per_session[path]["SessionStart:compact"].append(ts)
            if str(att.get("type", "")) == "compact_file_reference" and example is None:
                example = json.dumps(rec, ensure_ascii=False)[:400]
        if rec.get("type") == "queue-operation" and str(rec.get("content", "")).strip() == "/compact":
            per_session[path]["/compact"].append(ts)

print("COVERAGE  compactions each shape would find, corpus-wide")
totals = {s: sum(len(v[s]) for v in per_session.values()) for s in SHAPES}
for s in SHAPES:
    seen = s in ("compact_boundary", "isCompactSummary")
    print("   %-22s %-5s  %4d records over %2d sessions"
          % (s, "SEEN" if seen else "BLIND", totals[s],
             sum(1 for v in per_session.values() if v[s])))

visible_sessions = {p for p, v in per_session.items()
                    if v["compact_boundary"] or v["isCompactSummary"]}
blind_only = {p for p, v in per_session.items()
              if (v["SessionStart:compact"] or v["/compact"]) and p not in visible_sessions}
print()
print("   sessions with a VISIBLE marker: %d" % len(visible_sessions))
print("   sessions with ONLY a blind marker (a real gap would live here): %d" % len(blind_only))
for p in sorted(blind_only):
    v = per_session[p]
    print("      %s  SessionStart:compact=%d /compact=%d"
          % (os.path.basename(p)[:8], len(v["SessionStart:compact"]), len(v["/compact"])))

print()
print("   per-session counts, where any marker is present")
print("   %-9s %9s %9s %9s %9s" % ("session", "boundary", "summary", "hook", "/compact"))
for p in sorted(per_session, key=lambda x: os.path.basename(x)):
    v = per_session[p]
    if not any(v[s] for s in SHAPES):
        continue
    print("   %-9s %9d %9d %9d %9d"
          % (os.path.basename(p)[:8], len(v["compact_boundary"]), len(v["isCompactSummary"]),
             len(v["SessionStart:compact"]), len(v["/compact"])))

print()
print("CONTROL  one `compact_file_reference` record, to show what that attachment actually is")
print("   %s" % example)

# ---- secondary observation: what survived in cache at the nine events -----------------------
events = []
with io.open(JOIN, encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if line.startswith("{"):
            rec = json.loads(line)
            if rec.get("reason") == "messages_changed" and rec.get("causes") == ["UNEXPLAINED"]:
                events.append(rec)

print()
print("SECONDARY OBSERVATION (not a tested result)  what survived in cache at each event")
print("   %-19s %10s %10s %10s %10s" % ("when", "prev_total", "event read", "1st-turn read", "surviving %"))
for ev in events:
    turns, _ = sweep.session_turns(ev["path"])
    when = sweep.parse_ts(ev["when"])
    row = None
    for a, b in zip(turns, turns[1:]):
        if b["t"] and when and abs((b["t"].replace(tzinfo=None)
                                    - when.replace(tzinfo=None)).total_seconds()) < 1:
            row = (a, b)
            break
    if row is None:
        continue
    prev, cur = row
    first_read = turns[0]["read"] if turns else 0
    print("   %-19s %10d %10d %10d %9.1f%%"
          % (ev["when"], prev["total"], cur["read"], first_read,
             100.0 * cur["read"] / prev["total"]))
