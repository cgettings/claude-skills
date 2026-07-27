---
name: synonym-file-ownership
description: Support owns it, engineering reviews, neither deploys
metadata:
  type: project
---

`config/synonyms.txt` is owned by support. They edit it directly; engineering reviews the PR for
syntax only and does not second-guess the entries.

Deploying it is a third thing: the file is read at index build time, so a synonym change does
nothing until the next rebuild. Support has been surprised by this more than once.

If someone asks why a synonym "isn't working", check when the index was last rebuilt before
looking at anything else.
