---
name: query-log-retention
description: 30 days, why it isn't longer, what to do before it matters
metadata:
  type: project
---

Query logs are kept 30 days. The limit is legal, not technical — anything longer needs a
retention notice that nobody has written.

This bites when investigating a relevance regression reported late: if the complaint is older
than a month, the queries that produced it are gone and the investigation is guesswork.

If you need a window longer than 30 days for a specific investigation, export the subset you
need before the rolling delete catches it. There is no way to recover it afterwards.
