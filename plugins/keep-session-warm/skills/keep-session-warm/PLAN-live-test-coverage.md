---
status: closed — plugin retired 2026-08-09
audience: historical record; see docs/keep-session-warm-postmortem.md
date: 2026-08-09
---

## Ledger

**CLOSED 2026-08-09. Tasks 1-4 landed and pass; Tasks 5-8 will not be done.**
The live testing this plan commissioned falsified the tool's core premise: a
`claude -p --resume` ping maintains a different prompt-cache entry from the one
an interactive session resumes into, and no configuration joins them. The
plugin was withdrawn from the marketplace rather than finished. The verdict,
the measurements and what was ruled out are in
`docs/keep-session-warm-postmortem.md`, which is written to outlive this
directory. Everything below is the working record that produced it.

Status as of 2026-08-09: Tasks 1-4 done — Tasks 2, 3 and 4 all rescoped around
the falsified premise below, each with its correction recorded. Tasks 5-6 not
started; neither depends on the premise. Task 7 planned for this pass; Task 8
explicitly skipped (65-minute wait, user declined for this session). Spend so
far this session: ~$0.48.

**THE TOOL'S CORE PREMISE IS FALSIFIED. Measured 2026-08-09 against two real
interactive VS Code Haiku 4.5 sessions started for this test, `b6ff4e93` and
`cf9026f0`, both in `c:\Users\Chris\Documents\Projects\claude-skills`.**

A `claude -p --resume` ping cannot warm an interactive session's prefix. It
maintains a *separate* cache entry, and the boundary between them is fixed.

| what ran | read | write | prefix | read frac | cost |
|---|---|---|---|---|---|
| `cf9026f0` own interactive turn | 19,740 | 18,023 | 37,763 | — | — |
| `b6ff4e93` own interactive turn | 19,740 | 17,903 | 37,643 | — | — |
| plain ping → `cf9026f0` | 18,269 | 18,395 | 36,664 | **0.498** | $0.0390 |
| ping with `--ide` → `b6ff4e93` | 18,269 | 18,268 | 36,537 | **0.500** | $0.0387 |
| 2nd consecutive plain ping → `cf9026f0` | 36,664 | 99 | 36,763 | **0.997** | $0.0041 |

Three things this establishes:

1. **A ping rewrites half the prefix of a real interactive session**, every
   time it is the first to run against it. `--ide` made no difference: the read
   was byte-identical at 18,269.
2. **18,269 is a hard constant.** It is the same value on every `claude -p`
   first-resume measured this session — in a bare `$env:TEMP` throwaway with no
   CLAUDE.md, no plugins and no MCP servers, *and* in this project with all
   three. So the shared segment sits upstream of every project-specific thing,
   and no roster alignment can extend it. The roster hypothesis that motivated
   this experiment is dead.
3. **Pings warm each other, not the session.** The second ping read 36,664 —
   exactly what the first ping wrote — at read fraction 0.997. That is the
   healthy-looking `OK` line the keepwarm log has been reporting all along. It
   is real, and it refers to a cache entry the interactive client never reads.

The interactive base (19,740) and the headless base (18,269) are different
lengths, so the two are distinct entries from early on. Best case, a ping
refreshes shared blocks worth ~18K of reads ≈ $0.002 on Haiku, while costing
$0.0041 per warm ping and $0.039 for the first. **The ping costs more than the
benefit it could possibly deliver, and the ratio does not improve on a larger
model — both sides scale together.**

Consequence for Task 8: it is no longer the deciding test. It would measure the
size of a benefit now known to be smaller than its own cost.

Two sessions `b6ff4e93` and `cf9026f0` are the user's and were left in place;
each carries the "Acknowledge and take no action." turns these pings appended.

---

**LOAD-BEARING PREMISE FALSIFIED — read before starting any remaining task.**
The plan assumes a divergence can be forced on a throwaway by probing it with a
mismatched lineage key. It cannot. Measured 2026-08-09 on throwaway
`3ec7a40d-3411-4214-9658-54e2c6538c8b` (Haiku 4.5, 32,435-token prefix), five
`Ping-ClaudeSession.ps1` calls varying both keys:

| probe | CLAUDE_CODE_ENTRYPOINT | --effort | read | write | read fraction |
|---|---|---|---|---|---|
| baseline | `claude-vscode` | medium | 32,495 | 48 | 1.00 |
| entrypoint differs | `keepwarm-live-divergence-probe` | medium | 32,543 | 64 | 1.00 |
| effort differs | `claude-vscode` | high | 32,607 | 53 | 1.00 |
| both differ | `keepwarm-live-divergence-probe` | max | 32,660 | 52 | 1.00 |
| back to baseline | `claude-vscode` | medium | 32,712 | 53 | 1.00 |

