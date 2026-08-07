---
description: Stop a prompt-cache keepwarm before resuming the session interactively
argument-hint: "[session-id | --all]"
allowed-tools: PowerShell, Bash, Read
---

Stop a prompt-cache keepwarm, following the `keep-session-warm` skill.

Arguments given: $ARGUMENTS — a GUID maps to `-SessionId`; `--all`, `all`, or `every` maps to `-All`. With no arguments, stop the current session's keepwarm.

Run:

```
& "${CLAUDE_PLUGIN_ROOT}/skills/keep-session-warm/scripts/Stop-ClaudeKeepwarm.ps1" -PassThru
```

Report which tasks were unregistered. An `Action` of `NotFound` is a normal, successful outcome — the task either expired and self-deleted on schedule, or unregistered itself after detecting a diverged lineage. Distinguish those two before calling it fine: if `/keepwarm-status` shows a `MISS` for that session, the keepwarm ended early and the session is no longer warm.

This is the right thing to run before resuming a protected session interactively, because the scheduled ping and a live session both append to the same transcript file with nothing coordinating them.

Stopping does not delete the ping log, which is the record of whether the keepwarm worked. `/keepwarm-status` still reads it afterwards.
