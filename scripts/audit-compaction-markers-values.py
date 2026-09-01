#!/usr/bin/env python
"""Task 7, follow-up: the distinct VALUES on the blind compact-bearing paths.

A path count says a record mentions "compact" somewhere; it does not say whether the mention is a
structural marker or prose. `$.attachment.type`, `$.attachment.hookName` and `$.lastPrompt` are the
three that could be markers rather than text, so print their distinct values with counts -- plus a
timestamp census, since the step-4 window filter drops any marker record carrying no timestamp.
"""
import glob
import importlib.util
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "sweep", os.path.join(HERE, "sweep-cache-rewrites.py"))
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)

ROOT = os.path.expanduser("~/.claude/projects")

if sys.argv[1:]:
    sys.exit("unknown argument %r; this script takes no arguments" % sys.argv[1])

# Short, structural fields only. Prose fields (message content, thinking, stdout) are excluded by
# construction: their values are paragraphs, and listing them would print the corpus.
STRUCTURAL = [
    ("attachment", lambda r: (r.get("attachment") or {}).get("type"), "$.attachment.type"),
    ("attachment", lambda r: (r.get("attachment") or {}).get("hookName"), "$.attachment.hookName"),
    ("last-prompt", lambda r: r.get("lastPrompt"), "$.lastPrompt"),
    ("system", lambda r: r.get("subtype"), "$.subtype (system)"),
    ("queue-operation", lambda r: r.get("content"), "$.content (queue-operation)"),
]

values = {label: Counter() for _, _, label in STRUCTURAL}
no_ts = Counter()
all_attachment_types = Counter()

for path in sorted(glob.glob(os.path.join(ROOT, "*", "*.jsonl"))):
    for rec in sweep.records(path):
        rtype = str(rec.get("type"))
        if rtype == "attachment":
            all_attachment_types[str((rec.get("attachment") or {}).get("type"))] += 1
        for want, getter, label in STRUCTURAL:
            if rtype != want:
                continue
            try:
                val = getter(rec)
            except AttributeError:
                continue
            if isinstance(val, str) and "compact" in val.lower():
                values[label][val.strip()[:110]] += 1
                if not rec.get("timestamp"):
                    no_ts[label] += 1

print("DISTINCT VALUES on the blind structural paths")
for _, _, label in STRUCTURAL:
    print()
    print("  %s" % label)
    if not values[label]:
        print("     (none)")
    for val, n in values[label].most_common():
        print("     %6d  %s" % (n, val))

print()
print("TIMESTAMP CENSUS  marker records carrying no timestamp (step 4's window filter drops these)")
print("   %s" % (dict(no_ts) or "none - every marker record above is timestamped"))

print()
print("CONTROL  every attachment subtype in the corpus, to show the enumeration is complete")
print("   %d distinct attachment types; those whose name mentions compaction:" % len(all_attachment_types))
hits = {k: v for k, v in all_attachment_types.items() if "compact" in k.lower()}
print("   %s" % (hits or "none"))
