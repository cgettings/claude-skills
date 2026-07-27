# cgettings-skills

Two Claude Code skills for the moment work finishes. They're separate on purpose: one decides
what should be **added** to your durable notes, the other decides which assertions have **changed** 
in them. Different questions, different bars, and the second one runs even when the first finds 
nothing.

## `distill-lessons`

Reviews a finished stretch of work for durable lessons and writes each one where it will
actually be read.

**What it isn't.** Not a session recap, not a post-mortem, not a handover summary. Those
describe what happened. This decides what's worth carrying forward — and throws away most of
it. Most sessions yield zero to two durable lessons, and saying "nothing" is a normal
outcome rather than a failure.

Six steps: decide whether there's anything here at all; reflect, grounded in artifacts on disk
rather than recall; generalize each candidate from an instance to a reusable shape; route the
survivors (CLAUDE.md for standing rules, memory for incidents, nowhere for most of them);
verify each claim before it becomes durable; propose the exact wording as a diff before
writing anything.

## `reconcile-records`

Finds and fixes records that recent work made false — status lines that have moved on, numbers
something re-measured, notes the code now states better, rules a newer rule replaced.

**Why it's separate.** Note-keeping systems only ever add. Every pass appends, nothing is
retired, and the store grows until the wrong parts outnumber the parts anyone trusts. Nothing
schedules anyone to look. This pass is that schedule, and it applies to more occasions than a
lessons pass does: after a merge, after a release, when someone trips over a stale doc, or as a
periodic sweep.

Four steps: bound the scope to what the work touched; apply four gates for the kinds of thing
that go false; verify before deleting — including confirming the *claim* survives elsewhere,
not merely the keyword; propose the exact edits with evidence for what makes each current
version false.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install distill-lessons@cgettings-skills
/plugin install reconcile-records@cgettings-skills
```

They work independently, but they're designed to run back to back.

## Assumptions about your setup

- **CLAUDE.md** — standard, and required for the "standing instructions" destination.
- **A memory tier** — optional. If your setup has one, `distill-lessons` follows whatever format
  it specifies. If not, that destination collapses into CLAUDE.md or nowhere, and the skill says
  so rather than inventing a store to write to.
- **An always-loaded memory index** — optional. The hook-length rule only applies if your memory
  system has one.
- **Session transcripts** at `~/.claude/projects/<project-slug>/*.jsonl` — used only to recover
  user corrections, which artifacts never record.

## Evals

Each skill carries its own cases under `skills/<name>/evals/evals.json`, weighted toward
near-misses — the prompts that look like a trigger and aren't.

Three `reconcile-records` cases need fixtures: eval 1 needs a record calling the finished work
unmerged, eval 2 needs notes holding both a present-tense and a dated claim about the same
thing, and eval 4 needs two documents with overlapping but not identical content.

## License

Copyright (C) 2026 Chris Gettings

This program is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this
program. If not, see <https://www.gnu.org/licenses/>.

Full text in [LICENSE](LICENSE).
