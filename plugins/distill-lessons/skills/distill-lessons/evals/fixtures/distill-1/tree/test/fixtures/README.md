Shared fixture database. Built once by `test/setup.js` and reused by every test file.

Shared rather than per-file because per-file setup put the suite over ten minutes.
