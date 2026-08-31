#!/usr/bin/env python
"""Task 7b, control arm: is the boundary-arrival enrichment just window duration?

The 9 event windows span 44-904 s; a control boundary in these sessions is far shorter, and a longer
window contains more records of every kind. So an unstratified rate measures window duration, not
arrival. This re-runs the same presence-per-window measure inside gap bands, and breaks `system` out
by subtype, which the pooled run could not distinguish.

Prints aggregates only.
"""
import importlib.util
import io
import json
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "sweep", os.path.join(HERE, "sweep-cache-rewrites.py"))
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)

PROBE = os.path.join(os.path.dirname(HERE), ".task3-probe")
JOIN = os.path.join(PROBE, "cache-miss-reason-join.txt")

REASON = "messages_changed"
for arg in sys.argv[1:]:
    if not arg.startswith("--reason="):
        sys.exit("unknown argument %r; this script takes --reason=LABEL or nothing" % arg)
    REASON = arg.split("=", 1)[1]

BANDS = [(0, 30), (30, 60), (60, 180), (180, 600), (600, 3600), (3600, 10 ** 9)]
WATCH = ["queue-operation", "system", "attachment/total_tokens_reminder"]


def label(rec):
    rtype = str(rec.get("type"))
    if rtype == "attachment":
        att = rec.get("attachment") or {}
        return "attachment/%s" % (att.get("type") if isinstance(att, dict) else "?")
    if rtype == "system":
        return "system/%s" % rec.get("subtype")
    return rtype


def main():
    events = []
    with io.open(JOIN, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("{"):
                rec = json.loads(line)
                if rec.get("reason") == REASON and rec.get("causes") == ["UNEXPLAINED"]:
                    events.append(rec)
    paths = sorted({e["path"] for e in events})

    index = defaultdict(list)
    for path in paths:
        for rec in sweep.records(path):
            t = sweep.parse_ts(rec.get("timestamp"))
            if t is not None:
                index[path].append((t, label(rec), rec.get("type")))

    ev, ctl = [], []   # (gap, shapes, coarse_shapes)
    for path in paths:
        turns, _ = sweep.session_turns(path)
        wanted = {sweep.parse_ts(e["when"]).replace(tzinfo=None)
                  for e in events if e["path"] == path}
        for prev, cur in zip(turns, turns[1:]):
            if not (prev["t"] and cur["t"]):
                continue
            gap = (cur["t"] - prev["t"]).total_seconds()
            fine, coarse = set(), set()
            for t, lab, rtype in index[path]:
                if prev["t"] < t <= cur["t"]:
                    fine.add(lab)
                    coarse.add(str(rtype))
            row = (gap, fine, coarse)
            if any(abs((cur["t"].replace(tzinfo=None) - w).total_seconds()) < 1 for w in wanted):
                ev.append(row)
            else:
                ctl.append(row)

    print("GAP DISTRIBUTION  the confound this arm exists to divide out")
    egaps = sorted(g for g, _, _ in ev)
    cgaps = sorted(g for g, _, _ in ctl)
    print("   event   n=%3d  min %.0fs  median %.0fs  max %.0fs"
          % (len(egaps), egaps[0], sweep.median(egaps), egaps[-1]))
    print("   control n=%3d  min %.0fs  median %.0fs  max %.0fs"
          % (len(cgaps), cgaps[0], sweep.median(cgaps), cgaps[-1]))
    print()

    print("PRESENCE PER WINDOW, STRATIFIED BY GAP   (event k/n vs control k/n)")
    for shape in WATCH:
        print()
        print("   %s" % shape)
        print("      %-16s %14s %16s %8s" % ("gap band", "event", "control", "ratio"))
        for lo, hi in BANDS:
            e = [r for r in ev if lo <= r[0] < hi]
            c = [r for r in ctl if lo <= r[0] < hi]
            eh = sum(1 for r in e if shape in r[2] or shape in r[1])
            ch = sum(1 for r in c if shape in r[2] or shape in r[1])
            if not e and not c:
                continue
            er = (eh / float(len(e))) if e else None
            cr = (ch / float(len(c))) if c else None
            ratio = ("%.2fx" % (er / cr)) if (er is not None and cr) else "-"
            print("      %-16s %5s %8s %6s %9s %8s"
                  % ("%d-%ds" % (lo, hi) if hi < 10 ** 9 else "%d s+" % lo,
                     "%d/%d" % (eh, len(e)) if e else "-",
                     ("%.0f%%" % (100 * er)) if er is not None else "",
                     "%d/%d" % (ch, len(c)) if c else "-",
                     ("%.0f%%" % (100 * cr)) if cr is not None else "",
                     ratio))

    print()
    print("SYSTEM SUBTYPES at the 9 events, which the pooled run could not separate")
    sub = Counter()
    for _, fine, _ in ev:
        sub.update(s for s in fine if s.startswith("system/"))
    print("   events: %s" % (dict(sub) or "none"))
    csub = Counter()
    for _, fine, _ in ctl:
        csub.update(s for s in fine if s.startswith("system/"))
    print("   control (windows containing each, of %d): %s" % (len(ctl), dict(csub) or "none"))


if __name__ == "__main__":
    main()
