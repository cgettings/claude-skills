# reconcile-records

Finds and fixes records that recent work made false — status lines that have moved on, numbers
something re-measured, notes the code now states better, rules a newer rule replaced — and
captures the state the work left unrecorded, which is the same failure seen from the other side.

**Why it's separate.** Note-keeping systems only ever add. Every pass appends, nothing is
retired, and the store grows until the wrong parts outnumber the parts anyone trusts. Nothing
schedules anyone to look. This pass is that schedule.

## When it runs

After a merge, after a release, when a multi-stage task completes, when someone trips over a
stale doc, or as a periodic sweep — a wider set of occasions than a lessons pass. It also runs
right after [`distill-lessons`](../distill-lessons), **including when that pass found nothing**:
a session can teach you nothing and still merge a branch that falsifies a status line written
last week.

It is not for adding new knowledge — capturing a durable lesson belongs to
[`distill-lessons`](../distill-lessons). It is also not for reorganizing a store whose sections have
drifted into overlap or grown too long to read, which is [`refile-rules`](../refile-rules). Note
what you saw and move on: rearranging under cover of a correction sweep is how a bounded, cheap pass
becomes the expensive one nobody runs.

## The four steps

1. **Bound the scope** to what the work touched. An unbounded sweep is expensive, and expense is
   why this pass stops getting run.
2. **Apply the six gates** — status that has moved on; status that was never written down;
   numbers something re-measured; entries that became re-derivable; lines a newer rule subsumes;
   and claims that were never established, which no amount of drift makes stand out because
   nothing about them ever changes. Subsuming folds two rules into one that still states both
   specifics; it is not licence to shorten, because a rule fires on its specificity.
3. **Verify before deleting** — confirm the *claim* survives elsewhere, not merely the keyword;
   assume the summary may be newer than what it summarizes; separate a false present-tense claim
   from a true historical one.
4. **Propose, then apply** — the path, the line as it stands, the line as it would read, and what
   makes the current version false.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install reconcile-records@cgettings-skills
```

## What it won't touch

Dated historical statements that were true when written; anything whose current truth wasn't
actually checked; records outside the declared scope; and prose you merely disagree with. This
pass corrects what is false, not what is phrased differently than you'd phrase it.

## Evals

Seven cases in [`skills/reconcile-records/evals/evals.json`](skills/reconcile-records/evals/evals.json).
All but the near-miss need a seeded record store: a record calling the finished work unmerged (case 1), notes
holding both a present-tense and a dated claim about the same thing (case 2), two documents with
overlapping but not identical content (case 4), a store that says nothing at all about the
finished work (case 5), and — for the two gate-six cases — documents carrying unsourced claims
about outside systems, which case 7 requires to share no vocabulary with each other.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
