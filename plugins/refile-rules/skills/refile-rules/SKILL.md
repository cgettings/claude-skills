---
name: refile-rules
description: Reorganize a rule store whose structure stopped holding — sections drifted into overlap, a file grown past the length anyone reads to the end, rules filed by feel because the boundary was not real, or content sitting in an always-loaded file when the moment it is needed would have triggered it anyway. Use when a lessons pass reports it could not tell which section an entry belonged to, when a rule that already existed failed to fire and could not be narrowed into a checkable form, and whenever someone says a CLAUDE.md has got too big, that two sections say the same kind of thing, that they can never find the rule they need, or asks where something belongs. This is not for correcting what went false, which is `reconcile-records`, and not for deciding what is worth recording, which is `distill-lessons`. It moves rules between and within stores, and it may shorten one only where a specifics inventory shows that nothing making the rule fire was lost. Someone asking is a trigger in itself and running on demand is normal; absent a request, do not run it speculatively — a shuffle with no trigger is churn on a file whose whole value is that it stays put.
version: 1.1.0
license: GPL-3.0-or-later
---

# Refile rules

A rule store makes two kinds of claim. Each entry claims something is true. The file's organization claims its sections carve the subject at real joints — that there is a right place for each rule, and that a reader looking for one knows where to look.

The second kind goes false the same way the first does. Nothing ever checks it.

A rule that can't be found doesn't fire, and a rule that doesn't fire is indistinguishable from one that was never written. That is the whole cost, and it is invisible: the file still reads well, every line in it is still true, and the failure shows up somewhere else entirely, as a mistake nobody connects back to the store.

Be honest about the strength of this. You will almost never be able to show that a file's organization *caused* a particular miss; the counterfactual isn't available. The defensible claim is narrower and enough on its own — overlapping sections mean rules get filed arbitrarily and retrieved unreliably, and that is a bad property for rules whose entire purpose is to fire at moments you don't realize you need them.

## 1. Check that something triggered this

**Someone asking is a trigger, and it settles this step.** "This has got too big", "I can never find anything in here", "where does this even go?", or simply "run this on X" — that is the whole gate, and you go straight to step 2. Running on request is ordinary, not an exception. Read the request for a diagnosis before deriving your own; it usually names one.

The rest of this section governs runs **you** would be starting unprompted. Those need one of three:

- **A lessons pass reported it couldn't tell where an entry belonged** — two sections could hold it, or the choice came down to feel. Weight this one highest of the three: it is an observation made while actually filing, which is the only time a boundary gets tested rather than inspected.
- **A rule that already existed failed to fire, and couldn't be narrowed into a checkable form.** `distill-lessons` hands this over. The wording was not the problem; retrieval was.
- **A measurement taken while the file was open anyway** — length past the point anyone reads to the end, a section swollen past its neighbours.

Absent one of those, don't. A store whose rules stay where you last put them is worth more than a marginally better-organized one that moves every few weeks. Knowing where something lives is itself part of retrieval, and every reorganization spends that down. This pass is cheap to run and expensive to run often, unlike the passes it sits beside.

## 2. Diagnose before moving anything

The finding is never "this file is long." Length is a symptom shared by every possible cause, so it tells you nothing about what to do. Name which of these you actually found, and say how you established it:

- **Two sections both plausibly own the same rule.** The tell is usually recent: entries on the same subject filed into different sections, or one pass filing into both.
- **An entry partly subsumed by another**, often only a few bullets away, where neither reads as redundant on its own. This is the shape step 5's edit branch exists for; the others are fixed by moving things.
- **Content in the always-loaded tier that has a perfectly good trigger elsewhere.** Worth looking for first, because it is the shape that can be fixed without losing anything — see step 4. Whether it is also the bulkiest shape in a given file is a question that file can answer; don't assume it.
- **A section that has become a bucket** — a heading broad enough that nothing is ever wrong to file under it.

"It feels cluttered" is not a finding. Neither is a token count on its own.

## 3. Test the boundaries

