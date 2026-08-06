---
name: reconcile-records
description: Find and fix records that recent work made false — status lines that have moved on, numbers something re-measured, notes that became re-derivable, rules a newer rule replaced, and state the work left unrecorded. Use when a branch merges, a release ships, or a multi-stage task completes; right after a lessons pass, including when that pass found nothing worth recording; when someone trips over a stale doc, memory, comment, or README; and whenever the user asks "is this still true?", "anything out of date?", "clean up the notes", or "does the doc still match the code?". This is not for adding new knowledge — capturing a durable lesson is `distill-lessons`. It is also not for reorganizing a store whose sections have drifted into overlap or grown too long to read, which is `refile-rules`. Keeping a status record while work is live is `keep-ledger`; this pass checks one. This pass makes the record match reality — it corrects, retires, and where the work left state unrecorded, captures that state. It runs whether or not the work taught anything.
version: 1.4.0
license: GPL-3.0-or-later
---

# Reconcile records

Keeping a record true is half of keeping it useful. Most note-keeping only adds: every pass appends, nothing is retired, and the store grows until the wrong parts outnumber the parts anyone still trusts.

Nothing schedules anyone to look. This pass is that schedule.

It is not a lessons pass. That one asks what insight should be *added*; this one asks whether the record still describes reality. They run back to back, and this one runs even when the other found nothing — a session can teach you nothing and still merge a branch that falsifies a status line written last week.

Most of the work here is correcting and retiring. But a record can misdescribe reality by omission as easily as by error, so the gates below include the state this work left unwritten. That is not a lessons exception: bookkeeping is not knowledge, which is exactly why the lessons pass shouldn't be carrying it.

## 1. Bound the scope

Check what the work touched, not the whole store. An unbounded sweep is expensive, and expense is why this pass stops getting run.

Derive the scope from the work itself: the branch's `git log`, the files changed, the subject terms someone would have used when writing about it. Grep the record store for those terms — CLAUDE.md, memory, audit docs, READMEs, long-lived comments — and open only what matches.

State the scope you settled on. If asked for something broader, say what you covered and what you deliberately did not.

## 2. Apply the six gates

**Status that has moved on.** "Not yet merged", "still open", "parked", "in progress", "blocked on", "verified <date>". These go false by design the moment the thing they describe advances. If the work advanced it, fix the line or delete the entry.

A ledger — the per-step status record `keep-ledger` keeps in the document that owns the work — is written to be checked exactly this way: one line per step, each carrying a status and a date. Where one exists, start there.

**Status that was never written down.** The mirror of the gate above, and the one people skip because nothing stale is staring at them. Work that ends mid-flight leaves state no record holds: a branch that shipped but is unmerged, which stages of a plan landed, a verification deferred to a window that hasn't come, a decision taken but never filed. That state is usually the most perishable thing the session produced — it lives only in a transcript that is about to be summarized away. Write it where the status of that work already lives, in the same form as its neighbours. Judge it by whether a future session would be stuck without it, never by whether it taught anything: this is bookkeeping, and holding it to a lessons bar is how it goes unrecorded.

`keep-ledger` writes this state while the work is live, which is the only time it is cheap to write. Where no ledger was kept, this gate is what stands between that state and a transcript about to be summarized away — so when it fires, say so, because a ledger written now costs less than this gate firing again at the next boundary.

**Numbers something re-measured.** If a recent measurement contradicts what a record states, the record is wrong now. Correct it in place and say it was wrong — a quietly updated figure still misleads the next reader, who has no way to know it moved.

**Entries that became re-derivable.** A note whose content is now stated in the code, in CLAUDE.md, or in a doc has become a second copy. Two copies drift, and later readers can't tell which is current. Delete the copy; keep the load-bearing one.

**Lines a newer rule subsumes.** When a broad rule lands, the narrower rule it replaced usually survives beside it. Adding without subtracting is how an always-loaded file grows until nobody reads it.

Subsuming folds two rules into one that still states both specifics. It is not licence to shorten. A rule fires because of its specificity, so a merge that reads more smoothly and names less has removed the trigger while looking like tidying — and that loss is invisible afterwards, because what's left still reads as true.

**Claims that were never established.** The five gates above all detect something that *became* false: the branch merged, the number moved, a newer rule landed. This gate is for lines that were never true to begin with — a claim about how a vendor behaves, what a tool can detect, or what other teams do, written from recall and typeset as a conclusion. Nothing about them ever changes, so no amount of drift makes them stand out, and every pass that looks for change walks straight past them. They are the entries most likely to be years old and still steering decisions.

