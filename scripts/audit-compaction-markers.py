#!/usr/bin/env python
"""Task 7: does the sweep's compaction classifier see the client's real compaction family?

The classifier (sweep-cache-rewrites.py, session_turns) keys on exactly two shapes:
`isCompactSummary is True`, or a `system` record whose `subtype` contains `compact`. The binary
instruments at least twelve distinct compaction events (docs/cache-prefix-rewrite-experiments.md
section 1.5), so a compaction writing neither marker reaches the residual set as UNEXPLAINED.

Runs in the enumeration direction on purpose: inventory every `compact`-bearing record shape the
corpus actually holds, THEN ask which ones the classifier sees. A grep run once per already-named
marker cannot surface a marker nobody named.

Aggregates print; per-event detail goes to .task3-probe/compaction-marker-audit.txt.
"""
import glob
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

ROOT = os.path.expanduser("~/.claude/projects")
PROBE = os.path.join(os.path.dirname(HERE), ".task3-probe")
JOIN = os.path.join(PROBE, "cache-miss-reason-join.txt")
OUT = os.path.join(PROBE, "compaction-marker-audit.txt")

# A bare invocation is the one that does the whole audit, so an unrecognised argument must not be
# treated like no argument at all -- the failure mode named in the global CLAUDE.md.
REASON = "messages_changed"
for arg in sys.argv[1:]:
    if not arg.startswith("--reason="):
        sys.exit("unknown argument %r; this script takes --reason=LABEL or nothing" % arg)
    REASON = arg.split("=", 1)[1]


