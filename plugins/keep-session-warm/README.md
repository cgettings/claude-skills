# keep-session-warm

Keeps a Claude Code session's prompt cache warm across a gap you aren't working through —
overnight, over a weekend — so resuming it is a cache read rather than a full-prefix rewrite.
Windows / Task Scheduler.

**Why it's separate.** A keepwarm is easy to build and easy to build wrong, and the wrong
version is indistinguishable from the right one from the outside. It runs on schedule, exits
zero, and writes a log full of successes — while every ping refreshes a cache entry the morning
resume will never read. You pay for the pings *and* the rewrite.

So the thing this gets right isn't the schedule. It's the match, plus a check that the match
still holds.

## The finding it's built on

Anthropic's prompt cache is a strict prefix match over `tools → system → messages` (Anthropic's
prompt-caching documentation, read 2026-08-07). Two requests share cached tokens only up to the
first byte where they differ, and each one's write extends only the chain — the *lineage* — it
belongs to. The same conversation can have several, and they
don't help each other.

Measured on one session, same id, same directory, seconds apart (2026-08-07, Claude Code
2.1.220, Opus 5):

| `claude -p --resume` invoked with | cache read | cache write | cost |
|---|---|---|---|
| the session's own environment | 37,950 | 19 | $0.019 |
| a clean environment | **12,424** | **22,150** | **$0.228** |
| clean, then again | 34,574 | 1,154 | $0.029 |

The conversation was byte-identical in all three. The readable prefix collapses to 12,424 tokens
— inside the tools/system region, ahead of every message — so the whole history downstream is
rewritten. The second lineage then warms up perfectly well, which is exactly why the failure is
invisible: rows two and three look like a keepwarm working.

The variable is `CLAUDE_CODE_ENTRYPOINT`, and Task Scheduler supplies a clean environment, so a
naive scheduled ping is row two every time. Restoring that one variable restored the lineage
exactly — read 37,969, precisely where the first chain left off. Effort level is a second key.
Both are pinned automatically.

## Commands

| Command | Does |
|---|---|
| `/keepwarm-start` | Probe, gate, and register in one step. The normal entry point. |
| `/keepwarm-check` | Probe alone, registering nothing — for diagnosing a session. |
| `/keepwarm-status` | Schedule state, ping history, cache high-water, accumulated cost. |
| `/keepwarm-stop` | Unregister — before resuming the session interactively. |

`/keepwarm-start` is designed to be the last thing you run before bed: it verifies, registers,
and reports without asking follow-up questions.

## What it does that a plain scheduler doesn't

- **Pins the lineage keys** (`CLAUDE_CODE_ENTRYPOINT`, effort) from the live environment where
  possible, the session transcript otherwise, and reports which source it used.
- **Refuses to register a keepwarm it just measured as broken.** `start` probes the lineage with
  the keys it is about to pin and stops if the probe doesn't land — a broken keepwarm is worse
  than none, because it bills at rewrite prices while logging success.
- **Seeds the baseline from that probe**, which closes a hole the running keepwarm cannot close
  itself: divergence is detected against a high-water mark, and if the *first* ping established
  that mark it would set it from the wrong number and clear its own bar all night.
- **Aborts on divergence.** On a healthy chain the cache read only ever grows. When a ping's read
  collapses while its write balloons, the task logs `MISS` and unregisters itself rather than
  spending the night refreshing a chain nobody will resume into.
- **Checks the machine will still be awake.** `-WakeToRun` is inert when the power plan disables
  wake timers — commonly the default on battery even when enabled on AC — so a free power
  pre-flight runs before anything is paid for.
- **Fails at registration, not at 3am** — a wrong `-ProjectDir` is caught up front, because
  `--resume` only finds a session from the directory that created it.
- **Starts on battery.** `-DontStopIfGoingOnBatteries` leaves `DisallowStartIfOnBatteries` at
  `True`; it governs stopping, not starting, so an unplugged laptop otherwise never fires the
  task at all.
- **Keeps stderr out of the JSON.** Merging them makes `ConvertFrom-Json` throw, which replaces
  `claude`'s actual message with the parser's complaint about it.

## Whether it's worth running

A 1-hour-TTL cache write bills at 2× base input and a read at 0.1× (Anthropic's prompt-caching
documentation, read 2026-08-07), so a full rewrite costs about **twenty warm pings** — on any
model, since both scale with the same base price. That puts
break-even near 18 hours at the 55-minute default; `/keepwarm-start` warns when the requested
duration crosses it.

Small sessions aren't worth protecting — the saving is a fraction of the prefix cost. And cost
isn't the only reason to want this: a warm resume is also a fast one.

## Scope

Windows only (Task Scheduler, PowerShell). The entrypoint finding is measured on one machine, on
Claude Code 2.1.220, between `claude-vscode` and a clean environment; that it's *a* lineage key is
verified and reproduced three times, that it's the *only* one isn't. `/keepwarm-check` measures
the thing directly and stays the authority after an upgrade changes something this README never
knew about.
