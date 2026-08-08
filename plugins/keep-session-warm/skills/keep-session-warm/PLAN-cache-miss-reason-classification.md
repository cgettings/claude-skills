---
status: in progress
date: 2026-08-08
---

# Classify a ping MISS by `cache_miss_reason` instead of unregistering on all of them

**Status as of 2026-08-08: steps 1–8 done, uncommitted. Nothing left but the review targets below, then commit.**

The proofs below are re-runnable from `tests/` — see `tests/README.md` for what
each does and does not establish. Three cost nothing:

```powershell
& .\tests\Test-MissClassification.ps1   # PASS=14 FAIL=0
& .\tests\Test-ReasonReplay.ps1         # PASS=49 FAIL=0
& .\tests\Test-StatusTally.ps1          # PASS=6  FAIL=0
```

## Why

A keepwarm registered on session `2f3996cb-7992-4b20-95e4-b635f3b64399` took a
total cache miss on its first scheduled ping (2026-08-08 04:48 UTC,
`read=0 write=58782`), unregistered itself per `Ping-ClaudeSession.ps1` STEP 8b,
and left ~7 hours unheld; the 11:28 resume then paid `read=27594 write=33754`.

The miss was not a diverged lineage. The API said why in a field the scripts
never read:

```json
"diagnostics":{"cache_miss_reason":{"type":"system_changed","cache_missed_input_tokens":57416}}
```

The only thing that changed was the deferred-tool roster — `TodoWrite` dropped,
`TaskCreate`/`TaskGet`/`TaskList`/`TaskUpdate` added — a server-side gate flip
with CLI version, model, effort and cwd all constant across the boundary. That
listing is rendered as text into the system prompt, which is why the reason is
`system_changed` and not the separate `tools_changed` the API also emits.

Such a miss **re-warms the new prefix**, so continuing is correct and
unregistering is not.

## Evidence behind the design

All from a sweep of 217 transcripts / 25,675 assistant records under
`~/.claude/projects` [verified 2026-08-08: `node` sweep, script kept at
`scratchpad/an2.js`, `an3.js`].

- `cache_miss_reason.type` values and counts: `previous_message_not_found` 153,
  `unavailable` 131, `tools_changed` 129, `system_changed` 52,
  `messages_changed` 24, `model_changed` 2.
- **`system_changed` self-heals**: 20 recovered (next request's read ≥ 0.8× this
  request's write), 2 had no following request, 1 apparent non-recovery which is
  a second independent `tools_changed` invalidation 2.3 min later. Zero genuine
  counterexamples.
- **`tools_changed` self-heals**: 56 recovered, 6 apparent non-recoveries, all
  six sub-millisecond duplicate records in two sessions. Zero genuine
  counterexamples.
- **`unavailable` is not a miss signal**: median read-drop 0%, minimum −89% (the
  read grew). Must never trigger anything.
- **The field is absent on a genuine total miss.** A fresh session measured
  `read=0 write=39062` with no `diagnostics` object at all. So absence ≠ healthy,
  and the reason can only *classify* a miss the existing heuristic already caught
  — it cannot replace the heuristic as the detector.

## Constraints discovered

- `claude -p --output-format json` does **not** expose `diagnostics`. Its
  `usage` keys are `cache_creation, cache_creation_input_tokens,
  cache_read_input_tokens, inference_geo, input_tokens, iterations,
  output_tokens, server_tool_use, service_tier, speed`. The reason must be read
  from the transcript.
- The result's `uuid` matches **no** transcript record (result `5fd06fea…`,
  assistant record `a9651dba…`), so the lookup is "last assistant record", not a
  keyed join.
- `Resolve-ClaudeSessionContext` (in `Resolve-ClaudeSessionContext.ps1`) already
  returns `TranscriptPath` and already tails the file — reuse it rather than
  duplicating the `~/.claude/projects/<mangled-cwd>/` path mangling.
- Log tags are a 5-char field (`OK   `, `BASE `, `MISS `, `ERROR`). The new tag
  is `RESET`, which fits and — checked — does not collide with
  `Get-ClaudeKeepwarm.ps1`'s `'\sMISS\s'` counter.

## Steps

### 1. Investigate and fix the design — **DONE 2026-08-08**

Proof: the sweep above. Note the two corrections it forced: the mechanism is the
system-prompt text, not the tools array; and `cache_miss_reason` classifies
rather than detects, because it is absent on real misses.

### 2. Add reason lookup — **DONE 2026-08-08**

**Files:** new `scripts/Get-CacheMissReason.ps1`; `Ping-ClaudeSession.ps1`
dot-sources it just after `New-PingResult`.

Given its own file rather than living inline in the ping script, following the
`Resolve-ClaudeSessionContext.ps1` pattern — an inline helper cannot be
dot-sourced for the replay below without executing a ping.

