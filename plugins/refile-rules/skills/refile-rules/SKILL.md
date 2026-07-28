---
name: refile-rules
description: Reorganize a rule store whose structure stopped holding — sections drifted into overlap, a file grown past the length anyone reads to the end, rules filed by feel because the boundary was not real, or content sitting in an always-loaded file when the moment it is needed would have triggered it anyway. Use when a lessons pass reports it could not tell which section an entry belonged to, when a rule that already existed failed to fire and could not be narrowed into a checkable form, and whenever someone says a CLAUDE.md has got too big, that two sections say the same kind of thing, that they can never find the rule they need, or asks where something belongs. This is not for correcting what went false, which is `reconcile-records`, and not for deciding what is worth recording, which is `distill-lessons`. It moves rules between and within stores, and it never abbreviates them. Do not run it speculatively — a shuffle with no trigger is churn on a file whose whole value is that it stays put.
version: 1.0.0
license: GPL-3.0-or-later
---

# Refile rules

A rule store makes two kinds of claim. Each entry claims something is true. The file's organization claims its sections carve the subject at real joints — that there is a right place for each rule, and that a reader looking for one knows where to look.

The second kind goes false the same way the first does. Nothing ever checks it.

A rule that can't be found doesn't fire, and a rule that doesn't fire is indistinguishable from one that was never written. That is the whole cost, and it is invisible: the file still reads well, every line in it is still true, and the failure shows up somewhere else entirely, as a mistake nobody connects back to the store.

Be honest about the strength of this. You will almost never be able to show that a file's organization *caused* a particular miss; the counterfactual isn't available. The defensible claim is narrower and enough on its own — overlapping sections mean rules get filed arbitrarily and retrieved unreliably, and that is a bad property for rules whose entire purpose is to fire at moments you don't realize you need them.

## 1. Don't run this speculatively

This pass needs a trigger. There are four:

- **A lessons pass reported it couldn't tell where an entry belonged** — two sections could hold it, or the choice came down to feel. This is the strongest signal available, because it's an observation made while actually filing, which is the only moment the boundary gets tested in practice.
- **A rule that already existed failed to fire, and couldn't be narrowed into a checkable form.** `distill-lessons` hands this over. The wording was not the problem; retrieval was.
- **A measurement taken while the file was open anyway** — length past the point anyone reads to the end, a section swollen past its neighbours.
- **Someone asked.** "This has got too big", "I can never find anything in here", "where does this even go?"

Absent one of those, don't. A store whose rules stay where you last put them is worth more than a marginally better-organized one that moves every few weeks. Knowing where something lives is itself part of retrieval, and every reorganization spends that down. This pass is cheap to run and expensive to run often, which is the opposite of its siblings.

## 2. Diagnose before moving anything

The finding is never "this file is long." Length is a symptom shared by every possible cause, so it tells you nothing about what to do. Name which of these you actually found, and say how you established it:

- **Two sections both plausibly own the same rule.** The tell is usually recent: entries on the same subject filed into different sections, or one pass filing into both.
- **An entry partly subsumed by another**, often only a few bullets away, where neither reads as redundant on its own.
- **Content in the always-loaded tier that has a perfectly good trigger elsewhere** — the largest single source of bulk, and the cheapest to fix. See step 4.
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

This is the move that actually shrinks a store, and it shrinks it without losing anything — which is the only kind of shrinking this pass permits.

## 5. Re-file and merge; never abbreviate

A rule fires because of its specificity. Compare:

| Fires | Doesn't |
|---|---|
| "Never state a timing number you did not measure — and be suspicious of ones inferred from your own sleeps or polling intervals, which measure your parameter and not the system" | "Be rigorous about performance claims" |

Same subject. The first is an instrument; the second is a sentiment. Nobody has ever failed to be rigorous on purpose.

Compression is seductive here because it appears to buy the same space that re-filing buys. It does not. It buys space by removing the specifics that let a rule be recognized in a situation, and the loss is invisible afterwards — the shortened version still reads as true, still looks like a rule, and simply never fires. A store full of these is worse than a long one, because it also carries the appearance of coverage.

**Merging is subject to the same bar.** A merge states both specifics in one entry. If the merged form names less than the two entries it replaced, it is a deletion wearing a merge's clothes.

**Do not re-word while moving.** A move and a re-wording cannot be verified together, and step 6's proof depends on the text being unchanged. If a rule's wording should improve, that is `distill-lessons`' revision branch — a separate pass, in a separate commit.

## 6. Propose as a manifest, then prove the move

A reorganization diff is unreadable. Every moved line appears as a deletion and an insertion, hundreds of lines apart, and that is precisely the diff in which a dropped rule goes unnoticed. Do not ask anyone to review one.

**Propose a manifest instead.** Every rule in scope, accounted for on one line each: *moved to X* / *merged with Y* / *relocated to on-demand Z* / *deleted, surviving at W*. Anything not on the manifest should not have changed.

**Then prove it mechanically.** Sort the rule lines before and after, and diff the sorted forms. The only differences may be the ones the manifest names. Anything else is text that changed while claiming not to — which is the failure this whole step exists to catch, and it is not visible any other way.

Do this on a **clean working tree**. On a dirty one the proof is worthless: you'd be reading your reorganization fused with whatever else was in flight, and you'd have to reconstruct which was which afterwards from memory.

Deletions carry the higher bar they carry everywhere — name where the content survives, or say plainly that it is being dropped and why that's acceptable.

Then ask before applying. A project `CLAUDE.md` is usually shared with a team, and how it's organized is their call, not yours.

## What not to touch

- **The wording of a rule you're moving.** Improving it is a different pass; doing both at once makes the move unverifiable and the improvement unreviewable.
- **Entries whose position carries meaning** — a dated log, an ordered checklist, anything where sequence is content rather than filing.
- **Prose you merely disagree with.** This pass moves what is misplaced, not what is phrased differently than you'd phrase it.
- **A team-shared store's organization, without the team's say-so.** Propose; don't apply.
- **Any store you didn't diagnose in step 2.** Scope creep here is unbounded by nature — there is always another file that could be tidier, and none of them asked.
