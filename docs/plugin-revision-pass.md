# Plugin revision pass — 2026-08

**CLOSED 2026-08-19. All nine steps done, plus a prose pass after step 8 (recorded there). Merged
to `main` as `811e3e1` via PR #6; the work is `ad81025..811e3e1`.**

`[verified 2026-08-19: gh pr view 6 → state MERGED, mergedAt 2026-08-19T18:36:07Z, mergeCommit
811e3e1; git status --porcelain clean against 811e3e1; the quota, the "never abbreviate" absolute
and the old grounded section list confirmed absent from the working tree by grep]`

**This is now a dated historical record, not a live ledger.** Everything below describes what was
true when the work landed. `reconcile-records` should leave it alone rather than try to freshen it;
a status that has already been closed out is not a status that has moved on.

## State a cold session would otherwise be stuck without

None of this is recoverable from `git log` on this repo.

- **The branch was pushed manually by the user**, not by this session and not by a hook — checked,
  `.git/hooks/` holds no active hooks. Do not infer an automatic push exists.
- **The lessons pass ran and its output went outside this repo.** Four edits landed in
  `C:\Users\Chris\.claude\CLAUDE.md`: the serializer clause appended to the formatter bullet under
  Code philosophy (144 → 194 words), the structural-description clause added to the docs-commit
  rule under Verifying a claim before it hardens, a new "a pass that corrects under-hedging cannot
  see over-hedging" bullet in Claims & register (867 → 932 words), and — from step 3, earlier — the
  amendment removing the reconcile-after-distill requirement. A supporting memory,
  `json-roundtrip-reformats-hand-formatted-files`, was written to the `claude-skills` project store
  with an index hook of 152 characters. **Nothing in this repo records any of that.**
- **`refile-rules` was then run against that same global CLAUDE.md and correctly changed nothing.**
  Proved byte-identical against a snapshot, and by a sorted diff of all 43 rule lines. The findings
  worth not re-deriving: the 336-word `Nothing commits without my say-so` bullet is 3.5× the 96-word
  median and **fails the specifics-inventory bar** — fourteen items, none droppable — so it is step
  5's explicit non-qualifying case, not a target. The single qualifying edit found (lines 61 and 63
  both quote the "pass and fail states are indistinguishable" example) was declined at ~15 words on
  a 932-word section. Do not re-open either without a new reason.

## Open items

- **The rewritten evals in step 7 have never been run.** Their JSON validity and counts are
  verified; whether the new case 2 and case 4 discriminate is asserted, not measured. Running them
  needs `skill-creator`'s grader. Case 4 is the one that matters — it is what stops the shortening
  capability becoming a general compression licence, and PR #6 carries a note asking that it not be
  deleted as redundant with case 2.
- **A `reconcile-records` pass ran 2026-08-19, after the merge.** The merge was its trigger; under
  the coupling removed in step 3 it would have followed the lessons pass automatically instead.
  Scope: the files in `ad81025..811e3e1`, `docs/keep-session-warm-postmortem.md`, the project memory
  store, and the global CLAUDE.md lines naming these skills. It re-derived all six README counts as
  correct — 26 eval cases (7/7/7/5), both trigger sets 22 with 10 positive, grounded 1,016 words,
  four workflow skills — and found one stale status: this ledger's own "not yet merged" line, fixed
  in the same commit.
  - **Gate 6 was not re-run.** It was swept across all 11 shipped files in step 8 the same day,
    finding every outside-system claim sourced. Relying on that rather than repeating it hours later.
  - **`docs/keep-session-warm-postmortem.md` was checked for falsified cross-references (none — it
    names no revised skill) but not swept for gate 6.** It is the doc here densest with external
    claims about Claude Code's cache behaviour, the work never touched it, and a gate-6 pass over it
    is a real separate job. Left undone deliberately, not overlooked.
  - **One item deferred to the next lessons pass**, because fixing it adds knowledge rather than
    correcting a falsehood: the `preamble-confident-prose-trap` memory mandates stating the trap's
    *hypothesized* source, and following it literally is what produced three flat unhedged statements
    of that source in shipped files, which step 8 then had to correct. The memory is incomplete about
    how to apply itself rather than false.
- **Branch `plugin-revision-pass` still exists** locally and on `origin` at the close-out. It is
  fully merged into `main` and safe to delete; nothing here depends on it surviving.

