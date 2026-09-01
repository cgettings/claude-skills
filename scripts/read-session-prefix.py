"""Per-turn prefix continuity for ONE session transcript, for Task 3 of the prefix-rewrite plan.

sweep-cache-rewrites.py answers "which sessions in the corpus rebuilt their prefix". It cannot
answer Task 3, because its PREV_MIN/CREATE_MIN floors are tuned to find large rebuilds in large
sessions and the Task 3 probe session runs a ~52,000-token prefix on purpose -- a rebuild there
sits right on the floor, where a threshold decides the answer. So this prints every turn and the
continuity identity itself, with no floor at all.

The identity: on an ordinary turn cache_read[i] == crea[i-1] + read[i-1]. A turn where it fails
is a rewrite; delta is what the rebuilt prefix carries above (or below) the prior total.

Parsing is imported from the sweep rather than reimplemented -- the three traps in its docstring
(pretty-printed records, requestId duplicates, all-zero aborted turns) apply here identically.

Usage:  python scripts/read-session-prefix.py <transcript.jsonl>
"""

import importlib.util
import os
import sys

_SWEEP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sweep-cache-rewrites.py")
_spec = importlib.util.spec_from_file_location("sweep_cache_rewrites", _SWEEP)
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__.strip().splitlines()[-1])
    path = sys.argv[1]
    turns, compactions = sweep.session_turns(path)
    print("%s\n%d turn(s), %d compaction record(s)\n" % (path, len(turns), len(compactions)))
    print("%-3s %-21s %-9s %9s %9s %9s  %s" %
          ("#", "timestamp", "version", "read", "create", "total", "continuity"))
    prev = None
    for n, cur in enumerate(turns, 1):
        if prev is None:
            note = "start (read=%d)" % cur["read"]
        else:
            expect = prev["crea"] + prev["read"]
            delta = cur["read"] - expect
            gap = (cur["t"] - prev["t"]).total_seconds() if cur["t"] and prev["t"] else None
            if delta == 0:
                note = "OK"
            elif delta < 0:
                # The prefix collapsed and was rebuilt. "rebuilt vs prev total" is deliberately
                # NOT the plan's "offset": that one measures the rebuild above a per-version
                # session-start floor, which needs the whole corpus. This is a within-session
                # figure and the two must not be quoted for each other.
                note = "REWRITE  read %d vs expected %d  collapse %d  rebuilt %d  vs prev total %+d" % (
                    cur["read"], expect, cur["read"], cur["crea"], cur["crea"] - expect)
                causes = sweep.classify(prev, cur, gap, compactions)
                note += "  cause: %s" % (", ".join(causes) if causes else "UNEXPLAINED")
            else:
                # read ABOVE the accounted prefix is not a rewrite -- nothing collapsed. It means
                # a turn that consumed tokens is missing from the sequence (a sidechain, or a
                # record this parse drops). These are part of the sweep's "broken" self-check
                # count; reading one as a rewrite is how a probe session would report a false hit.
                note = "GAP  read %d exceeds expected %d by %d -- a turn is unaccounted for, not a rewrite" % (
                    cur["read"], expect, delta)
        print("%-3d %-21s %-9s %9d %9d %9d  %s" % (
            n, cur["t"].strftime("%Y-%m-%dT%H:%M:%SZ") if cur["t"] else "?",
            cur["version"] or "?", cur["read"], cur["crea"], cur["total"], note))
        prev = cur


if __name__ == "__main__":
    main()