The detector is **categorical, not positional**: any sentence whose subject is a system outside the repo. In-repo claims can be re-checked from the repo by anyone, forever; these cannot be re-checked from the repo at all, which is why they get the least scrutiny exactly where correction is hardest. Derive your search terms from that definition — crawler and vendor behaviour, ranking factors, what a tool can detect, industry convention, what other teams do — and not from the hits you have already found. A probe built from one cluster of hits finds that cluster again and reports zero everywhere else.

That has happened. A sweep whose terms came from a dense passage about search crawlers fired five times inside that passage, treated the firing as a positive control, and returned zero across three other documents — where a wider pattern later found claims in all three. The terms were the giveaway: "crawler", "robots" and "sitemap" share no vocabulary with the claims that were missed, which ran to the shape "this analytics library anonymises IP by default" and "this mapping library has no such method on a polygon". The probe could not have matched those sentences, so its zero described the probe rather than the documents.

Sourced and unsourced claims sit side by side in the same voice, so good attribution nearby is not evidence. In that same crawler passage, three claims named the vendor's published guidance and six others in identical register named nothing. Read the sentences; do not infer from the neighbourhood.

**The fix is attribution, not deletion.** Supply a source, a date, the command that was run, or — for a ranking claim — the axis and the set compared. Delete only when none of those can be produced, and say that is why.

Be honest that this is not a cheap gate. The other five are look-ups: you know the term, you grep, you compare. This one reads for subject matter across a document. Bound it the way step 1 bounds everything else — by *which files you open*, choosing the ones whose subject touches external systems at all — and not by narrowing the test back to a couple of predictable positions. Position has been tried and misses: these claims track what the author was writing *about*, so they land in ordinary body prose wherever a vendor, a browser, a spec, or a tool comes up. A cheap test that cannot find the category is worse than an expensive one you scope down to three files.

## 3. Verify before you delete

Deletion is the irreversible half of this pass, and the check that feels sufficient usually isn't.

**Confirm the *claim* survives elsewhere, not the keyword.** Grepping for a term proves the word is present. It does not prove the surviving copy asserts the same thing.

**Assume the summary may be newer than what it summarizes.** An index line, a README, or a status field often gets updated when the underlying file doesn't. If the two disagree, work out which is newer before deleting either — the short one may be the only place a correction ever landed.

**Separate a false present-tense claim from a true historical one.** "The suite is 12 pages" is wrong once it's 14. "The suite was 12 pages when this shipped" is a dated record and stays. Only the first is in scope, and confusing the two destroys history to fix a non-problem.

## 4. Propose, then apply

Show the exact edits before making them: the path, the line as it stands, the line as it would read, and one sentence on what makes the current version false. For a capture under gate five there is no current line — give the path, the exact text, and the sentence a future session would be stuck without.

"Looks stale" is not a finding. Say what specifically is no longer true and how you established that — the command you ran, the file you read, the measurement you took.

Deletions carry a higher bar than corrections: name where the content survives, or say plainly that it's being dropped and why that's acceptable.

Report briefly what you checked and found *correct*. A pass that lists only problems gives no sense of coverage, and the reader can't tell a clean store from a shallow sweep.

## What not to touch

- Dated historical statements that were true when written and are labelled as such.
- Anything whose current truth you didn't actually check. An unverified guess about staleness is worse than leaving it alone.
- Records outside the scope you declared in step 1. Note them for a later pass rather than expanding silently.
- Prose you merely disagree with. This pass corrects what is false, not what is phrased differently than you'd phrase it. Read this together with gate six, which is one bad reading away from licensing exactly that: a missing source is a checkable fact about the document — the sentence names an outside system and cites nothing, and anyone can confirm it — whereas finding the sentence overconfident, or badly put, or not how you'd say it, is taste. Gate six fires on the first and never on the second. If your proposed edit rewrites a line that already carries its source, you are outside this pass.
- The *organization* of a store, as against the truth of its lines. Sections that have drifted into overlap, a file grown past the length anyone reads to the end, an entry half-subsumed by another three bullets up — all real problems, none of them this pass. They belong to `refile-rules`. Note what you saw and move on: rearranging under cover of a correction sweep is how a bounded, cheap pass becomes the expensive one nobody runs.
