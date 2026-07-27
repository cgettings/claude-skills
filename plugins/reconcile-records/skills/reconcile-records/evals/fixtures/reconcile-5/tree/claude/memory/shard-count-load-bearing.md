---
name: shard-count-load-bearing
description: 12 on staging, 24 on prod, and why they differ
metadata:
  type: project
---

Staging runs 12 shards, prod runs 24. This is deliberate and not a drift to be tidied up:
staging exists to catch mapping errors, which reproduce at any shard count, and doubling it
would double the rebuild time for no extra signal.

The consequence is that rebuild timings from staging do not extrapolate to prod. A staging
rebuild finishing in an hour says nothing useful about the prod window.

Anything that depends on shard count — routing, the reindex script's batching — reads it from
`ops/reindex.env` rather than hardcoding.
