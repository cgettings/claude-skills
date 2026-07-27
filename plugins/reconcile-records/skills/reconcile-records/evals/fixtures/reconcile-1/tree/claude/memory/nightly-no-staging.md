---
name: nightly-no-staging
description: What the missing staging environment costs and how we work around it
metadata:
  type: project
---

There is no staging copy of the nightly job. A bad deploy is found the next morning from the
partner mismatch report, roughly nine hours after it lands.

The workaround is a dry-run flag that writes to a scratch schema instead of the real one. It is
not wired into cron — you run it by hand before pushing anything that touches `emit`.

This is why `pytest -q` before pushing is a standing instruction rather than a suggestion.