Neither key split the lineage. **Positive control, so this is a real null and
not a dead instrument:** the same session's first `--resume` in
`New-ThrowawaySession.ps1` STEP 6 reported read 18,269 / write 14,226 with
`cache_miss_reason=system_changed` — the instrument does register a rewrite when
one happens.

Scope of the claim: this is measured on a session *created* by `claude -p`. It
does not establish that entrypoint is inert on an interactive session, which is
where `SKILL.md`'s 37,950-read-vs-12,424-read measurement was taken. The
plausible mechanism is that `claude -p --resume` renders the headless system
prompt regardless of these variables, so they only move the prefix an
*interactive* client builds. Settling that requires buying a rewrite on a real
interactive session, which Ground rule 3 forbids.

Siblings resting on the same premise, all suspect until re-derived:
- Task 2 case 2 (`forced divergence` → `Diverged`) — **falsified**, observed `Warm`.
- Task 3 case 2 (`Start-ClaudeKeepwarm.ps1` refuses with `LineageProbeFailed`) —
  will not fire; the probe returns `Warm`.
- Task 4 (`MISS` branch unregisters a real task) — needs a different trigger.
  The state file's high-water mark is a candidate that does not require buying a
  rewrite, but the `MISS` branch also consults `cache_miss_reason`, so check
  that path before assuming it works.
- Task 7 (rapid-invocation runbook) uses a different mechanism and may survive.
- `SKILL.md` §3's "single variable measured to split the cache lineage" is now
  known not to hold for headless-created sessions. Reconciliation is a separate
  pass; do not edit `SKILL.md` here.

