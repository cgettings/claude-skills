---
name: reconcile-records
description: Find and fix records that recent work made false — status lines that have moved on, numbers something re-measured, notes that became re-derivable, rules a newer rule replaced. Use when a branch merges, a release ships, or a multi-stage task completes; right after a lessons pass, including when that pass found nothing worth recording; when someone trips over a stale doc, memory, comment, or README; and whenever the user asks "is this still true?", "anything out of date?", "clean up the notes", or "does the doc still match the code?". This is not for adding new knowledge — capturing a durable lesson is `distill-lessons`. This pass only corrects and retires what is already written, and it runs whether or not the work taught anything.
---

# Reconcile records

Keeping a record true is half of keeping it useful. Most note-keeping only adds: every pass appends, nothing is retired, and the store grows until the wrong parts outnumber the parts anyone still trusts.

Nothing schedules anyone to look. This pass is that schedule.

It is not a lessons pass. That one asks what should be *added*; this one asks what should stop being asserted. They run back to back, and this one runs even when the other found nothing — a session can teach you nothing and still merge a branch that falsifies a status line written last week.

## 1. Bound the scope

Check what the work touched, not the whole store. An unbounded sweep is expensive, and expense is why this pass stops getting run.

Derive the scope from the work itself: the branch's `git log`, the files changed, the subject terms someone would have used when writing about it. Grep the record store for those terms — CLAUDE.md, memory, audit docs, READMEs, long-lived comments — and open only what matches.

State the scope you settled on. If asked for something broader, say what you covered and what you deliberately did not.

## 2. Apply the four gates

**Status that has moved on.** "Not yet merged", "still open", "parked", "in progress", "blocked on", "verified <date>". These go false by design the moment the thing they describe advances. If the work advanced it, fix the line or delete the entry.

**Numbers something re-measured.** If a recent measurement contradicts what a record states, the record is wrong now. Correct it in place and say it was wrong — a quietly updated figure still misleads the next reader, who has no way to know it moved.

**Entries that became re-derivable.** A note whose content is now stated in the code, in CLAUDE.md, or in a doc has become a second copy. Two copies drift, and later readers can't tell which is current. Delete the copy; keep the load-bearing one.

**Lines a newer rule subsumes.** When a broad rule lands, the narrower rule it replaced usually survives beside it. Adding without subtracting is how an always-loaded file grows until nobody reads it.

## 3. Verify before you delete

Deletion is the irreversible half of this pass, and the check that feels sufficient usually isn't.

**Confirm the *claim* survives elsewhere, not the keyword.** Grepping for a term proves the word is present. It does not prove the surviving copy asserts the same thing.

**Assume the summary may be newer than what it summarizes.** An index line, a README, or a status field often gets updated when the underlying file doesn't. If the two disagree, work out which is newer before deleting either — the short one may be the only place a correction ever landed.

**Separate a false present-tense claim from a true historical one.** "The suite is 12 pages" is wrong once it's 14. "The suite was 12 pages when this shipped" is a dated record and stays. Only the first is in scope, and confusing the two destroys history to fix a non-problem.

## 4. Propose, then apply

Show the exact edits before making them: the path, the line as it stands, the line as it would read, and one sentence on what makes the current version false.

"Looks stale" is not a finding. Say what specifically is no longer true and how you established that — the command you ran, the file you read, the measurement you took.

Deletions carry a higher bar than corrections: name where the content survives, or say plainly that it's being dropped and why that's acceptable.

Report briefly what you checked and found *correct*. A pass that lists only problems gives no sense of coverage, and the reader can't tell a clean store from a shallow sweep.

## What not to touch

- Dated historical statements that were true when written and are labelled as such.
- Anything whose current truth you didn't actually check. An unverified guess about staleness is worse than leaving it alone.
- Records outside the scope you declared in step 1. Note them for a later pass rather than expanding silently.
- Prose you merely disagree with. This pass corrects what is false, not what is phrased differently than you'd phrase it.
