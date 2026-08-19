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

**On demand, whenever you ask.** "This has got too big", "I can never find anything in here",
"where does this even go?", or just "run this on my CLAUDE.md" — a request is the whole gate, and
running it this way is normal rather than an exception. Most requests carry the diagnosis with
them, too.

Unprompted it needs one of three: a lessons pass reported it couldn't tell which section an entry
belonged to; a rule that already existed failed to fire and couldn't be narrowed into a checkable
form; or a measurement taken while the file was open anyway. Absent one of those, it doesn't run
itself. Knowing where something lives is part of retrieval, and every reorganization spends that
down — this pass is cheap to run and expensive to run often, unlike the passes it sits beside.

It is not for correcting what went false ([`reconcile-records`](../reconcile-records)) or deciding
what is worth recording ([`distill-lessons`](../distill-lessons)).

## The six steps

1. **Check that something triggered this** — a request settles it; otherwise one of the three
   unprompted triggers, or nothing.
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
5. **Re-file and merge — and shorten only against an inventory.** A rule fires because of its
   specificity, so the default is that a move preserves text byte for byte. Shortening is available
   under a bar, described below.
6. **Propose a two-class manifest, and prove each class its own way.** A reorganization diff is
   unreadable, which is exactly how a dropped rule goes unnoticed.

## Shortening, and the bar it has to clear

Re-filing alone can't remove genuine redundancy. Handing each instance back to
[`distill-lessons`](../distill-lessons) is the clean answer on paper; the objection is that it costs
a round trip per entry, and an extra pass someone has to remember to run is a weak place to put the
fix. So this pass can shorten an entry, under conditions that exist to stop it quietly removing the
specifics that make a rule fire.

**The bar is a specifics inventory.** Before changing a word, enumerate what makes the entry
recognizable in a situation: named artifacts, commands and flags, file paths, numbers, dates,
conditions, the incident it rests on, the vocabulary someone would search for. Afterwards, every
item must be locatable in the new text or named in the manifest as a deliberate drop with a reason.

**Three shapes qualify:** two entries duplicating a specific (the merged form states the union);
connective prose that names nothing; an entry restating a rule stated in full elsewhere in the same
file. **One explicitly doesn't:** an entry that carries its own specifics and is merely long. Length
was never the finding.

**The scope boundary.** This pass changes how much text a rule takes; only `distill-lessons` changes
what it *asserts*. If the after-text asserts something the before-text didn't, or stops asserting
something it did, it's out of scope — and both are visible in the before/after pair.

**Which is why the manifest has two classes.** Moves, relocations and deletions keep the surviving
text byte for byte, so they're proved mechanically: sort the rule lines before and after, diff the
sorted forms, and on a clean working tree that diff is the proof. Edits get no mechanical proof —
by construction the text changed — so each is shown in full with its inventory, and the class has
to stay small enough to read. **Merges are edits**, not moves: a merge produces text that was in
neither original, so the sorted diff can't speak to it. A large edit class is itself a finding —
that's a rewrite running under a reorganization's name. The two classes are proposed separately and
can be accepted separately.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install refile-rules@cgettings-skills
```

## What it won't touch

The wording of a rule in the same manifest line that moves it (the two can't be verified together);
what a rule *asserts*, as against how much text it takes; entries whose position carries meaning,
like a dated log or an ordered checklist; prose you merely disagree with — an entry you find wordy
whose every specific is load-bearing isn't a candidate, and the inventory is what separates those
two cases; a team-shared store's organization without the team's say-so; and any store it didn't
diagnose in step 2.

## Siblings

Its pair is [`distill-lessons`](../distill-lessons), which decides what's worth recording and where
it goes where this one repairs the *where*. Two of the three unprompted triggers come from it, and
the same division draws the scope boundary on shortening.

## Evals

Five cases in [`skills/refile-rules/evals/evals.json`](skills/refile-rules/evals/evals.json), plus a
trigger set in [`skills/refile-rules/evals/trigger_eval.json`](skills/refile-rules/evals/trigger_eval.json).

No fixtures are checked in. Cases 1, 2 and 5 describe the store they would need — sections that have
genuinely drifted (case 1), a file mixing rules that must stay with conventions that should relocate
(case 2), and a file whose longest entry is the one that has to survive (case 5). Cases 3 and 4 need
no fixture and are judgeable from the response alone.

Cases 2 and 4 are where the shortening bar is tested, from both sides. Case 2 ("my CLAUDE.md has got
out of hand, can you get it down?") is the prompt that invites unbounded compression, and it also
checks that a direct request is accepted as a trigger without hunting for another. Case 4 is the same
complaint against a file where nothing qualifies, so the correct answer is to decline — and to
decline on the grounds that no entry meets the inventory bar, not that shortening is forbidden. Case
5 adds the third side: its longest entry must survive both relocation *and* shortening, which are the
same error reached by two different routes.

Twenty-two phrasings, ten positive and twelve negative. The negatives are the point: six of them are
prompts squarely in [`reconcile-records`](../reconcile-records)' territory and three in
[`distill-lessons`](../distill-lessons)'. All three skills describe a rule store going wrong, so
they compete for the same prompts, and a pass on this skill's happy path proves nothing about
separation.

Two deliberate calls. *"Can you clean up the notes now that this is done"* is negative: "now that
this is done" scopes it to a work boundary, which makes it a correctness question rather than a
structural one. And *"reword the caching rule so it's clearer"* is negative even though this skill
can now change a rule's text — rewording for clarity changes what a rule asserts, which is
`distill-lessons`' revision branch, where shortening a redundant entry is this one's. That pair of
phrasings is the trigger-level form of the scope boundary. Ambiguous phrasings resolve to the
sibling that already claims them.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
