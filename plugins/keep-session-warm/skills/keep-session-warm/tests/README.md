# Tests

Four scripts. Three cost nothing and need no credentials; one spends money and
says so in its name-adjacent warning. Run the free three after any change to
`Ping-ClaudeSession.ps1`, `Get-CacheMissReason.ps1`, or `Get-ClaudeKeepwarm.ps1`.

```powershell
& .\Test-MissClassification.ps1
& .\Test-ReasonReplay.ps1
& .\Test-StatusTally.ps1
```

Each prints one line per case and a `PASS=n FAIL=n` total, and exits 1 on any
failure.

## What each one proves, and what it cannot

| Script | Proves | API cost |
|---|---|---|
| `Test-MissClassification.ps1` | The right branch is taken for every `cache_miss_reason`; `RESET` re-baselines the high-water mark while `MISS` leaves it alone; and the reset budget stops the keepwarm on the fourth rewrite | none |
| `Test-ReasonReplay.ps1` | `Get-CacheMissReason` returns what real transcripts actually recorded | none |
| `Test-StatusTally.ps1` | `Get-ClaudeKeepwarm` counts each tag, and `RESET` is not swept into the `MISS` count | none |
| `Test-FlushRace.ps1` | The ping's own record is readable before the 500 ms lookup timeout | **one resume ping** |

The split between the first two is deliberate. `Test-MissClassification` uses
fabricated records, so it proves the wiring but nothing about whether real
transcripts look the way the parser assumes. `Test-ReasonReplay` uses real ones,
so it proves the parser but nothing about what the ping script then does with
the answer. Neither alone is worth much.

### What none of them prove

**The branch has never been observed deciding unattended on a real miss.** A
real `system_changed` cannot be summoned — it needs something outside this
tooling to rewrite the prompt prefix. One was observed live on 2026-08-08, and
the recovery it produced is recorded in `SKILL.md` §6, but it happened outside
the script. Everything here fabricates that input.

**Which reason a TTL lapse reports is unmeasured.** No lapse with a known cause
appears in the transcripts these tests draw from, so the diverged-versus-lapsed
ambiguity `SKILL.md` §6 documents is not resolved by any of this.

## Notes on the harnesses

`Test-MissClassification` puts a shim `claude.cmd` on `PATH` that prints canned
result JSON, and writes a fabricated transcript under a reserved session id
(`1111…`) in the location `Resolve-ClaudeSessionContext` would look. It removes
both afterwards; `-KeepArtifacts` leaves them for inspection. It never passes
`-TaskName`, so it cannot touch a real scheduled task.

Its second half runs a **sequence** against one carried state file, which the
single-shot cases structurally cannot cover: continuing through a rewrite is
correct once and ruinous without limit, so the cap only exists across pings.
The sequence puts a healthy ping between two rewrites on purpose, to catch the
budget being treated as a consecutive streak rather than a lifetime total.

`Test-ReasonReplay` reads whatever is under `~/.claude/projects`, so its
coverage depends on the machine. It prints which reasons it found — check that
line rather than only the total, because a reason with no cases is a gap, not a
pass. It fails outright if it finds no cases at all, on the principle that a
replay which quietly tested nothing is the null result most worth distrusting.

It also reports an ambiguity count: `(read, write)` pairs mapping to records
with conflicting reasons. This validates the lookup rule, which identifies a
ping's record by matching those two numbers. Measured 0 across 217 transcripts
on 2026-08-08. A non-zero count here means the rule can pick the wrong record
and needs a stronger key.

`Test-FlushRace` needs a **throwaway** session, and one pinged recently — a warm
resume was $0.020 where a cold one is a full-prefix write. Pin `-Entrypoint` and
`-Effort` to what the target session runs under or the ping lands on a different
cache lineage and pays for a rewrite regardless.