The mechanical form of "the boundary is not real":

> Take four or five entries already in the file. From the **section headings alone**, predict which section each one lives in. Then check.

If you can't predict placement, neither could the pass that filed them, and neither will the retrieval that needs them later.

Run it on entries you did **not** just write. Your own recent filing is remembered, not predicted, and testing on it measures your memory of the session rather than the file's structure. This is the difference between an instrument and a mirror.

The failure mode tells you the fix. If two sections both attract the same rules, the usual answer is to merge them — and resist the pull to invent a distinction that explains the split, because an invented distinction is how the overlap arrived. If a section attracts *everything*, it's a bucket, and the fix is to find the two or three real subjects inside it.

## 4. Decide what belongs in the always-loaded tier

One criterion does most of the work here:

> **Content belongs in the always-loaded tier when the moment you need it is a moment you would not know to go get it.**

**It qualifies** for verification habits, judgment calls, and rules about how to work. You do not know you are about to assert something unverified. There is no file extension for "about to overclaim", no event that fires when an estimate is about to be stated as a measurement. Nothing will summon these except their already being there.

**It does not qualify** for anything with a natural trigger. An open `.R` file, a `.github/workflows/*.yml`, a `.ps1`, a Dockerfile — each is a better and more reliable summons than a rule sitting in a file being read for unrelated reasons. That content belongs in an on-demand skill, and the always-loaded file keeps at most a pointer naming it and when to reach for it.

This is the move that shrinks a store without losing anything: the content is still there, still reachable, and now summoned by something more reliable than proximity. Step 5's edit branch also shrinks a store, but it removes text rather than relocating it — which is why it carries a bar and this does not.

## 5. Re-file and merge — and shorten only against an inventory

A rule fires because of its specificity. Compare:

| Fires | Doesn't |
|---|---|
| "Never state a timing number you did not measure — and be suspicious of ones inferred from your own sleeps or polling intervals, which measure your parameter and not the system" | "Be rigorous about performance claims" |

Same subject. The first is an instrument; the second is a sentiment. Nobody has ever failed to be rigorous on purpose.

Compression is seductive here because it appears to buy the same space that re-filing buys. It does not. It buys space by removing the specifics that let a rule be recognized in a situation, and the loss is invisible afterwards — the shortened version still reads as true, still looks like a rule, and simply never fires.

So the default stands: **a move preserves text byte for byte.** That is what lets step 6 prove a reorganization mechanically, and most of any manifest should be moves.

### When an edit is permitted

Stores accumulate redundancy that re-filing alone cannot remove. Handing each instance back to `distill-lessons` is the clean answer on paper, but it costs a round trip per entry, and an extra pass someone has to remember to run is a weak place to put the fix. So an edit is available here, under a bar, and listed apart from the moves.

**Build the specifics inventory before changing a word.** Enumerate what makes the entry recognizable in a situation: named artifacts, commands and their flags, file paths, numbers, dates, conditions, the incident it rests on, the vocabulary someone would search for. Write the list down. It is both what you check against and what goes in the manifest.

**Then the bar: every item on that inventory is locatable in the new text, or named in the manifest as a deliberate drop with a reason.** No item is excused by the edit reading better.

Three shapes qualify:

- **Two entries duplicating a specific.** The merged form states the union of both inventories; the second copy of the shared specific goes.
- **Connective prose that names nothing** — a sentence restating the entry's own heading, a transition, a re-assertion of what the previous bullet just said.
- **An entry restating a rule stated in full elsewhere in the same file.** The full statement stays; the restatement becomes a pointer, or goes.

What does not qualify: **an entry that carries its own specifics and is merely long.** Length was never the finding — step 2 says so directly. An entry long because it names four conditions and the incident behind them is doing what a rule is for.

The scope boundary, which is what stops this becoming a rewrite pass: **this pass changes how much text a rule takes.** Only `distill-lessons` changes what it *asserts*. If the after-text asserts something the before-text didn't, or stops asserting something it did, you are past the boundary. Both are visible in the before/after pair, which is why step 6 shows them in full.

