# Notes

Candidates and open questions. Not commitments — things worth investigating, with the evidence
that raised them, so a later pass can judge them rather than re-derive them.

---

## Candidate: a handoff-readiness skill, adapted from superpowers' plan/brief split

*Raised 2026-08-06, from the EH-dataportal Neighborhood Reports retirement work.
Substantially revised 2026-08-06 after reading the superpowers plugin at
`~/.claude/plugins/cache/claude-plugins-official/superpowers/6.2.0`, which the first pass could
not find. The revision changed which artifact the candidate should copy — see "Correction" below.*

### What happened

Twice in one session, Chris asked a checking question, and both times the check found a gap.

**"Did you update the ledger?"** — I had not. I had updated the plan file the harness assigned
under `~/.claude/plans/`, which is outside the repo, while the tracked ledger at §11 of the
scoping memo still said the steps were untouched. That one produced
`feedback-existing-ledger-is-not-current` in the project memory store: an existing ledger is not
a current one, and a plan file outside the repo is not a ledger at all.

**"You have enough info saved to trust another you with implementing it?"** — I did not. An audit
of the committed docs against what a cold session would need found two substantive gaps. The
entire Pagefind analysis for the next stage — which parts of the search index the work touches,
why one build-time filter breaks silently on generated pages, and a recommendation about what
*not* to duplicate across 210 pages — existed only in that same untracked plan file. So did a
template's dependency on a Hugo `.Sections` call that the next stage deletes the inputs to.

The second gap is the interesting one, because it happened *after* the lesson from the first was
written down and while the ledger was being kept diligently. The ledger was not the problem. It
was accurate, current, and cited commit hashes. It simply does not hold this kind of content.

**The remedy that was actually applied** is the thing to build on, and the first pass of this note
did not record it: commit `92843b84e1`, "docs: move decision 4's execution plan into the repo",
which added `documents/nr-output-option-d-execution-plan-2026-08-06.md`, 286 lines. It carries the
Pagefind analysis under its own heading (18 occurrences of the term, against 21 in the untracked
plan) and the `neighborhoodMap`/`.Sections` dependency as its §1 `[verified 2026-08-06: git log
and grep -c against both files]`. So the fix was: write the executable detail into a tracked file.
That matters for scoping the candidate — the move is known and cheap. What is missing is anything
that asks for it before someone notices.

### The diagnosis

`keep-ledger` asks *what is done, what is proven, what runs next*. That is status. It is
deliberately not a second copy of the plan — its own text says so, because two copies drift and a
reader cannot tell which is current.

But "the plan" was assumed to exist somewhere durable, and in this case it did not. The ledger
correctly refused to duplicate a document that was never committed. Status was preserved and
executable detail was lost, and nothing in the current four-skill set asks after the second.

That is a seam the set does not cover, in the same sense the README already uses: a different
question, at a different bar, from the ones the other four ask. It is also a seam of a different
*kind*: all four existing skills look backward or sideways at work — what it taught, what it made
false, where it stands, where a rule belongs. This one would look forward, at work not yet done.

### Correction: the brief is not the artifact — the plan is

The first pass of this note read the 17 task briefs in EH-dataportal's `.superpowers/sdd/` and
inferred that superpowers' `subagent-driven-development` *produces* them as self-contained
execution documents. It does not. `scripts/task-brief PLAN_FILE N` is a 40-line shell script whose
working part is one `awk` program: it prints the plan's `### Task N` section, fence-aware, to a
file, and prints the path. It authors nothing.

Verified: re-running that extraction against the tracked plan and diffing the result against the
on-disk brief returns identical `[verified 2026-08-06: awk extraction of Task 3 from
documents/tier-4.1-render-measures-plan.md, diffed against .superpowers/sdd/task-3-brief.md — no
output, exit 0]`.

The script's own header comment states its purpose, and it is not durability: extract the task
text "into a file the implementer reads in one call, so the task text never has to be pasted
through the controller's context." It is a context-budget device. `SKILL.md` says the same thing
in its own voice at the top of The Task Loop — everything pasted into a dispatch prompt stays
resident for the rest of the session and is re-read every turn, so artifacts are handed over as
files.

Every property the first pass admired is therefore authored one level up, by `writing-plans`,
and mandated by name in its Task Structure and No Placeholders sections:

| What the briefs showed | Where it is actually required |
|---|---|
| `**Files:**` list with exact paths and line ranges | `writing-plans` § Task Structure |
| `**Interfaces:**` — Consumes / Produces, exact signatures | § Task Structure, with the reason: an implementer sees only their own task |
| Numbered steps carrying the exact replacement code | § Bite-Sized Task Granularity + § No Placeholders ("code blocks required for code steps") |
| Rationale, including what the design doc got wrong | § Overview: write for an engineer with zero context and questionable taste |

And `writing-plans` says where that document goes: `docs/superpowers/plans/YYYY-MM-DD-<name>.md`,
in the repo, tracked.

### What this does to the ephemerality argument

The first pass framed durability as the deliberate divergence to argue about, on the evidence that
`.superpowers/sdd/` ships a `.gitignore` containing a single `*`. The ignore is real. The
inference from it is not.

Briefs are ignored because they are **derivable**, not because superpowers thinks executable
detail is disposable. A brief is one command away from a tracked plan section. The ignore also has
a stated, unrelated reason, in `sdd-workspace`'s header: the workspace has to live in the working
tree rather than under `.git/` because Claude Code denies agent writes to `.git/`, which would
block an implementer from writing its report — so a self-ignoring `.gitignore` keeps scratch out
of `git status` "without modifying any tracked file."

So there is no lifetime disagreement to have. Superpowers already puts durable executable detail
in a committed document; it just calls that document the plan. The candidate skill does not have
to argue for durability against a system that rejects it — it has to notice when the durable
document is missing, which in this incident it was.

Two smaller notes from the same read, both bearing on how much the EH-dataportal artifacts can be
trusted as evidence:

- The count in the first pass was wrong: `.superpowers/sdd/` holds 96 files, of which **17** are
  briefs. The rest are 17 implementer reports, ~58 `review-*.diff` packages, and 4 ledgers
  (`progress.md` plus three `.bak-*` copies) `[verified 2026-08-06: ls | wc -l, ls | grep -c
  brief]`. "97 briefs" conflated the directory with one kind of file in it.
- That directory is the **old flat layout**. 6.2.0 scopes a workspace per plan
  (`.superpowers/sdd/<plan-basename>/`) and `SKILL.md` explicitly calls a ledger at the flat path
  "another plan's progress: leave it in place and start your own." The EH-dataportal artifacts are
  scratch from a superseded version, which is consistent with them being scratch.

### The seam, restated

Superpowers' chain is `brainstorming → writing-plans → subagent-driven-development /
executing-plans → finishing-a-development-branch`, and the durable artifact is produced in step
two.

The harness supplies its own plan-file default — `~/.claude/plans/`, outside the repo — and
`writing-plans` explicitly yields to it: "(User preferences for plan location override this
default)." Those two defaults disagree about durability, and the harness's wins silently. That is
a precise, nameable statement of what went wrong above, and it is not a superpowers bug: the plan
was written to the location the harness assigned, and that location is not tracked by any repo.

### Two plan-writing paths, and only one of them is the default

Chris asked, on reading the above, whether the `~/.claude/plans/` files *were* `writing-plans`
output filed to a different location. They are not, and the measurement is worth keeping, because
it turns the seam from a missing capability into an unused one.

**`superpowers:writing-plans` has been invoked 3 times, across every project, ever.** All three
were EH-dataportal, in July 2026 `[verified 2026-08-06: grep for '"skill":"…"' across
~/.claude/projects/**/*.jsonl; probe validated by the same pattern returning plausible sibling
counts — reconcile-records 9, subagent-driven-development 8, brainstorming 7, distill-lessons 7]`.

The two populations separate cleanly on six template markers from `writing-plans`' own text
`[verified 2026-08-06: per-marker grep -c]`:

| | `~/.claude/plans/`<br>(23 files) | EH-dataportal `documents/`<br>(3 files) |
|---|---|---|
| `REQUIRED SUB-SKILL` header | 0 | 3 |
| `**Files:**` block | 1 | 3 |
| `**Interfaces:**` block | 0 | 3 |
| `### Task N` headings | 4 | 3 |
| `- [ ]` checkbox steps | 0 | 3 |
| `Global Constraints` | 1 | 3 |
| tracked in git | 0 | 3 |

So the three conformant plans exist, are tracked, and carry exactly the implementer-granular
detail this note says goes missing — `data-explorer-state-namespace-plan-2026-07-10.md` alone has
11 tasks and 102 checkbox steps. The 23 files in `~/.claude/plans/` are harness plan-mode
documents in my own prose style: context, tables, staged narrative, no task decomposition and no
per-step verification.