Nine-item revision agreed in session on 2026-08-19. The user proposed eight changes and accepted
one reshaping (step 2) and one added condition (step 4) after pushback. This document is the
ledger; the reasoning behind each item is summarised inline so a session with no memory of the
conversation can execute it.

## Scope

Ten markdown files across five plugins, two eval files, five `plugin.json` files, the root
`README.md` and `.claude-plugin/marketplace.json`, plus the user's global
`C:\Users\Chris\.claude\CLAUDE.md` (outside this repo — explicitly authorised in session).

## Standing constraints for every step

- Nothing commits without the user's say-so. Recommend, don't run `git commit` unprompted.
- The register sweep (step 8) runs **last**, so it also covers text written in steps 2–7.
- Do not weaken imperatives while softening claims. The filter is in step 8's entry.

## Steps

### 1. Write this ledger — DONE 2026-08-19

`docs/plugin-revision-pass.md` created. Chosen over `~/.claude/plans/` because the work will
outlive the sitting and that directory is invisible to any session that does not inherit this
conversation.

### 2. Replace the lessons-yield quota — DONE 2026-08-19

**Why:** "Most stretches of work yield zero to two durable lessons" is an unmeasured
distributional claim stated flat — the "generalization about how work goes" that the skill's own
step 5 table forbids. The user reports the pass almost never returns zero and that ~4 is the
number they normally accept. Raising 2 to 4 keeps the defect and moves the number; their sample
is also biased, since they invoke manually at moments already judged lesson-rich.

**Change:** cut the count. Keep "nothing is a normal answer". Say yield tracks *when* the pass
ran — a proactive pass at an unflagged boundary often produces nothing, a manually invoked one
produces more. Leave the throttle on the per-candidate bar (nameable cost, statable shape).

**Files:** `plugins/distill-lessons/skills/distill-lessons/SKILL.md` §1; that plugin's
`README.md` ("What it isn't" para); root `README.md` (`distill-lessons` section).

**Proof, as written:** `grep -rn "zero to two" .` returns nothing. **That check cannot pass**, and
the reason will trip any later step written the same way: this ledger quotes the old wording in
order to justify replacing it, so it is itself a hit. Every step here that greps for retired text
has the same problem.

