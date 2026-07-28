# cgettings-skills

Three Claude Code skills for the moment work finishes. They're separate on purpose, and they ask
different questions at different bars:

| Skill | Question | Runs |
|---|---|---|
| [`distill-lessons`](plugins/distill-lessons) | What **knowledge** is worth keeping? | Every work boundary |
| [`reconcile-records`](plugins/reconcile-records) | What written thing **went false**? | Every work boundary, and more besides |
| [`refile-rules`](plugins/refile-rules) | Does the store's **organization** still hold? | Only when tripped |

The first two run back to back, and the second runs even when the first finds nothing. The third
isn't scheduled at all — it fires on evidence the other two produce while they're already standing
in the file.

## `distill-lessons`

Reviews a finished stretch of work for durable lessons and writes each one where it will
actually be read.

**What it isn't.** Not a session recap, not a post-mortem, not a handover summary. Those
describe what happened. This decides what's worth carrying forward — and throws away most of
it. Most sessions yield zero to two durable lessons, and saying "nothing" is a normal
outcome rather than a failure.

Six steps: decide whether there's anything here at all; reflect, grounded in artifacts on disk
rather than recall; generalize each candidate from an instance to a reusable shape; route the
survivors (CLAUDE.md for standing rules, memory for incidents and methods, nowhere for most of them);
verify each claim before it becomes durable; propose the exact wording as a diff before
writing anything.

Routing has a fork ahead of those destinations: if a rule for this **already exists**, the lesson
isn't the rule — the rule is written and it didn't fire, and a second copy makes two rules that will
both sometimes fail to fire. The output is a revision of the existing entry, narrowed until a
command can check it, never a new entry.

## `reconcile-records`

Finds and fixes records that recent work made false — status lines that have moved on, numbers
something re-measured, notes the code now states better, rules a newer rule replaced — and
captures the state the work left unrecorded, which is the same failure seen from the other side.

**Why it's separate.** Note-keeping systems only ever add. Every pass appends, nothing is
retired, and the store grows until the wrong parts outnumber the parts anyone trusts. Nothing
schedules anyone to look. This pass is that schedule, and it applies to more occasions than a
lessons pass does: after a merge, after a release, when someone trips over a stale doc, or as a
periodic sweep.

Four steps: bound the scope to what the work touched; apply five gates for the kinds of thing
that go false or go missing; verify before deleting — including confirming the *claim* survives elsewhere,
not merely the keyword; propose the exact edits with evidence for what makes each current
version false.

## `refile-rules`

Reorganizes a store whose structure stopped holding — sections that drifted into overlap, a file
grown past the length anyone reads to the end, rules filed by feel because the boundary was never
real, and content sitting in an always-loaded file when the moment it's needed would have triggered
it anyway.

**Why it's separate.** A store makes two kinds of claim: each entry claims something is true, and
the organization claims its sections carve the subject at real joints. Only the first ever gets
checked. But a rule that can't be found doesn't fire, and a rule that doesn't fire is
indistinguishable from one that was never written — the file still reads well, every line in it is
still true, and the failure surfaces somewhere else entirely.

**Why it isn't scheduled.** Knowing where something lives is itself part of retrieval, and every
reorganization spends that down. So it needs a trigger, and the triggers come from the other two
passes while they're already standing in the file: a lessons pass that couldn't tell which section
an entry belonged to, a rule that already existed and couldn't be narrowed into a checkable form, a
measurement taken in passing — or someone simply asking.

Six steps: don't run speculatively; diagnose before moving anything, because length is a symptom
shared by every cause; test the boundaries by predicting where existing entries live from the
headings alone; apply the placement criterion — always-loaded is for content whose moment of need is
a moment you wouldn't know to go get it; re-file and merge but **never abbreviate**, since a rule
fires on its specificity; propose as a manifest and prove the move by diffing the sorted rule lines.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install distill-lessons@cgettings-skills
/plugin install reconcile-records@cgettings-skills
/plugin install refile-rules@cgettings-skills
```

They work independently. The first two are designed to run back to back; the third fires only when
one of them trips it.

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
near-misses — the prompts that look like a trigger and aren't. Sixteen cases in all: six for
`distill-lessons`, five each for `reconcile-records` and `refile-rules`. Four of them turn on the
workflow not running *at all*, and two more on the pass running and correctly producing nothing;
most of the rest carry at least one expectation that some action must not be taken. Every case
carries both an `expected_output` written for a human reader and an `expectations` array of
individually checkable assertions, which is what `skill-creator`'s grader scores.

`refile-rules` also carries a `trigger_eval.json` — twenty phrasings with expected
trigger/no-trigger outcomes, nine positive and eleven negative. It exists because all three skills
describe a rule store going wrong and therefore compete for the same prompts, so eight of its
negatives are prompts belonging squarely to the other two. The negative half is the actual test;
passing the happy path proves nothing about separation.

Four `reconcile-records` cases need a seeded record store. Eval 1 needs a record calling the
finished work unmerged. Eval 2 needs notes holding both a present-tense and a dated claim about the
same thing, plus a per-type breakdown the notes still give as 14/7/4 against the 22 lookup / 12
multi-hop / 6 negative actually present. Eval 4 needs two documents with overlapping but not
identical content. Eval 5 needs a store that records nothing about the finished work while still
holding a real staleness elsewhere — a staging shard count of 12 where the rebuild left 16, in both
the memory file and its `MEMORY.md` hook — plus a neighbouring entry of the same shape, so the form
of the missing record is inferable without being spelled out.

`distill-lessons` eval 1 needs a fixture of a different kind: a session transcript. The rejected
suggestion it expects to be recovered appears in no artifact, which is the whole point of the case.

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
