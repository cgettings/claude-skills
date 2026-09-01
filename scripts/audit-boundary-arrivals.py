#!/usr/bin/env python
"""Task 7b: what arrives at the 9 `messages_changed` boundaries, against a same-session control.

Task 7 excluded compaction and left an insertion reading: the nine rewrite everything below the
tool-definitions breakpoint while the prefix GROWS by more than an ordinary turn. I1 records
injected content as `attachment` records, so this is answerable from disk.

Scored as presence-per-window, not record count, so one burst cannot carry a subtype. Control is
every other boundary in those same sessions. Aggregates print; per-event detail goes to
.task3-probe/boundary-arrivals.txt.
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
OUT = os.path.join(PROBE, "boundary-arrivals.txt")

REASON = "messages_changed"
for arg in sys.argv[1:]:
    if not arg.startswith("--reason="):
        sys.exit("unknown argument %r; this script takes --reason=LABEL or nothing" % arg)
    REASON = arg.split("=", 1)[1]

# Pre-registered in the plan: these two are corpus-dominant and are expected to appear in both arms.
NO_POWER = {"attachment/output_style", "attachment/total_tokens_reminder"}


def label(rec):
    """One stable name per record shape: attachments by subtype, everything else by type."""
    rtype = str(rec.get("type"))
    if rtype == "attachment":
        att = rec.get("attachment") or {}
        return "attachment/%s" % (att.get("type") if isinstance(att, dict) else "?")
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
    print("Task 7b: %d events with reason=%s, over %d sessions" % (len(events), REASON, len(paths)))

    # index every record by session, with its timestamp and shape label
    index = defaultdict(list)
    for path in paths:
        for rec in sweep.records(path):
            t = sweep.parse_ts(rec.get("timestamp"))
            if t is not None:
                index[path].append((t, label(rec)))
        index[path].sort(key=lambda x: x[0])

    ev_windows, ctl_windows = [], []
    detail = []
    for path in paths:
        turns, _ = sweep.session_turns(path)
        wanted = set()
        for e in events:
            if e["path"] != path:
                continue
            wanted.add(sweep.parse_ts(e["when"]).replace(tzinfo=None))
        for prev, cur in zip(turns, turns[1:]):
            if not (prev["t"] and cur["t"]):
                continue
            shapes = {lab for t, lab in index[path] if prev["t"] < t <= cur["t"]}
            is_event = any(abs((cur["t"].replace(tzinfo=None) - w).total_seconds()) < 1
                           for w in wanted)
            (ev_windows if is_event else ctl_windows).append(shapes)
            if is_event:
                detail.append("=== %s  %s" % (cur["t"], os.path.basename(path)[:8]))
                detail.append("    %s" % sorted(shapes))

    print("   event windows: %d   same-session control windows: %d"
          % (len(ev_windows), len(ctl_windows)))
    print()

    ev_n = Counter()
    for s in ev_windows:
        ev_n.update(s)
    ctl_n = Counter()
    for s in ctl_windows:
        ctl_n.update(s)

    print("PRESENCE PER WINDOW   event k/%d   control k/%d" % (len(ev_windows), len(ctl_windows)))
    print("   %-38s %10s %10s %9s  %s"
          % ("record shape", "event", "control", "ratio", "verdict"))
    rows = sorted(set(ev_n) | set(ctl_n), key=lambda k: -ev_n[k])
    for k in rows:
        e_rate = ev_n[k] / float(len(ev_windows)) if ev_windows else 0.0
        c_rate = ctl_n[k] / float(len(ctl_windows)) if ctl_windows else 0.0
        ratio = (e_rate / c_rate) if c_rate else float("inf")
        # verdicts, in the order the pre-registration fixes them
        if k in NO_POWER and ev_n[k] >= 0.8 * len(ev_windows) and c_rate >= 0.5:
            verdict = "NO POWER (pre-registered)"
        elif ev_n[k] < 3:
            verdict = "underpowered (n<3)"
        elif e_rate >= 0.8 and c_rate >= 0.5:
            verdict = "NO POWER (present in both arms)"
        elif ratio >= 2.0:
            verdict = "ENRICHED"
        elif ratio <= 0.5:
            verdict = "depleted"
        else:
            verdict = "at base rate"
        print("   %-38s %4d %5.0f%% %4d %5.0f%% %9s  %s"
              % (k, ev_n[k], 100 * e_rate, ctl_n[k], 100 * c_rate,
                 ("%.2fx" % ratio) if ratio != float("inf") else "inf", verdict))

    with io.open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(detail) + "\n")
    print()
    print("per-event detail written to .task3-probe/%s (not printed)" % os.path.basename(OUT))


if __name__ == "__main__":
    main()
