# cgettings-skills

Four Claude Code skills for the seams in a piece of work — where it starts, pauses, resumes, and
finishes. They're separate on purpose, and they ask different questions at different bars:

| Skill | Question | Runs |
|---|---|---|
| [`keep-ledger`](plugins/keep-ledger) | What's **done**, what's **proven**, what runs next? | At the start of multi-step work, and on every resume |
| [`distill-lessons`](plugins/distill-lessons) | What **knowledge** is worth keeping? | Every work boundary |
| [`reconcile-records`](plugins/reconcile-records) | What written thing **went false**? | Every work boundary, and more besides |
| [`refile-rules`](plugins/refile-rules) | Does the store's **organization** still hold? | Only when tripped |

The first runs while the work is live rather than at its end; the other three run when it stops.
Of those, the lessons and reconcile passes run back to back, and the second runs even when the
first finds nothing. `refile-rules` isn't scheduled at all — it fires on evidence the other two
produce while they're already standing in the file.

`keep-ledger` and `reconcile-records` are two halves of one loop: a ledger is a status record, so
it's precisely what that pass's first two gates look for, and keeping one is what gives them
something greppable to find.

A fifth plugin, [`grounded-output-style`](plugins/grounded-output-style), is a different kind of
thing: not a workflow that runs at a boundary, but a working style that's live for the whole
session.

## `keep-ledger`

Keeps a resumable ledger for work that runs past one sitting — what is done, what proof actually
ran, and the exact next command — in the tracked document that owns the work.

**Why it's separate.** A plan says what to do. It does not say what happened, and after the first
session that's the only thing a reader needs. The gap is invisible while you're in the session,
because you *are* the record; it becomes the whole problem the moment you're not. So the failure
it guards against isn't forgetting to keep a ledger — it's keeping one that lists steps and holds
no state.

Seven steps: write it at the start, because the moment you need it is the moment you can't write
it; put it in the tracked document that owns the work; give every step a status, distinguishing
parked from blocked by who acts next; record the proof that **ran**, not the proof you planned;
point at landmarks rather than line numbers; update it in the commit that finishes each step; and
on resume, treat the ledger and `git log` as outranking your own recollection.

The load-bearing one is the fourth: a ledger recording the intended check rather than the executed
one is worse than a ledger with no proof field at all, because the next session follows it.

**Credit.** The ledger's shape is adapted from `subagent-driven-development` in
[superpowers](https://github.com/obra/superpowers) by Jesse Vincent, which is where I first saw one
specified rather than recommended. The plugin's own [README](plugins/keep-ledger) says what was
borrowed and where this departs — chiefly that the ledger lives in a tracked document rather than a
git-ignored workspace.

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

## `grounded-output-style`

Carries a verification-first, claims-calibrated working style into any project as a real Claude
Code output style, appended to the system prompt with `keep-coding-instructions: true` so it
changes how Claude verifies and reports without discarding its engineering behavior.

**The trap it closes.** Confident, well-formed prose reads as verified whether or not it was: a
polished sentence and a carefully measured one read with the same apparent authority, though only
one is backed by verified evidence, so a reader who must act on the writing has no way to tell
them apart except by re-deriving the claim. That
confidence is borrowed from a genre built for a different audience — technical writing, talks,
threads — where the job is to hold a reader free to leave. The actual audience for a review or an
audit cannot leave; they're already committed to acting on what's written. Applying the
leaveable-audience voice to a can't-leave audience is what makes an unsourced guess and a
line-cited measurement sound the same.

See the plugin's own [README](plugins/grounded-output-style) for what it changes and its
per-session cost.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install keep-ledger@cgettings-skills
/plugin install distill-lessons@cgettings-skills
/plugin install reconcile-records@cgettings-skills
/plugin install refile-rules@cgettings-skills
/plugin install grounded-output-style@cgettings-skills
```

They work independently. The first runs while work is in flight and feeds the third; the second and
third are designed to run back to back; the fourth fires only when one of them trips it; the fifth
is a standing style, not a workflow — after installing it, select
it under `/config` → **Output style** → **Grounded**, and only in projects where
verification/audit/documentation writing is frequent enough to justify its per-session cost.
Selecting it replaces whatever output style is active, built-ins included.

## Assumptions about your setup

- **A git repository** — required by `keep-ledger`, whose whole argument is that a ledger survives
  because it's committed. Without one it has nowhere to put the ledger that beats a scratch file.
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
near-misses — the prompts that look like a trigger and aren't. Twenty-six cases in all: seven each
for `keep-ledger`, `distill-lessons`, and `reconcile-records`, five for `refile-rules`. Six of them
turn on the workflow not running *at all*, and `distill-lessons` eval 2 on the pass running and
correctly producing nothing; most of the rest carry at least one expectation that some action must
not be taken. Every case carries both an `expected_output` written for a human reader and an
`expectations` array of individually checkable assertions, which is what `skill-creator`'s grader
scores.

`refile-rules` and `keep-ledger` also carry a `trigger_eval.json` — phrasings with expected
trigger/no-trigger outcomes, twenty for the first (nine positive) and twenty-two for the second
(ten positive). They exist because all four skills describe a document going wrong and therefore
compete for the same prompts, so eight of `refile-rules`' negatives and seven of `keep-ledger`'s
are prompts belonging squarely to siblings. The negative half is the actual test; passing the happy
path proves nothing about separation.

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
