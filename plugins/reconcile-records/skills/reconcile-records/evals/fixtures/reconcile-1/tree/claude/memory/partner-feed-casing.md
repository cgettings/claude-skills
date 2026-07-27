---
name: partner-feed-casing
description: Why lowercasing happens at the boundary and nowhere else
metadata:
  type: project
---

Two partners send the same organisation under different casing (`NorthBay` and `northbay`), and
one of them changed casing mid-month without telling anyone. Joins silently produced two rows.

Lowercase at the ingest boundary, once, and treat every name downstream as already normalised.
Re-casing for display happens in the report layer, which is not in this repo.

The check that catches a regression is a group-by count on partner name before and after the
join — if they differ, something downstream re-cased.
