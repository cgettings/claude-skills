"""Join the server's own cache_miss_reason onto the sweep's rewrite events.

The API returns a diagnosis of why a prompt-cache prefix missed, on the assistant message:
message.diagnostics.cache_miss_reason = {"type": ..., "cache_missed_input_tokens": N}. The sweep
never read it, so the whole residual "UNEXPLAINED" set was built without consulting the one field
that names the cause directly.

Turn construction mirrors sweep-cache-rewrites.py's session_turns() exactly -- same dedup key, same
all-zero-aborted-turn skip, same usage floor -- and adds `diag`. It is duplicated rather than
imported because session_turns() drops the raw record before the caller sees it; any change to the
sweep's turn rules must be mirrored here or the two populations silently diverge.

Coverage is the thing to read first, not the distribution: diagnostics ride on a minority of turns,
so "no reason on the 33" would mean the field was absent, NOT that the events have no cause.

Usage:  python scripts/join-cache-miss-reason.py [--min-create=N] [--out=FILE]
"""

import collections
import glob
import importlib.util
import json
import os
import sys

_SWEEP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sweep-cache-rewrites.py")
_spec = importlib.util.spec_from_file_location("sweep_cache_rewrites", _SWEEP)
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)


def turns_with_diagnostics(path):
    """session_turns(), plus the message.diagnostics the sweep discards."""
    turns, seen, compactions = [], set(), []
    bridges, mode = 0, None
    for rec in sweep.records(path):
        if rec.get("type") == "bridge-session":
            bridges += 1
        if rec.get("permissionMode"):
            mode = str(rec["permissionMode"])
        if rec.get("isCompactSummary") is True or (
            rec.get("type") == "system" and "compact" in str(rec.get("subtype", "")).lower()
        ):
            compactions.append(sweep.parse_ts(rec.get("timestamp")))
        if rec.get("type") != "assistant" or rec.get("isSidechain"):
            continue
        msg = rec.get("message") or {}
        usage = msg.get("usage") or {}
        if "cache_read_input_tokens" not in usage:
            continue
        key = rec.get("requestId") or msg.get("id") or rec.get("uuid")
        if key in seen:
            continue
        seen.add(key)
        inp = usage.get("input_tokens") or 0
        crea = usage.get("cache_creation_input_tokens") or 0
        read = usage.get("cache_read_input_tokens") or 0
        if inp + crea + read == 0:
            if turns:
                turns[-1]["abort_after"] = True
            continue
        turns.append({
            "bridges_before": bridges,
            "mode": mode,
            "t": sweep.parse_ts(rec.get("timestamp")),
            "effort": rec.get("effort"),
            "model": msg.get("model"),
            "version": rec.get("version"),
            "read": read,
            "crea": crea,
            "total": inp + crea + read,
            "ttl5m": (usage.get("cache_creation") or {}).get("ephemeral_5m_input_tokens", 0),
            "diag": (msg.get("diagnostics") or {}).get("cache_miss_reason"),
        })
        bridges = 0
    return turns, compactions


def reason_of(turn):
    d = turn.get("diag")
    return d.get("type") if isinstance(d, dict) else None


def main():
    min_create = 0
    out = ".task3-probe/cache-miss-reason-join.txt"
    for arg in sys.argv[1:]:
        if arg.startswith("--min-create="):
            min_create = int(arg.split("=", 1)[1])
        elif arg.startswith("--out="):
            out = arg.split("=", 1)[1]
        else:
            sys.exit("unknown argument: %s" % arg)

    paths = sorted(glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")))
    events, all_turns = [], 0
    reason_everywhere = collections.Counter()

    for path in paths:
        turns, compactions = turns_with_diagnostics(path)
        all_turns += len(turns)
        for t in turns:
            reason_everywhere[reason_of(t)] += 1
        for i in range(1, len(turns)):
            prev, cur = turns[i - 1], turns[i]
            if not (prev["total"] > sweep.PREV_MIN
                    and cur["read"] < sweep.COLLAPSE * prev["total"]
                    and cur["crea"] > min_create):
                continue
            gap = (cur["t"] - prev["t"]).total_seconds() if (cur["t"] and prev["t"]) else None
            events.append({
                "when": cur["t"].isoformat()[:19] if cur["t"] else "?",
                "path": path,
                "causes": sweep.classify(prev, cur, gap, compactions),
                "reason": reason_of(cur),
                "missed": (cur["diag"] or {}).get("cache_missed_input_tokens")
                          if isinstance(cur.get("diag"), dict) else None,
                "gap": gap,
                "read": cur["read"],
                "crea": cur["crea"],
                "prev_total": prev["total"],
            })

    events.sort(key=lambda e: e["when"])
    unexplained = [e for e in events if e["causes"] == ["UNEXPLAINED"]]

    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="") as fh:
        for e in events:
            fh.write(json.dumps(e, default=str) + "\n")

    print("files=%d  turns=%d  events=%d  unexplained=%d"
          % (len(paths), all_turns, len(events), len(unexplained)))
    print("per-event detail written to %s (not printed)" % out)
    print()

    # Coverage first. A null here is "the field was absent", not "the event has no cause".
    covered = sum(1 for t_ in [None] for e in unexplained if e["reason"])
    print("COVERAGE  diagnostics present on %d of %d unexplained events (%.0f%%)"
          % (covered, len(unexplained), 100.0 * covered / max(1, len(unexplained))))
    print("          and on %d of %d turns corpus-wide (%.1f%%)"
          % (all_turns - reason_everywhere[None], all_turns,
             100.0 * (all_turns - reason_everywhere[None]) / max(1, all_turns)))
    print()

    print("cache_miss_reason on the UNEXPLAINED events")
    for r, n in collections.Counter(e["reason"] for e in unexplained).most_common():
        print("   %-28s %d" % (r, n))
    print()
    print("cache_miss_reason on ALL rewrite events")
    for r, n in collections.Counter(e["reason"] for e in events).most_common():
        print("   %-28s %d" % (r, n))
    print()
    print("cross-tab: sweep cause x server reason")
    xt = collections.Counter((",".join(e["causes"]), e["reason"]) for e in events)
    for (c, r), n in sorted(xt.items(), key=lambda kv: -kv[1]):
        print("   %-34s %-28s %d" % (c, r, n))


if __name__ == "__main__":
    main()
