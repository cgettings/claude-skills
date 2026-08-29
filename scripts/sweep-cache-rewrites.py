"""Enumerate and classify mid-session prompt-prefix rewrites across all session transcripts.

Answers "when did a session rebuild its whole cached prefix, and why" by walking every
~/.claude/projects/*/*.jsonl, flagging turns where a substantial cached prefix collapsed and
was rebuilt, and classifying each against the causes a transcript can actually settle.

The transcript cannot recover the *content* of an injected instruction block (grep -c
system-reminder returns 0 on these files). It can enumerate, date, and classify occurrences.
Do not let the first limitation retire the second.

Three parsing traps, each of which produced a confidently wrong number in a first draft:
  * Five transcripts store pretty-printed multi-line records. A line-oriented parse drops
    1,894 assistant turns silently while reporting a 56% "bad JSON" rate. Hence raw_decode.
  * One API call emits several assistant records repeating the same usage object. Without
    requestId dedupe, 99 real events read as 302, each classified one trailed by a phantom
    UNEXPLAINED half a second later.
  * All-zero-usage rows are aborted turns. They must be dropped from the sequence but
    remembered, because an abort is itself a cause of the next turn's rebuild.

Instrument self-check: on an ordinary turn cache_read[i] == crea[i-1] + read[i-1]. If that
does not hold for the overwhelming majority of turn pairs, the sweep is misaligned and its
counts mean nothing -- investigate before reading any result.

Usage:  python scripts/sweep-cache-rewrites.py [--all]
        --all  list every event, not only the unexplained ones
"""

import collections
import datetime
import glob
import json
import os
import sys

ROOT = os.path.expanduser("~/.claude/projects")
DECODER = json.JSONDecoder()

# A rewrite worth flagging: a real prefix existed, it collapsed, and it was rebuilt at cost.
PREV_MIN = 50000
COLLAPSE = 0.5
CREATE_MIN = 50000


def records(path):
    """Yield every top-level JSON object, whether one-per-line or pretty-printed."""
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        blob = handle.read()
    i, n = 0, len(blob)
    while i < n:
        while i < n and blob[i].isspace():
            i += 1
        if i >= n:
            break
        try:
            obj, end = DECODER.raw_decode(blob, i)
        except ValueError:
            nxt = blob.find("\n", i)
            if nxt == -1:
                break
            i = nxt + 1
            continue
        if isinstance(obj, dict):
            yield obj
        i = end


def parse_ts(value):
    try:
        return datetime.datetime.fromisoformat((value or "").replace("Z", "+00:00"))
    except ValueError:
        return None


def session_turns(path):
    """Deduplicated assistant turns for one transcript, plus its compaction timestamps."""
    turns, seen, compactions = [], set(), []
    for rec in records(path):
        if rec.get("isCompactSummary") is True or (
            rec.get("type") == "system" and "compact" in str(rec.get("subtype", "")).lower()
        ):
            compactions.append(parse_ts(rec.get("timestamp")))
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
                turns[-1]["abort_after"] = True   # an aborted turn precedes the next rebuild
            continue
        turns.append({
            "t": parse_ts(rec.get("timestamp")),
            "effort": rec.get("effort"),
            "model": msg.get("model"),
            "version": rec.get("version"),
            "read": read,
            "crea": crea,
            "total": inp + crea + read,
            "ttl5m": (usage.get("cache_creation") or {}).get("ephemeral_5m_input_tokens", 0),
        })
    return turns, compactions


def classify(prev, cur, gap, compactions):
    causes = []
    if prev.get("abort_after"):
        causes.append("abort-before")
    if any(c and prev["t"] and cur["t"] and prev["t"] <= c <= cur["t"] for c in compactions):
        causes.append("compaction")
    if gap is not None and gap > 3600:
        causes.append("TTL-1h")
    elif gap is not None and gap > 300 and prev["ttl5m"]:
        causes.append("TTL-5m")
    if prev["effort"] != cur["effort"]:
        causes.append("effort %s->%s" % (prev["effort"], cur["effort"]))
    if prev["model"] != cur["model"]:
        causes.append("model")
    if prev["version"] != cur["version"]:
        causes.append("version %s->%s" % (prev["version"], cur["version"]))
    return causes or ["UNEXPLAINED"]


def main():
    show_all = "--all" in sys.argv[1:]
    events = []
    stats = collections.Counter()
    continuity = collections.Counter()

    for path in sorted(glob.glob(os.path.join(ROOT, "*", "*.jsonl"))):
        stats["files"] += 1
        turns, compactions = session_turns(path)
        stats["turns"] += len(turns)
        if not turns:
            continue
        start_floor = turns[0]["read"]   # the already-warm tools/system block at session start

        for i in range(1, len(turns)):
            prev, cur = turns[i - 1], turns[i]
            continuity["exact" if cur["read"] == prev["crea"] + prev["read"] else "broken"] += 1
            if not (prev["total"] > PREV_MIN
                    and cur["read"] < COLLAPSE * prev["total"]
                    and cur["crea"] > CREATE_MIN):
                continue
            gap = (cur["t"] - prev["t"]).total_seconds() if (cur["t"] and prev["t"]) else None
            events.append({
                "when": cur["t"].isoformat()[:19] if cur["t"] else "?",
                "gap": gap,
                "prev_total": prev["total"],
                "read": cur["read"],
                "crea": cur["crea"],
                "start_floor": start_floor,
                "offset": cur["read"] - start_floor,
                "version": cur["version"],
                "effort": cur["effort"],
                "project": os.path.basename(os.path.dirname(path)),
                "causes": classify(prev, cur, gap, compactions),
            })

    events.sort(key=lambda e: e["when"])
    unexplained = [e for e in events if e["causes"] == ["UNEXPLAINED"]]

    print("files=%(files)d  turns=%(turns)d" % stats)
    print("continuity self-check  cache_read[i] == crea[i-1]+read[i-1]:  %d exact / %d broken"
          % (continuity["exact"], continuity["broken"]))
    if continuity["exact"] < 20 * continuity["broken"]:
        print("!! SELF-CHECK WEAK -- the sweep may be misaligned; do not trust the counts below")
    print()
    print("rewrite events: %d   unexplained: %d" % (len(events), len(unexplained)))
    for cause, n in collections.Counter(",".join(e["causes"]) for e in events).most_common():
        print("   %-34s %d" % (cause, n))

    print()
    print("=== %s ===" % ("ALL EVENTS" if show_all else "UNEXPLAINED EVENTS"))
    print("%-20s %-8s %-9s %-8s %-9s %-7s %-6s %s"
          % ("when", "gap_s", "prev_tot", "collapse", "rebuilt", "offset", "eff", "version"))
    for e in (events if show_all else unexplained):
        print("%-20s %-8s %-9d %-8d %-9d %-7d %-6s %s"
              % (e["when"], "%.0f" % e["gap"] if e["gap"] is not None else "?",
                 e["prev_total"], e["read"], e["crea"], e["offset"],
                 e["effort"], e["version"]))

    # The offset above each session's own start floor is the load-bearing number: a discrete
    # constant that steps with version implies a fixed block above the break, not conversation.
    usable = [e for e in unexplained if e["start_floor"] > 0 and e["read"] > 0]
    print()
    print("offset above session start floor, unexplained only (%d usable of %d):"
          % (len(usable), len(unexplained)))
    for offset, n in sorted(collections.Counter(e["offset"] for e in usable).items()):
        print("   %-8d %d event(s)" % (offset, n))


if __name__ == "__main__":
    main()
