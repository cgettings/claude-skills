---
description: Verify and register a keepwarm for this session, in one step
argument-hint: "[hours] [interval-minutes] [session-id]"
allowed-tools: PowerShell, Bash, Read
---

Start a prompt-cache keepwarm for a Claude Code session, following the `keep-session-warm` skill. This is meant to be the last thing run before leaving the session for the night, so it completes without asking follow-up questions.

Arguments given: $ARGUMENTS — map a bare number of hours to `-DurationHours`, an interval to `-IntervalMinutes`, and a GUID to `-SessionId`. With no arguments the defaults protect the current session for 9 hours at 55-minute intervals.

Run:

```
& "${CLAUDE_PLUGIN_ROOT}/skills/keep-session-warm/scripts/Start-ClaudeKeepwarm.ps1"
```

The script already does the verification, so do not run `/keepwarm-check` first and do not ask whether to check — it probes the cache lineage itself, refuses to register if the probe does not land, and seeds the ping baseline from the probe's measurement.

Report, in this order:

1. Whether the keepwarm is registered, its first ping time, and when it expires.
2. The `Verdict` and `ProbeRead` — this is the evidence that the pings will land, and it is the whole reason to trust the registration.
3. Any warnings the script emitted, verbatim rather than summarised. The power ones are not boilerplate: a machine that sleeps with wake timers disabled will stop pinging, and `OnACPower: False` is the common cause.

If the script threw `LineageProbeFailed`, nothing was registered. Say so plainly, give the verdict and the advice it carried, and do not retry or fall back to `-SkipCheck` — the probe measured that the pings would not land, and registering anyway would cost more than doing nothing.

Close by reminding them to run `/keepwarm-stop` before resuming this session interactively: the scheduled ping and a live session both append to the same transcript file with nothing coordinating them.