**Interfaces:** produces `Get-CacheMissReason -Read -Write [-TranscriptPath |
-SessionId -ProjectDir] [-TimeoutMs] [-TailLines]` → reason string or `$null`;
consumed by step 3.

Records are located by matching the ping's own read/write, not by taking the
newest assistant record — during the flush window that would return the
*previous* turn's reason. The result JSON's `uuid` cannot be used for this: it
matches no transcript record.

**Proof** [verified 2026-08-08]: replay of 56 cases drawn from real transcripts
— 10 each of `unavailable`, `system_changed`, `previous_message_not_found`,
`tools_changed`, 3 `messages_changed`, 1 `model_changed`, and 12 records
carrying no reason — **PASS=56 FAIL=0**. Harness at `scratchpad/mkcases.js` plus
a dot-source loop.

Corrected from the plan as written: the replay was going to be circular on the
selection rule, since expected values used the same "last matching read/write"
rule the function does. Re-deriving settled it instead — **0 read/write keys
corpus-wide map to records with conflicting reasons**, so the rule is
unambiguous on real data and the circularity does not arise.

### 3. Branch the STEP 8b MISS path — **DONE 2026-08-08**

**Files:** `scripts/Ping-ClaudeSession.ps1` STEP 8b.

Keep the `$diverged` heuristic unchanged as the trigger. On a detected miss:

| reason | action |
|---|---|
| `system_changed`, `tools_changed` | log `RESET`, do **not** unregister, re-baseline `MaxRead` to this ping's **write**, continue |
| `previous_message_not_found`, `messages_changed`, `model_changed` | unregister (today's behaviour) |
| absent, `unavailable`, unrecognized | unregister (today's behaviour) |

Failure-closed: every unproven path keeps current behaviour.

The re-baseline to `write` rather than `read` is the load-bearing bit — after a
prefix rewrite the *new* prefix is what later pings will read, so leaving the
old high-water in place would make the next healthy ping look diverged.

**Proof** [verified 2026-08-08]: `scratchpad/Test-Branch.ps1` runs the real ping
script end to end against a shim `claude` on PATH returning canned JSON, plus a
fabricated transcript record per reason — no API call. **PASS=8 FAIL=0** across
all six reason values, an absent reason, and a healthy read, asserting both the
Status returned and the resulting `MaxRead` (re-baselined to the write on RESET,
untouched on MISS).

Still not proven: the branch taking that decision unattended on a real miss. A
live `system_changed` did occur during step 6, but outside the script.

### 4. Teach `Get-ClaudeKeepwarm.ps1` the new tag — **DONE 2026-08-08**

**Files:** `scripts/Get-ClaudeKeepwarm.ps1` — `.DESCRIPTION`, the tally, the
`$status` ladder, and the output object.

Adds `ResetPings`, and a `Status` of `OK (with resets)` — below `OK (with
errors)` in the ladder, above plain `OK`. A reset night is a working night.

**Proof** [verified 2026-08-08]: synthetic log with BASE/OK/RESET/OK lines →
`Status='OK (with resets)'`, `ResetPings=1`, `MissPings=0`, `OkPings=2`,
`TotalCostUsd=0.45`. Confirms the new tag does not leak into the `'\sMISS\s'`
counter.

### 5. Update `SKILL.md` MISS semantics — **DONE 2026-08-08**

**Files:** `SKILL.md` §4 (the log/MISS section) and §6 (what is not established).

§6 gained two caveats worth keeping: which reason a **TTL lapse** reports is
unmeasured, so `cache_miss_reason` does not close the diverged-vs-lapsed gap
§6 already documents; and the rule-vs-branch distinction from step 3.

**Proof:** re-read against the implemented branch table. No command.

### 6. Live end-to-end ping — **DONE 2026-08-08**

Run against throwaway session `8e0e6024-7833-4af9-952d-f6a467b3e1b3` in the
scratchpad project dir. It runs `claude-vscode` / `medium`, and the ping must
pin **both** or it lands on another lineage.

**Proof** [verified 2026-08-08, `scratchpad/Test-FlushRace.ps1`]: after
`claude -p --resume` returned, the ping's own assistant record was readable in
the transcript after **44 ms**, against the 500 ms default — an order of
magnitude of headroom. Wall time from process exit to match, 70 ms.

**Unplanned and more valuable than the step:** that same ping took a real
`system_changed` miss — `read=16101 write=22931`, `$0.2376` — with no roster
delta recorded, same entrypoint, effort and directory. The following ping, run
through `Ping-ClaudeSession.ps1` itself, read **39,032** for a 22-token write at
`$0.02` and logged `OK`. The recovery claim the whole `RESET` branch rests on is
therefore measured on a live miss, not only inferred from the corpus sweep.

That instance also falsified a claim drafted into `SKILL.md`, that a roster flip
is the usual trigger. Three `system_changed` events are now on record; two had a
roster delta and one did not. The text was corrected to say the roster is one
cause, not the cause.

**Cost:** measured $0.020 per warm ping versus $0.391 to create a session, so
the throwaway was reused throughout. The one $0.2376 ping was the live miss,
which was not something to avoid — it was the evidence.

### 7. Move the proofs into the repo — **DONE 2026-08-08**

**Files:** new `tests/` beside `scripts/` — `Test-MissClassification.ps1`,
`Test-ReasonReplay.ps1`, `Test-StatusTally.ps1`, `Test-FlushRace.ps1`,
`README.md`.

The proofs for steps 2–4 originally ran from a scratchpad, and one of them
needed `node`. A reviewer could read the numbers but not reproduce them, which
is the same defect as an unsourced claim. Ported to pure PowerShell, dependent
only on `$PSScriptRoot/../scripts`.

**Proof** [verified 2026-08-08, run from `tests/`]: `Test-MissClassification`
PASS=8 FAIL=0; `Test-ReasonReplay` PASS=49 FAIL=0 over 60 transcripts;
`Test-StatusTally` PASS=6 FAIL=0.

Two things the port changed, both worth knowing:

- The replay now re-derives the ambiguity check in PowerShell rather than
  inheriting it from the `node` sweep — **0 conflicting `(read, write)` keys**,
  independently reconfirmed.
- Its coverage is drawn from whatever is on the machine, and the 60-transcript
  sample yielded **no `model_changed` case** (only 2 exist corpus-wide). The
  script prints coverage per reason so the gap is visible rather than hidden
  inside a green total; `model_changed` is covered by the fabricated-record test
  instead.

### 8. Cap the reset budget at 3 — **DONE 2026-08-08**

**Files:** `scripts/Ping-ClaudeSession.ps1` (`-MaxResets`, the RESET branch, and
the two other state writes); `scripts/Get-ClaudeKeepwarm.ps1`
(`ResetBudgetUsed`); `SKILL.md` §4; `tests/Test-MissClassification.ps1`.

Step 3 as built converted a bounded failure into an unbounded one. Before it, a
miss unregistered and the loss was capped at the rest of the night. After it,
`RESET` continued with no limit on how many full-prefix rewrites it would buy —
$0.39 on a 59K-token session, ~$3.64 for the recorded 363,713-token rewrite on a
large one — and logged each as a healthy night.

The budget is a **lifetime total, not a consecutive streak**, so `ResetCount`
has to be carried through the `BASE` and `OK` state writes as well; an `OK` ping
that dropped the field would silently refill the budget. That is the bug this
step is most likely to regress into, and the sequence test exists for it.

Over budget, the log says `reset budget exhausted`, not `lineage diverged` —
nothing diverged, and the wrong wording sends the next reader hunting.

**Proof** [verified 2026-08-08]: `tests/Test-MissClassification.ps1` **PASS=14
FAIL=0**, its second half a five-ping sequence against one carried state file —
RESET, RESET, healthy OK, RESET, then MISS on the fourth rewrite — asserting
`ResetCount` after each and that the stopping line explains itself. The healthy
ping sits third specifically to catch the streak-vs-total error.

## Review targets

Ranked on one axis: **which review catches errors the tests structurally
cannot.** Rank re-derived after step 8, which closed what had been the top item.

1. **Claims audit** — cold session, cheapest tier. Does the recorded evidence
   support each assertion in the code comments, `SKILL.md` §6, and this file?
   Two claims in this work were false while the tests were green (the
   `tools_changed` mechanism; "read the reason and branch on it"), so this is
   the failure mode with a track record here. Specific targets:
   - §6 calls recovery "measured on a live miss". That is **n=1**, plus 86
     retrospective cases. Does the sentence carry more weight than the evidence?
   - The corpus recovery rule uses a threshold nobody has audited:
     `next.read >= 0.8 * this.write`.
   - Three `system_changed` events are on record, one with no roster delta and
     no known cause. §4 hedges; check that it hedges enough.
2. **The `MaxResets = 3` default.** Chosen as a judgement call, not measured —
   no data exists on how often a prefix flaps within one night. Worth a second
   opinion on the number, and on whether a total is the right shape versus a
   spend cap in dollars.
3. **Skip a line-by-line correctness review of the diff.** ~110 lines under 69
   assertions with all six reason values exercised. That rung is climbed.

Hand a reviewer the diff, this file, `SKILL.md` §4 and §6, and `tests/`. Do not
hand over the session that produced it — the artifacts are self-contained by
design, and the narrative anchors a reviewer to the reasoning being checked.

## Not in scope

`NOTES-rapid-invocation-divergence.md` in this directory is a separate finding.
This work does answer one of its open questions — the probe's injected turn is a
real turn, appending `user` and `assistant` JSONL records to the same transcript
— but reconciling that file is not part of this change.
