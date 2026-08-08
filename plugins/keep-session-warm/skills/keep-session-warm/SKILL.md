---
name: keep-session-warm
description: Keep a Claude Code session's prompt cache warm across a gap you are not working through — overnight, over a weekend, across a long break — so resuming it is a cache read rather than a full-prefix rewrite. Use when the user is about to leave a long session and wants to come back to it cheaply, says a session "went cold", asks why resuming cost so much or took so long, asks to keep a session alive or warm, mentions a keepwarm or pinging a session on a schedule, or wants to know whether an existing keepwarm is actually working. Also use when a scheduled keepwarm reports success but the morning resume was still expensive — that is the failure this skill exists to detect. This is not for reducing the cost of an active session, which is prompt design; and not for resuming a session whose cache has already lapsed, where the rewrite is already unavoidable and the only question is whether to pay it.
version: 1.0.0
license: GPL-3.0-or-later
---

# Keep a session warm

A prompt-cache keepwarm is easy to build and easy to build wrong, and the wrong version is indistinguishable from the right one from the outside. It runs on schedule. It exits zero. It writes a log full of successes. And in the morning the resume costs full price anyway, because every ping was refreshing a cache entry the resume would never read.

So the thing to get right is not the schedule. It is the match.

## 1. A ping only counts if it lands on the same lineage

Anthropic's prompt cache is a strict prefix match over `tools → system → messages` (Anthropic's prompt-caching documentation, read 2026-08-07). Two requests share cached tokens up to the first byte where they differ, and each one's write extends only the chain it belongs to. Call that chain a **lineage**. The same conversation can have several, and they do not help each other.

The keepwarm's entire job is to keep the lineage the *next interactive resume* will use. Measured on one session, same id, same directory, seconds apart (2026-08-07, Claude Code 2.1.220, Opus 5):

| `claude -p --resume` invoked with | cache read | cache write | cost |
|---|---|---|---|
| the session's own environment | 37,950 | 19 | $0.019 |
| a clean environment | **12,424** | **22,150** | **$0.228** |
| clean, then again | 34,574 | 1,154 | $0.029 |

The conversation was byte-identical in all three. The readable prefix collapses to 12,424 tokens — inside the tools/system region, ahead of every message — so the whole history downstream is invalidated and rewritten. The second lineage then warms up perfectly well, which is exactly why the failure is invisible: rows two and three look like a keepwarm working.

**The variable is `CLAUDE_CODE_ENTRYPOINT`.** Task Scheduler starts processes with a clean environment, so a naive scheduled ping is row two, every time. Restoring just that one variable restored the lineage exactly — read 37,969, precisely where the first chain had left off. Effort level is a second key, since it is part of the cache key too.

Both are pinned automatically: `Start-ClaudeKeepwarm.ps1` reads them from the live environment when you start the keepwarm from inside the session you are protecting, and falls back to the session's transcript otherwise. It reports which source it used; `Environment` is ground truth and `Transcript` is a weaker signal worth checking.

## 2. Decide whether it is worth it before scheduling it

