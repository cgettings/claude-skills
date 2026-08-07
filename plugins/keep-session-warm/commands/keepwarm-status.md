---
description: Report keepwarm schedule state, ping history, and whether the cache is still being held
argument-hint: "[session-id] [tail-lines]"
allowed-tools: PowerShell, Bash, Read
---

Report the state of prompt-cache keepwarms, following the `keep-session-warm` skill.

Arguments given: $ARGUMENTS — a GUID maps to `-SessionId`, a bare number to `-Tail`. With no arguments, report every keepwarm on the machine.

Run:

```
& "${CLAUDE_PLUGIN_ROOT}/skills/keep-session-warm/scripts/Get-ClaudeKeepwarm.ps1"
```

Lead with `Status` for each session, because it is the only field that answers the question the user is actually asking:

- **`OK`** — pings are landing on the session's lineage; the cache is being held.
- **`MISS`** — a ping's cache read collapsed and the task unregistered itself. **The session stopped being protected at that timestamp** and resuming it will pay a full-prefix rewrite. Say this outright; do not report the OK pings that preceded it as if the night succeeded. Quote the MISS line from `RecentLog`, and treat finding what changed — a Claude Code upgrade, a different effort level, an altered tool list — as the next step, not restarting the keepwarm.
- **`ERROR`** — pings are failing outright. The message in `RecentLog` is `claude`'s own; read it rather than guessing.
- **`NoPingsYet`** — registered but the first interval has not elapsed.

Then give the supporting numbers: `NextRunTime`, `Pings`/`OkPings`/`MissPings`, `TotalCostUsd`, and `CacheHighWater`.

A row with `TaskRegistered: False` and a populated log is a finished or aborted keepwarm whose log survives. That is normal for a completed night and is the record of whether it worked.
