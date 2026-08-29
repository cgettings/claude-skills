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

Threshold caveat: CREATE_MIN is a floor on the *rebuild*, so this sees large rebuilds only.
A real compaction rewrite in session 2e2d5ebe on 2026-08-29 collapsed 232,740 -> 27,775 and
rebuilt 46,219, and went unflagged. Read every count here as a lower bound, not a total.

Usage:  python scripts/sweep-cache-rewrites.py [--all] [--step3]
        --all    list every event, not only the unexplained ones
        --step3  re-test the explanations ruled out on 2026-08-26, each against a control
                 drawn from the same sessions and normalised by window duration
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


def median(values):
    ordered = sorted(values)
    if not ordered:
        return 0.0
    mid = len(ordered) // 2
    if len(ordered) % 2:
        return float(ordered[mid])
    return (ordered[mid - 1] + ordered[mid]) / 2.0


def collect_signals():
    """Timelines for the explanations that were ruled out against two events in 2026-08.

    Two scopes, deliberately. Skill use and permission mode are properties of the session that
    rewrote, so they are kept per transcript. A CLAUDE.md or memory-store write is not: another
    Claude session editing those files is exactly the cross-session case the original two-event
    pass had no way to see, so those go in one global timeline keyed only by time.

    Blind spot, and it has a floor: an edit made by hand outside Claude Code leaves no trace in
    any transcript. The 2026-08-26 em-dash normalisation was one. This cannot return a clean zero.
    """
    per_session = collections.defaultdict(list)
    global_edits = []
    for path in sorted(glob.glob(os.path.join(ROOT, "*", "*.jsonl"))):
        for rec in records(path):
            when = parse_ts(rec.get("timestamp"))
            if when is None:
                continue
            mode = rec.get("permissionMode")
            if mode:
                per_session[path].append((when, "mode", str(mode)))
            content = (rec.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                name = block.get("name") or ""
                if name == "Skill":
                    per_session[path].append((when, "skill", ""))
                if name in ("Edit", "Write", "NotebookEdit", "MultiEdit"):
                    target = str((block.get("input") or {}).get("file_path") or "")
                    norm = target.replace(os.sep, "/")
                    if norm.endswith("CLAUDE.md"):
                        global_edits.append((when, "claudemd"))
                    if "/memory/" in norm:
                        global_edits.append((when, "memory"))
    return per_session, global_edits


def fired(kind, path, t_prev, t_cur, per_session, global_edits):
    """Did `kind` occur in the window (t_prev, t_cur] that precedes a rewrite?"""
    if t_prev is None or t_cur is None:
        return False
    if kind in ("claudemd", "memory"):
        return any(k == kind and t_prev < w <= t_cur for w, k in global_edits)
    rows = per_session.get(path, ())
    if kind == "skill":
        return any(k == "skill" and t_prev < w <= t_cur for w, k, _ in rows)
    # A permission-mode change, not merely a mode being recorded: compare what the window
    # contains against the last value seen at or before it.
    before = [v for w, k, v in rows if k == "mode" and w <= t_prev]
    inside = [v for w, k, v in rows if k == "mode" and t_prev < w <= t_cur]
    return bool(inside) and (not before or any(v != before[-1] for v in inside))


def step3(unexplained, boundaries, per_session, global_edits):
    """Re-test the ruled-out explanations at n=31, each beside a control that it can fire at all."""
    print()
    print("=== Task 1 Step 3: the six explanations ruled out on 2026-08-26, re-tested ===")
    print("TTL and effort switch are 0 by construction -- the classifier removes them before an")
    print("event can reach the unexplained set. They are not evidence, and are not counted below.")
    print()
    # Every predicate asks whether a timestamped signal fell inside a window, so a longer window
    # catches more of everything by construction. Raw counts are therefore not comparable between
    # the two populations; hits per window-hour are. Report both, and read the second.
    def seconds(a, b):
        return (b - a).total_seconds() if (a and b) else 0.0

    # Control only on boundaries from the sessions that actually contain an event. An event window
    # sits in a busy session by construction, and every signal here clusters in busy sessions, so
    # a control drawn from all 367 transcripts would credit that clustering to the predicate.
    host_sessions = set(e["path"] for e in unexplained)
    event_windows = set((e["path"], e["t_prev"], e["t"]) for e in unexplained)
    boundaries = [b for b in boundaries if b[0] in host_sessions and b not in event_windows]

    ev_secs = sum(seconds(e["t_prev"], e["t"]) for e in unexplained)
    ct_secs = sum(seconds(a, b) for _, a, b in boundaries)
    print("window exposure: unexplained %.1f h over %d windows, control %.1f h over %d windows"
          % (ev_secs / 3600.0, len(unexplained), ct_secs / 3600.0, len(boundaries)))
    print("median window: unexplained %.0f s, control %.0f s"
          % (median([seconds(e["t_prev"], e["t"]) for e in unexplained]),
             median([seconds(a, b) for _, a, b in boundaries])))
    print()
    print("%-16s %-14s %-16s %-12s %-12s %s"
          % ("predicate", "unexplained", "control", "ev/hour", "ctrl/hour", "verdict"))
    for kind, label in (("mode", "permission mode"), ("skill", "skill use"),
                        ("claudemd", "CLAUDE.md edit"), ("memory", "memory write")):
        hits = sum(1 for e in unexplained
                   if fired(kind, e["path"], e["t_prev"], e["t"], per_session, global_edits))
        ctrl = sum(1 for path, a, b in boundaries
                   if fired(kind, path, a, b, per_session, global_edits))
        ev_rate = hits / (ev_secs / 3600.0) if ev_secs else 0.0
        ct_rate = ctrl / (ct_secs / 3600.0) if ct_secs else 0.0
        if ctrl == 0:
            verdict = "DEAD PROBE -- its zero means nothing"
        elif hits == 0:
            verdict = "confirmed ruled out"
        elif ct_rate and ev_rate / ct_rate < 2.0:
            verdict = "at base rate -- no signal"
        else:
            verdict = "ENRICHED %.1fx -- worth a look" % (ev_rate / ct_rate if ct_rate else 0)
        print("%-16s %-14s %-16s %-12.2f %-12.2f %s"
              % (label, "%d / %d" % (hits, len(unexplained)),
                 "%d / %d" % (ctrl, len(boundaries)), ev_rate, ct_rate, verdict))


def main():
    show_all = "--all" in sys.argv[1:]
    run_step3 = "--step3" in sys.argv[1:]
    events = []
    boundaries = []
    stats = collections.Counter()
    continuity = collections.Counter()

    sessions = []
    for path in sorted(glob.glob(os.path.join(ROOT, "*", "*.jsonl"))):
        stats["files"] += 1
        turns, compactions = session_turns(path)
        stats["turns"] += len(turns)
        if not turns:
            continue
        sessions.append((path, turns, compactions))

    # A session's own first-turn cache_read is 0 when it starts genuinely cold and inflated when it
    # resumes warm, so it is not a baseline -- it is why seven events have no usable floor and two
    # go negative. Use instead the smallest positive first-turn read seen across sessions sharing a
    # version AND a project, which is a property of the fixed blocks rather than of one session's
    # history. Both keys are needed: the always-loaded CLAUDE.md files sit above the breakpoint too
    # and differ per project, so a floor pooled across projects measures the wrong thing.
    version_floor = {}
    for path, turns, _ in sessions:
        key = (turns[0]["version"], os.path.basename(os.path.dirname(path)))
        r = turns[0]["read"]
        if r > 0 and r < version_floor.get(key, 1 << 30):
            version_floor[key] = r

    for path, turns, compactions in sessions:
        proj = os.path.basename(os.path.dirname(path))
        start_floor = turns[0]["read"]   # the already-warm tools/system block at session start

        for i in range(1, len(turns)):
            prev, cur = turns[i - 1], turns[i]
            continuity["exact" if cur["read"] == prev["crea"] + prev["read"] else "broken"] += 1
            boundaries.append((path, prev["t"], cur["t"]))
            if not (prev["total"] > PREV_MIN
                    and cur["read"] < COLLAPSE * prev["total"]
                    and cur["crea"] > CREATE_MIN):
                continue
            gap = (cur["t"] - prev["t"]).total_seconds() if (cur["t"] and prev["t"]) else None
            events.append({
                "when": cur["t"].isoformat()[:19] if cur["t"] else "?",
                "path": path,
                "t": cur["t"],
                "t_prev": prev["t"],
                "gap": gap,
                "prev_total": prev["total"],
                "read": cur["read"],
                "crea": cur["crea"],
                "start_floor": start_floor,
                "offset": cur["read"] - start_floor,
                "vfloor": version_floor.get((cur["version"], proj), 0),
                "voffset": cur["read"] - version_floor.get((cur["version"], proj), 0),
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

    # The same offsets against a per-version floor, grouped by version. Two questions at once:
    # whether the floor above rescues the events the per-session one could not measure, and
    # whether the offset is a pure function of version -- which zero within-version variance
    # would say and any spread would deny.
    # Two populations, and pooling them is what manufactured every negative offset: an event whose
    # cache_read is 0 rebuilt from nothing at all, so it has no floor to sit above and its "offset"
    # is just minus the floor. Only read > 0 events carry an offset worth banding.
    cold = [e for e in unexplained if e["read"] == 0]
    warm = [e for e in unexplained if e["read"] > 0]
    by_version = collections.defaultdict(list)
    for e in warm:
        by_version[(e["version"], e["project"])].append(e)
    print()
    print("unexplained split: %d rebuilt from a floor (read>0), %d rebuilt from nothing (read==0)"
          % (len(warm), len(cold)))
    print()
    print("offset above per-version-and-project floor, read>0 events only:")
    print("   (a group with floor=0 had no session that started warm on that version+project)")
    for key in sorted(by_version, key=str):
        rows = by_version[key]
        offsets = sorted(r["voffset"] for r in rows)
        print("   %-10s %-38s floor=%-7d n=%-3d spread=%-7d offsets: %s"
              % (key[0], key[1][-38:], rows[0]["vfloor"], len(rows),
                 offsets[-1] - offsets[0], " ".join(str(o) for o in offsets)))

    if run_step3:
        per_session, global_edits = collect_signals()
        step3(unexplained, boundaries, per_session, global_edits)


if __name__ == "__main__":
    main()