def walk(obj, path="$"):
    """Yield (json-path, key-or-None, value) for every key and scalar in a record."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield (path + "." + k, k, v)
            for item in walk(v, path + "." + k):
                yield item
    elif isinstance(obj, list):
        for v in obj:
            for item in walk(v, path + "[]"):
                yield item


def classifier_sees(rec):
    return rec.get("isCompactSummary") is True or (
        rec.get("type") == "system" and "compact" in str(rec.get("subtype", "")).lower())


def main():
    paths = sorted(glob.glob(os.path.join(ROOT, "*", "*.jsonl")))

    # ---- step 1: enumerate every compact-bearing shape, corpus-wide -------------------------
    key_shapes = Counter()
    val_shapes = Counter()
    marker_index = defaultdict(list)
    n_records = 0

    for path in paths:
        for rec in sweep.records(path):
            n_records += 1
            rtype = str(rec.get("type"))
            sub = str(rec.get("subtype")) if rec.get("subtype") is not None else "-"
            hits_k, hits_v = set(), set()
            for jpath, key, val in walk(rec):
                if key is not None and "compact" in key.lower():
                    hits_k.add(jpath)
                if isinstance(val, str) and "compact" in val.lower():
                    hits_v.add(jpath)
            if not hits_k and not hits_v:
                continue
            visible = classifier_sees(rec)
            for h in sorted(hits_k):
                key_shapes[(rtype, sub, h, visible)] += 1
            for h in sorted(hits_v):
                val_shapes[(rtype, sub, h, visible)] += 1
            marker_index[path].append({
                "t": sweep.parse_ts(rec.get("timestamp")),
                "type": rtype, "subtype": sub, "visible": visible,
                "keys": sorted(hits_k), "vals": sorted(hits_v),
            })

    print("corpus: %d files, %d records" % (len(paths), n_records))
    print()
    print("STEP 1  compact-bearing shapes, KEY matches   (SEEN = one of the classifier's two)")
    for (rtype, sub, jpath, visible), n in sorted(key_shapes.items(), key=lambda kv: -kv[1]):
        print("   %-9s %-20s %-44s %-5s %6d"
              % (rtype, sub, jpath, "SEEN" if visible else "BLIND", n))
    print()
    print("STEP 1  compact-bearing shapes, string-VALUE matches")
    for (rtype, sub, jpath, visible), n in sorted(val_shapes.items(), key=lambda kv: -kv[1]):
        print("   %-9s %-20s %-44s %-5s %6d"
              % (rtype, sub, jpath, "SEEN" if visible else "BLIND", n))
    print()
    total_marker_recs = sum(len(v) for v in marker_index.values())
    visible_recs = sum(1 for v in marker_index.values() for r in v if r["visible"])
    print("STEP 2  %d records carry a compact marker; the classifier scores %d (%d blind)"
          % (total_marker_recs, visible_recs, total_marker_recs - visible_recs))
    print()

    # ---- step 3: positive control -- does the classifier ever fire? -------------------------
    fired, fired_sessions = 0, set()
    for path in paths:
        turns, compactions = sweep.session_turns(path)
        for prev, cur in zip(turns, turns[1:]):
            gap = ((cur["t"] - prev["t"]).total_seconds()
                   if prev["t"] and cur["t"] else None)
            if "compaction" in sweep.classify(prev, cur, gap, compactions):
                fired += 1
                fired_sessions.add(path)
    print("STEP 3  positive control: %d boundaries classify as `compaction`, over %d sessions"
          % (fired, len(fired_sessions)))
    print("        (a zero here would make step 4's null unreadable)")
    print()

    # ---- step 4: join the markers onto the target events ------------------------------------
    events = []
    with io.open(JOIN, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line.startswith("{"):
                continue
            rec = json.loads(line)
            if rec.get("reason") == REASON and rec.get("causes") == ["UNEXPLAINED"]:
                events.append(rec)
    print("STEP 4  %d UNEXPLAINED events with reason=%s" % (len(events), REASON))

    detail, growth_rows = [], []
    with_marker = 0
    for ev in events:
        path = ev["path"]
        when = sweep.parse_ts(ev["when"])
        turns, _ = sweep.session_turns(path)
        prev = cur = None
        for a, b in zip(turns, turns[1:]):
            if b["t"] and when and abs((b["t"].replace(tzinfo=None)
                                        - when.replace(tzinfo=None)).total_seconds()) < 1:
                prev, cur = a, b
                break
        if cur is None:
            detail.append("NO BOUNDARY MATCHED for %s %s" % (ev["when"], path))
            print("   !! no boundary matched for %s" % ev["when"])
            continue
        lo, hi = prev["t"], cur["t"]
        in_window = [m for m in marker_index.get(path, [])
                     if m["t"] and lo and hi and lo <= m["t"] <= hi]
        blind = [m for m in in_window if not m["visible"]]
        if in_window:
            with_marker += 1

        deltas = [b["total"] - a["total"] for a, b in zip(turns, turns[1:])]
        ordered = sorted(deltas)
        q1 = ordered[len(ordered) // 4] if ordered else 0
        q3 = ordered[(3 * len(ordered)) // 4] if ordered else 0
        growth_rows.append((ev["when"], os.path.basename(path)[:8], prev["total"],
                            cur["total"], cur["total"] - prev["total"],
                            q1, sweep.median(deltas), q3, len(deltas)))
        detail.append("=== %s  %s" % (ev["when"], path))
        detail.append("    window %s .. %s   markers: %d (blind: %d)"
                      % (lo, hi, len(in_window), len(blind)))
        for m in in_window:
            detail.append("      %s %s/%s keys=%s vals=%s"
                          % ("SEEN " if m["visible"] else "BLIND", m["type"], m["subtype"],
                             m["keys"], m["vals"]))
        detail.append("    prev_total=%d cur_total=%d delta=%+d"
                      % (prev["total"], cur["total"], cur["total"] - prev["total"]))

    print("        %d of %d have ANY compact-bearing record in the boundary window"
          % (with_marker, len(events)))
    print()
    print("ARITHMETIC ARM  does the prefix shrink, as a compaction requires?")
    print("   %-19s %-9s %10s %10s %10s | %8s %8s %8s %4s"
          % ("when", "session", "prev_total", "cur_total", "delta",
             "sess q1", "sess med", "sess q3", "n"))
    shrank = 0
    for row in growth_rows:
        print("   %-19s %-9s %10d %10d %+10d | %8d %8.0f %8d %4d" % row)
        if row[4] < 0:
            shrank += 1
    print("   %d of %d events show a prefix that shrank" % (shrank, len(growth_rows)))

    with io.open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(detail) + "\n")
    print()
    print("per-event detail written to .task3-probe/%s (not printed)" % os.path.basename(OUT))


if __name__ == "__main__":
    main()
