#!/usr/bin/env python
"""Task 9 step 0: how does a memory topic file reach a session's context?

The question gates Task 9 step 1. If a topic file arrives as a *tool result* it
is ordinary conversation history, nothing re-reads it from disk, and arm 1
returns "stale" under every hypothesis -- the injection machinery would never
have been under test. If it arrives as an *injected block*, arm 1 is live.

This sweeps every session transcript on the machine for tool calls whose
file_path lands inside a `memory/` directory, and reports them by tool.

READ THE RESULT ONE-DIRECTIONALLY. A non-zero Read count proves the file-tool
path is real and in use. Zero would NOT prove the injection path, and no count
here can rule the injection path out: injected blocks are not written to the
session JSONL at all (docs/durable-memory-model.md, "What the transcripts
cannot do"), so this instrument is structurally blind to them.

Counts are also a floor, not a census -- a malformed line is skipped and
reported rather than guessed at. That is fine for the claim being made, which
is presence.

Exit status is 0 whenever the sweep completed; the finding is in the output,
not in the code. Chain it with `;`.
"""

import collections
import json
import os
import sys

ROOT = os.path.expanduser("~/.claude/projects")


def sweep(root: str) -> dict:
    """One pass over every .jsonl under root. One process, not one per file --
    Git Bash process creation makes a per-file loop unusable at this count."""
    by_tool = collections.Counter()
    sessions = set()
    memory_md = 0
    lines = files = parse_fail = file_fail = 0
    worst = collections.Counter()

    for dirpath, _dirs, names in os.walk(root):
        for name in names:
            if not name.endswith(".jsonl"):
                continue
            files += 1
            path = os.path.join(dirpath, name)
            try:
                # errors="replace": transcripts carry UTF-8 that the console
                # codepage cannot decode, and a hard failure here would look
                # like an absent result rather than an unread file.
                with open(path, encoding="utf-8", errors="replace") as fh:
                    for line in fh:
                        lines += 1
                        # Cheap prefilter. Strictly weaker than the real test
                        # below, which requires "/memory/" in the path, so it
                        # cannot exclude a hit the real test would have kept.
                        if "memory" not in line:
                            continue
                        try:
                            rec = json.loads(line)
                        except Exception:
                            parse_fail += 1
                            worst[name[:8]] += 1
                            continue
                        msg = rec.get("message")
                        if not isinstance(msg, dict):
                            continue
                        content = msg.get("content")
                        if not isinstance(content, list):
                            continue
                        for blk in content:
                            if not isinstance(blk, dict):
                                continue
                            if blk.get("type") != "tool_use":
                                continue
                            inp = blk.get("input") or {}
                            fp = str(inp.get("file_path") or inp.get("path") or "")
                            norm = fp.replace("\\", "/")
                            if "/memory/" not in norm.lower():
                                continue
                            base = norm.rsplit("/", 1)[-1]
                            if base.upper() == "MEMORY.MD":
                                memory_md += 1
                            elif norm.lower().endswith(".md"):
                                by_tool[blk.get("name", "?")] += 1
                                sessions.add(name)
            except OSError:
                file_fail += 1

    return {
        "by_tool": by_tool, "sessions": len(sessions), "memory_md": memory_md,
        "lines": lines, "files": files, "parse_fail": parse_fail,
        "file_fail": file_fail, "worst": worst.most_common(3),
    }


def main() -> int:
    if not os.path.isdir(ROOT):
        print(f"no transcript root at {ROOT}", file=sys.stderr)
        return 2
    r = sweep(ROOT)

    # Coverage first: a count means nothing until you know what was not read.
    print(f"transcripts scanned   : {r['files']}  ({r['lines']} lines)")
    print(f"files that failed open: {r['file_fail']}")
    print(f"lines unparsed        : {r['parse_fail']}  "
          f"most in: {r['worst']}")
    print()
    print(f"tool calls on TOPIC files : {sum(r['by_tool'].values())} "
          f"across {r['sessions']} sessions")
    for tool, n in r["by_tool"].most_common():
        print(f"    {tool:<8} {n}")
    print(f"tool calls on MEMORY.md   : {r['memory_md']}")
    print()
    reads = r["by_tool"].get("Read", 0)
    writes = r["by_tool"].get("Edit", 0) + r["by_tool"].get("Write", 0)
    if reads:
        print(f"=> file-tool READ path is real and in use ({reads} reads). "
              "Arm 1 on a topic file is void as an injection test; run it on "
              "an injected file instead.")
    else:
        print("=> no topic-file reads found. This does NOT establish the "
              "injection path -- see the module docstring.")
    print(f"=> {writes} writes to topic files: the concurrent-writer surface "
          "Task 7 reasons about is drawn from live behaviour, though this "
          "cannot show two sessions writing at once.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
