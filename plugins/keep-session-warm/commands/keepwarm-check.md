---
description: Probe whether a keepwarm ping would land on this session's prompt-cache lineage
argument-hint: "[session-id] [project-dir]"
allowed-tools: PowerShell, Bash, Read
---

Probe whether a scheduled ping would actually keep this session's prompt cache warm, using the `keep-session-warm` skill's guidance for interpreting the result.

Run:

```
& "${CLAUDE_PLUGIN_ROOT}/skills/keep-session-warm/scripts/Test-ClaudeCacheLineage.ps1"
```

Arguments given: $ARGUMENTS — if a session id and/or directory are present, pass them as `-SessionId` and `-ProjectDir`. With no arguments the script targets the current session and directory, which is the normal case.

Report the `Verdict` first, then the numbers behind it (`CacheRead`, `CacheWrite`, `ReadFraction`, `CostUsd`) and the lineage keys it probed with (`Entrypoint`, `EntrypointSource`, `Effort`).

Two things to say plainly rather than leave the user to infer:

- A `Diverged` verdict means scheduling a keepwarm with these keys would pay full-rewrite prices on every ping and still leave the session cold. Do not offer to start one until the cause is found.
- An `EntrypointSource` of `Transcript` rather than `Environment` means the key was inferred from the session's log rather than read from the live environment. It is a weaker signal — worth flagging if the verdict is marginal.

This probe costs one cache read and appends one turn to the session. Do not run it repeatedly to "confirm" a result.