**Merging is subject to the same bar, and is declared as an edit.** A merge states both specifics in one entry; if the merged form names less than the two entries it replaced, it is a deletion wearing a merge's clothes. It produces text that was in neither original, so it is proved by being read rather than by step 6's sorted diff — build the inventory from *both* entries and check the merged form against the union.

**Never move and re-word an entry in the same manifest line.** The two cannot be verified together: the sorted-line diff that proves a move reads a re-wording as one rule dropped and another appearing. An entry needing both appears twice — once in the moves class, at its new location, text intact; once in the edits class, with the before/after shown.

## 6. Propose a two-class manifest, and prove each class its own way

A reorganization diff is unreadable. Every moved line appears as a deletion and an insertion, hundreds of lines apart, and that is precisely the diff in which a dropped rule goes unnoticed. Do not ask anyone to review one.

**Propose a manifest instead, split into two classes** — they are proved by different means, and mixing them costs you the mechanical proof.

**Class 1 — moves.** One line each: *moved to X* / *relocated to on-demand Z* / *deleted, surviving at W*. The rule's text is either unchanged or, for a deletion, removed whole. Anything not on the manifest should not have changed.

Prove this class mechanically: sort the rule lines before and after, and diff the sorted forms. The only differences may be the ones the manifest names. Anything else is text that changed while claiming not to — the failure this step exists to catch, and not visible any other way. The proof works *because* moves preserve text, which is why step 5's default is what it is.

**Class 2 — edits, merges included.** Each is shown in full: the before text — both befores, for a merge — the after text, and step 5's specifics inventory with every item marked carried-over or dropped-with-reason.

This class gets no mechanical proof; by construction the text changed. It is proved by being read, which is only possible while the class stays small. If it isn't small, that is itself the finding — a rewrite is running under a reorganization's name, and it needs a different conversation before it goes any further.

Do this on a **clean working tree**. On a dirty one the proof is worthless: you'd be reading your reorganization fused with whatever else was in flight, and you'd have to reconstruct which was which afterwards from memory.

Deletions carry the higher bar they carry everywhere — name where the content survives, or say plainly that it is being dropped and why that's acceptable.

Then ask before applying. A project `CLAUDE.md` is usually shared with a team, and how it's organized is their call, not yours. **Ask about the two classes separately.** Someone may take every move and refuse every edit; that is a normal outcome, not a rejection of the pass, and the moves shouldn't be held hostage to it.

## What not to touch

- **The wording of a rule you're moving, in the same manifest line.** Doing both at once makes the move unverifiable and the edit unreviewable. Step 5 says how to declare an entry that genuinely needs both.
- **What a rule asserts** — step 5's scope boundary. Re-scoping a rule, adding a condition, dropping one, or sharpening it into a checkable form is `distill-lessons`' revision branch.
- **Entries whose position carries meaning** — a dated log, an ordered checklist, anything where sequence is content rather than filing.
- **Prose you merely disagree with.** This pass moves what is misplaced and shortens what is redundant — not what is phrased differently than you'd phrase it. An entry you find wordy whose every specific is load-bearing is not a candidate, and step 5's inventory is what separates the two cases. If your proposed edit drops nothing from the inventory and simply reads more like you, you are outside this pass.
- **A team-shared store's organization, without the team's say-so.** Propose; don't apply.
- **Any store you didn't diagnose in step 2.** Scope creep here is unbounded by nature — there is always another file that could be tidier, and none of them asked.

## Siblings

**`distill-lessons` is this skill's pair.** It decides what is worth recording and where it goes; this pass repairs the *where* when the structure can no longer hold it. Two of the three unprompted triggers in step 1 come from it, because filing is when a store's boundaries get tested. The same division of labour draws step 5's scope boundary.

`keep-ledger` and `reconcile-records` are the other pair and neither feeds this one. A line that went *false* is `reconcile-records`' — note it and move on rather than correcting it here, since a correction folded into a reorganization is invisible in both proofs.
