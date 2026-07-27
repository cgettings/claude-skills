---
name: pipeline-refactor-status
description: Stage split, branch open, waiting on review
metadata:
  type: project
---

The pipeline is being split into one module per stage — `ingest`, `transform`, `emit` — instead
of the single `pipeline.py` that grew to about 600 lines.

Work is on the `pipeline-refactor` branch and is **not yet merged**. The three stages are
written and the tests pass locally; it is waiting on review from whoever picks it up next.

Do not start anything that touches `src/pipeline.py` until this lands — the split moves every
function in it, and a change made against the old file will not apply cleanly afterwards.

Related: [[partner-feed-casing]] moved to the `ingest` module as part of this.