- **Task 1 (`tests/New-ThrowawaySession.ps1`): DONE 2026-08-09.**
  [verified 2026-08-09: dot-sourced the script, called `New-ThrowawaySession`,
  got SessionId `d49e1194-8d18-4393-8176-5386e9a83210`, Model
  `claude-haiku-4-5`, ModelPinHolds `True`, PrefixTokens 32433, CostUsd
  0.0614; called `Remove-ThrowawaySession` and confirmed both TranscriptPath
  and ProjectDir returned `Test-Path -eq $false` afterward.]
  **Correction to the plan's assumed JSON shape:** `claude -p --output-format
  json` carries no top-level `model` field (CLI 2.1.220) — the model used is
  the sole key of `usage.modelUsage`, whose value's `canonicalModel` names it.
  The script reads it via a `Get-ResultModel` helper; every later task that
  inspects a `claude -p` result for its model must do the same, not read
  `.model`.
  **Four defects corrected 2026-08-09 after the first pass:** (a) the nested
  `Assert-SpendCap` mutated `$script:spent`, which in a dot-sourced file is the
  *calling* script's scope, not the function's — so the cap was checked against
  an accumulator tangled with the caller's own; it is now a pure predicate taking
  `-Spent`/`-Cap`. (b) `--effort medium` was added to the create call on the
  theory it would populate the transcript's `effort` field; it does not (see
  Task 2 entry) and has been removed. (c) `$PSCommandPath` was used to locate
  `scripts/`, which resolves to the *caller's* path once dot-sourced and `$null`
  from an interactive prompt; now captured as `$KeepwarmTestsDir = $PSScriptRoot`
  at dot-source time. (d) the returned object now carries `Effort = 'medium'`,
  the value callers must pass explicitly.
- **Task 2 (`tests/Test-LiveLineageVerdicts.ps1`): DONE 2026-08-09**, with case 2
  rescoped from "forced divergence" to "entrypoint mismatch is inert" per the
  falsified premise above — user decision, this session.
  [verified 2026-08-09: `PASS=6 FAIL=0`, exit 0, on throwaway
  `09e8ab18-3f47-4d8d-832e-cd8859f0d980` (Haiku 4.5, ModelPinHolds True,
  32,435-token prefix). case 1 read 32,524 / write 53 / frac 1.00 `Warm`;
  case 2 read 32,577 / write 68 / frac 1.00 `Warm`; case 3 read 32,645 /
  write 51 / frac 1.00 `Warm`; all three left no state file. Total spend
  $0.0723 against a $1.00 cap. Cleanup confirmed after the run: no
  `keepwarm-live-*` scratch dir, no `*keepwarm*` project dir, no probe log.]
  Case 2's null has now replicated on three independent throwaways
  (`675923f7`, `3ec7a40d`, `09e8ab18`). The assertion was inverted rather than
  deleted so a future CLI that makes entrypoint load-bearing again breaks it.
  **Correction to the plan's prescribed proof:** the plan's expected result for
  this task was a `Diverged` verdict. That cannot be produced by this harness;
  what ran instead is the five-probe two-variable sweep recorded above, whose
  positive control is the `system_changed` rewrite in `New-ThrowawaySession.ps1`
  STEP 6. Any later task prescribing "force a divergence" needs the same
  substitution.
  Also fixed here: the script passes `-Effort` explicitly on every probe, and
  removes the probe log in its `finally` — `Get-ClaudeKeepwarm.ps1` globs
  `claude-keepwarm-*.log`, so a stray probe log makes the user's status report
  list a phantom session `probe-<id>` (two such strays were found on disk from
  the first pass and deleted).
- **Ground rule 7 exception, granted by the user 2026-08-09:** two one-line
  guards in `scripts/`, both the same bug. `Test-ClaudeCacheLineage.ps1:74` and
  `Start-ClaudeKeepwarm.ps1:154` both did `if (-not $Effort) { $Effort =
  $context.Effort }`. PowerShell enforces a `ValidateSet` on every assignment to
  a parameter variable, not only at binding, so a session resolving to a `$null`
  effort throws before any later code runs. Both now read `if (-not $Effort -and
  $context.Effort)`. `Start-ClaudeKeepwarm.ps1:233`'s own comment already named
  this hazard for the probe splat while line 154 performed the failing
  assignment. Everything else in `scripts/` remains untouched.
- **Task 3 (`tests/Test-LiveStartGate.ps1`): DONE 2026-08-09.**
  [verified 2026-08-09: `PASS=18 FAIL=0`, exit 0, on throwaway
  `47f118ac-6655-4dc1-b1b8-f5c1fe0dd555`. Case 1 registered with
  `Verdict=Warm`, `ProbeRead=32504`, state `MaxRead=32504` matching,
  `EstimatedPings=6`; `Stop-ClaudeKeepwarm.ps1 -PassThru` returned
  `Action=Unregistered` and the task was gone. Case 3 threw
  `LineageProbeFailed,Start-ClaudeKeepwarm.ps1` with no task and no state file
  left. Case 4 threw `PromptQuoting,...` and `TranscriptNotFound,...`. Foreign
  `ClaudeKeepwarm-*` set was `(none)` before and `(none)` after. Total spend
  $0.0687.]
  **Correction to the plan's prescribed proof for case 2.** The plan asked for
  a `Diverged` verdict from a mismatched `-Entrypoint`, and for `Start` to
  refuse. Neither happens: the probe returned `Warm` (read 32,551) and `Start`
  **registered the task anyway**. The case now asserts that, because it is the
  actionable finding — the gate does not protect against a wrong entrypoint on
  a `claude -p` session.
  **Substituted proof for the refusal branch.** `Start-ClaudeKeepwarm.ps1:247`
  throws `LineageProbeFailed` on `Diverged` *or* `ProbeFailed`, so case 3
  reaches the same `throw` by the second route: a `claude.cmd` stub emitting
  `@exit /b 1`, prepended to `$env:PATH` for the duration of the case and
  restored in a nested `finally`. Deterministic, and costs no tokens because
  the stub exits before any API call. Use this technique for any later task
  needing a probe failure.
- **Task 4 (`tests/Test-LiveMissAbort.ps1`): DONE 2026-08-09.**
  [verified 2026-08-09: `PASS=9 FAIL=0`, exit 0, on throwaway
  `38117766-710f-4745-955a-1d2b04441ae4`. A real task
  `ClaudeKeepwarm-38117766-...` was registered, then one ping returned
  `Status=MISS` (read 32,725 / write 57), the task was confirmed gone, and the
  log line read: `MISS  read=32725 write=57 cost=$0.0036  lineage diverged:
  read fell 75% below high-water 130712; unregistered
  'ClaudeKeepwarm-38117766-710f-4745-955a-1d2b04441ae4'` — with no `FAILED to
  unregister`. Foreign task set `(none)` before and after. Total spend $0.0698.]
  **Correction to the plan's prescribed proof.** The plan's step 2 said to
  trigger the miss by pinging with the wrong entrypoint. That produces a
  healthy read, not a miss. What ran instead: seed the state file's `MaxRead`
  to 4x the probe read (130,712) and pass `-MinWriteTokens 10`, which satisfies
  both halves of the divergence test at `Ping-ClaudeSession.ps1:285` using a
  healthy ping's own numbers.
  **Scope of what this proves, stated because the substitution narrows it.**
  Everything downstream of the decision is real and previously unobserved: the
  branch is entered, the reason lookup runs against a real transcript,
  `Unregister-ScheduledTask` fires on a real registered task, the task is gone,
  and the log says so. The *detection* is not proven — the numbers entering the
  comparison are healthy ones. The offline suite covers that arithmetic.
  **Real `cache_miss_reason` measured, answering the plan's step 4 with a
  genuine value.** The first `--resume` after a `claude -p` create reliably
  reports `system_changed` with a large write — read 18,269 / write 14,409 on
  this run, and 18,269 read on all five throwaways created this session. This
  is the one real cache miss the harness observes; `New-ThrowawaySession.ps1`
  now surfaces it as `FirstResumeRead`/`FirstResumeWrite`/`FirstResumeReason`
  rather than discarding it. The MISS ping itself had no reason at all, which
  is what routed it past the RESET branch — asserted, to keep the manufactured
  trigger honest about what it manufactured.
- Tasks 5-6: not started.
- Task 7 (manual, rapid-invocation divergence): not started, planned.
- Task 8 (manual, TTL lapse, 65 min wait): **skipped this session** — user
  declined when asked. Mark `not run` in the results file per the plan's own
  allowance.

---

# Live test coverage for keep-session-warm

## Context

The existing suite (`tests/Test-MissClassification.ps1`, `Test-ReasonReplay.ps1`,
`Test-StatusTally.ps1`) is deliberately offline. It proves the wiring against
fabricated inputs, and `tests/README.md` names what it therefore cannot prove:

- the branch has never been observed deciding unattended on a real miss;
- `Test-ClaudeCacheLineage.ps1` has never returned `Diverged` from a real
  measurement — `SKILL.md` §3 says the probe "deliberately does not test the
  mismatching case, because reproducing a divergence on a real session means
  paying for the full-prefix write";
- which `cache_miss_reason` a TTL lapse reports is unmeasured (`SKILL.md` §6);
- `Start-ClaudeKeepwarm.ps1`, `Stop-ClaudeKeepwarm.ps1` and
  `Resolve-ClaudeSessionContext.ps1` have no test at all.

Every one of those is blocked on the same thing: a real API call against a real
session, including one call that is *supposed* to be expensive.

**What makes that affordable is the target, not the driver.** Each of these
tests runs against a throwaway session created for the test, whose prefix is a
`claude -p` system prompt plus one turn — so the full-prefix rewrite being
bought is a rewrite of *that*, not of a 300K-token working session.

Two independent model choices follow from that, and they are worth keeping
apart. **The driver** — which model executes this runbook — governs the cost of
doing the work, and should be Haiku or Sonnet. **The throwaway's own model**
governs the price of every rewrite the tests deliberately buy: the cache
multipliers are model-invariant (write 2× at the 1-hour TTL, read ~0.1×, so
`SKILL.md` §2's 20× ratio holds everywhere), but base input price is not —
$1/MTok on Haiku 4.5 against $3 on Sonnet 5 ($2 under introductory pricing
through 2026-08-31) and $5 on Opus 5. This machine's `claude -p` default is
Sonnet, so the throwaway is pinned to Haiku at creation (Ground rule 4),
subject to the resume check in Task 1 step 6.

The deliverable is six live test scripts plus two manual runbooks, and a
results file recording what they measured. **The implementer does not edit
`SKILL.md`** — findings go into `tests/RESULTS-live-<date>.md` and get
reconciled into the skill in a separate pass.

## Ground rules (read before writing any code)

These are hard constraints. A violation costs real money or breaks the user's
own running keepwarm.

1. **Never target a session the test did not create.** No script may pass
   `-SessionId $env:CLAUDE_CODE_SESSION_ID`, and none may call
   `Stop-ClaudeKeepwarm.ps1 -All`. The only legal session ids are the ones
   `New-ThrowawaySession.ps1` returns in this run.
2. **Snapshot foreign tasks first.** Before any test registers anything, record
   `@(Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue).TaskName`.
   Cleanup may only remove tasks absent from that snapshot. The user may have a
   real keepwarm running.
3. **Spend cap.** Every script takes `-MaxSpendUsd` (default `1.00`), keeps a
   running total from each result's `CostUsd` / `total_cost_usd`, and aborts
   with a clear message the moment the total would exceed it. Report the actual
   total at the end of every run, pass or fail.
4. **Pin the throwaway to Haiku at creation, and never pass `--model` again
   after that.** Model is part of the cache key, and base input price varies by
   model while the cache multipliers do not (write 2× at the 1-hour TTL, read
   ~0.1× — so the 20× rewrite:ping ratio in `SKILL.md` §2 holds on every model,
   but the dollar figure does not). This machine's `~/.claude/settings.json`
   sets `"model": "sonnet"` with no `ANTHROPIC_MODEL` override (verified
   2026-08-09: read the file), so an unpinned throwaway is Sonnet 5 at $3/MTok
   input, or $2 under introductory pricing through 2026-08-31; Haiku 4.5 is
   $1/MTok, making every deliberate rewrite 2–3× cheaper depending on when the
   run happens. `Ping-ClaudeSession.ps1` passes no `--model`,
   so the pin only holds if resume inherits the session's model — Task 1 step 6
   verifies that before anything depends on it. If a `model_changed` reason
   appears at any point after that, it is a finding to record, not a problem to
   work around.
5. **Cleanup in `finally`, always.** Unregister every task the run created,
   delete its state file, keep its log (the log is the evidence), and delete
   the throwaway transcript directory. Assert at the end that no
   `ClaudeKeepwarm-*` task outside the snapshot remains.
6. **Match the existing house style.** Hand-rolled `PASS=n FAIL=n` output, one
   line per case, `exit 1` on any failure — copy the shape of
   `tests/Test-StatusTally.ps1`. **Do not introduce Pester**; nothing in this
   repo uses it. Comment-based help at the top of each script, in the voice of
   the existing ones.
7. **Read only these files.** `scripts/*.ps1` (seven files),
   `tests/Test-MissClassification.ps1`, `tests/Test-StatusTally.ps1`,
   `tests/README.md`, and `SKILL.md`. Do not sweep the wider repo.

## Ordering hazard (this bites if ignored)

`Resolve-ClaudeSessionContext.ps1` prefers the live environment over the
transcript **only when `-SessionId` equals `$env:CLAUDE_CODE_SESSION_ID`**
(step 3, lines 77-80). A throwaway session is never that session, so detection
always takes the transcript path — and a deliberate-divergence ping writes a
turn carrying the *wrong* entrypoint as the newest one.

Therefore: run every matching-lineage case **before** any divergence case on
the same throwaway, and after any divergence case pass `-Entrypoint`
explicitly rather than relying on detection. Task 5 turns this hazard into an
assertion.

---

## Task 1 — `tests/New-ThrowawaySession.ps1`

**Files:** create `plugins/keep-session-warm/skills/keep-session-warm/tests/New-ThrowawaySession.ps1`.

**Interfaces:** every later task consumes the object this returns. Produces
`PSCustomObject` with `SessionId`, `ProjectDir`, `Entrypoint`, `Model`,
`ModelPinHolds`, `PrefixTokens`, `TranscriptPath`, `CostUsd`.

**Steps:**

1. Create a scratch project directory under `$env:TEMP` named
   `keepwarm-live-$PID-<n>`; `New-Item -ItemType Directory -Force`.
2. Set `$env:CLAUDE_CODE_ENTRYPOINT` to a known value for the creating call.
   Use the process's current value if set, else the literal `cli`. Record which.
3. From that directory, run
   `claude -p 'Reply with the single word: ready.' --output-format json --model claude-haiku-4-5`
   and parse stdout. Read `session_id`, `model`,
   `usage.cache_read_input_tokens`, `usage.cache_creation_input_tokens`,
   `total_cost_usd`. Assert the returned `model` starts with
   `claude-haiku-4-5` — if the CLI ignored the flag, everything downstream
   bills at Opus rates and the run should stop here rather than find out later.
4. Compute `PrefixTokens = read + write`. **Assert `PrefixTokens -gt 8192`.**
   Two independent constraints land on the same number here, and both must
   clear: `Ping-ClaudeSession.ps1` requires `write > $MinWriteTokens` (default
   4096) before it will call anything diverged, and **Haiku 4.5's minimum
   cacheable prefix is 4096 tokens** — higher than Sonnet 5's 1024, and a
   consequence of the pin. Below that the prompt silently does not cache at
   all: no error, just `cache_creation_input_tokens: 0` and a suite measuring
   nothing. Do not lower this gate on the strength of one constraint. If the assertion fails, send one more turn to the
   session (`claude -p --resume <id> 'Reply: ok.'`) and re-measure; fail with
   an explicit message if it still does not clear 8192.
5. Resolve the transcript path the same way the scripts do:
   `~/.claude/projects/<ProjectDir with [:\/] replaced by ->/<SessionId>.jsonl`.
   Assert it exists.
6. **Verify the model pin survives a resume — the whole suite rests on this.**
   `Ping-ClaudeSession.ps1` never passes `--model`, so if `--resume` falls back
   to the CLI default (`opus` on this machine) instead of the session's own
   model, every later ping is a `model_changed` miss and no test means anything.
   Run
   `claude -p --resume <SessionId> 'Reply: ok.' --output-format json`
   from the project directory with **no** `--model` flag, and record:
   - the returned `model` — set `ModelPinHolds = $true` only if it still starts
     with `claude-haiku-4-5`;
   - `usage.cache_read_input_tokens` — on a held pin this should be a large
     fraction of the creating call's prefix, not near zero;
   - `Get-CacheMissReason -Read <read> -Write <write> -TranscriptPath <path>`,
     dot-sourcing `scripts/Get-CacheMissReason.ps1` first.

   **If `ModelPinHolds` is `$false`:** print the returned model and the reason
   verbatim, then re-create the throwaway with **no** `--model` flag (Sonnet 5
   on this machine's current default, 2–3× the rewrite cost) and set `Model` to
   what that returns. Do not proceed
   on a session whose resumes silently switch models. Record the outcome either
   way — whether the pin holds is itself an unmeasured fact about the tooling,
   and `Ping-ClaudeSession.ps1` gaining a `-Model` parameter is the obvious
   follow-up if it doesn't.

**Expected result:** an object whose `TranscriptPath` exists on disk, whose
`PrefixTokens` clears 8192, and whose `Model` matches what step 6 measured.
Print it, including `ModelPinHolds`.

**Cleanup helper in the same file:** `Remove-ThrowawaySession -Session <obj>`,
which deletes the transcript directory and the scratch project directory.

---

## Task 2 — `tests/Test-LiveLineageVerdicts.ps1`

Proves `Test-ClaudeCacheLineage.ps1` returns `Warm` on a matching invocation
and `Diverged` on a real mismatch. **This is the script that buys the rewrite
the offline suite refuses to buy.** Cost: roughly one cache read plus one
full-prefix write of the throwaway.

**Files:** create `tests/Test-LiveLineageVerdicts.ps1`.
**Interfaces:** consumes `New-ThrowawaySession.ps1`. Produces nothing later
tasks read.

**Cases, in this exact order:**

| # | Invocation | Pass criterion |
|---|---|---|
| 1 | `Test-ClaudeCacheLineage.ps1 -SessionId $s.SessionId -ProjectDir $s.ProjectDir -Entrypoint $s.Entrypoint` | `Verdict` is `Warm` or `WarmWithBacklog`; `ReadFraction -ge 0.5` |
| 2 | same, but `-Entrypoint 'keepwarm-live-divergence-probe'` | `Verdict -eq 'Diverged'` exactly; `CacheWrite -gt 4096`; `ReadFraction -lt 0.5` |
| 3 | re-run case 1 verbatim | `Verdict` is `Warm` or `WarmWithBacklog` — proves the original lineage survived the excursion and re-warms |

Case 2 is the whole point: it is the first real measurement of the `Diverged`
branch. Print `CacheRead`, `CacheWrite`, `ReadFraction`, `CostUsd` for every
case and copy all three rows into the results file.

Also assert, after every case, that
`$env:TEMP\claude-keepwarm-<SessionId>.state.json` does **not** exist — the
probe passes no `-StatePath` and must not leave a high-water mark a later real
keepwarm would inherit (`Test-ClaudeCacheLineage.ps1` lines 88-90).

---

## Task 3 — `tests/Test-LiveStartGate.ps1`

Proves `Start-ClaudeKeepwarm.ps1` refuses to register when the probe says
`Diverged`, and registers with a seeded high-water mark when it says `Warm`.

**Files:** create `tests/Test-LiveStartGate.ps1`.
**Interfaces:** consumes `New-ThrowawaySession.ps1`; must take the foreign-task
snapshot from Ground rule 2 before case 2.

**Cases:**

1. **Registers on a matching lineage.** Run
   `Start-ClaudeKeepwarm.ps1 -SessionId $s.SessionId -ProjectDir $s.ProjectDir -Entrypoint $s.Entrypoint -IntervalMinutes 1 -DurationHours 0.1`.
   Assert: it returns an object with `Verdict` in `Warm`/`WarmWithBacklog`; a
   task named `ClaudeKeepwarm-<SessionId>` now exists; the state file exists and
   its `MaxRead` equals the returned `ProbeRead`; `EstimatedPings` is 6.
   Then unregister via `Stop-ClaudeKeepwarm.ps1 -SessionId $s.SessionId`.
2. **Refuses on a diverged lineage.** Run the same command with
   `-Entrypoint 'keepwarm-live-divergence-probe'` inside `try`/`catch`.
   Assert: it **threw**; the error record's `FullyQualifiedErrorId` contains
   `LineageProbeFailed`; **no** `ClaudeKeepwarm-<SessionId>` task exists; **no**
   state file exists. A silent success here is the failure this whole plan
   exists to catch.
3. **Argument gates cost nothing — assert they still fire.**
   `-Prompt 'say "hi"'` throws `PromptQuoting`; a random unused GUID as
   `-SessionId` throws `TranscriptNotFound`. Neither should reach the API.

Run case 1 before case 2 (see the ordering hazard above). In `finally`,
unregister `ClaudeKeepwarm-<SessionId>` if present and delete its state file.

---

## Task 4 — `tests/Test-LiveMissAbort.ps1`

Proves the thing `tests/README.md` says has never been observed: the miss
branch, deciding unattended, on a real miss, taking down a real scheduled task.

**Files:** create `tests/Test-LiveMissAbort.ps1`.
**Interfaces:** consumes `New-ThrowawaySession.ps1`.

**Steps:**

1. Register a real task on the matching lineage:
   `Start-ClaudeKeepwarm.ps1 -SessionId $s.SessionId -ProjectDir $s.ProjectDir -Entrypoint $s.Entrypoint -IntervalMinutes 1 -DurationHours 0.1`.
   Capture `LogPath`, `StatePath`, `TaskName`. Assert the task exists.
2. Send one ping **by hand** with the wrong entrypoint and the real task name —
   this is the unattended decision, driven deliberately:
   `Ping-ClaudeSession.ps1 -SessionId $s.SessionId -ProjectDir $s.ProjectDir -LogPath <LogPath> -StatePath <StatePath> -TaskName <TaskName> -Entrypoint 'keepwarm-live-divergence-probe'`.
3. Assert, in order:
   - the returned `Status` is `MISS` (if it is `RESET`, the run hit a real
     `system_changed`/`tools_changed` — record that as a finding and re-run once);
   - the task `ClaudeKeepwarm-<SessionId>` **no longer exists**;
   - the last log line matches `MISS` and contains `unregistered '<TaskName>'`;
   - the last log line does **not** contain `FAILED to unregister`.
4. Record the `cache_miss_reason` the run actually saw by calling
   `Get-CacheMissReason -Read <CacheRead> -Write <CacheWrite> -TranscriptPath $s.TranscriptPath`
   after the ping, and write it into the results file. An entrypoint-induced
   divergence has no recorded reason value in the corpus the classifier was
   built from — whatever it returns here is new information either way.

---

## Task 5 — `tests/Test-LiveContextResolution.ps1`

Proves `Resolve-ClaudeSessionContext.ps1` against a real transcript, including
the stray-turn hazard.

**Files:** create `tests/Test-LiveContextResolution.ps1`.
**Interfaces:** consumes `New-ThrowawaySession.ps1`. Costs one ping (case 3).

**Cases:**

1. **Detection on a clean throwaway.** `Resolve-ClaudeSessionContext -SessionId $s.SessionId -ProjectDir $s.ProjectDir`
   returns `Entrypoint -eq $s.Entrypoint`, `EntrypointSource -eq 'Transcript'`,
   a non-empty `Effort`, and `TranscriptPath` equal to the real file.
2. **Wrong `-ProjectDir` names the right one.** Call it with
   `-ProjectDir $env:TEMP` and assert it throws, and that the message contains
   `-ProjectDir is probably wrong`.
3. **A stray ping poisons transcript detection.** Send one ping with
   `-Entrypoint 'keepwarm-live-divergence-probe'` (no `-TaskName`, no
   `-StatePath`), then call `Resolve-ClaudeSessionContext` again with no
   overrides. Assert it now returns the stray entrypoint.
   **This case asserts current behaviour, not desired behaviour.** The
   environment-beats-transcript guard at lines 77-80 only covers the case where
   the caller is inside the session being resolved. Record it in the results
   file as a documented sharp edge, with the note that the mitigation is to
   pass `-Entrypoint` explicitly whenever a session may have been probed.
4. **Unknown session.** A random GUID under a real directory throws with
   `No transcript with that id exists under any project directory.`

Case 3 must run last — it changes what the transcript says.

---

## Task 6 — `tests/Test-LiveScheduledCycle.ps1`

Proves Task Scheduler actually fires the ping the way `Start-ClaudeKeepwarm.ps1`
registers it — the command line, the working directory, the pinned environment.
Nothing offline can test this, and it is where a quoting error would hide.

**Files:** create `tests/Test-LiveScheduledCycle.ps1`.
**Interfaces:** consumes `New-ThrowawaySession.ps1`.

**Steps:**

1. Register with `-IntervalMinutes 1 -DurationHours 0.1 -Entrypoint $s.Entrypoint`.
   Record the state file's seeded `MaxRead`.
2. Fire it immediately rather than waiting: `Start-ScheduledTask -TaskName <TaskName>`.
3. Poll for up to 120 seconds for the log to gain a line beyond what
   registration left (`Get-Content -LiteralPath <LogPath>` count). Sleep 5s
   between polls. Fail with the log contents if nothing appears — a task that
   fires and writes nothing is the 3am silent failure this test exists for.
4. Assert on the new line: it is tagged `OK` (not `BASE`, which would mean the
   probe's seeded state file was not found, and not `ERROR`); the state file's
   `MaxRead` is `-ge` the seeded value; `PingCount` incremented.
5. `Get-ClaudeKeepwarm.ps1 -SessionId $s.SessionId` reports
   `TaskRegistered -eq $true`, `Status -eq 'OK'`, `OkPings -ge 1`,
   `TotalCostUsd -gt 0`.
6. `Stop-ClaudeKeepwarm.ps1 -SessionId $s.SessionId -PassThru` returns
   `Action -eq 'Unregistered'`; the task is gone; the state file is gone; **the
   log still exists** (`Stop-ClaudeKeepwarm.ps1` lines 86-88 keep it on purpose).
7. Call `Stop-ClaudeKeepwarm.ps1 -SessionId $s.SessionId -PassThru` a second
   time; assert `Action -eq 'NotFound'` and that it does not throw.

If step 3 times out, capture `Get-ScheduledTaskInfo -TaskName <TaskName>` and
its `LastTaskResult` into the failure output — that number is the diagnosis.

---

## Task 7 (manual runbook) — rapid-invocation divergence

Closes the open questions in `NOTES-rapid-invocation-divergence.md`, which asks
whether back-to-back probing produces self-inflicted `Diverged` verdicts.

Not scripted, because the observation was about cadence and interleaving. Write
it as a numbered runbook section in the results file and execute it by hand:

1. On one throwaway, run `Test-ClaudeCacheLineage.ps1` with matching keys five
   times back to back with no pause. Record all five verdicts and
   `ReadFraction` values.
2. Repeat, but interleave a `claude -p --resume <id> 'Reply: ok.'` turn between
   each probe. Record the same five.
3. Repeat with a 90-second pause between probes.

Report whether any run produced `Diverged` with matching keys, and at what
`ReadFraction`. The NOTES file's specific question — whether such a verdict is
"correct but unhelpful" or a false negative — is answered by whether
`CacheWrite` on those probes is large (real rewrite) or small (a read fraction
depressed only by accumulated turns).

---

## Task 8 (manual, optional, 65 minutes wall clock) — TTL lapse reason

`SKILL.md` §6 states plainly that which `cache_miss_reason` a TTL lapse reports
has not been measured. This measures it.

1. Create a throwaway; record `SessionId`, `PrefixTokens`, and the timestamp.
2. Touch nothing on that session for **65 minutes**. No probes, no pings, no
   resumes. Do not register a keepwarm on it.
3. Send one ping with matching keys and a `-StatePath` pre-seeded with
   `MaxRead` = the creating call's read+write.
4. Record `Status`, `CacheRead`, `CacheWrite`, and the value
   `Get-CacheMissReason -Read <read> -Write <write> -TranscriptPath <path>`
   returns.

Whatever it returns, write it down verbatim, including `$null`. If it returns
`system_changed` or `tools_changed`, that is significant: it would mean a TTL
lapse can buy a `RESET` reprieve the classifier intends only for a rewritten
prefix, and it belongs in the results file flagged for follow-up.

Mark this task skipped rather than guessed if the wall clock is not available.

---

## Verification

Run in this order; each must print `PASS=n FAIL=0` and exit 0.

```powershell
$t = 'plugins/keep-session-warm/skills/keep-session-warm/tests'
& "$t/Test-MissClassification.ps1"     # regression: offline suite still green
& "$t/Test-StatusTally.ps1"
& "$t/Test-ReasonReplay.ps1"
& "$t/Test-LiveContextResolution.ps1"  # cheapest live script first
& "$t/Test-LiveLineageVerdicts.ps1"
& "$t/Test-LiveStartGate.ps1"
& "$t/Test-LiveMissAbort.ps1"
& "$t/Test-LiveScheduledCycle.ps1"
```

Then, as the run's own proof of Ground rules 2 and 5:

```powershell
Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*' -ErrorAction SilentlyContinue |
    Select-Object TaskName
Get-ChildItem $env:TEMP -Filter 'claude-keepwarm-*' | Select-Object Name
```

The task list must be identical to the snapshot taken at the start. Any
`claude-keepwarm-*.state.json` for a throwaway id is a cleanup failure; the
`.log` files are expected to remain and are the evidence.

## Deliverables

1. Six new scripts under `tests/` (Tasks 1-6).
2. `tests/RESULTS-live-<YYYY-MM-DD>.md` — one section per task, containing the
   **actual numbers measured**, not restated expectations: every `CacheRead`,
   `CacheWrite`, `ReadFraction`, `CostUsd`, `cache_miss_reason`, and the total
   spend for the run. State at the top **which model each throwaway ran on** and
   whether `ModelPinHolds` was true — every dollar figure in the file is
   meaningless without it, and the existing figures in `SKILL.md` §4
   (`write=58782 cost=$0.3909`, implying a base rate near $3.3/MTok rather than
   Opus 5's $5) appear to have been measured on a different model than this run
   will use. Mark Task 8 `not run` if it was not run.
3. A new row per script in the table in `tests/README.md`, in the existing
   format, with an honest `API cost` column. Add a sentence to that file's
   "What none of them prove" section retracting only what these tests actually
   established — if Task 4 passed, "the branch has never been observed deciding
   unattended on a real miss" is no longer true and the paragraph must say so.
4. **No edits to `SKILL.md`.** List, at the end of the results file, the
   specific `SKILL.md` claims the run confirmed, contradicted, or newly
   measured, so a later pass can reconcile them.

## Self-review before reporting done

- Does every script clean up in `finally`, including on a thrown error?
- Does any script reference a session id it did not create?
- Does the results file contain a number that was not printed by a command in
  this run? Every figure must be traceable to output.
- Did anything get reported as passing that was skipped for time or cost?
  Say so explicitly instead.

## Out of scope

- Offline unit tests for `Stop-ClaudeKeepwarm.ps1` via cmdlet shadowing — the
  live path in Task 6 covers it for real.
- `tests/Test-FlushRace.ps1`, which already exists and already spends money.
- Editing `SKILL.md`, `NOTES-rapid-invocation-divergence.md`, or the command
  markdown under `commands/`.
