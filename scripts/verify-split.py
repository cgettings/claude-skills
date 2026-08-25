#!/usr/bin/env python3
"""Prove the Task 3 split lost nothing, and measure what it saved.

Five checks, each stated so a failure names the bullet:

  1. bullet count is preserved (17 -> 17)
  2. the three no-evidence bullets are byte-identical before and after
  3. every [[pointer]] in the after-text resolves to a file in ~/.claude/lessons/
     (override that directory with LESSONS_DIR, and docs/ with SECTIONS_DIR --
      the fault-injection control needs both to point at a copy)
  4. every split bullet's ORIGINAL text is present verbatim in its lesson file
     -- this is the "every evidence item is locatable" bar, as a substring test
  5. every lesson file is pointed at by exactly one rule (no orphans, no dupes)

Exit non-zero on any failure. That is its informative answer, so chain with ';'.
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SECTIONS = Path(os.environ.get("SECTIONS_DIR") or ROOT / "docs")
BEFORE = SECTIONS / "task-3-section-before.md"
AFTER = SECTIONS / "task-3-section-after.md"
LESSONS = Path(os.environ.get("LESSONS_DIR")
               or Path(os.path.expanduser("~")) / ".claude" / "lessons")
UNCHANGED_IDX = {2, 15, 16}  # B3, B13, B14 in document order


def read(p: Path) -> str:
    with open(p, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def bullets_of(text: str) -> list[str]:
    return [ln for ln in text.split("\n")
            if ln.startswith("- ") or ln.startswith("    - ")]


def main() -> int:
    before_text = read(BEFORE)
    after_text = read(AFTER)
    before = bullets_of(before_text)
    after = bullets_of(after_text)
    fails = []

    # 1. bullet count
    if len(before) != len(after):
        fails.append(f"[1] bullet count {len(before)} -> {len(after)}")
    else:
        print(f"[1] PASS  bullet count preserved: {len(before)}")

    # 2. the unchanged bullets really are unchanged
    n = min(len(before), len(after))
    bad = [i for i in sorted(UNCHANGED_IDX) if i >= n or before[i] != after[i]]
    if bad:
        fails.append(f"[2] bullets {bad} were declared unchanged but differ")
    else:
        print(f"[2] PASS  {len(UNCHANGED_IDX)} no-evidence bullets byte-identical")

    # 3. pointers resolve
    ptr = re.compile(r"\[\[([a-z0-9-]+)\]\]")
    pointed = []
    for i, ln in enumerate(after):
        for slug in ptr.findall(ln):
            pointed.append((i, slug))
            if not (LESSONS / f"{slug}.md").exists():
                fails.append(f"[3] bullet {i} points at missing lesson {slug}.md")
    if not any(f.startswith("[3]") for f in fails):
        print(f"[3] PASS  {len(pointed)} pointers all resolve in {LESSONS}")

    # 4. the ORIGINAL bullet is verbatim inside the lesson file it points to
    for i, slug in pointed:
        # A missing file is check [3]'s finding; reading it here would crash and
        # cost the run its FAILURES block, which reads as a broken harness.
        if not (LESSONS / f"{slug}.md").exists():
            continue
        lesson = read(LESSONS / f"{slug}.md")
        original = before[i].strip().lstrip("- ").strip()
        if original not in lesson:
            fails.append(f"[4] bullet {i} ({slug}): original text NOT verbatim in lesson file")
    if not any(f.startswith("[4]") for f in fails):
        checked = sum(1 for _, s in pointed if (LESSONS / f"{s}.md").exists())
        print(f"[4] PASS  all {checked} originals verbatim in their lesson files")

    # 5. no orphan lesson files, no slug pointed at twice
    slugs = [s for _, s in pointed]
    on_disk = {p.stem for p in LESSONS.glob("*.md")}
    dupes = {s for s in slugs if slugs.count(s) > 1}
    orphans = on_disk - set(slugs)
    if dupes:
        fails.append(f"[5] slugs pointed at more than once: {sorted(dupes)}")
    if orphans:
        fails.append(f"[5] lesson files nothing points at: {sorted(orphans)}")
    if not any(f.startswith("[5]") for f in fails):
        print(f"[5] PASS  {len(on_disk)} lesson files, 1:1 with pointers, no orphans")

    # measurement -- bytes, not characters (CLAUDE.md: len() counts chars)
    b_before = len(before_text.encode("utf-8"))
    b_after = len(after_text.encode("utf-8"))
    b_lessons = sum(len(read(p).encode("utf-8")) for p in LESSONS.glob("*.md"))
    print()
    print(f"section before      {b_before:7,d} B")
    print(f"section after       {b_after:7,d} B   ({b_after - b_before:+,d}, "
          f"{100 * (b_after - b_before) / b_before:+.1f}%)")
    print(f"lessons off-tier    {b_lessons:7,d} B   (loaded on demand, not per session)")
    print(f"always-loaded saved {b_before - b_after:7,d} B")

    cr = sum(read(p).count("\r") for p in LESSONS.glob("*.md")) + after_text.count("\r")
    print(f"CR bytes            {cr:7,d}   (expect 0)")
    if cr:
        fails.append(f"[cr] {cr} CR bytes present")

    if fails:
        print("\nFAILURES:", file=sys.stderr)
        for f in fails:
            print("  " + f, file=sys.stderr)
        return 1
    print("\nall checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
