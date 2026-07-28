# refile-rules

Reorganizes a rule store whose structure stopped holding — sections that drifted into overlap, a
file grown past the length anyone reads to the end, rules filed by feel because the boundary was
never real, and content sitting in an always-loaded file when the moment it is needed would have
triggered it anyway.

**Why it's separate.** A store makes two kinds of claim: each entry claims something is true, and
the organization claims its sections carve the subject at real joints. Only the first ever gets
checked. But a rule that can't be found doesn't fire, and a rule that doesn't fire is
indistinguishable from one that was never written — the file still reads well, every line in it is
still true, and the failure surfaces somewhere else entirely.

## When it runs

Not on a schedule, and not speculatively. Four triggers: a lessons pass reported it couldn't tell
which section an entry belonged to; a rule that already existed failed to fire and couldn't be
narrowed into a checkable form; a measurement taken while the file was open anyway; or someone
asked.

Absent one of those, don't. Knowing where something lives is itself part of retrieval, and every
reorganization spends that down. This pass is cheap to run and expensive to run often — the
opposite of its siblings.

It is not for correcting what went false ([`reconcile-records`](../reconcile-records)) or deciding
what is worth recording ([`distill-lessons`](../distill-lessons)).

## The six steps

1. **Don't run speculatively** — one of the four triggers, or nothing.
2. **Diagnose before moving anything.** Length is a symptom shared by every possible cause. Name the
   failure shape: overlapping sections, a half-subsumed entry, triggered content in the always-loaded
   tier, a section that has become a bucket.
3. **Test the boundaries** — from the section headings alone, predict where four or five existing
   entries live, then check. Run it on entries you did *not* just write; your own recent filing is
   remembered, not predicted.
4. **Apply the placement criterion** — content belongs in the always-loaded tier when the moment you
   need it is a moment you would *not* know to go get it. Verification and judgment rules qualify.
   Language and tool conventions don't: an open `.R` file is a better summons than a rule in a file
   being read for other reasons.
5. **Re-file and merge; never abbreviate.** A rule fires because of its specificity. Compression
   buys space by removing what makes a rule recognizable, and the loss is invisible afterwards —
   the shortened version still reads as true and simply never fires.
6. **Propose as a manifest, then prove the move.** A reorganization diff is unreadable, which is
   exactly how a dropped rule goes unnoticed. Account for every rule as moved, merged, relocated, or
   deleted; then sort the rule lines before and after and diff the sorted forms. On a clean working
   tree, that diff is the proof.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install refile-rules@cgettings-skills
```

## What it won't touch

The wording of a rule it's moving (a move and a re-wording can't be verified together); entries
whose position carries meaning, like a dated log or an ordered checklist; prose you merely disagree
with; a team-shared store's organization without the team's say-so; and any store it didn't diagnose
in step 2.

## Evals

Five cases in [`skills/refile-rules/evals/evals.json`](skills/refile-rules/evals/evals.json), plus a
trigger set in [`skills/refile-rules/evals/trigger_eval.json`](skills/refile-rules/evals/trigger_eval.json).

No fixtures are checked in. Cases 1, 2 and 5 describe the store they would need — sections that have
genuinely drifted (case 1), a file mixing rules that must stay with conventions that should relocate
(case 2), and a file whose longest entry is the one that has to survive (case 5). Cases 3 and 4 need
no fixture and are judgeable from the response alone.

Twenty phrasings, nine positive and eleven negative. The negatives are the point: six of them are
prompts squarely in [`reconcile-records`](../reconcile-records)' territory and two in
[`distill-lessons`](../distill-lessons)'. All three skills describe a rule store going wrong, so
they compete for the same prompts, and a pass on this skill's happy path proves nothing about
separation.

One deliberate call: *"can you clean up the notes now that this is done"* is negative here.
"Now that this is done" scopes it to a work boundary, which makes it a correctness question rather
than a structural one. Ambiguous phrasings resolve to the sibling that already claims them.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