**Proof that ran** `[verified 2026-08-19]`: `grep -rn "zero to two" .` returns two hits, both in
`docs/plugin-revision-pass.md` — the quotation above and this line. Zero hits in `plugins/` and in
the root `README.md`. Replacement text is in `SKILL.md` §1 ("There is no target number, in either
direction"), the plugin README's "What it isn't", the plugin README's step 1, and the root
README's `distill-lessons` section.

### 3. Re-topologize the cross-references — DONE 2026-08-19 (refile's share deferred into step 4)

Two changes to the same lines, done together to avoid editing them twice.

**3a. Drop the reconcile-after-distill requirement.** Nothing is lost: `reconcile-records`' own
trigger list already covers the same moment independently ("when a branch merges, a release
ships, or a multi-stage task completes"). The coupling was an artifact of these being the first
two plugins written. Relocate the load-bearing clause — "even when the lessons pass found
nothing" — into `reconcile-records`' own triggers, so it still guards against reading an empty
lessons result as "nothing to do". Demote `distill-lessons`' "After this pass" section to a
pointer.

**3b. State the two sibling pairs.** `keep-ledger` <-> `reconcile-records` (one writes status
while work is live, the other checks it at the boundary — already half-stated in the root README
as "two halves of one loop"). `distill-lessons` <-> `refile-rules` (one decides what is worth
recording and where it goes, the other fixes the *where* when the structure cannot hold it —
already half-stated via refile's triggers 1 and 2). Replace the current chain topology
(distill then reconcile then refile) with the two pairs.

**Files:** `plugins/distill-lessons/skills/distill-lessons/SKILL.md` ("After this pass", and the
`refile-rules` hand-off lines in §4 and §6); `plugins/distill-lessons/README.md`;
`plugins/reconcile-records/skills/reconcile-records/SKILL.md` (intro para + description
frontmatter); `plugins/reconcile-records/README.md` ("When it runs");
`plugins/keep-ledger/README.md`; `plugins/refile-rules/README.md`; root `README.md` (the table
and the paragraph under it); `C:\Users\Chris\.claude\CLAUDE.md` ("Session workflow" -> "Record
lessons after long stretches of work", which carries the same requirement and would otherwise
make the plugin change cosmetic for the user's own sessions).

**Proof that ran** `[verified 2026-08-19]`:
`grep -rni "run it after this one\|run back to back\|back to back\|follow it with" .` in the repo
root returns no matches (exit 1). `grep -c "Follow it with .reconcile-records"` against
`C:\Users\Chris\.claude\CLAUDE.md` returns 0. `grep -rn "^## Siblings" .` returns six hits — both
files of `distill-lessons`, `keep-ledger`, and `reconcile-records`.

**Decisions taken, so a later session doesn't relitigate them:**

- The heading for the cross-reference block is `## Siblings` in every skill and README, replacing
  the old `## After this pass`. Chosen so the pairing is visible in the heading structure itself.
- Each block names the pair first and the neighbour second, and says explicitly that the neighbour
  is not a required next step.
- The global CLAUDE.md edit carries its own `amended 2026-08-19` note in the sentence, matching the
  house form already used in that file's "Pause where the pause carries a decision" bullet.

**Deferred into step 4:** `refile-rules`' own `## Siblings` section and its README's sibling
paragraph. Step 4 rewrites large parts of both files, and editing them twice would make the second
edit unreviewable against the first. `refile-rules` is therefore the one plugin **without** a
`## Siblings` section until step 4 lands.

### 4. Let `refile-rules` propose text edits — DONE 2026-08-19

**Why:** the user finds it cumbersome to run distill, then refile, then distill again to shorten
what refile caught. The risk they named: revising out the triggers that make a rule fire.

**The entanglement to respect:** "never abbreviate" is in the skill description, the README,
step 5 and "what not to touch" — and step 6's proof *depends* on it. Sorting rule lines before
and after and diffing the sorted forms only works because moves preserve text. Opening editing
without changing the proof leaves a verification step that no longer verifies.

**Change, as agreed:**

- **Two manifest classes.** Moves stay byte-identical, so the sorted-line diff still proves them
  mechanically. Edits are listed separately, few, each shown before/after in full for human
  review rather than diff review.
- **The bar is a specifics inventory.** Before editing, enumerate what makes the entry
  recognisable in a situation: named artifacts, commands, flags, file paths, numbers, dates,
  conditions, the incident. After editing, every one must be locatable in the new text or named
  in the manifest as a deliberate drop with a reason.
- **Scope boundary.** `refile-rules` may change how much text a rule takes; only
  `distill-lessons` may change what it asserts. If the after-text asserts something the
  before-text did not, or stops asserting something it did, it is out of scope. Testable from the
  before/after pair.
- **Qualifying edits:** two entries duplicating a specific (the union survives); connective prose
  that names nothing; an entry restating a rule stated in full elsewhere in the same file.
  **Not qualifying:** a single long entry carrying its own specifics — length alone was never the
  finding.

**4b. Make the on-demand case visible.** "Someone asked" is already trigger 4, but §1 opens with
"Don't run this speculatively" and argues against running the pass, which reads as general
discouragement. Make the split explicit: the anti-speculation rule governs *unprompted* runs; a
direct request ends the question. This compounds with 4a — "this file is too long" is both the
commonest on-demand prompt and exactly where shortening is what is being asked for.

**Files:** `plugins/refile-rules/skills/refile-rules/SKILL.md` (description frontmatter, §1, §5,
§6, "What not to touch"); `plugins/refile-rules/README.md`.

**Proof that ran** `[verified 2026-08-19]`: `grep -rni "never abbreviat" .` returns four hits —
three in this ledger, and one in `refile-rules/skills/refile-rules/evals/evals.json`'s `notes`
field, which still calls abbreviation "the skill's central prohibition". **That eval note is step
7's work and is the one place the old absolute still stands.** Zero hits in any `SKILL.md` or
`README.md`. `grep -rni "four triggers" .` returns nothing (exit 1). All four JSON files parse.

**What landed, beyond the ledger's plan:**

- `SKILL.md` §1 renamed from "Don't run this speculatively" to "Check that something triggered
  this", with the request case first and the three unprompted triggers second.
- §5 renamed to "Re-file and merge — and shorten only against an inventory", keeping the
  fires/doesn't table and the compression warning intact ahead of the new `### When an edit is
  permitted` subsection.
- §6 renamed to "Propose a two-class manifest, and prove each class its own way".
- "What not to touch" gained a **what a rule asserts** bullet, and its "prose you merely disagree
  with" bullet now names the inventory as the test separating redundancy from taste — that bullet
  carries more weight now that editing is possible at all.
- `refile-rules` got its `## Siblings` section, closing the deferral from step 3.
- The README gained a `## Shortening, and the bar it has to clear` section; the root README's
  `refile-rules` section gained an equivalent paragraph.
- The description is duplicated in **three** places, not two as the ledger's step 9 said:
  `SKILL.md` frontmatter, `plugins/refile-rules/.claude-plugin/plugin.json`, and
  `.claude-plugin/marketplace.json`. All three updated.

**Method note for anyone editing the JSON files:** a `json.load` / `json.dumps(indent=2)` round
trip reformats the single-line `keywords` array and rewrites nine lines to change one. Reverted and
redone as a targeted string replacement with `newline=''` to preserve CRLF. The diff should be
`2 +-` per JSON file; anything larger means the round trip happened again.

### 5. `grounded`: concision and pushback — DONE 2026-08-19

**5a. Concision.** `grounded.md` currently says nothing about response length. The user skims long
output and misses things that get caught later. The tension to design around, which the user
confirmed is the priority: the style's other rules (source the claim, state which check ran and
why it suffices, name the mechanism) all *add* words, so a plain "be concise" would cut the
evidence first. **Evidence is above all else; concision acts on everything else.** Cut what
carries no information — preamble, restating the request, narrating what is about to be done,
recapping what the user can already see, closing summaries. Add a placement rule alongside the
length one: anything needing a decision, and any caveat that must be acted on, goes first.

**5b. Pushback.** Frame as the same failure family rather than a new topic: agreeing because it
is the user's idea is the same calibration failure as unearned confidence, pointed at the user
instead of at a claim. Both make assertion independent of evidence. Two guards — do not
manufacture disagreement to look rigorous (the "manufacturing a lesson to look thorough" failure
in a different costume), and once the objection has been heard and the user has reaffirmed, do it
their way and stop raising it.

**Files:** `plugins/grounded-output-style/output-styles/grounded.md`;
`plugins/grounded-output-style/README.md` ("What it changes", and the Cost section's word count).

**Proof that ran** `[verified 2026-08-19]`:
`sed '1,5d' plugins/grounded-output-style/output-styles/grounded.md | wc -w` returned **570**
before and **1,012** after — then **1,016** after the user's own manual edits to the file on the
same day, which is the figure the README now carries. The cost figure went from "roughly 600" to
"roughly 1,000", with the measurement cited inline and the growth named.

**The user's manual pass removed the fifth `Disagreeing` bullet** ("once they have heard the
objection and chosen anyway, it is decided"). The README's "What it changes" still credited the
section with it and now says "separates 'worse' from 'different'" instead. Worth noting the shape:
this is the *same* stale-description bug found below in this step's Effort/Code finding, recurring
within a day, in the same file pair. **A README that summarises a sibling file's sections goes
false whenever anyone edits that file, and nothing checks it** — if this recurs a third time, the
fix is a check rather than another correction. Section headings are now
`The reason you exist`, `Claims and register`, `Verification`, `Cutting`, `Disagreeing`.

**Cost to flag to the user:** the per-session tax nearly doubled. That is the honest trade for the
two new sections and it is stated in the README rather than buried; if the user would rather have
the old size, the cut candidates are `Cutting`'s third bullet and `Disagreeing`'s last two, which
are the least mechanical of the ten.

**Unplanned finding, fixed here.** The README's "What it changes" listed four groups —
Verification, Claims & register, **Effort**, and **Code** — and the style file has never contained
an Effort or a Code section. The README was describing content that was not in the artifact. It now
lists the four sections that exist. This is `reconcile-records`' gate four wearing a different hat;
it was found by reading the file rather than by any sweep, which is worth remembering when step 8
runs.

### 6. `keep-ledger`: the clean-session test — DONE 2026-08-19

**Why:** running every step in one session should be a typical case, not an assumption.

**Change:** convert §6 ("update it as part of the step") into a check — could a session with no
memory of this run the next step from the ledger alone? Mechanical form: write the literal next
command; if writing it needs a fact the ledger does not hold, that fact is what to record. Name
the categories that actually strand a fresh session and that the current text does not prompt
for: decisions taken and alternatives rejected (so the next session does not relitigate or undo
them), environment state (branch, worktree, seeded fixture, temp dir), anything deliberately
deferred, and uncommitted state.

**Tension to respect:** this fights §1's "scale the ledger to the work". Resolution to state
explicitly — the question is asked every step and the answer is usually "nothing"; the question is
cheap, the entry appears only when it is not.

**Files:** `plugins/keep-ledger/skills/keep-ledger/SKILL.md` §6 (and the description frontmatter
if the scope line changes); `plugins/keep-ledger/README.md` (the seven-steps list).

**Proof that ran** `[verified 2026-08-19]`: read-through — no mechanical check exists for a prose
addition. §6 retitled to "Update it as part of the step, then check it against a cold session"; the
description frontmatter now ends "written so a session that was not there can run the next step
from it alone"; the plugin README's step 6 and the root README's seven-step paragraph both carry
the check. This ledger is itself the dogfood: every DONE entry here was written under the new rule,
which is why they carry decisions-taken and method notes rather than only a status.

### 7. Evals — DONE 2026-08-19

Two `refile-rules` cases assert the opposite of step 4 and need rewriting, not deleting:

- Case 2 `too-long-must-not-abbreviate`, expectation *"No surviving rule is reworded, summarised,
  or shortened"* — becomes a test of the new bar: shortening is offered only for entries that meet
  it, with a specifics inventory shown.
- Case 5, expectation *"Compressing or shortening the rules is not offered as an alternative"* —
  **keep as a negative.** A long file whose rules each carry their own specifics should still get
  no shortening offer. This case is what stops the new capability becoming a general compression
  licence.

Also check `distill-lessons`' two `reconcile-records` references and `refile-rules`' four for
assertions that step 3 invalidates.

**Files:** `plugins/refile-rules/skills/refile-rules/evals/evals.json`;
`plugins/distill-lessons/skills/distill-lessons/evals/evals.json` (check only, likely no change).

**Proof that ran** `[verified 2026-08-19]`: all four JSON files parse. The refile evals diff is
`21 insertions, 13 deletions` — small enough to confirm the `json.dumps(indent=2)` round trip
matched the file's existing formatting and line endings rather than reformatting it. Case counts
after: 1→9 expectations, 2→13, 3→5, 4→7, 5→8.

**A finding from this step that changed step 4's output.** Writing case 1's expectations exposed an
error in the two-class manifest as step 4 first wrote it: §6 listed *merged with Y* under class 1,
the mechanically-proved class. **A merge produces text that was in neither original, so the sorted
rule-line diff cannot speak to it.** Merges are now declared as edits, in `SKILL.md` §5 and §6 and
in both READMEs. Class 1 is moves, relocations and deletions only. This is worth knowing because the
original skill had the same tension before this pass — it listed merges in the manifest and relied
on "the only differences may be the ones the manifest names" to cover them, which is weaker than the
proof it advertised.

**Case-by-case decisions, so a later session doesn't undo them:**

- **Case 2 renamed** `too-long-must-not-abbreviate` → `too-long-shorten-only-against-inventory`. It
  now tests the bar rather than a prohibition, and additionally checks that a direct request is
  accepted as a trigger without hunting for one of the unprompted three.
- **Case 4 kept as a negative, deliberately.** Its store is a long file whose entries each carry
  their own specifics, so nothing meets the bar. Its guard expectation is now "No shortening or
  compression of any rule is proposed", plus a softer one allowing the branch to be *considered* and
  ruled out on inventory grounds. This case is what stops the new capability becoming a general
  compression licence — do not delete it.
- **Case 5 strengthened.** Its longest entry must now survive shortening as well as relocation. The
  old expectation "No relocated or retained rule is reworded in the process" was replaced by two
  narrower ones, because under the new skill a rewording is not automatically wrong — only one
  attached to a move, or one failing the inventory, is.
- **`distill-lessons` and `reconcile-records` evals: checked, no change needed.** Their only
  cross-references are scoping notes about which file owns which case, not assertions about the
  distill→reconcile coupling that step 3 removed. Distill eval 2 (the pass runs and correctly
  produces nothing) still stands, since step 2 kept "say plainly when that is the answer".

### 8. Register sweep — DONE 2026-08-19

**Runs last, so it covers text written in steps 2–7.**

Sweep by category, not by feel. The filter, which matters because `grounded.md`'s own rule cuts
the other way (hedging something that *was* checked makes a measurement read as a guess):

| Category | Action |
|---|---|
| Unsourced causal or psychological claims | Mark as hypothesis, or attach the case |
| Superlatives with no axis | Name the axis and set compared, or cut |
| Imperatives | Leave hard |
| Punch with the incident beside it | Leave |

Known instances, from a keyword sweep on 2026-08-19 — **representative, not the complete
per-sentence read of all ten files**, which is what this step owes:

- `grounded.md` "The reason you exist" and `grounded-output-style/README.md` "Where the confidence
  comes from" state the genre-source claim flat. The memory that mandates that preamble
  (`preamble-confident-prose-trap`, this project's store) calls it *the hypothesized source* — the
  shipped text dropped the hedge its own source carried. This was the user's example.
- `refile-rules/SKILL.md` §2, "the largest single source of bulk" — a ranking across a set nobody
  scored, in a file that forbids exactly that.
- `refile-rules/SKILL.md` §5, "A store full of these is worse than a long one" — generalization
  with no case.
- `reconcile-records/SKILL.md` gate six, "the entries most likely to be years old and still
  steering decisions" — unmeasured superlative.

Explicitly **kept**: "Nobody has ever failed to be rigorous on purpose"
(`refile-rules/SKILL.md` §5) and "The smallest thing that can be committed beats the best thing
that can't" (`keep-ledger/SKILL.md` §2). Both compress something true stated nearby; trimming
them loses the trigger. Recorded here so a later pass does not re-litigate them.

**Proof that ran** `[verified 2026-08-19]`: three greps across all 11 shipped files, terms derived
from the category definitions rather than from the hits already listed. Category 2 (superlatives)
ran on `the (only|most|biggest|largest|strongest|highest|richest)` plus `-est` compounds; category
1 on `people|nobody|everyone|anyone|is how a|tends to|borrowed from|genre|audience`; category 3 on
named outside systems. A fourth, unplanned check measured **bold density** per file, since bold is
a superlative in typographic form and the sweep's own categories imply it.

**Category 3 needed no fixes.** Every outside-system claim already carries a source, a version, or
a fetch date: superpowers 6.2.0 with a `grep -ci ledger` count of 33 against 0 for the other
thirteen skills; the `/output-style` removal in v2.1.91 with a docs link fetched 2026-07-30;
Anthropic's own flag on output-style cost. This is a finding, not an absence of one — the sweep
found the category well-served rather than failing to look.

**Fixed (11 sites):**

- The genre-source claim, in all three places, now labelled a hypothesis with the half that doesn't
  depend on it stated separately: `grounded.md` "The reason you exist",
  `grounded-output-style/README.md`, root `README.md`.
- `refile/SKILL.md` §2 "the largest single source of bulk" → worth looking for first, with the
  bulkiness question handed to the file rather than assumed.
- `refile/SKILL.md` §4 "the only kind of shrinking this pass permits" — **this had become false**,
  not merely overconfident, when step 4 added the edit branch. A register sweep caught a
  correctness bug, which is the argument for running it after the content steps rather than before.
- `refile` §5 and README "a round trip that mostly doesn't happen" → the objection stated as an
  argument rather than an empirical claim about what teams do.
- `distill/SKILL.md` §2 "the richest source", "the highest-value project entries", "the strongest
  signal available" → each restated with its axis, or as a reason rather than a ranking.
- `distill/SKILL.md` §6 "the only moment register is judgeable" → "where register is judgeable
  against the real wording".
- `reconcile/SKILL.md` gate two "usually the most perishable thing the session produced" and gate
  six "most likely to be years old" → both restated without the unscored ranking.
- Two claims **I wrote in steps 5 and 6** and swept on the same terms as the pre-existing text:
  grounded's "long output gets skimmed" and keep-ledger's "the answer is usually nothing".

**Explicitly kept, so a later pass doesn't re-litigate them:** "Nobody has ever failed to be
rigorous on purpose"; "The smallest thing that can be committed beats the best thing that can't";
"the only thing a reader needs"; "the only time it is cheap to write"; the superlatives *inside* the
rules that define superlatives, in `distill` §5's table and `grounded.md`'s claims section, which
are quoting the failure they describe.

**A prose pass ran after this step, at the user's request, and is part of it.** Thirteen fixes, in
three kinds. Redundancy was the largest: `refile/SKILL.md` carried the scope-boundary formulation
three times and the merge-vs-sorted-diff argument twice; `reconcile/SKILL.md` had "a transcript
about to be summarized away" in two adjacent paragraphs plus a third copy of the gate-two argument
in its new Siblings section. Each is now stated in full once, with pointers elsewhere — which is
step 5's own "an entry restating a rule stated in full elsewhere in the same file" rule, applied to
the file that states it. Ambiguous antecedents in `distill`'s Siblings section ("its boundaries",
"what that showed") were named explicitly. The rest was dead words and one vague claim of mine
("it spends something to do it" — now says what it spends).

**The register sweep over-corrected, and the prose pass caught it.** `grounded-output-style/README.md`
stated the hypothesis hedge three times across two paragraphs; the root README had "offered as a
hypothesis and labelled as one", redundant with itself, and a pre-existing "backed by verified
evidence" that says *verified* twice. **Hedging something three times is a calibration failure in
the same family as not hedging it at all** — worth knowing for the next sweep, because the
correction pass has no natural check on itself and this one needed a second reader to find it.

**Bold density, measured across all 11 files:** 0.55–1.59 per 100 words, against the ~1 per 100 the
user's own memory files hold. `distill-lessons/README.md` is highest at 1.59 and
`refile-rules/SKILL.md` was 1.34 before trimming two whole-clause spans down to their claims. Most
remaining bold is list-item leads, which is structure rather than emphasis — worth knowing before
anyone treats the raw ratio as a defect.

### 9. Versions and final verification — DONE 2026-08-19

Bump `version` in the affected `plugin.json` files and in each changed `SKILL.md`'s frontmatter.
Current: distill-lessons 1.3.0, reconcile-records 1.4.0, keep-ledger 1.0.0, refile-rules 1.0.0,
grounded-output-style 2.0.0. `refile-rules` gains a capability — minor bump, and its
**description is duplicated in `.claude-plugin/marketplace.json`**, which must be updated in step
4 or here.

**Proof that ran** `[verified 2026-08-19]`: every JSON file in `.claude-plugin/`,
`plugins/*/.claude-plugin/` and `plugins/*/skills/*/evals/` parses. `git diff --stat` is 19 files,
376 insertions, 176 deletions, plus this ledger, which was untracked until the commit that carries
it. (It read 378/173 before the prose pass recorded in step 8 — the earlier figure is what a stat
taken mid-pass says, not a correction of it.)

Versions bumped, all minor — every plugin gained behaviour and none broke an interface:
distill-lessons 1.3.0→1.4.0, keep-ledger 1.0.0→1.1.0, reconcile-records 1.4.0→1.5.0, refile-rules
1.0.0→1.1.0, grounded-output-style 2.0.0→2.1.0. Each `SKILL.md` frontmatter matches its
`plugin.json`; `grounded-output-style` has no skill, so only its `plugin.json` carries a version.

**Unplanned work absorbed here — the eval counts stated in prose.** Both READMEs assert eval counts,
which are claims about files outside their own diff and go stale silently:

- Root README's "Twenty-six cases in all: seven each for `keep-ledger`, `distill-lessons`, and
  `reconcile-records`, five for `refile-rules`" — **re-derived and correct**, left alone.
- Both READMEs' `trigger_eval` counts were **falsified by this pass**. Two phrasings were added to
  `refile-rules`' set, taking it 20→22 (10 positive, 12 negative), which happens to match
  `keep-ledger`'s 22. The root README said "twenty for the first (nine positive)"; corrected.
- The added positive is *"the same rule is written out in three places in here, can you consolidate
  them"*, which tests the new edit branch at trigger level. The added negative is *"reword the
  caching rule so it's clearer"* — the trigger-level form of the scope boundary, since this skill
  can now change a rule's text and the set has to draw the line the skill draws.
- Sibling-owned negatives re-counted by hand: six `reconcile-records`, three `distill-lessons`
  (including the new one), which is the "nine" both READMEs now state. `"what's in CLAUDE.md right
  now?"`, `"reformat this file to wrap at 80 columns"` and `"add a line to CLAUDE.md about…"` are
  counted as belonging to no sibling.

**Method note:** `trigger_eval.json` is stored one entry per line, not `json.dumps(indent=2)`. A
round trip reformats all 20 lines (88 insertions / 21 deletions) to add two entries. Reverted and
redone as a targeted string insert; the correct diff is `3 insertions, 1 deletion`. Same trap as
step 4's, second occurrence — **treat every JSON file here as having a hand-maintained format until
checked.**

## Not in scope

- Rewriting the skills' step numbering or structure. Steps 4 and 6 add to existing sections.
- Any change to `docs/keep-session-warm-postmortem.md` or the retired plugin's records.