The sharpest data point is the remedy from the incident itself.
`nr-output-option-d-execution-plan-2026-08-06.md` — the file written specifically to make the work
handoff-ready, and committed for that reason — scores **0 on all six markers**. It got the
location right and the form not at all.

That reframes the candidate. The gap is not that this repo lacks a planning skill; the skill is
installed and has produced good output. It is that two plan-writing paths exist with different
outputs and different durability, and the one that fires by default — plan mode, which assigns a
path outside any repo before the question of durability is ever raised — is the one that produces
neither. `writing-plans` has to be reached for deliberately, and over four months it was reached
for three times.

### Open questions for the investigation

- **What is the skill actually about?** Not brief-writing — that is a projection. The candidate is
  closer to: *before a stage is handed off, does a tracked document exist that carries what an
  implementer needs, at implementer granularity?* Whether that is a planning skill, a
  handoff-readiness gate, or a check appended to an existing skill is open.
- **Is a new skill even the right instrument? — acted on 2026-08-06, not yet tested.** Raised by
  the 3-invocations measurement above: if `writing-plans` already produces the wanted artifact and
  simply is not reached for, a fifth skill is a second thing that also will not be reached for.
  Chris's call was to take the cheap instrument first — global `CLAUDE.md` § Plan mode now carries
  three bullets beside the existing rename rule: that the assigned path is outside every repo and
  executable detail moves in-repo once work outlives the sitting; that `superpowers:writing-plans`
  supplies the form (Files/Interfaces blocks, No Placeholders, three-pass Self-Review); and what to
  drop from it — the `docs/superpowers/plans/` location, the `REQUIRED SUB-SKILL` header and
  Execution Handoff (both presume SDD is executing), and the TDD-shaped step template, with the
  `[verified <date>: how]` convention kept. **This is now the thing to evaluate.** A fifth skill
  stays parked until the rule has had real plan-mode sessions to fire in and been observed to
  fail — a rule that has never been tested is not evidence that a skill is unnecessary, only that
  the cheaper option was tried first.
- **Is this a fifth skill, or a section of `keep-ledger`?** Still open, and the correction sharpens
  both sides. For separate: the question is forward-looking where all four current skills are
  retrospective, and it fires at a different moment. For merged: `keep-ledger`'s resume path
  already reads the tracked document that owns the work, and "is there a plan section for the next
  step" is a natural thing to check while reading it.
- **Does it need the subagent framing at all?** Answered: no. `task-brief` is context management
  for dispatch, and the incident had no subagents in it. The value is in the plan existing, not in
  anything being dispatched.
- **What is the bar for "enough"?** Superpowers has a more checkable answer than "could another
  session execute this," and it is worth borrowing rather than inventing. `writing-plans` § No
  Placeholders is a list of banned strings and shapes — "TBD", "add appropriate error handling",
  "similar to Task N", steps with no code block, references to types no task defines. Its
  Self-Review is three named passes: spec coverage, placeholder scan, type consistency. That is
  grep-shaped, which is the property the first pass wanted from the per-fact audit.
- **Relationship to `reconcile-records`.** The staleness cost is real but is no longer an argument
  for ephemerality, because superpowers' plans are tracked and go stale too — its briefs being
  scratch buys it nothing here. The cost has to be accepted and managed either way, and
  `reconcile-records` is the pass that manages it.
- **What does the trigger look like?** Open, and the sharpest available test is still Chris's own
  question, which caught the gap when the diligent ledger did not: *is there enough saved to trust
  another you with implementing it?*

### Prior art in this repo

`keep-ledger` was adapted from `subagent-driven-development` — its identity line, `parked`/`BLOCKED`
vocabulary, completion line, and resume rule, with the borrowings named in its README and a
deliberate departure recorded. The same approach applies here, with the source corrected: the
skill to read is `writing-plans`, and the borrowing is its Task Structure and No Placeholders bar,
not the brief mechanism.

### Method note, kept deliberately

The first pass carried a caveat saying the skill's own instructions had not been read and that
anything about its intent was inferred from its output. The caveat was correct, and the inference
it guarded was wrong — a mechanical extraction was read as an authored artifact, and a project's
`.gitignore` was read as a design philosophy. The output looked exactly as it would have if the
inference were true, which is why the caveat, not the reasoning, is what saved it.

That is the same failure shape as the `git check-ignore` error the first pass already recorded
(running it against the directory, which is not ignored, rather than a file inside it, which is)
and the same shape as the incident the whole note is about: a check that appears to confirm
something it never examined.
