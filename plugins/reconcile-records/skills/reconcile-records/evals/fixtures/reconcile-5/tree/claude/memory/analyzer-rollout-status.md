---
name: analyzer-rollout-status
description: Staging done, prod behind a flag until the Nordics dictionary lands
metadata:
  type: project
---

The new language analyzer is running on staging and has been since 2026-05-30. Prod has it
behind `SEARCH_ANALYZER_V2`, defaulted off.

It stays off until the Nordics dictionary is signed off by support — Danish compound splitting
is the only part with no test coverage, and it is also the part most likely to be wrong.

Next step is support's review, not ours. Nothing is blocked on engineering.