A 1-hour-TTL cache write bills at 2× base input and a read at 0.1× (Anthropic's prompt-caching documentation, read 2026-08-07). Both scale with the same base price, so the ratio holds on any model: **a full rewrite costs about twenty warm pings.**

That sets a hard break-even at ~20 pings — about 18 hours at the 55-minute default. Inside that window the keepwarm saves money roughly in proportion to how much of it you use; past it you are spending more than the rewrite you are avoiding. `Start-ClaudeKeepwarm.ps1` warns when the requested duration crosses the line.

Two things change the calculus and are worth saying out loud rather than assuming:

- **Small sessions are not worth protecting.** The saving is a fraction of the prefix cost, so on a 30K-token session it is cents. The tool earns its keep on long sessions.
- **Cost is not the only reason.** A warm resume is also a fast one. If the user cares about picking up instantly rather than about the bill, the break-even argument does not apply and should not be recited at them.

## 3. The check is part of starting, not a step before it

`/keepwarm-start` probes the lineage itself, refuses to register if the probe does not land, and seeds the ping baseline from what it measured. There is no "remember to check first" — the intended use is one command and then bed.

It works this way because **the running keepwarm cannot check itself.** Divergence is detected by watching the cache read fall below a high-water mark, and the first ping is what establishes that mark. A keepwarm that was on the wrong lineage from its very first ping seeds the mark from the wrong number, and every later ping clears a bar set too low — `OK` all night, on a lineage nobody will resume into. The probe covers exactly the case the abort structurally cannot.

Timing is why it cannot be deferred to the first scheduled ping. The probe is diagnostic because it runs while the session's cache is still hot from live use, so a matching ping should read nearly everything. Fifty-five minutes later, a lapsed cache and a diverged lineage produce the same shape — low read, large write — and are no longer distinguishable.

The verdicts:

- **Warm** — the prefix was read, not rewritten. Registration proceeds.
- **WarmWithBacklog** — right lineage, turns accumulated on it since its last request. Registration proceeds.
- **Diverged** — the read collapsed. Nothing is registered, and `-SkipCheck` is the wrong response: the probe measured that the pings would not land.

The probe costs one cache read — roughly 5% of the rewrite it protects — and appends one turn. It deliberately does not test the mismatching case, because reproducing a divergence on a real session means paying for the full-prefix write this tooling exists to avoid.

`/keepwarm-check` still exists for diagnosing a session without registering anything.

## 4. The log is the record, and MISS is the line that matters

Each ping appends one line:

```
2026-08-07 11:43:26 BASE  read=38138 write=19 cost=$0.0195 (baseline established)
2026-08-07 11:43:29 OK    read=38157 write=22 cost=$0.0195
2026-08-07 11:44:27 MISS  read=12424 write=21877 cost=$0.2252  lineage diverged: read fell 67.5% below high-water 38179; unregistered 'ClaudeKeepwarm-...'
2026-08-08 00:48:54 RESET read=0 write=58782 cost=$0.3909  prefix rewritten (system_changed): read fell 100% below high-water 30648; re-baselined and continuing
```

`BASE` sets the high-water mark. `OK` means the read held. `MISS` and `RESET` both mean it collapsed while the write ballooned — and they are the same measurement, split by a second question.

That detection rests on one property: on a healthy chain the cache read only ever grows, because the prefix only grows. A read that falls sharply cannot happen without the prefix changing. The write-size guard alongside it stops a small session's noise from tripping the check — a collapsed read with a 22-token write is an artifact, not a divergence.

But *the prefix changed* has two causes with opposite responses, and the numbers alone cannot separate them. The pings may have drifted onto another lineage, in which case continuing refreshes a chain nobody will resume into. Or something outside the keepwarm may have rewritten the prefix under the session — and then the ping that paid for the rewrite has already re-warmed the new one, so stopping forfeits every hour that remains.

What separates them is a field the API returns and `claude -p` does not print: `cache_miss_reason`, read back out of the session transcript. `system_changed` and `tools_changed` mean the prefix was rewritten, and the keepwarm logs `RESET`, re-baselines its high-water mark to what the ping just wrote, and keeps running. Every other value — and an absent one — unregisters as before. That default is deliberate: the field is missing outright on some genuine misses, so nothing unproven gets to buy a reprieve.

What triggers it is not anything the keepwarm controls, and not always identifiable afterwards. A server-side tool-roster flip does it: on 2026-08-08 one dropped `TodoWrite` for `TaskCreate`/`TaskGet`/`TaskList`/`TaskUpdate`, rewriting the deferred-tool listing in the system prompt with CLI version, model, effort and directory all unchanged, and cost a keepwarm the remaining seven hours of its night. But a `system_changed` observed the same day on a throwaway session had **no roster delta recorded at all**, on the same entrypoint, effort and directory — so the roster is one cause rather than the cause, and a `RESET` line is not evidence that the roster is what moved.

**A `MISS` is not a tool failure to be retried.** It means the session stopped being protected at that timestamp, and resuming it will pay the rewrite. The useful response is to find out what moved — a Claude Code upgrade changing the harness preamble, or a different effort level — not to restart the keepwarm and hope.

**A `RESET` is not a failure at all.** The session stayed protected. The only thing worth reading off it is the cost: each one is a full-prefix rewrite that got billed, so several in a night is worth investigating even though none of them broke anything.

**Which is why continuing is capped at three.** Absorbing a rewrite is right when rewrites are occasional, because the ping that paid for one has re-warmed the new prefix. It stops being right if the prefix keeps moving — an uncapped keepwarm would buy a rewrite every interval all night and log each as a healthy line, and a rewrite is billed at full prefix rate: $0.39 on a 59K-token session, and a recorded 363,713-token rewrite on a large one came to about $3.64. The fourth rewrite therefore stops the keepwarm and logs `reset budget exhausted` rather than `lineage diverged`, because nothing diverged and the next reader should not go looking. The budget is a lifetime total, not a consecutive streak: a healthy ping in between two rewrites does not refill it. `-MaxResets` changes it.

## 5. What else breaks it

- **Battery.** `New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries` leaves `DisallowStartIfOnBatteries` at `True`; it governs stopping, not starting, so an unplugged laptop simply never fires the task. `-AllowStartIfOnBatteries` is the one that matters and is set.
- **Sleep.** `-WakeToRun` is set, but a lid-closed sleep or hibernate can still suppress firings. On a laptop, plugged in and awake, or do not bother.
- **Resuming interactively while it runs.** The ping and the live session both append to the same transcript file and nothing coordinates them. Stop the keepwarm first — `/keepwarm-stop`.
- **The wrong directory.** `--resume` only finds a session from the directory that created it; elsewhere it exits 1 with `No conversation found with session ID`. This is checked at registration rather than at 3am.

## 6. What is not established

The entrypoint finding is measured on this machine, on Claude Code 2.1.220, between `claude-vscode` and a clean environment. That one variable splits the lineage is verified and reproduced three times. That it is the *only* such variable is not — it is the one that showed up, not the result of an exhaustive sweep. Treat the probe as the authority, not this file: it measures the thing directly, and it will keep being right after an upgrade changes something this paragraph never knew about.

**`MISS` does not distinguish a diverged lineage from a lapsed one.** Both produce a collapsed read and a large write, and the detector cannot tell them apart. A machine that slept through several intervals and let the cache expire will trip the same abort as a genuine lineage switch. The abort is still the right response — in both cases the session stopped being protected — but do not read the log line as proof that something changed about the prompt prefix. Check whether the machine was awake first; the power pre-flight at registration is there to make that the less likely explanation.

`cache_miss_reason` does not close that gap. **Which value a TTL lapse reports has not been measured** — no lapse with a known cause appears in the transcripts the classifier was built from — so a lapse may well arrive as an unrecognised or absent reason and unregister, which is the behaviour wanted anyway. Do not infer from a `MISS` line that the reason field ruled a lapse out.

**The rule the `RESET` branch rests on is verified live; the branch firing on a real miss is not.** Keep the two apart.

The rule — that `system_changed` and `tools_changed` re-warm the prefix they invalidated — comes from 217 transcripts and 25,675 assistant records swept on 2026-08-08: of 23 `system_changed` and 63 `tools_changed` misses, every one whose session made a following request had that request served from cache, with no genuine counterexample. A live instance then landed the same day, unplanned, on a throwaway session: a ping took `read=16101 write=22931` with `cache_miss_reason: system_changed`, and the next ping read **39,032** for a 22-token write and $0.02. Recovery after a real miss is measured, not inferred.

What has *not* been watched is the branch itself taking that decision unattended — the live miss happened outside the script, and the script's own next run was an ordinary `OK`. The branch is exercised by a harness that fabricates a transcript record per reason, because a real `system_changed` cannot be summoned on demand.

## Commands

| Command | Does |
|---|---|
| `/keepwarm-start` | Probe, gate, and register in one step. The normal entry point. |
| `/keepwarm-check` | Probe alone, registering nothing — for diagnosing a session. |
| `/keepwarm-status` | Schedule state, ping history, cache high-water, accumulated cost. |
| `/keepwarm-stop` | Unregister — before resuming the session interactively. |

Scripts live in `scripts/` beside this file and are usable directly; each carries comment-based help. `Ping-ClaudeSession.ps1` is the worker the task runs and is not normally invoked by hand except through `/keepwarm-check`.
