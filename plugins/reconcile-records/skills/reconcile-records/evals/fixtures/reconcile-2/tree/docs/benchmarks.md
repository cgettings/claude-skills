# Benchmark notes

## What the suite covers

The suite is 25 cases: 14 lookup, 7 multi-hop, and 4 negatives where the right answer is that
nothing matches. Every case carries an expected document id and a rank threshold.

Runtime is roughly four minutes on a laptop, which is the number that decided this runs
pre-push rather than in CI.

## History

The harness shipped on 2026-03-14 with 25 cases, all of them lookup. That first suite was
deliberately narrow — the point was to get a repeatable number before arguing about coverage,
and a broad suite nobody trusted would have been worse than a narrow one everybody did.

Multi-hop and negatives came later, in two batches, and each batch reset the baseline because
pass rate across a changed suite is not comparable to pass rate before it.

## What the numbers mean

Pass rate is the fraction of cases where the expected document lands at or above its rank
threshold. It is not accuracy — a case can pass with three irrelevant documents above the
expected one, provided the threshold is loose enough.

Compare pass rates only within a suite version. Across versions, compare the per-case table.
