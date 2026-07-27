---
name: benchmark-suite-scope
description: What the 25 cases cover and why pass rate isn't accuracy
metadata:
  type: project
---

The suite currently holds 25 cases. The split matters more than the total: negatives are the
only cases that catch an over-eager retriever, and there are only four of them, so a jump in
pass rate driven entirely by lookup cases means very little.

When the harness shipped in March 2026 the suite was 25 cases and all of them were lookup.
Everything since has been about widening it, not lengthening it.

Pass rate is not accuracy — see `docs/benchmarks.md` for what the threshold actually asserts.
