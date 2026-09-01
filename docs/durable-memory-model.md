# A durable memory model that stops the always-loaded tier growing

**Decision, 2026-09-01: stop measuring, start routing.** The efficacy question Task 3 step 5 was
built to answer is **closed without a verdict, by decision rather than by result.** Three runs
licensed nothing, and §5 Task 8's arithmetic had already shown the trim they were testing cannot
reach §3c's ceiling on its own. A further reason arrived with the decision: `c3e4aa0` audited the
one judge shared by all three runs — on the 18 responses of the three-arm run, complete rather than
sampled — and it **failed its own 90% gate at 14/18 (77.8%), with disagreement arm-correlated**. A
fourth run would have had to rebuild the instrument before it could measure anything. What replaces the judge is use: apply the model, record every rule
that misses, and let the misses answer what the runs could not. The re-sequenced main line is
**Task 10 → 4 → 11 → 7 → 12 → 13**. **Task 10 landed 2026-09-01 (`fe46278`, in the `~/.claude`
repo). Task 4's step 1 ran the same day and closed the task at global scope without moving
anything — 0 of its 11 bullets are file-triggered. **Task 11 ran the same day and unblocked Task 7
with a changed brief: its routing table asks two questions, not one, because §3a's four classes
conflate two axes. Task 7 is next.** Task 14 is promoted from tidy-up to the task the plan now
turns on.

**The ceiling is unreachable by any mechanism in this plan, and that is a 2026-09-01 finding rather
than a failure.** Task 8 closed §3b's trim as insufficient; Task 4 step 1 closed §3a's routing as
empty at global scope. Both routes to 25,000 B are shut. §3c already called those numbers *chosen,
not derived* — Task 14 replaces them with a saturation reading, and it is no longer optional. Tasks 5 and 6 come **off** the main line — no longer gated on
Task 3, but no longer the point either. Task 14 carries the stopping condition that §3c's chosen
ceilings were standing in for.

**What this trades away, written once so nobody re-discovers it as a surprise.** Whether a trimmed
rule fires as reliably as a full one is still unknown; shipping the split would mean finding out in
production. Task 13 is what makes that observable instead of silent, and Task 12 is what keeps it
reversible. Neither is optional if Tasks 5-6 are ever picked up.

**The order is not a preference.** Task 10 precedes everything that moves a file, because
`~/.claude` had no version control until 2026-09-01 and the reconstitution promise has nothing
behind it otherwise. Task 11 precedes Task 7 because Task 7 writes a routing table into a skill,
and an untested table is a table every future pass will file against by feel.

**Status as of 2026-09-01.** Tasks 1 and 2 are done and Task 1's **premise held**: `paths:` is
honoured at user scope, so §4's global routing lane is real rather than assumed. §1's *method* stands,
but its **numbers are a 2026-08-25 baseline, not current** — the live global `CLAUDE.md` has since
grown from 49,553 B to **62,370 B**, and nothing has re-measured its token share. Task 3's split was
**re-cut a third time on 2026-09-01** against a section that had drifted to 14,749 B and still proved
lossless — 22 bullets, 14,749 -> 10,042 B (-31.9%), 19 lesson files — but it is **not applied**.
Step 5 has now run **three times** and none of the three licensed a verdict: a ceiling null on
2026-08-29, a query screen on 2026-09-01 whose survivors were retracted the same day as a
two-repeat artefact, and a three-arm run that voided two of its three queries on its own
replication gate. Pooled post-hoc the arms read A 12/12, B 2/6, C 2/12 — the shape that would
**stop** Tasks 5-6 — but **arm is aliased with run order in every run so far**, so drift is an
unexcluded explanation. **Tasks 5 and 6 are no longer gated** — the decision above closed step 5
rather than resolving it, and the interleaved ~$6.91 run was considered and declined. **Task 8 was
built and validated on 2026-08-29** and its first sweep changes the plan's shape: all nine live
directories are over budget, the largest at 147,391 B always loaded, and the arithmetic shows
**§3c's 25,000 B ceiling is not reachable by §3b's trimming at all** — it would take 10.5
pilot-sized splits. Routing whole rules out is the only route that reaches it, which promotes
**Task 4** from "the one reduction that does not depend on Task 3" to the main event. Task 4 is
unblocked and untouched; Tasks 5-7 are not started. **Task 9 was added, designed, revised and
completed on 2026-08-28.** It asked whether an instruction-file edit reaches a session that is
already running, and the answer is **replay on ordinary turns, rebuild at compaction** — the
replay/re-read binary it was framed around is false. Steps 2 and 3 are **retired rather than
skipped**: a write costs a concurrent session nothing at any injection point, so the proxy has
nothing to measure. What survives is a correctness hazard: a session that has not compacted since a
write holds superseded content and cannot tell, which makes **Task 7's protocol read-before-write or
a lock**, and unblocks that task.

## 0. Ledger

| # | Task | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 1 | Falsify the user-scope `paths:` premise | `0f82133` — no code commit; the result **is** §5 Task 1 below | **DONE 2026-08-25** | `InstructionsLoaded` hook log + model self-report, 2 sessions, 4 arms, 5 controls, all passed. Verbatim log line in §5 Task 1 |
| 2 | Record the real baseline | `0f82133` — no code commit; the result **is** §1 below | **DONE 2026-08-25** | differential token measurement, 11 `claude -p` runs, each arm controlled by the same hook log. Method, and the two arms it voided, in §1 |
| 3 | Pilot the recognition/evidence split on one section | `c9b7204` write-up, `9dd9eb8` instruments, `e7ddc91` + `08239e7` re-cuts, and the **2026-09-01 re-cut** — no hash cited, because this row moved in it; find it with `git log --follow docs/task-3-section-before.md`, end state 22 bullets, 14,749 -> 10,042 B, 19 lesson files | **Steps 1-4 DONE (re-cut 2026-09-01). Step 5 CLOSED WITHOUT A VERDICT, 2026-09-01, by decision — not by result.** Three runs, none licensing an answer; **no fourth run will be commissioned**, so the run-order confound is now a permanent limitation of this record rather than a defect to fix. The split is still NOT applied, and Tasks 5-6 are **no longer gated on it**. A session reading this row should not re-run the judge | Steps 1-4: split built and proved lossless, most recently by the **2026-09-01 re-cut**: 22 bullets, **14,749 -> 10,042 B (-31.9%)**, all 19 relocated originals verbatim in `~/.claude/lessons/`, 3 no-evidence bullets byte-identical. Verifier itself validated by 6-arm fault injection, check 4 re-injected on 2026-08-28, and checks 2 and 4 re-injected on 2026-09-01 against the re-indexed bullet list. Guard fired twice, passed clean on 2026-08-29, and **fired a third time on 2026-09-01**. Step 5, three runs, all `RESTORED OK` (sha verified), 0 unresolved judge holes: **2026-08-29** 30 responses, 30/30 on all three arms including the deleted one, `A≈B≈C`, licenses nothing; **2026-09-01 screen** 22 responses, 3 of 8 candidates looked discriminating and were **retracted the same day** (a 0/2 screen fires 56% against a true rate of 0.25); **2026-09-01 three-arm** 18 responses, **2 of 3 queries VOID** on the replication gate, third's B cell 1/2. Pooled post-hoc A 12/12, B 2/6, C 2/12, A-vs-B `p = 0.0049` — but **arm is aliased with run order in all three**, and the judge behind every one of these numbers **failed its own audit** (`c3e4aa0`): a complete Opus re-judge of the three-arm run returns 14/18 (77.8%), 0 holes, below the 90% gate, with disagreement arm-correlated (A 6/6, B 4/6, C 4/6). Full results and the decision in the step-5 note in §5 Task 3 |
| 4 | Route the file-triggered content | — | **STEP 1 DONE 2026-09-01; STEP 2 NOT DONE AND SHOULD NOT BE.** The classification came back **0 of 11 bullets file-triggered**, so there is nothing to move at global scope and moving anyway would make the rules fire less often. **Closed at global scope**; the same classification is now Task 6's first step against the project file | Labelled sweep over all 11 bullets of §Language & platform conventions (9,414 B), each classified by naming the glob open at its moment of need. 0 move; 2 hold a file-triggered half worth ~600 B that only exists after an edit. Swept the other 129 lines for file-triggered content the section-level table missed: 5 extension mentions, all citations inside momentary rules, each read individually; control returns 11 hits inside the target section. Table and consequences in §5 Task 4, "Step 1 result" |
| 5 | Roll the split across the rest of global CLAUDE.md | — | **Ungated 2026-09-01, and off the main line.** Optional; §5 Task 5 states the only basis on which it gets picked up | — |
| 6 | Same for the project CLAUDE.md | — | **Ungated 2026-09-01, deliberately sequenced last.** Needs the team's agreement, and wants a working global example to show them first | — |
| 7 | Make the routing rule enforceable at write time | — | **Gated on Task 11** — its routing table must survive the boundary test before it is written into a skill. Task 9 already settled its write protocol: **read-before-write or a lock**, for correctness | — |
| 8 | Make the ceiling check mechanical | see the commit that adds `scripts/check-memory-budget.sh` | **DONE 2026-08-29** | `scripts/check-memory-budget.sh` + `test-check-memory-budget.sh`, **11-arm fault injection, all pass**, including a negative control that redirects `HOME` so exit 0 is reachable. Injection caught a real bug: the store-name fold missed `.`, so **every worktree read "no project store"** while ten arms passed. First sweep: **all 9 live directories over budget**, worst 147,391 B always loaded. Ceiling shown unreachable by §3b alone — see §5 Task 8 |
| 9 | Does an instruction-file edit reach a running session? | — | **DONE 2026-08-28.** Answer: **replay on ordinary turns, rebuild at compaction** — the pre-registered binary was false. Steps 2-3 retired, not skipped: nothing is left for the proxy to measure | Step 0: `scripts/probe-memory-delivery.py`, 281 transcripts / 182,561 lines, 0 unreadable, **63 `Read` calls on topic files** ⇒ moved X to the project `CLAUDE.md`. Step 1: 2 sessions, 4 asks + `/compact` + arm 3, **0 tool calls** in B (transcript-checked), stale window **~2m55s across 2 turns**. Full timeline in §5 Task 9 |
| 10 | Put `~/.claude` under version control | `fe46278` — **in the `~/.claude` repo, not this one**; `git -C ~/.claude show fe46278` | **DONE 2026-09-01.** Tasks 4, 5 and 12 are unblocked. The root commit is the pre-migration baseline every later revert diffs against | Allowlist `.gitignore`, **30 paths, 57.84 KiB tracked against a 313 M directory** (`git count-objects -vH`). Two-armed proof over `git add -A --dry-run`: excluded pattern (`projects/`, `file-history/`, `plugins/`, `debug/`, `shell-snapshots/`, `plans/`, `*.exe`, `.credentials.json`) returns **0**; the positive control (`CLAUDE.md`, `lessons/`, `settings.json`) returns **21**, so an empty dry-run cannot pass as a clean one. All 30 staged files scanned for private-key headers, token prefixes and password assignments: clean. No CR bytes on any tracked file |
| 11 | Test the routing rule's boundaries before rolling it out | — | **DONE 2026-09-01. Task 7 is unblocked, with a changed brief:** its routing table must ask **two** questions, not one. Rule axis needs no fix (degenerate, not ambiguous); evidence axis needed a rule and now has one | Mechanical sample, 5 of 58 entries outside the pilot section, step 11, file lines 27/77/93/107/146 across five sections. **Rule axis: NO POWER** — 5 of 5 *momentary → stays*, 4 forced; the pre-registered redraw would fail because Task 4 emptied the `paths:` destination and the skills already hold the language content. **Evidence axis: failure criterion tripped 4 of 5** — three global rules cite evidence in two *different* project memory stores and none cites `~/.claude/lessons/`. Fixed by a two-question rule, derived from "only one memory store loads per session". One instrument error caught mid-run: `grep -n` over an `awk`-filtered stream returns filtered-stream line numbers. Full table in §5 Task 11, "Result" |
| 12 | Make the lazy tiers reachable | — | **Not started — blocks applying any split** | — |
| 13 | Close the loop from use | — | **Not started.** This is what replaces step 5 | — |
| 14 | Replace the chosen ceilings with a saturation reading | — | **Not started, and deliberately last** — it needs several `distill-lessons` passes under the new model before it has anything to read | — |

**Live environment state — not in this repo, and it goes with the machine rather than the branch.**
Task 1 registered an `InstructionsLoaded` hook in `~/.claude/settings.json` and **deliberately left
it there**, because Tasks 4 and 5 are proved with it and removing it would only mean rebuilding it.
It appends one JSON line per instruction-file load to `C:/Users/Chris/probe-instructions-loaded.log`,
which grows unbounded and is not rotated.

```sh
tail -3 "C:/Users/Chris/probe-instructions-loaded.log"        # what it logs, newest last

# to remove it: restore the pre-Task-1 settings, then delete the script and the log
cp ~/.claude/settings.json.bak-probe-20260825 ~/.claude/settings.json
rm -f ~/.claude/hooks/instructions-loaded-probe.sh "C:/Users/Chris/probe-instructions-loaded.log"
```

The probe rule and trigger files Task 1 created are **already deleted** — neither `~/.claude/rules/`
nor the repo's `.claude/rules/` exists again, so nothing extra loads into any session. Confirm with
`ls ~/.claude/rules/` (expect "No such file or directory").

**A second piece of live environment state, added 2026-08-25 by Task 3.** `~/.claude/lessons/`
now exists and holds **19 files / 27,534 B** — the evidence moved out of the pilot section, each
containing its original bullet verbatim. Nothing loads them; they are read only when a rule's
`[[pointer]]` is followed. **The split itself is still not applied** — the live section holds the full
text, not the split text, because the firing test that would license applying it has not returned a
usable answer. `~/.claude/CLAUDE.md` is no longer untouched, though: on 2026-09-01 the parked
lessons bullet was applied to it (see below), and the pre-edit file is at
`~/.claude/CLAUDE.md.bak-recut-20260901`. Derive that rather than trusting this line, because the probe below copies each arm over that
file and restores it afterwards: the guard command returns 14,749 while the section is unsplit and
10,042 once it is not. To undo the lessons directory: `rm -rf ~/.claude/lessons/`.

**One thing owed, and it is not a step in this document.** The `keep-ledger` 1.3.1 release that
this work's lessons pass produced is **settled**: `efd2637` merged to `main` as PR #8 on
2026-08-26 `[verified 2026-08-28: git merge-base --is-ancestor efd2637 origin/main, exit 0]`.
Nothing here depends on it and it needs no further action.

Still owed: a `reconcile-records` sweep of this project's memory store and `README.md`,
**deferred until step 5 lands**, because that run moves the same numbers again — one of the four
memory files was spot-checked (`eval-suites-have-no-behavioural-runner`, current) and the other
three were not. The 2026-08-28 re-cut adds to what that sweep must reconcile: §1's byte figures for
the global `CLAUDE.md` (49,553 B, measured) against the file as it now stands (**62,370 B** on
2026-09-01, after the 2026-08-28 lessons pass added 858 B and the parked bullet added 507 B).

**The parked lessons-pass bullet is no longer parked — it was applied on 2026-09-01.** The
2026-08-28 pass produced three entries for the global `CLAUDE.md`; two were applied that day, into
`Choosing and running the check` and `Session workflow`. The third lands in
**`Validating the instrument`, which is the Task 3 pilot section**, so it was held to avoid forcing
a re-cut of its own. That reason expired when the section drifted anyway: the 2026-09-01 re-cut had
to run regardless, so the bullet was applied first and the cut covered it in one pass. It sits
immediately above `In a two-arm comparison, perturb the variable under test` and added **507 B**
(14,242 —> 14,749). Its text, for the record:

> - **A precondition check that reads the same field the measurement reads contaminates it.**
>   Verify the precondition on a different instance than the one you perturb. Confirming a session
>   held a file meant asking it to quote the sentence that would later be deleted — which put that
>   sentence in the session's own history, so "still present" afterwards no longer proved stale
>   context. The added-token half of the nonce stayed clean and carried the result; the deleted
>   half was dead on arrival `[2026-08-28]`.

The general form of what this cost: **a deferral that exists to avoid a re-cut is void the moment
something else forces one.** The hold was correct when written and wrong four days later, and
nothing in the deferral itself would have said so — re-read the reason, not the decision.

**Next command — decide between one more probe run and route (c). Nothing runs until that is
decided.** Three runs now exist and none has produced a licensed verdict:

| run | date | result |
|---|---|---|
| `measure-rule-firing.py` | 2026-08-29 | `A≈B≈C` at the ceiling, 30/30 every arm. Licenses nothing |
| `screen-queries.py` | 2026-09-01 | 3 of 8 candidates looked discriminating. **Retracted the same day** — at 2 repeats a 0/2 screen fires 56% of the time against a true rate of 0.25 |
| `probe-confirmed-queries.py` | 2026-09-01 | 2 of 3 queries VOID on the replication gate; the third's B cell is 1/2. Licenses nothing |

Pooled post-hoc the numbers read **A 12/12, B 2/6, C 2/12** (A-vs-B `p = 0.0049`), which is the
`A > B ≈ C` branch that would **stop Tasks 5-6**. It is not actionable, because **every run so far
loops arm-by-arm, so arm is perfectly aliased with position in the run** and drift produces the
same pattern. Fixing that is the precondition for any further run: interleave the arms in one
randomized job list.

The decision, with prices attached — both are in §5 Task 3's step-5 note in full:

  * **Spend ~$6.91.** A vs B interleaved, 3 queries x 8 repeats, 48 responses. Answers the
    question that gates Tasks 5-6. Arm C's floor is already established at 2/12 pooled.
  * **Route (c), ~$0.** Apply the split on the lossless proof alone and drop §3b's firing claim.
    Task 8's arithmetic says §3b cannot reach the ceiling either way, so this closes a lane that
    was never going to be the main one.

**Do not re-run any of the three scripts unchanged.** None is a flake; each answered what it was
built to ask. **Do not re-run any part of Task 9** —
its steps 2 and 3 are retired on the result, not left undone, and §5 Task 9 says why.

**One thing Task 9 changed about running step 5.** The old advice was to keep other sessions closed
because a re-read would perturb them. Measured, that is not the mechanism: ordinary turns replay, so
another session's turn *during* the run does **not** read an arm. The real hazard is unchanged and
is the other one — a session live across the run holds whichever arm was mounted when it last
compacted, and a hand edit landing mid-run is written onto an arm and lost at the restore. Still run
it with no other sessions live, but for the correctness reason, not the cost one.

**Task 3 step 5** is the gate everything downstream of Task 3 sits
on. It costs money (see the estimate in §5 Task 3, which is stale low — it was computed against a
43,380-token prefix and the global file has grown since) and it mutates the live file. The probe is written and unrun at `scripts/measure-rule-firing.py` (see the step-5 note in §5
Task 3 for what it does, how to read each outcome, and why the originally-named instrument could
not). It refuses to run if the section is not found exactly once in the live file, so the check
below is what it does first anyway:

```sh
awk '/^### Validating the instrument/,/^### Verifying a claim/' ~/.claude/CLAUDE.md | head -n -1 | wc -c
# expect 14749 — if not, the section moved and section-before.md must be re-cut before anything else
```

**This guard has now fired three times.** On 2026-08-25 a
lessons pass appended a sentence to one bullet between the fixtures being cut and step 5 being
reached, and the section read 11,069 B against an expected 10,858 B; the re-cut is `e7ddc91`. On
2026-08-28 it read 11,350 B against 11,069 B, and the +281 B was **two independent drifts, not one**
— which is the part worth carrying forward, because the mechanical one was invisible in the byte
delta. A whole-file normalization had replaced **every em dash with an ASCII hyphen** (48 across the
fixtures; the live file now holds zero U+2014 and kept U+2192, U+2026 and U+00A7, so it was
dash-specific), *shrinking* the section by 54 B, while one bullet gained 335 B of new evidence. Net
+281 B, and a re-cut that touched all 17 bullets and all 14 lesson files rather than one of each,
because check 4 tests the original verbatim and "the original" had changed everywhere.

**The third firing, 2026-09-01, was the cheapest of the three and had a third distinct cause.** The
section read 14,242 B against an expected 11,350 B — **+2,892 B, an order of magnitude past the
+211 and +281 of the first two** — and the whole drift was **5 changed lines: 4 new bullets and 1
amended**, with no mechanical transform to disentangle (the file already held zero U+2014 from the
2026-08-26 normalization). Cause: the `feature-cache-rewrite-sweep` branch's lessons pass, merged
as PR #9. So the byte delta and the work are not proportional — the +281 firing touched all 17
bullets and all 14 lesson files, and this +2,892 one touched 5 bullets and 6 lesson files. Do not
read the guard's number as an estimate of the re-cut.

**The normalization was a hand edit, not a tool** — the repo owner made it on 2026-08-26 while
testing cache rewrites `[stated by them 2026-08-28]`. That is the reassuring answer and the
inconvenient one at once. Nothing is going to re-run it, so no scheduled process has to be found and
stopped; but the file's drift is driven by a person editing it, which no schedule predicts and no
guard can pre-empt. Assume the section has moved every time you approach step 5, and note the two
firings had *different* causes — a lessons pass, then a manual sweep — so do not narrow the guard to
either. Its value is that it is indifferent to the reason.

**Step 5 inherits a sharper version of this.** The probe swaps three arms over the live
`~/.claude/CLAUDE.md` and restores in a `finally`; an edit to that file *while the run is in flight*
lands on an arm rather than on the real file, and the restore then writes back a file the edit never
reached. The run takes long enough for that to be a real window. Agree with the owner not to touch
`~/.claude/CLAUDE.md` for the duration, and read the `RESTORED OK` line rather than assuming it.

The recipe holds either way, and step 1 absorbs a mechanical drift for free: re-cut `before.md`
from the live file, apply the same mechanical transform to `after.md` and `~/.claude/lessons/`,
re-split any genuinely amended bullet, then propagate the new byte counts here and into
`measure-rule-firing.py`'s docstring. Prove the mechanical half did only what it claims — assert the
byte delta equals the substitution count times the per-substitution width — and prove the whole with
`python scripts/verify-split.py`. Expect to do it again.

Then the run itself. **It mutates `~/.claude/CLAUDE.md` in place** — the three arms are copied over
it in turn — and restores from a backup in a `finally`, printing `RESTORED OK` or
`!! RESTORE MISMATCH` before it starts judging. Read that line. If a run dies hard enough to skip
the `finally`, the backup is `.task3-probe/CLAUDE.md.live-backup` and restoring it by hand is the
whole recovery.

```sh
python scripts/measure-rule-firing.py    # 3 arms x 5 queries x 2 repeats = 30 responses,
                                         # judged one call each on claude-haiku-4-5
python scripts/rejudge-on-opus.py        # only if the audit gate trips; re-judges the same
                                         # 30 recorded responses, does not re-run the probe leg
# results  -> docs/task-3-firing-results.json
# scratch  -> .task3-probe/ (gitignored)
# expect   -> "RESTORED OK", then an Opus-vs-Haiku agreement rate over a random 10 of the 30
```

Agreement below 90% means stop and re-judge everything on Opus before reading any arm difference:
that number is a fact about the judge, not about the split. **On the 2026-08-29 run the gate
tripped at 60% and the trip was spurious** — a fault in the gate, not in the judge. `judge()`
returns `raised=None` when a reply has no parseable JSON, and the audit scores
`a["raised"] == records[i]["raised"]`, so `None != True` counts as a *disagreement*. The 6/10 was
6 agreements, 0 disagreements and 4 unreadable Opus replies. "The judges disagree" and "one judge
did not answer" need different fixes, and the gate reported the second as the first; a rate must
never fold in the cases the instrument failed to score. `scripts/rejudge-on-opus.py` is the
recovery — it re-judges the recorded responses rather than re-running the expensive probe leg,
gives the judge a longer timeout, retries an unreadable reply once, and reports holes separately
from the rate. It returned **30/30 judged, 0 unreadable, Haiku-vs-Opus 30/30 = 100%**.

Read the arms by the three-way rule in
§5 Task 3 — `A≈B>C` licenses applying the split, `A>B≈C` says §3b is wrong and everything
downstream stops, `A≈B≈C` means the probe is dead and licenses nothing either way. Whichever it
is, three things here go stale the moment it runs and are updated in the same step: this block,
the Task 3 row's status cell, and §5 Task 3's "written and unrun". **All three were updated on
2026-08-29; the answer was `A≈B≈C`.**

The problem this solves: `distill-lessons` routes standing instructions to CLAUDE.md, so every
lesson that qualifies grows a file loaded into every session, forever. `refile-rules` can shrink
that file, but only by moving content to a tier that has a trigger — and it does not say which
tier, because the trigger taxonomy did not exist. This spec supplies it.

---

## 1. Measured baseline

Task 2 changed two things here, and both matter downstream.

**Two of the original three rows were wrong.** The `EH-dataportal/CLAUDE.md` row read 34,207 B —
that is the `feature-site-characterization` **worktree's** copy, not `production`'s, which is
25,198 B. And the `MEMORY.md` row was the EH-dataportal store, not this repo's; the two differ by
9x. `[measured 2026-08-25: wc -c per file; worktree copies enumerated with git worktree list]`

**The token counts are measured, not estimated** — method below.

| File | Bytes | Tokens | B/token | Lines |
|---|---:|---:|---:|---:|
| `~/.claude/CLAUDE.md` | 49,553 | **11,973** | 4.14 | 135 |
| `EH-dataportal/CLAUDE.md` (`production`) | 25,198 | **6,590** | 3.82 | 209 |
| EH-dataportal `MEMORY.md` | 13,291 | **4,117** | 3.23 | 74 |
| **always-loaded total, in EH-dataportal `production`** | **88,042** | **22,680** | — | — |
| `claude-skills/CLAUDE.md` | 1,861 | **555** | 3.35 | 26 |
| `claude-skills` `MEMORY.md` | 1,491 | **487** | 3.06 | 13 |
| **always-loaded total, in this repo** | **52,905** | **13,015** | — | — |
| EH memory topic files (63, **not** loaded) | 325,679 | — | — | — |
| `claude-skills` memory topic files (8, **not** loaded) | 22,846 | — | — | — |

**This table is a fixed point, not a current reading, and it has already drifted.** The figures are
`~/.claude/CLAUDE.md` as it stood at **49,553 B on 2026-08-25, before any instruction file was
edited** — which is what Task 2 required of it. Later the same day a `distill-lessons` pass added
two rules and took it to **50,686 B (+1,133, +2.3%)**, and an evening amendment to a single
bullet took it to **50,897 B (+211, +2.7% on the baseline)** — a figure that closes exactly
against the pilot section's own +211 B, so that one bullet is the whole of the second move
`[measured 2026-08-25: wc -c on the file and on the awk-extracted section]`. The token count was **not** re-measured, and
is deliberately not scaled: §1 states measured figures only, and a baseline that moves is not a
baseline. Re-measure against the table, never edit the table to match.

That drift is itself a finding, and the cheapest evidence in this document for §3c: **one ordinary
lessons pass, on a day spent writing a spec about shrinking this file, grew it 2.3%.** Nothing in
the loop objected, because nothing in the loop can see a ceiling. That is Task 8's whole argument,
and a reason to consider moving Task 8 ahead of Task 5.

**The project file has no single size — it is branch-dependent.** The four live EH-dataportal
worktrees carry a CLAUDE.md of 20,666 / 25,198 / 34,207 / **59,726** B `[measured 2026-08-25]`. The
largest is bigger than the global file, and a session in that worktree starts on **15,804 tokens**
of project instructions alone. So a ceiling in §3c has to name the branch it is measured on, and
the branch that needs one most is the one nobody is currently looking at.

**Method, because `/context` could not supply this.** `/context` is client-side and does not exist
in `claude -p` — asked headlessly it is simply answered as a prompt `[verified 2026-08-25]`. The
figures above are **differential** instead: run `claude -p` on a fixed trivial prompt, read the
first assistant turn's `input_tokens + cache_creation_input_tokens + cache_read_input_tokens` from
the session transcript, remove exactly one memory file, re-run. The delta is that file's cost.

Three things make it trustworthy, and one of them caught a false arm:

- **Run-to-run variance is ±1-3 tokens** on identical runs `[4 baseline runs: 43,380 / 43,381 /
  43,383 / 43,384]`. A delta of thousands is far outside it.
- **Every arm carries its own control.** The `InstructionsLoaded` log (§2) names the files that
  actually loaded in that run, so an arm whose file still appears in it did not do what it claims.
- **That control voided the first two arms.** `claudeMdExcludes` excluded nothing in 2.1.227 —
  tried through `--settings` and through the documented `.claude/settings.local.json`, in both slash
  conventions; the file appeared in the log every time, and the deltas were −106 and −4 tokens,
  which is noise wearing a result's clothes `[2026-08-25]`. What works is moving the file aside for
  the duration of one run. **Do not use `claudeMdExcludes` to measure anything without reading the
  log first** — it fails silently, and the failure looks like a small answer rather than an error.
- Cross-harness check: global CLAUDE.md measures **11,973** tokens from inside this repo and
  **12,023** from an empty scratch directory. Each is stable to ±1 within its own harness; the 0.4%
  gap between them is unexplained. Compare deltas within one harness, never across two.

Two caps apply, from the official docs (see §2): `MEMORY.md` loads only its first 200 lines **or**
25KB, whichever comes first. The EH-dataportal index is at 74 lines / 13,291 B — averaging 180
B/line, so **25KB is the binding cap and it arrives at ~139 lines, not 200.** Currently 53%
consumed. Anything past the cap is dropped silently on load.

**Nothing comparable caps CLAUDE.md.** The docs state Claude Code loads a CLAUDE.md of up to
**4 MiB** in full, and skips a larger one `[docs, fetched 2026-08-25]`. At 4.14 B/token that is
around a million tokens, so the platform imposes no practical brake — §3c's ceiling is the only one
there is.

---

## 2. What the platform actually does

Verified against <https://code.claude.com/docs/en/memory> `[fetched 2026-08-25]`. This table is
the load-bearing reference for every routing decision below; re-check it before acting on this
spec, because it is an outside-world claim that decays.

| Mechanism | Loads when | Cost while idle | Trigger is |
|---|---|---|---|
| `~/.claude/CLAUDE.md`, project `CLAUDE.md` | every session, at launch | full text | — |
| `@path` import | every session, at launch (max 4 hops) | full text | — |
| `.claude/rules/*.md` **without** `paths:` | every session, at launch | full text | — |
| project `.claude/rules/*.md` **with** `paths:` | Claude reads a file matching the glob | zero | deterministic |
| **user** `~/.claude/rules/*.md` **with** `paths:` | same — **verified 2026-08-25, Task 1** | zero | deterministic |
| subdirectory `CLAUDE.md` | Claude reads a file in that subdirectory | zero | deterministic |
| Skill `SKILL.md` body | invoked, or judged relevant | name + description | judgment |
| auto-memory topic file | Claude chooses to read it | zero | judgment |
| `MEMORY.md` | every session; first 200 lines **or** 25KB | full text to cap | — |

Five quotes worth carrying, because they each kill an otherwise-obvious idea:

- *"Splitting into `@path` imports helps organization but doesn't reduce context, since imported
  files load at launch."* — imports are an organizing device, never a budget device.
- *"Rules load into context every session or when matching files are opened. For task-specific
  instructions that don't need to be in context all the time, use skills instead."*
- *"Claude Code doesn't load topic files such as `user_role.md` at startup. Claude reads them on
  demand using its standard file tools when it needs the information."*
- *"Auto memory is machine-local. All worktrees and subdirectories within the same git repository
  share one auto memory directory. Files are not shared across machines or cloud environments."* —
  this is the one that decides §4's project-scope question, and the first version of this spec
  missed it. A lesson the team is meant to share can never live in `MEMORY.md`.
- *"Project-root CLAUDE.md survives compaction: after `/compact`, Claude re-reads it from disk and
  re-injects it into the session. Nested CLAUDE.md files in subdirectories and rules with `paths:`
  frontmatter reload as Claude reads files they apply to."* — so the lazy tier is lazy across a
  compaction too. A path-scoped rule that matched an hour ago is **gone** after a compact until
  something re-matches it. That is the correct behaviour for a budget, and a real behavioural
  difference from the always-loaded tier that §3a's routing has to be willing to accept.

**There is no retrieval engine behind a bare pointer.** A blog post claims a non-`@` path in
CLAUDE.md becomes "a pointer that the recall system surfaces when it judges the file relevant";
the official docs describe no such mechanism. A pointer is read only if the model reads the hook
line and decides to open the file. That is the same judgment-based trigger `MEMORY.md` already
runs on — which is why §4 does not build a second index for project-scoped content.

**Instrument.** The `InstructionsLoaded` hook *"logs exactly which instruction files are loaded,
when they load, and why"* — documented as being for debugging path-specific rules and lazy-loaded
files. Every lazy-tier claim in this spec is checkable against it. Nothing here should be believed
without it. It is registered on this machine; §0 says where, and how to remove it.

**Its payload is richer than the docs describe, and the extra fields are the useful ones.** Measured
from the hook itself rather than from the documentation `[2026-08-25]`, each event carries
`session_id`, `transcript_path`, `cwd`, `hook_event_name`, **`file_path`**, **`memory_type`**
(`User` or `Project`), and `load_reason` (`session_start`, `nested_traversal`, `path_glob_match`,
`include`, `compact`). A lazy load adds `prompt_id`, **`globs`** — the rule's own `paths:` list —
and **`trigger_file_path`**, the file whose read caused it. So the log answers not just *which* rule
loaded but *which read pulled it in*, which is what makes Task 4's proof a one-liner.

**One thing it does not see: `MEMORY.md`.** No `InstructionsLoaded` event fires for the auto-memory
index or its topic files in any of the six runs that loaded a real one `[2026-08-25; the other runs
pointed auto-memory at an empty directory and cannot speak to this]`. The hook covers CLAUDE.md and
`.claude/rules/` only. So the instrument that validates the rules tier **cannot validate the memory
tier** — §1's `MEMORY.md` figures rest on the differential measurement alone, and any future claim
about when a topic file gets read needs a different instrument than this one.

---

## 3. The routing rule

`refile-rules` §4 already states the criterion:

> Content belongs in the always-loaded tier when the moment you need it is a moment you would not
> know to go get it.

That criterion decides *whether* something is always-loaded. It does not decide *where else* it
goes, and it treats each rule as atomic. Both gaps are what let the file grow. This spec adds two
things.

### 3a. Classify by what would summon it

| Class | Summoned by | Goes to |
|---|---|---|
| **File-triggered** | a kind of file being open — `.R`, `.ps1`, `.github/workflows/*.yml`, front-end JS | `.claude/rules/` with `paths:` |
| **Task-triggered** | starting a recognizable kind of work — planning, committing, reviewing, distilling | skill |
| **Momentary** | nothing external. Verification habits, claims calibration, register | **stays always-loaded** |
| **Evidence** | wanting to know whether a rule is still true, or why it exists | memory topic file / `docs/` |

The momentary class is irreducible. You do not know you are about to overclaim; no file extension
fires for it. Everything else has a better summons than proximity.

> **Corrected 2026-09-01 by Task 11: this table conflates two axes.** The first three rows are one
> question — which **rule** tier holds the recognition line. **Evidence** is not a fourth answer to
> it; it is the answer to a second, independent question about where a rule's *evidence* goes, and
> under §3b a rule that stays always-loaded still has one. Read as a flat list of four, every entry
> matches two rows and the classification looks ambiguous when it is not. Task 7 writes it down as
> two questions.

**The file-triggered lane is currently unused.** No `.claude/rules/` directory exists on this
machine, at user or project scope `[verified 2026-08-25: ls on both]`. The four language skills
(`writing-r-code`, `writing-powershell`, `hardening-github-actions`, `reviewing-web-performance`)
carry exactly this content and fire on model judgment instead of on a glob — and global CLAUDE.md
says so itself: *"These live in skills rather than here, because the file you have open is a
reliable trigger and this file is not."* The reasoning is right; the mechanism available when it
was written was not. A `paths:`-scoped rule makes that trigger deterministic.

### 3b. Split each rule's specifics into recognition and evidence

This is the part that makes the always-loaded tier stop growing, and it is the part that needs
testing before it is trusted.

`refile-rules` §5 does not ban shortening. It puts it **behind a bar and behind the moves**, which
is a different thing and is what this split has to satisfy. Its default is that *"a move preserves
text byte for byte"*; an edit is permitted only where a written specifics inventory shows nothing
load-bearing was lost — *"every item on that inventory is locatable in the new text, or named in
the manifest as a deliberate drop with a reason"* — and the two may not happen at once:
*"never move and re-word an entry in the same manifest line"*, because the sorted-line diff that
proves a move reads a re-wording as one rule dropped and another appearing. An entry needing both
appears twice, once in each class, and the edit is the **second** step.

What it warns against is compression that removes *recognition*: *"it buys space by removing the
specifics that let a rule be recognized in a situation, and the loss is invisible afterwards."*
Global CLAUDE.md says the same, with a test attached: *"read the line with the citation deleted and
see whether it still tells you what to do."*

Both treat a rule's specifics as one set. They are two:

- **Recognition specifics** — the vocabulary and situation shape that make you notice the rule
  applies, plus the action it demands. Command names, flag names, the symptom, the instruction.
  These are what fires. **They stay.**
- **Evidence specifics** — what makes you *believe* it. Dates, run IDs, measured numbers, byte
  counts, the incident narrative, the disconfirmed alternatives. **These can move**, because you
  consult evidence at a moment when you already know to go look: deciding whether to trust a rule,
  or whether it has expired.

Worked example, from global CLAUDE.md §Language & platform conventions:

> **Before (≈90 words).** `git diff --no-index` prints no diff at all on a long path, while still
> returning the correct exit code. Against a ~150-character temp path it exited 1 for a genuinely
> different tree and emitted zero lines, alongside `Filename too long` warnings; the same
> comparison under `C:/temp` printed full field-level output `[verified 2026-08-23]`. A check
> built on it then fails without saying what changed, which reads as a broken harness rather than
> a caught regression. Keep generated comparison trees at a short path.

> **After (≈40 words).** `git diff --no-index` prints no diff at all on a long path while still
> returning the correct exit code, so a check built on it fails without saying what changed and
> reads as a broken harness. Keep generated comparison trees at a short path. Evidence:
> `[[git-diff-no-index-long-path]]`.

Recognition kept: the command, "long path", "no diff but correct exit code", the misreading it
causes, the action. Evidence moved: `~150 characters`, `exited 1`, the `Filename too long`
warning text, the `C:/temp` control, the date.

**The `[[pointer]]` in that example is wrong and Task 12 replaces it.** The syntax already means a
file in the per-project memory store, and is in live use there. Write the path instead —
``Evidence: `~/.claude/lessons/git-diff-no-index-long-path.md` ``. This example is the template
every later split copies, so it is the one place the wrong form does the most damage.

So the split is a **fourth qualifying edit shape** to add to `refile-rules` §5's three, not an
exception to a prohibition — and it inherits that section's bar unchanged, which is exactly Task 3
step 3. Task 7 is where it gets written into the skill.

**The test that the split is safe — and it has not been run.** Whether trimmed rules fire as
reliably as full ones is a hypothesis. The instrument exists: `scripts/run-trigger-evals.py`,
committed in `0c8fba9`. It had to be written because `skill-creator`'s own `run_eval.py` cannot
execute a query on Windows and reports a pass count instead of an error — the commit message
carries the mechanism and the verification. Task 3 pilots the split on one section and measures it.
If firing degrades, the split is wrong and this spec's budget claim collapses with it — say so
rather than shipping the trim anyway.

### 3c. A ceiling, and a shallower slope

The goal is **both**: a smaller file now, and one that grows more slowly from here. Not one that
stops growing — it will keep growing, because lessons keep arriving and some of them are genuinely
momentary, and a rule store that stops growing has usually stopped being written to rather than
stopped needing to be.

What changes is the **slope**. Today a new rule lands with everything attached: the date, the run
ID, the disconfirmed alternatives, the incident. After §3b, most of that lands somewhere else and is
loaded on demand, so an addition costs the recognition line and not the paragraph. Same rate of
lessons, a fraction of the bytes per lesson.

A ceiling is what turns that from an intention into a mechanism: at the ceiling, adding a rule
requires routing one out, so every addition becomes a routing decision instead of an append.

| File | Ceiling | Note |
|---|---:|---|
| `~/.claude/CLAUDE.md` | 25,000 B | from 49,553 — about 6,000 tokens, from 11,973 |
| project `CLAUDE.md` | 20,000 B | **per branch.** From 25,198 on EH-dataportal `production`; the `feature-MOD-Lab-NR-recode-refactor` worktree is at 59,726 and would have to shed two-thirds |
| `MEMORY.md` | 20,000 B | hard cap is 25,000; this leaves headroom |

**These numbers are chosen, not derived.** No measurement establishes 25,000 B as better than
30,000. Anthropic's own guidance is *"Longer files consume more context and reduce adherence"* and
*"target under 200 lines"* — a direction, not a threshold, and unusable here directly, since these
files run **72–367 B/line** `[measured 2026-08-25: claude-skills project 72, EH-dataportal
production 121, EH `MEMORY.md` 180, global 367]`. "200 lines" therefore spans a **5x** range in real
context cost, and the file furthest over on lines is not the file furthest over on tokens. Count
bytes or tokens; lines are not a budget unit here.

**A derived stopping rule may be available, and it comes from `align` (§7): saturation.** Its
heuristic is *"if ~20 new traces don't surface a new failure category, the corpus is saturated"* —
a threshold you observe rather than pick. The analogue: if N consecutive `distill-lessons` passes
add no rule that fires on a situation the store did not already cover, the always-loaded tier is
saturated and the right ceiling is roughly where it sits. That is a real experiment and nobody has
run it. Until then these are placeholders: Task 3 measures what the split actually yields on a real
section, and the ceilings get revised against that result rather than defended.

**Amended 2026-09-01, twice over.** First, the table's own numbers are stale: `~/.claude/CLAUDE.md`
is **62,370 B**, not 49,553, so the shortfall is 37,370 B rather than 24,553
`[measured 2026-09-01: sh scripts/check-memory-budget.sh, true exit 1 — read the exit status
without a pager, since a `| head` reports the pager's]`. Second, Task 8 established that **§3b's
trimming cannot close that gap at any effort** — it would take 10.5 pilot-sized splits — so the
25,000 B figure is not a target the split is failing to hit; it is a target only Task 4's routing
can reach. Treat the whole table as a **placeholder with a named replacement**: Task 14 adopts the
saturation reading above, which is observed rather than chosen. Do not defend these three numbers
and do not tune them.

---

## 4. Tier assignment for the existing content

### Global (`~/.claude/CLAUDE.md`)

| Section | Class | Destination |
|---|---|---|
| Verification → Choosing and running the check | momentary | stays |
| Verification → Validating the instrument | momentary | stays; evidence out |
| Verification → Verifying a claim before it hardens | momentary | stays; evidence out |
| Claims & register | momentary | stays |
| Effort & orchestration | momentary | stays; the cache-lineage numbers are evidence |
| Session workflow | mixed | commit/branch rules stay; ledger and lessons rules are already skill pointers |
| Code philosophy, Comments | momentary | stays |
| Language & platform conventions | ~~**file-triggered**~~ **momentary — corrected 2026-09-01** | ~~`~/.claude/rules/` with `paths:`~~ **stays.** 0 of its 11 bullets are file-triggered; §5 Task 4 step 1 |
| Plan mode | task-triggered | already a skill pointer; keep the pointer |
| Team context | momentary | stays (2 lines) |

**Section sizes, which decide where the effort goes** `[measured 2026-08-25, awk over the file]`:

| Section | Bytes | Share |
|---|---:|---:|
| Verification | 21,685 | 44% |
| Language & platform conventions | 7,815 | 16% |
| Session workflow | 5,848 | 12% |
| Claims & register | 5,585 | 11% |
| Effort & orchestration | 4,836 | 10% |
| Code philosophy | 1,247 | 3% |
| Plan mode | 1,243 | 3% |
| Comments | 648 | 1% |
| Team context | 611 | 1% |

**This inverts the obvious priority, and it is the single most important number in this spec.**
Routing (§3a) can only move the file-triggered content, and that is 7,815 B — 16%. `Verification`
alone is 21,685 B and is entirely momentary class: nothing external summons "you are about to
trust an unvalidated instrument", so **none of it can be routed anywhere.** It can only shrink by
the recognition/evidence split.

> **Corrected 2026-09-01: that 7,815 B was never routable.** It is the size of the section, not the
> size of its file-triggered content, and the two were assumed equal here without the per-bullet
> classification that would have separated them. Run in Task 4 step 1, the classification returns
> **0 of 11 bullets movable and ~600 B of split candidates**. The paragraph's conclusion survives
> and hardens: routing was never the safe move, and now it is not a move at all at global scope.

So the plan does not rest on the safe move. It rests on Task 3, the untested one. If §3b's
hypothesis fails, the reachable reduction is roughly the routing lane alone — and the 25,000 B
ceiling in §3c is not reachable at all. Run Task 3 before believing any number here.

**Caveat that must not be lost in the move.** Part of that section fires when *composing a Bash or
PowerShell tool call*, not when a file is open. No glob matches that. Those rules are momentary and
stay — global CLAUDE.md already flags this: *"The one thing with no file to trigger it: this
machine has two shell tools."* Splitting the section means separating the file-triggered rules from
the shell-composition rules, not moving the heading wholesale.

### Project (`EH-dataportal/CLAUDE.md`)

| Section | Class | Destination |
|---|---|---|
| What this project is, Repo structure, Content sections | momentary (orientation) | stays, trimmed |
| Commands, Smoke test, Site characterization | task-triggered | `.claude/rules/` with `paths:` on `scripts/*.mjs`, plus skill pointers |
| Four ways a local check silently lies | momentary | stays — no file summons "you are about to trust a build" |
| JS architecture → Data explorer | **file-triggered** | `.claude/rules/` `paths: assets/js/data-explorer/**` |
| SCSS | file-triggered | `paths: assets/scss/**` |
| Hugo-specific rules | file-triggered | `paths: themes/dohmh/layouts/**`, `content/**` |
| Coding conventions | file-triggered | per-language `paths:` |
| Root-cause claims, Refactors and renames | momentary | stays |
| Branching and deployment, Common gotchas | momentary | stays |

Project scope has a mechanism global scope lacks: a **subdirectory `CLAUDE.md`** also loads on
demand. `themes/dohmh/layouts/CLAUDE.md` and `assets/js/data-explorer/CLAUDE.md` are equivalent to
path-scoped rules here and are checked into the repo the same way. Prefer `paths:` rules — one
directory holds them all, and the glob is explicit — but either satisfies the routing rule.

### The global-scope gap, which is smaller than it looked

Auto-memory is per-repository. `autoMemoryDirectory` is settable at user scope, so a shared store
*is* now possible — but **only one store loads per session**: a user-scope setting gives every
project the same store, and a project-scope override gives that project its own. You get global or
project, never both. `[from the docs' settings-precedence description, 2026-08-25; not tested]`

So cross-project lessons have no lazy, judgment-triggered store equivalent to `MEMORY.md`, and the
original proposal was to hand-build one: hooks in `~/.claude/CLAUDE.md` pointing at
`~/.claude/lessons/*.md`, firing on model judgment.

**Drop that.** The platform already ships the same mechanism, better. A **skill** at
`~/.claude/skills/<lesson>/` costs its name and description in context and loads its body on
demand — which is what a pointer line costs and what a pointer line buys, except the matching is
done by the harness against a description written for the purpose, rather than by the model
happening to read a hook line partway down a 49KB file. §2's own table already had both rows; they
are the same row. `az9713/claude-code-continual-learning-skills` (§7) is this idea already built.

Two things to hold against it, neither fatal. A user-scope skill is offered in **every** project, so
a lesson really about one stack clutters the roster everywhere — an argument for making the
description carry its own scope, not for going back to pointers. And no measurement exists, here or
in that repo, of how often a lessons-skill actually fires. That is the same gap Task 3 has to close
for §3b, and the same instrument closes both.

### Repo-scoped lessons belong in the repo, not in `MEMORY.md`

**This reverses what the first version of this spec said.** It said: for project scope, do not build
a second index, because `MEMORY.md` is already one and has an automated write path. That skipped the
property that actually decides it — the docs are explicit that auto-memory is **machine-local**:
*"Files are not shared across machines or cloud environments."* `[docs, fetched 2026-08-25]`

So `MEMORY.md` can never hold a lesson the team is meant to share. The objection was that a repo
index duplicates an existing tier; the tier it duplicates is invisible to everyone but this machine,
on this checkout. A teammate, a fresh clone, and a cloud session all get nothing.

**The rule: if a lesson or a memory is genuinely repo-scoped, it lives in the repo, committed, the
same way the project `CLAUDE.md` does.** That is the whole point of the project file — shared
through source control — and a repo-scoped lesson has no reason to be held to a weaker standard.

| What | Where | Loads | Shared with |
|---|---|---|---|
| repo-scoped rule with a file trigger | `.claude/rules/<topic>.md` with `paths:` | on a matching read; zero at launch | the team, via git |
| repo-scoped rule with no file trigger | project `CLAUDE.md` | every session | the team, via git |
| the evidence behind either | `docs/lessons/<slug>.md`, linked from the rule | when someone follows the link | the team, via git |
| genuinely personal, machine-local notes | `MEMORY.md` + its topic files | index every session, topics on demand | nobody |

`MEMORY.md` keeps a real job under this — personal working preferences, corrections that are about
how *I* want to be worked with, machine-specific facts — and loses the one it should never have had.

**What this gives up is the automated write path**, and it is worth naming rather than glossing:
`MEMORY.md` gets written without anyone asking, and a repo file does not. That is Task 7's problem —
`distill-lessons` has to learn to write to the repo tier, which is the same edit that teaches it
§3a's four classes. Until Task 7 lands, the repo tier is written by hand and will be written less
often than the store it replaces.

---

## 5. Migration

Each task states the observable end state it is proved by, not the files it touches.

### Task 1: Falsify the premise the global lazy tier rests on — **DONE 2026-08-25, premise held**

**Result: `paths:` is honoured at user scope in Claude Code 2.1.227.** A `~/.claude/rules/*.md`
carrying `paths:` stays out of context at launch and loads when a matching file is read, exactly as
a project rule does. §4's global routing lane is real, and Task 4 is unblocked.

The question was live because the docs describe `paths:` under *project* rules and describe
`~/.claude/rules/` as the user-level version of the same directory, without ever saying a user-scope
rule honours `paths:`. If it did not, user rules would load unconditionally and §4's global routing
would be dead.

**Design — four arms, because "absent from the log" has three innocent explanations.** A single
user-scope probe cannot distinguish *`paths:` works* from *`~/.claude/rules/` is not read at all*
from *my frontmatter syntax is wrong*. Each arm is one rule file with an unguessable sentinel:

| Arm | Scope | `paths:` | What its result rules out |
|---|---|---|---|
| A | user | yes | **the question itself** |
| B | project | yes | my `paths:` syntax being wrong — documented to work, so it must show lazy |
| C | user | no | `~/.claude/rules/` not being read at all |
| D | project | no | the repo's `.claude/rules/` not being read at all |

Two instruments, independently: the `InstructionsLoaded` hook log, and a self-report from the probe
session asked **by heading rather than by sentinel**, so the prompt never hands over the answer a
loaded file would supply. Predictions were written to disk before the first run.

**Run 1 — fresh session, no file reads.** C and D present at `session_start`; A and B absent. Both
instruments agreed. All four controls passed: the rules directories are read at both scopes, and the
syntax is right.

**Run 2 — fresh session, reads `probe-trigger.probep` then `probe-trigger.probeu`.** Both A and B
loaded on the matching read. The decisive line, verbatim:

```json
{"hook_event_name":"InstructionsLoaded",
 "file_path":"C:\\Users\\Chris\\.claude\\rules\\probe-user-paths.md",
 "memory_type":"User","load_reason":"path_glob_match","globs":["**/*.probeu"],
 "trigger_file_path":"C:\\Users\\Chris\\Documents\\Projects\\claude-skills\\probe-trigger.probeu"}
```

`memory_type: "User"` with `load_reason: "path_glob_match"` is the whole answer in one record.

**Three things learned that were not the question**, and each changes something downstream:

- The glob `**/*.probeu` matched a file at the **repo root**, so `**/` matches zero directories as
  well as many. Task 4's globs do not need a `{,**/}` dance.
- The payload names `trigger_file_path` and `globs`, so the log says which read pulled a rule in —
  §2 records the full field list.
- **`MEMORY.md` fires no event at all.** The instrument does not cover the memory tier (§2).

**Reproducing it costs about two minutes**: recreate the four rule files and two trigger files, run
two `claude -p` sessions, read the log. The probe files were deleted (§0); the hook was kept.

### Task 2: Record the real baseline — **DONE 2026-08-25**

**Files:** this document, §1.

**Interfaces:** produces the token figures every later measurement is compared against.

The numbers, the method, and the two arms that failed their own control are in §1. Three things
worth carrying forward rather than re-deriving:

- **`/context` cannot supply this headlessly** — it is a client-side command, and `claude -p
  "/context"` answers it as a prompt. The differential method in §1 replaces it and is more precise
  (±1–3 tokens against `/context`'s rounded display).
- **`claudeMdExcludes` silently excluded nothing** in 2.1.227, through two settings paths and both
  slash conventions. Any future measurement that reaches for it must check the
  `InstructionsLoaded` log before believing the delta.
- **The original §1 table mixed three different repos' files**, and one row was a worktree copy. The
  corrected table names the branch and the repo for every row, because §1 showed the project file's
  size varies 3x across live worktrees of one repository.

Commit this document before any instruction file is edited — a baseline taken after the first edit
is not a baseline.

### Task 3: Pilot the recognition/evidence split on one section

**Files:** `~/.claude/CLAUDE.md` §Verification → Validating the instrument;
`~/.claude/lessons/` (new).

Chosen as the pilot because it is the largest single subsection in the file at **14,749 B**
`[re-measured three times: 10,166 B when this task was written, 10,858 B after the 2026-08-25
lessons pass — which §1 describes — 11,069 B after an amendment that evening, 11,350 B on
2026-08-28 after a dash normalization and a second amendment, and 14,749 B on 2026-09-01 after four
new bullets, one amendment and the parked bullet]` — bigger than six of the nine top-level sections —
and because it is the densest in evidence specifics, so it is where the split has the most to prove
and the most to lose. The other two Verification subsections are unchanged at 5,418 B and 5,246 B.

Measure the section again at the moment you start, rather than trusting any number here: it grew
6.8% in a day and a further 1.9% within four hours, and a before/after against a stale "before"
reports the wrong reduction. The second of those two moves landed after the fixtures were cut and
was caught only by §0's guard — which is the argument for the guard, not an aside.

**Interfaces:** produces a measured before/after byte count and a firing-rate result. Tasks 5 and 6
are gated on it.

**Why `~/.claude/lessons/` and not a skill, given §4.** Skills are for content that has to be
*found* — the description does the matching, and that costs description bytes in every session.
Evidence does not need finding: the rule that cites it names it, so a plain file at a known path is
enough and costs nothing at all. Use a skill when something must summon the content; use a file when
something already points at it. These are evidence, so they are files.

1. For each bullet, write down its recognition inventory (trigger vocabulary + action) and its
   evidence inventory (dates, numbers, incident, disconfirmed alternatives) **before** editing —
   `refile-rules` §5's inventory rule, applied per-bullet.
2. Rewrite each bullet to recognition + action + a `[[pointer]]`. Move evidence to
   `~/.claude/lessons/<slug>.md`.
3. Every evidence item is locatable in the lesson file, or named here as a deliberate drop with a
   reason. No item is excused by the result reading better.
4. Measure: section bytes before and after.
5. **Measure firing.** ~~via `scripts/run-trigger-evals.py`~~ — **that instrument cannot answer
   this question, established 2026-08-25 before it was run.** It reports one signal: which `Skill`
   the model invokes first. The pilot section names **zero** skills `[verified: grep for every
   installed skill name over the section returned 0]`, so that signal is invariant to whether these
   bullets are full, trimmed, or deleted outright. Running it would return two identical pass counts
   — the exact failure this section's own "a fixture field identical across every case it covers is
   dead, not passing" bullet describes. **Do not run it here and do not read a matching pair of
   numbers from it as agreement.**

   What step 5 needs instead is a **behavioural probe**, at
   `scripts/measure-rule-firing.py` — **run 2026-08-29; the result is the step-5 block below and
   it is a null**. Three arms differing only in this section of
   `~/.claude/CLAUDE.md`: **A** full (14,749 B), **B** split (10,042 B), **C** deleted — built from
   `docs/task-3-section-{before,after}.md` and verified to differ by exactly 4,707 B and 14,749 B
   `[checked 2026-08-25, re-checked after the e7ddc91 and 2026-09-01 re-cuts]`. Arm C is load-bearing: without
   a floor, A≈B cannot be told apart from a
   probe that never saw the section. Five queries, each presenting a situation **without** the
   rule's own vocabulary — which is this section's own rule about eval prompts that hand over the
   fact under test. Q5 is a control: its bullet is byte-identical in A and B, so A-vs-B is the
   probe's noise floor and A-vs-C its sensitivity to the section existing at all.

   Reading: `A≈B>C` split is safe; `A>B≈C` **stop, §3b is wrong**; `A≈B≈C` probe is dead and
   licenses no conclusion either way.

   **The judge is one call per response and is never batched.** Independent calls are independent
   by construction; batched ones are not, and coupling the instrument to save money on a 2-repeat
   experiment is the wrong trade. It runs on `claude-haiku-4-5` with the global `CLAUDE.md` moved
   aside, and **that swap is itself checked** — `claude-opus-5` re-judges a random 10 of the 30 and
   the agreement rate is reported. Below 90%, re-judge everything on Opus before reading any arm
   difference: low agreement is a fact about the judge, not about the split.

   **Which model the arms run on, and why it is pinned.** `run_probe` used to spawn `claude -p`
   with **no `--model`**, so the 30 responses that *are* the experiment resolved from
   `~/.claude/settings.json` — `"model": "sonnet"` on this machine `[verified 2026-08-28: a bare
   `claude -p` returns `claude-sonnet-5`]`. The judge and auditor were pinned; the measured thing
   was not, so a settings edit or a `/model` elsewhere would have silently changed it. Now
   `PROBE_MODEL = "claude-sonnet-5"`, and each response records its own answering model into the
   results JSON, so the pin is checkable after the fact rather than only asserted.

   **Sonnet is the conservative arm, which is the reason to keep it.** Step 5 asks whether trimming
   evidence out of a rule degrades firing, and a more capable model can infer from a trimmed rule
   what a weaker one cannot. A pass on Opus would license a split that might still break Sonnet
   sessions; a pass on Sonnet implies Opus passes too. Revisit only if every session these rules
   serve runs on Opus.

   **Cost, recomputed 2026-08-28 after the pin.** The 2026-08-25 figures — `~$2` cached, `~$11`
   cold — were computed at **Opus** rates and the probe leg does not run on Opus. Current rates:
   Opus 5 `$5`/`$25` per Mtok, **Sonnet 5 `$2`/`$10`**, Haiku 4.5 `$1`/`$5`, cache read 0.1x, write
   1.25x `[claude-api skill's pricing table, cached 2026-06-24, read 2026-08-28]`. Sonnet is exactly
   **0.4x** Opus on both axes; the probe leg is ~71% of the run and the Haiku judge and Opus auditor
   are unchanged, so the total scales by `0.71x0.4 + 0.29 ≈ 0.57`: **~$1 if the prefix cache holds,
   ~$6 if it never hits.** The probe leg stays irreducible — 30 cold sessions x ~43K of fixed prefix
   *is* the experiment; only fewer arms or fewer repeats would move it, and both weaken the design.
   Still an estimate, and now a compounded one: it inherits §1's measured 43,380-token baseline
   (taken in-repo while the probe runs from a workdir, so conservative) *and* the ~71% split. Read
   the order of magnitude, not the digits.

   That ratio is itself a datapoint for §3c: the global `CLAUDE.md` is **11,973 of the 43,380
   tokens on every invocation, 27.6%**. The probe is expensive for the reason the spec exists.

**If firing degrades, stop.** §3b is wrong and §3c's ceilings are unreachable by this route. Say
so here and report before continuing.

**Step 5 result, 2026-08-29: `A≈B≈C` at the ceiling. The probe is dead and licenses nothing.**

| query | A full | B split | C deleted |
|---|:--:|:--:|:--:|
| Q1-B2 comment is not evidence | 2/2 | 2/2 | 2/2 |
| Q2-B7 constant fixture field | 2/2 | 2/2 | 2/2 |
| Q3-B9 control ≠ recall | 2/2 | 2/2 | 2/2 |
| Q4-B12 conditions allow the effect | 2/2 | 2/2 | 2/2 |
| Q5-B13 CONTROL (identical in A and B) | 2/2 | 2/2 | 2/2 |
| **probes only, control excluded** | **8/8** | **8/8** | **8/8** |

Run hygiene first, because the result is only worth reading if the mechanics held. `RESTORED OK`,
sha `49b5d278f376`, re-hashed independently afterwards. All 30 answered on `claude-sonnet-5` —
the pin held, and it is checkable after the fact because each response records its own model.
30/30 `message-stop`, no timeouts, no empty texts, responses 1,023-2,777 chars. The hook log
gained **+20 lines in every arm**, including C, confirming the arm really was mounted and read
each time. The §0 guard passed clean at 11,350 B, its first non-firing.

**The floor did not drop, which is the whole finding.** Arm C exists precisely so that `A≈B`
cannot be confused with a probe that never saw the section, and it did its job: it reported that
this probe never discriminated. `A≈B` here is not evidence the split is safe.

**Why it saturated — not "the queries are too easy", which is the diagnosis that would send you to
write harder ones and fail the same way.** Read against arm C, `claude-sonnet-5` raises every one
of the five points *unprompted, correctly, and in the rubric's own terms* with the section deleted:
Q1 "a code comment asserting *why*... should get checked, not copied, when it's about to be
promoted into a design doc"; Q4 "5/5 non-reproductions isn't evidence the race doesn't exist, it's
5 trials of a scenario that was never at risk"; Q5 "an agent that never opens the transcript and
one that dutifully reads it will both answer identically". These bullets encode general
methodological competence that a frontier model already has, so **the rule was never the thing
supplying the answer** and no arm could have differed.

There is a sharper structural reason underneath, and it generalizes past this section. **§3b's
split removes evidence and keeps recognition + action. The probe scores whether the action
fires — and the action text is present in both A and B by construction.** A-vs-B was therefore
near-guaranteed to be flat whatever the truth is; the only live comparison was A-vs-C, and that
one measures whether the model needs the rule at all. On rules whose action restates a widely-held
practice, it does not. A probe of this shape can only ever discriminate on rules that are
**local and non-obvious** — `grep -c` exiting non-zero on its informative answer, a named tool's
version-specific behavior, a threshold from one incident — which is a different sample of bullets
than the pilot section offers.

**What this does and does not license.** It does **not** say the split is safe: applying it on
`A≈B` would be reading a null as a pass, which is the failure this section's own bullets describe.
It does **not** say §3b is wrong either — nothing degraded, because nothing could. Tasks 5 and 6
stay gated. The split stays built, proved lossless, and unapplied.

**Three routes out, cheapest first.** (a) **Re-select the queries against rules that are local and
non-obvious**, using arm C as the screen: draft a query, run arm C only, and keep it only if the
model *fails* to raise the point without the rule — a two-response pre-test per candidate, and it
kills a dead query for ~$0.10 instead of ~$3. (b) **Measure the evidence, not the action** — the
split's actual deletion is dates, numbers and incidents, so score whether the response can still
*cite* the specific case, which is the thing B no longer carries inline. This is the measurement
that matches what §3b changes, and (a) does not test it at all. (c) **Accept the split on the
lossless proof alone** and drop the firing claim from §3b, which is honest but gives up the
argument Tasks 5-6 were resting on. (a) and (b) compose — (a) fixes the sample, (b) fixes what is
scored — and doing (b) without (a) risks the same ceiling.

**Route (a)'s screen ran 2026-09-01, and the ceiling turned out to be a property of the sample.**
`scripts/screen-queries.py`, eight candidates drawn from bullets that are local and non-obvious,
reading rule pre-registered in its docstring. Two phases: arm C first, keeping a candidate only if
the model **fails** to raise the point; then arm A on the survivors only. Phase 2 is not
bookkeeping — a phase-1 survival has two innocent readings, the rule is load-bearing or the
query is too vague to engage, and nothing in phase 1's output separates them.

**Three of eight looked like they discriminate, and the follow-up run says that was mostly noise
— read the correction below before using this table.** Five saturated at 2/2 on arm C. Three came
back 0/2 without the rule and 2/2 with it:

| id | bullet | C | A |
|---|---|---|---|
| S2-B4 | the corpus records your own query | 0/2 | 2/2 |
| S5-B17 | a trigger that also moves something your classifier already explains | 0/2 | 2/2 |
| S8-B6 | a no-op proof is scoped to the unit you compare | 0/2 | 2/2 |

**Retracted 2026-09-01, same day, by the run below.** This paragraph originally read that the
old probe's null was a fact about its sample rather than about the section, and that "the queries
are too easy" was closer to right than the structural argument beside it. The three-arm run
re-measured arm C on these same three queries and got **1/2, 1/2, 0/2** where the screen had got
0/2, 0/2, 0/2. Arm C is not zero; it is a low nonzero rate, and **two repeats cannot distinguish
those.** At a true arm-C rate of 0.25 a 0/2 screen fires **56%** of the time `[binomial, (1-p)^2]`,
so three survivors out of eight candidates is roughly what screening saturated bullets at two
repeats produces on its own. The screen did not find load-bearing rules; it found the queries whose
coin came up tails twice. What survives from it: the *procedure* is sound and the arm-A leg is
solid (12/12 pooled). What does not: the count.

**The verdict is one contested judgment away from "underpowered", which is why it is recorded
here rather than in a footnote.** S5-B17's second arm-C response came back a judge hole.
Re-judged on both models, **Haiku returned `raised=true` and Opus `raised=false`**, and Opus was
taken: Haiku's own quote — "no positive control proving the classifier can surface a
permission-mode rebuild" — is a point about positive controls, not about a covariate the
classifier already strips. If Haiku's score stands, S5 is saturated, the count is **2**, and the
pre-registered rule reads *underpowered — report and decide*. The 2026-08-29 run measured
Haiku-vs-Opus agreement at 30/30; this is the first disagreement, and it landed on the one
response that decides a threshold.

**A defect in the screen's own summary, the same shape as the audit-gate defect above.** The
verdict table printed S5-B17 as "saturated (raised without the rule)" when its arm-C scores were
`False` and a hole — the opposite of what happened. The survivor filter was correct; the label
came from an `else` branch that treated everything non-surviving as saturated. **A category
printed for whatever falls through the branches above it will eventually assert something no arm
measured.** Fixed: unscored candidates now print `UNSCORED — N judge hole(s); re-judge before
reading`.

**Cost: $3.17 for 22 responses** `[computed 2026-09-01 from the recorded `usage` in
`task-3-screen-results.json`; output undercounted, `usage` is read at `message_start`]` —
**$0.144 per response**, against the $0.104 the 2026-08-29 run's arithmetic implies. Cache hit
rate 33%. The step-5 note above says a dead query costs "~$0.10 instead of ~$3"; that figure is
**per response, not per candidate**, so a two-response pre-test is ~$0.29. Budget accordingly.

**The three-arm run on those three queries, 2026-09-01.** `scripts/probe-confirmed-queries.py`,
18 responses, `RESTORED OK`, 0 judge holes. Its pre-registered rule voids any query whose screen
result fails to replicate, and **two of three voided**:

| query | A | B | C (screen) | C (this run) | |
|---|---|---|---|---|---|
| S2-B4  | 2/2 | 0/2 | 0/2 | **1/2** | VOID |
| S5-B17 | 2/2 | 1/2 | 0/2 | **1/2** | VOID |
| S8-B6  | 2/2 | 1/2 | 0/2 | 0/2 | B ambiguous at 2 repeats |

**By its own rule this run licenses nothing** — one replicating query, and its B cell is 1/2,
which two repeats cannot resolve. The replication gate earned its place: without it the table
would have been read as a result.

**Post-hoc, and flagged as post-hoc because it is not what was pre-registered**, pooling both runs
over all three queries: **A 12/12 (100%), B 2/6 (33%), C 2/12 (17%)**; A-vs-B Fisher exact
two-sided **p = 0.0049**, B-vs-C **p = 0.57**. That is the `A > B ~= C` shape — the branch that
says §3b is wrong and stops Tasks 5-6.

**Do not act on it yet, because arm is confounded with run order in every run so far.** Both this
script and `measure-rule-firing.py` iterate arms **sequentially** — the whole A leg, then B, then
C — so an arm's position in the run is a perfect alias for the arm. A monotone drift over the
~10 minutes a run takes (cache state, service load, anything) reproduces `A > B > C` with no arm
effect whatsoever. The 2026-08-29 run had the same structure and it did not matter, because every
arm sat at the ceiling; it matters now that they do not. **So p = 0.0049 is evidence that arm A
differs from arm B OR that the run drifted, and nothing measured so far separates those.**

**What a run that could answer this needs, and what it costs.** Interleave the arms in one
randomized job list rather than looping arm-by-arm, which is a change to `leg()`'s caller and not
to its logic. Then buy resolution: 2 repeats can separate 0 from 2 and can do nothing else, which
is the whole story of this pair of runs. Three queries x three arms x six repeats is **54
responses, ~$7.78** at the measured $0.144. Dropping arm C — its floor is established well enough
at 2/12 pooled — and running A vs B interleaved at eight repeats is **48 responses, ~$6.91**, and
answers the question that actually gates Tasks 5-6.

**Route (c) is still on the table and is now cheaper than the evidence.** Two runs and ~$6 have
bought a signal in the direction of the split *breaking* firing, that cannot yet be told from
drift. If ~$7 more is not worth spending, (c) — apply the split on the lossless proof alone and
drop the firing claim from §3b — is the honest alternative, and the arithmetic under Task 8 says
§3b cannot reach the ceiling either way.

**Cost, now measured rather than estimated, and the estimate was low.** The probe leg cost
**$3.11** at Sonnet rates against a predicted ~71% of $1-$6 `[computed 2026-08-29 from the
per-response `usage` recorded in `task-3-firing-results.json`; output tokens are undercounted
because `usage` is read at `message_start`, worth ~$0.15 at ~500 tokens x 30]`. The reason is a
bad input, not bad arithmetic: **the per-response prefix is ~66,780 tokens, not the 43,380 §1's
estimate inherited — 54% higher.** Cache hit rate was 40% (1,179,526 created against 777,171
read), so the run was closer to the cold case than the warm one. Anything downstream that
inherited the 43,380 figure inherits the same error.

**The audit gate has a defect, and it is the reusable lesson here.** It tripped at 60% and the trip
was spurious — 6 agreements, 0 disagreements, 4 Opus replies that returned no parseable JSON and
were scored as disagreements by `None != True`. A rate that folds in the cases the instrument
failed to score cannot distinguish "the judges disagree" from "one judge did not answer", and those
have different fixes. `scripts/rejudge-on-opus.py` separates them, and re-judging all 30 on Opus
gave 30/30 judged, 0 unreadable, **100% Haiku-vs-Opus agreement** on that run, and the gate nearly
bought an unnecessary re-run.

**"So the cheap judge was fine all along" was the wrong generalization, and `c3e4aa0` corrects it.**
That 100% is one run's agreement, on a sample of 10 of 30 — it is not a property of the judge. A
complete audit of the later 18-response three-arm run, `scripts/audit-judge.py`, returns **14/18
(77.8%) with 0 holes**, below the same 90% gate, and the disagreement is **arm-correlated**:
`A_full` 6/6, `B_split` 4/6, `C_absent` 4/6, with all four disagreements in B and C and none in A.
Under Opus the tallies read A 6/6, B 2/6, C 0/6 against Haiku's A 6/6, B 2/6, C 2/6; both give
Fisher `p = 0.0606`. So the A>B ordering survives a second judge while the judge itself fails its
own quality gate — which is a third independent reason step 5 could not license a verdict, beside
the ceiling null and the run-order aliasing, and it is the one that reaches back across every
Haiku-derived number in this section.

**One check worth not repeating the way I first ran it.** Asked whether the judges' quotes were
real, an exact-substring test said 43% were fabricated. They were not: the test scored *elisions*
as inventions — Haiku's Q2 quote drops the clause "in whatever logic produces it" from a sentence
that is otherwise verbatim. A fuzzy rewrite was no better, scoring zero of 60 quotes as verbatim
when at least one plainly is. Both versions of the check were wrong in the direction that would
have discredited a sound judge. What actually settled it was reading five arm-C responses in full;
the earlier read that seemed to show Q2 missing its point was truncated at 1,000 characters and
the point was in the third bullet.

**Steps 1-4 result, 2026-08-25; re-cut 2026-09-01.** Inventory: `task-3-split-inventory.md`, built
before any edit; it describes the 17-bullet section as it stood then, and is not re-cut. The
section is now **22 bullets** (18 top-level, 4 nested), not the flat list it reads as. **Three of
the 22 carry no evidence specifics at all** — no date, no number, no incident — and are kept byte
for byte; that is the first real bound on the yield, since the section's size is not uniformly
evidence. The other 19 split to `~/.claude/lessons/<slug>.md`, each holding its original bullet **verbatim**,
which turns "every evidence item is locatable" from a judgment call into a substring test.

**Measured: 14,749 → 10,042 B, −4,707 B, −31.9%.** `[re-measured 2026-09-01 after the third
re-cut; earlier figures were 10,858 → 8,048 B (−25.9%), 11,069 → 8,106 B (−26.8%) and
11,350 → 8,310 B (−26.8%)]` **The yield ratio did not hold.** This document previously read the
two 26.8% figures as weak evidence that the ratio is a property of the section's evidence density
rather than of one cut; the third cut returns **31.9%**, so that reading was wrong and is
withdrawn. The five bullets added since carry an unusually high share of dates, counts and memory
citations, which is exactly what the split removes — so the ratio tracks **which bullets arrived
most recently**, not a stable property of the section. Treat 26.8-31.9% as the observed range and
do not project a single figure from it. Proved by five checks — bullet count preserved,
the three unchanged bullets byte-identical, all 19 pointers resolving, all 19 originals verbatim in
their lesson files, and a 1:1 pointer↔file mapping with no orphans.

**The verifier was itself validated before its passes were believed**, by injecting six faults and
confirming each is caught and names its own finding. That found three real bugs in it: it read the
real `~/.claude/lessons/` while the control perturbed a copy, so two arms silently tested nothing;
and two checks crashed instead of reporting, which exits non-zero and reads as a catch. Had it been
trusted on its first all-pass, this task would have reported a clean proof from an instrument with
two dead arms.

**Not applied.** The live `~/.claude/CLAUDE.md` still holds the full section, not the split one.
(The file itself was edited on 2026-09-01 to land the parked bullet — see §0 — so "untouched", which
this line used to say, is no longer the right word for it.) The split is `docs/task-3-section-after.md`,
its pre-split source is `docs/task-3-section-before.md`, and applying it is gated on step 5.
`scripts/verify-split.py` re-proves the whole thing from those two files plus `~/.claude/lessons/`
in about a second, and exits non-zero on any failure — that being its informative answer, chain it
with `;`.

### Task 4: Route the file-triggered content

**Files:** `~/.claude/CLAUDE.md` §Language & platform conventions; new
`~/.claude/rules/{powershell,windows-cli,git-tooling}.md`.

**Interfaces:** consumed Task 1's yes/no, which came back **yes**. Produces the first real reduction
in the global file, and it is the one reduction that does not depend on Task 3.

> **STEP 1 RAN 2026-09-01, AND ITS RESULT STOPS STEP 2. Nothing was moved.** The separation §4's
> caveat asks for was performed as a labelled sweep over all 11 bullets, and **0 of 11 are cleanly
> file-triggered.** The move this task specifies would make the rules fire *less* often, not more.
> Full classification and the consequences are in "Step 1 result" below; the move procedure that
> follows it is retained for the project file, where the classification has not been run.

Separate the file-triggered rules from the shell-composition rules first (§4's caveat), then move
only the former, **byte for byte** — this is `refile-rules`' moves class and gets its mechanical
proof: sort the rule lines before and after and diff the sorted forms; the only differences may be
the ones a manifest names. Any rule that also wants trimming appears a second time in the edits
class, never in the same manifest line (§3b).

Proof of the end state, not of the file list: with a `.ps1` open, the PowerShell rules are in
context per the `InstructionsLoaded` log; at launch with nothing open, they are not. Task 1 leaves
the log already registered, so this is two greps:

```sh
LOG="C:/Users/Chris/probe-instructions-loaded.log"
grep -c 'powershell.md' "$LOG"                                    # after a launch with nothing open: expect 0
grep 'powershell.md' "$LOG" | grep -o '"load_reason":"[^"]*"'     # after reading a .ps1: path_glob_match
```

Note the compaction behaviour recorded in §2 before treating this as free: a path-scoped rule is
**out of context again after a `/compact`** until something re-matches it. For rules that only
matter while editing a matching file that is correct. For a rule that matters when *composing a
command about* such a file, it is a real loss — which is the same boundary §4's caveat draws, and a
second reason to draw it carefully.

#### Step 1 result, 2026-09-01: the routing lane is empty at global scope

**The test applied per bullet, chosen because it is answerable rather than arguable:** name the glob
that would be matching at the moment of need. Not "is this rule about PowerShell" — every bullet
here is about a platform — but "what file is open when you need it". §Language & platform
conventions is **9,414 B** across 11 bullets `[measured 2026-09-01: awk over ~/.claude/CLAUDE.md
lines 130-153; it was 7,815 B on 2026-08-25, so it grew 20% during the analysis]`.

| Bullet | Moment of need | Glob | Class |
|---|---|---|---|
| L132 skill pointer, 338 B | about to write R / PowerShell / front-end / Actions | — already routed; the four skills' descriptions are the trigger | **stays** (it *is* the routing) |
| L134 section meta-rule, 347 B | filing a rule into this section | none | momentary |
| L136 two shell tools + heredoc form, 2,104 B | composing a `Bash` or `PowerShell` call | none | momentary — **its own first clause says so**: *"The one thing with no file to trigger it"* |
| L138 backslashes survive a quoted delimiter, 747 B | composing a heredoc body | none | momentary |
| L140 PowerShell eats `--` in `npm run`, 825 B | typing an npm command, usually copied from a README | none | momentary |
| L142 npm bare positionals, 449 B | compose time; **and** writing a script npm calls | `**/*.mjs`, `**/*.js` for the second half only | **split candidate** |
| L144 `$var` expanded by the parent `pwsh`, 396 B | composing a cross-process call — the caller may be any language | none reliable | momentary |
| L146 join with `;` not `&&`, 834 B | composing a verification chain | none | momentary — the bullet says it outright: *"at the moment a `Bash` call is being composed"* |
| L148 Windows CLI flags and `/tmp` under Bash, 1,666 B | composing a Bash call | none | momentary |
| L150 `git diff --no-index` on a long path, 518 B | composing that command | none | momentary |
| L152 per-file shell loop; Python decoding, 1,144 B | compose time; **and** writing a `.py` sweep | `**/*.py` for the second half only | **split candidate** |

**0 of 11 move. 2 of 11 contain a file-triggered half that does not exist until the bullet is
edited** — and an edit is `refile-rules`' class 2, proved by reading against an inventory, never the
sorted-line diff this task was scoped around. Their routable halves total roughly 600 B of 9,414.

**Why moving them anyway would be worse than doing nothing.** A `paths:` rule loads on a glob match.
A rule whose moment of need is *composing a command* has no file open that matches, so routing it
converts a rule that is always present into one that is present only by coincidence — and §2's
compaction behaviour makes that strictly worse again, since a path-scoped rule is out of context
after a `/compact` until something re-matches. This is not a close call: the failure mode the rules
prevent is a `Bash` call composed in PowerShell idiom, which happens when no `.ps1` is open.

**Nor is there file-triggered content elsewhere in the file that §4's section-level table missed.**
Swept for it rather than assumed: the only file-extension mentions outside this section are at
L34 (`smoke-pages.mjs:246`), L36, L62 and L80 (`map.js:452`), and each is a citation inside a
momentary rule, not a rule with a file trigger `[verified 2026-09-01: grep -noE over lines 1-129
returned 5 hits, all 4 lines read individually; control: the same pattern returns 11 hits inside
§Language & platform conventions, so it fires]`.

**A skill is not the escape hatch either.** §3a's task-triggered class needs the model to recognise
it is starting a kind of work. These rules fire when you do *not* recognise that — the whole point
of L136 is that the wrong idiom is what feels natural. A skill whose description says "before
composing a shell call" depends on the recognition the rule exists to supply. That is the definition
of the momentary class, so the classification is not a routing failure; it is the correct answer.

**What this falsifies, named with its siblings, per the plan-expectations rule.** The premise is
*"the file-triggered lane is the reachable reduction at global scope."* It is false. Resting on it:

1. **§4's table row** — `Language & platform conventions | file-triggered | one file per platform`.
   Wrong classification. The caveat beneath it was right and understated: not *"part of that
   section"*, but all of it bar two half-bullets.
2. **§0 and the status block** — *"Task 4 promoted to the main event."* There is no main event.
3. **§5 Task 8's conclusion** — *"routing whole rules out is the only route that reaches
   [the ceiling]."* Both routes are now closed at global scope: §3b's trim cannot reach 25,000 B by
   Task 8's arithmetic, and §3a's routing has ~600 B of candidates. **The 25,000 B ceiling is not
   reachable by any mechanism in this plan.** That is a finding about the ceiling, not about the
   file — and it is what Task 14 exists to replace, which is now the load-bearing task rather than
   the tidy-up it was scheduled as.

**What survives, and it is not nothing.** The four language skills already carry the file-triggered
content, and L132's pointer is the routing this task was going to perform — done, before the plan
was written, by the reasoning quoted in §3a. The global file's `paths:` lane is real (Task 1) and
now has no cargo at global scope. **Its cargo, if any, is in the project file**, where Hugo
templates, R scripts and workflow YAML are genuinely open at the moment their rules are needed —
so this classification runs again as Task 6's first step, against the project `CLAUDE.md`, and the
move procedure below is retained for it.

### Task 5: Roll the split across the rest of global CLAUDE.md

**Files:** `~/.claude/CLAUDE.md`, one section per pass; `~/.claude/lessons/<slug>.md` for each
relocated evidence block.

**Interfaces:** consumes Task 12's pointer convention — without it a split section's `[[slug]]`
references resolve to nothing and the split is a straight deletion of evidence. Produces entries for
Task 13's miss log to be read against.

**Ungated 2026-09-01, and off the main line.** Per section, same procedure: two classes, proved two
ways, per `refile-rules` §6.

**The only basis on which this gets picked up.** Not "the plan says so" — that gate is gone with
step 5. Pick it up when Task 4 has landed and the budget check still reports over, *and* Task 13's
miss log holds no entries of the form *in context, but trimmed past recognition*. The second
condition is the one that matters: it is the same question step 5 failed to answer, asked of real
misses instead of judged responses, and it costs nothing to wait for.

**Prove each section, not the roll.** `scripts/verify-split.py` proves that every relocated original
survives verbatim, and that property is what makes the single-file model reconstitutable. Run it
per section as you go. Proved once at the pilot and never again, reversibility expires with no
event to notice — the split would still look correct in every diff.

### Task 6: Same for the project CLAUDE.md, plus the repo lesson tier

**Ungated 2026-09-01, and deliberately sequenced last.** **Ask before applying** — the project file
is team-shared and its organization is the team's call. Propose the manifest; do not apply it
unilaterally.

**Last is a decision, not a leftover.** The global tier is one person's file and can be changed and
reverted without consulting anyone; the project file is three people's and spans 20,666–59,726 B
across live worktrees, so a mistake here is a conversation rather than a `git revert`. Run the model
on global for several weeks first, then propose this to the team with a working example and Task
13's miss log in hand, rather than with a spec.

Two things §4 added to this task after the fact:

- **Pick the branch first.** The project file spans 20,666–59,726 B across live worktrees (§1), so
  "the project CLAUDE.md" is not one file. Do the work on the branch that will merge last, or it
  gets done twice and conflicts.
- **Stand up `docs/lessons/` in the repo at the same time**, and move the repo-scoped evidence there
  from `MEMORY.md` rather than leaving it in a machine-local store the team cannot read. That move
  is `reconcile-records`' shape, not `refile-rules`' — content is not just relocating, it is
  changing who can see it — so each entry needs a decision about whether it was ever repo-scoped,
  and the personal ones stay put.

### Task 7: Make the routing rule enforceable at write time

**Files:** `plugins/distill-lessons/skills/distill-lessons/SKILL.md`;
`plugins/refile-rules/skills/refile-rules/SKILL.md`.

**Interfaces:** consumes §3a and §3b. Without this task the files grow back.

`distill-lessons` currently decides *whether* a lesson is a standing instruction. It must also
decide *which tier*, using §3a's four classes, and must split recognition from evidence at
write time rather than leaving a full-evidence bullet for a later `refile-rules` pass to move.

It gains a second decision from §4, and this one is about audience rather than trigger: **is this
lesson repo-scoped?** If it is, it goes in the repo — a `paths:` rule, the project `CLAUDE.md`, or
`docs/lessons/` — and not into `MEMORY.md`, which no teammate can read. The question to ask at write
time is *"would a colleague on a fresh clone need this?"*, and it is answerable without knowing
anything about tiers, which is what makes it a good gate.

`refile-rules` §5 gains the recognition/evidence distinction as a **fourth named permitted edit
shape** beside its existing three, with §3b's test as its bar and its existing rule intact that the
edit is a separate manifest line from the move.

### Task 8: Make the ceiling check mechanical — **DONE 2026-08-29**

**Files:** `scripts/check-memory-budget.sh` and `scripts/test-check-memory-budget.sh`, beside the
existing `scripts/check-versions.sh`.

Report bytes for each always-loaded file against §3c's ceiling, and `MEMORY.md` against both the
200-line and 25KB platform caps. Non-zero exit when a ceiling is passed. The point is not to block
a commit — it is that passing the ceiling surfaces as a routing decision instead of silently.

**Two limits, deliberately not merged.** A **ceiling** is a number §3c chose: passing it costs
tokens in every session and means the next addition should route something out. A **truncation
cap** is the platform's (§2): `MEMORY.md` loads its first 200 lines *or* 25,000 B, whichever
arrives first, and passing it means the tail stops loading while the file on disk still looks
whole. The report prints the line the byte cap actually lands on rather than a line count, because
which cap binds depends on bytes-per-line and for prose indexes it is never the line count — at
EH-dataportal's 178 B/line, 25,000 B arrives at about line 140. "Under 200 lines" is not evidence.

It measures the **current directory's** project, not the repo it lives in, so it can be run from
any worktree, and the project row names the branch it measured — the ceiling is per-branch and the
branch is something you run, not something you read from a stale status block.

**Validated by 11-arm fault injection before any of its passes were believed**, since in this
environment the script prints one `OVER` row and four `ok`s, and an `ok` that has never been
anything else is a dead field rather than a passing one. Every branch is driven to both states with
the exit code checked alongside the text. The arm that makes the rest mean anything is the
all-under one: `HOME` is redirected to a fixture so exit 0 is reachable at all, because against the
real `HOME` the global file is 227% over and no run could ever pass — the success path would have
been permanently unexercised.

**The injection found a real bug, and found it late.** The store directory name folds `:`, `/`
**and `.`** to `-`, and the first ten arms passed against a fold that handled only the first two —
`mktemp` never produces a dotted path, so the sample could not exercise it. The convention that
breaks it is in daily use here: `EH-dataportal.worktrees/` resolves to a store named
`...-EH-dataportal-worktrees-...`, so **every worktree silently reported "no project store"** while
the harness read green. The arms were real; the sample was not. An arm with a dotted path is now
arm 9.

**First sweep, 2026-08-29 — all nine live directories are over budget.**

| directory | branch | project `CLAUDE.md` | always loaded |
|---|---|---:|---:|
| `EH-dataportal` | `feature-pin-action-hashes` | 41,074 (205%) | 111,051 |
| `.worktrees/feature-MOD-Lab-NR-recode-refactor` | `...-merge` | **90,555 (452%)** | **147,391** |
| `.worktrees/feature-smoke-GHA` | — | 41,074 (205%) | 97,910 |
| `.worktrees/content-heat-2024-dw-iframe` | — | 41,074 (205%) | 97,910 |
| `.worktrees/feature-base-control-provenance` | — | 41,074 (205%) | 97,910 |
| `.worktrees/feature-smoke-env` | — | 40,505 (202%) | 97,341 |
| `.worktrees/feature-site-characterization` | — | 35,534 (177%) | 92,370 |
| `.worktrees/feature-new-data-explorer` | — | 20,666 (103%) | 77,502 |
| `claude-skills` | `feature-durable-memory-model` | 1,861 (9%) | 60,603 |

The global file is 56,836 B against a 25,000 B ceiling in all nine, which is the floor every
directory starts from: even `claude-skills`, whose own two files use 9% of their ceilings, begins
at 60,603 B.

**§1's worktree figures are stale, and stale in the direction it predicted.** §1 recorded four
worktrees at 20,666 / 25,198 / 34,207 / 59,726 B. There are now eight plus the main checkout, and
the largest is **90,555 B — up 52% from 59,726 in four days**, on a branch nobody was looking at.
That is exactly the blind spot §1 argued a ceiling had to name a branch to catch, now measured
rather than predicted. Per §1's own instruction the table is a fixed point and is not edited to
match; this script is the re-measurement.

**The ceiling is not reachable by §3b, and this is the sweep's most consequential number.** The
global file must shed **31,836 B** to reach 25,000. The pilot returned 3,040 B, so the target is
**10.5 pilot-sized splits** from a file holding roughly five evidence-dense sections. Applying the
pilot's 26.8% yield to the *entire* file — optimistic, since 3 of its 17 bullets had no evidence to
move and the non-Verification sections are thinner — returns 15,232 B and lands at 41,604 B, still
66% over. **Trimming evidence cannot get there; only routing whole rules out can**, which makes
Task 4's lane and §4's skills route load-bearing rather than complementary. §4 already suspected
this ("if the hypothesis fails, the reachable reduction is roughly the routing lane alone"); the
arithmetic now says it holds whether or not the hypothesis fails.

**Re-run against the 2026-09-01 figures, the conclusion is unchanged and slightly worse.** The
global file is now 62,370 B, so it must shed **37,370 B**; the re-cut pilot returns 4,707 B, so the
target is **7.9 pilot-sized splits** rather than 10.5. Applying the re-cut's 31.9% yield to the
entire file returns 19,896 B and lands at **42,474 B, still 70% over**. Both inputs moved in the
direction that flatters — a bigger pilot yield against a bigger file — and the gap did not close. §1's
table and the sweep table above are fixed points and are not edited to match; this paragraph is the
re-measurement.

```sh
sh scripts/check-memory-budget.sh        ; echo $?   # 0 = all under, 1 = over, 2 = nothing measured
sh scripts/test-check-memory-budget.sh   ; echo $?   # 11 arms; 0 = every arm behaved
```

Chain both with `;`: a non-zero exit is the informative answer.

**Not wired to anything.** Nothing runs this on a schedule or at commit time, so it reports only
when invoked — deliberate, per this task's own "not to block a commit", but it means the ceiling
still surfaces only if someone asks. Giving it a trigger is Task 7's problem, not this one's.

### Task 9: Does an instruction-file edit reach a session that is already running?

**Files:** `scripts/probe-memory-delivery.py` (step 0, **written and run**);
`scripts/capture-proxy.py` (new, step 2 and step 3); this section for the result. Step 1 is manual
and needs no script — the earlier `scripts/probe-edit-propagation.py` line named a file with no
described job and is dropped.

**Interfaces:** consumes nothing — it is answerable today and gates **Task 7**, which decides how
`distill-lessons` writes. It also constrains **Task 3 step 5**: see "Interaction with step 5" below.
Nothing else in this document depends on it.

**Why this gates Task 7 — and it gates the protocol's *shape*, not its existence.** Task 7 makes
`distill-lessons` route a lesson to a tier and split it at write time. Both of those are *file
writes*, and this document has so far reasoned about their cost at session start only.

Both branches below force a write protocol, for opposite reasons, and neither verdict lets Task 7
skip one:

- **Re-read** ⇒ a write perturbs every live session's prefix, so the cost question is live and the
  answer is batching, writing at a boundary, or a lock.
- **Replay** ⇒ a live session holds a stale copy it cannot detect, so a concurrent `distill-lessons`
  pass can write back over a correction another session just made. That is the **lost-update**
  hazard, and it needs read-before-write or a lock — more protocol, not less.

Stated this way so a *replay* verdict does not read as "Task 7 unblocked, nothing to do." It is the
branch with the correctness failure. What Task 9 supplies is which protocol, not whether.

**ANSWERED 2026-08-28 — it is the replay branch, so Task 7 needs the correctness protocol and not
the cost one.** Step 1's result is below. Ordinary turns replay, so no batching, no write boundary
and no lock is needed *for cost*: the write is free to every concurrent session. What is now a
measured hazard rather than a hypothesis is the **lost update** — a session that has not compacted
since the write is reasoning from superseded content and cannot tell, so a second `distill-lessons`
pass can overwrite a correction the first just made. Task 7's write protocol is therefore
**read-before-write on the target file**, or a lock; the observed stale window was ~3 minutes and
two turns, and only a compaction closed it.

**The question, stated so it can come back "no".** Two sessions, both live, both with file X in
context. One edits X. On the other session's next turn, does the request body it sends differ?

Two branches, and they fail in completely different ways — which is the reason this is worth
measuring rather than assuming:

- **Replay** — the harness re-sends the message array it already holds. The edit costs the other
  session nothing, but that session now holds **stale content and cannot tell**. It may reason from,
  or write back, a memory the first session just corrected. A correctness failure, not a cost one,
  and the concurrent writer it threatens is another `distill-lessons` pass.
- **Re-read** — the harness rebuilds from disk at request time. The edit changes the body from the
  injection point down, so the cost is **positional**: content injected early invalidates nearly
  everything, content injected late costs almost nothing. Materially different from the global
  `CLAUDE.md`, which sits in the first user message and therefore always invalidates the whole
  prefix.

**Those two are endpoints, not alternatives, and §2 already rules out the pure-replay end for
instruction files.** §2 quotes the official docs: *"Project-root CLAUDE.md survives compaction:
after `/compact`, Claude re-reads it from disk and re-injects it into the session. Nested CLAUDE.md
files … and rules with `paths:` frontmatter reload as Claude reads files they apply to."* So the
harness demonstrably rebuilds instruction content from disk **at defined events inside a running
session** — a compaction, and a path-glob match. That quote is about `CLAUDE.md` and `paths:` rules,
so it does not by itself settle a memory file, which is step 0's job. What it does settle is that
the machinery exists and has named trigger points: the live question is therefore not *replay or
re-read* but **at which events does it rebuild**, with "every request" and "never" as the ends and
two rebuild events already documented for one file class.

Two consequences, and both change what gets run:

- Replay on an ordinary turn is the *expected* reading, not a finding. A design that stops there
  answers a question already half-answered.
- The Task 7-relevant quantity is the **stale window**: how long a session can hold a superseded
  copy, and which events close it. That is measurable and the binary is not.

So every arm below is sampled **twice** after the edit — once on the next ordinary turn, once after
an event §2 names as a rebuild point. A single post-event read cannot separate "never rebuilds" from
"rebuilds on a trigger that did not fire," which is §Verification's single-point-reading rule on its
time axis.

**Step 0 — establish how X reaches B's context. Free, and it decides whether step 1 can answer.**

X was chosen at "Order, and why the memory file goes first" below on grounds of *consequence* —
correctness failure mode, positional cost, the file `distill-lessons` writes. None of those is a
reason the arm can **discriminate**. That depends on the delivery mechanism, and the two candidates
give opposite answers:

- **Tool result.** §2 quotes the docs: *"Claude reads them on demand using its standard file tools
  when it needs the information."* On that path X is ordinary conversation history. Nothing re-reads
  a past tool result from disk, so arm 1 returns *old* under every hypothesis and step 2 never runs.
  The injection machinery would never have been under test at all.
- **Injected block.** This harness's own memory instructions describe recalled memories arriving
  inside `<system-reminder>` blocks `[first-party, read 2026-08-28 in this session's system prompt]`
  — an injection, not a tool call, and on that path the question is live.

Those two claims are both current and they disagree. **Resolve it before step 1 rather than
assuming it**, and the resolution is free: step 1.1 already requires confirming the recall happened;
record *how*. §0's transcript finding says an injected block is not in the JSONL — but a `Read`
call is.

| Transcript shows | Mechanism | What it means for step 1 |
|---|---|---|
| A `Read` of X | tool result | arm 1 is **void as an injection test**. Add a second X that is unambiguously injected — this repo's project `CLAUDE.md` — and run the arms on that |
| No tool call, B knows X | injected block | arm 1 is live; proceed |
| No tool call, B does not know X | recall never fired | precondition failed; fix the question before editing anything |

Running step 1 without this is the shape §Verification calls *a test run under conditions where the
effect cannot occur* — which is not evidence against the effect.

**Step 0 RESULT, 2026-08-28 — row 1. It needed no session at all.** The population form of the
question is answerable from transcripts already on disk, so this cost one sweep rather than the
session pair the step was scoped for. `python scripts/probe-memory-delivery.py`, re-runnable:

| | |
|---|---:|
| transcripts scanned | 281 (182,561 lines) |
| files that failed to open | 0 |
| lines unparsed | 190 — **174 of them in one file** (`047c3934`) |
| tool calls on memory **topic** files | **233**, across 46 sessions |
| — `Edit` / `Read` / `Write` / `Grep` | 139 / **63** / 30 / 1 |
| tool calls on `MEMORY.md` | 73 |

**63 `Read` calls put row 1 in force**: §2's *"standard file tools"* quote describes something that
demonstrably happens, so a topic file does arrive as a tool result — conversation history, which
nothing re-reads from disk.

**Read this one-directionally, which is the whole discipline of the step.** A non-zero count proves
the file-tool path is real and in use. It does **not** rule out a co-existing injection path, and no
count here ever could: injected blocks are not written to the JSONL (see "What the transcripts
cannot do"), so this instrument is structurally blind to the alternative. Zero would have been the
uninformative outcome; non-zero is the informative one, and that asymmetry is why the sweep was
worth running before the session pair rather than instead of it.

**Consequence for step 1, and it changes which file gets edited.** Arm 1 on a memory topic file is
the void case. Step 1 runs on **this repo's project `CLAUDE.md`** — unambiguously injected, per §2's
first table row. The purpose-made memory file below becomes optional: keep it only to exercise the
write-hazard cell, drop it if step 1 is only chasing the injection question.

**A second finding, free from the same sweep.** 169 writes to topic files (139 `Edit`, 30 `Write`)
across those 46 sessions. That establishes the write path is *frequent* — not that two sessions ever
wrote concurrently, which this cannot see — so Task 7's concurrent-writer scenario is drawn from
live behaviour rather than from hypothesis. The corpus also grows while the instrument runs: two
consecutive runs read 182,540 and 182,561 lines, the difference being the measuring session's own
transcript. Quote these counts with their date.

**Predictions.** Written 2026-08-28 before any arm ran, and **revised 2026-08-28, still before any
arm ran** — no result exists to have been fitted to, which is checkable: no `capture-proxy.py`, no
results file, and §0's Task 9 row reads not started. Two rows changed and the reasons are below the
table. Superseded: row 1 read *old token / new token* on a single added nonce; row 4 read *Parallel
session in a **different repo**, X being project-scoped — old / old*.

| # | Arm | If **replay** | If **re-read** |
|---|---|---|---|
| 1 | B quotes X from context, tools forbidden, **two-sided nonce** | S present, T absent | S absent, T present |
| 2 | B's request body, before vs after the edit | differs **only** in B's own new turn; X's region byte-identical | differs from X's injection point down |
| 3 | New session started after the edit (control) | S absent, T present | S absent, T present |
| 4 | Parallel session in **another worktree of this repo** — *memory-file cell only, see below* | S present, T absent | S absent, T present |

**Arm 3 rules out one explanation, and its stated one is available more cheaply.** "The edit never
landed on disk" is settled by `wc -c`. What arm 3 uniquely rules out is *the harness reads X from a
different path or a cached index than the one you edited* — state it that way, or it reads as
redundant and gets dropped.

**Arm 4 changed cell, because the old one could not be informative.** §2 states auto-memory is
machine-local and *"all worktrees and subdirectories within the same git repository share one auto
memory directory."* A session in an **unrelated** repo never held X, so "old token" there passes
under every hypothesis except a broadcast model nobody has proposed — an arm spent on the cell with
the least information. A **different worktree of this repo** shares the store, so it makes a
non-trivial prediction, and it is the exact configuration Task 7's threat model describes: a
`distill-lessons` pass in one worktree writing a store another worktree's live session is holding.
It is promoted out of step 3's grid for that reason.

**Arm 4 does not survive step 0's move of X, and that is a constraint on the whole design.** Its
entire force came from auto-memory being one *shared* store across worktrees. A project `CLAUDE.md`
is a **tracked file**, so every worktree checks out its own copy — §1 measures four EH-dataportal
worktrees carrying four different sizes, 20,666 to 59,726 B. Editing this worktree's copy cannot
reach another worktree's session under any hypothesis, so on the `CLAUDE.md` run arm 4 is degenerate
in exactly the way the unrelated-repo version was. Do not run it there and read agreement as
confirmation.

So the arms split by file class, and this is the reason to keep the optional memory-file cell rather
than drop it:

- **`CLAUDE.md` run (steps 1-2):** arms 1, 2, 3. Arm 4 is unavailable — no cross-session cell exists
  for a per-worktree tracked file. A session in an unrelated repo can be run as a **scoping assert**
  if you want it, but it is a sanity check on §4, not a finding: it returns "no T" whichever way the
  harness works.
- **Memory-file cell (optional):** the *only* place arm 4 has a non-trivial prediction, because the
  store is genuinely shared. It cannot answer the injection question — step 0 settled that — but it
  is the one configuration that tests cross-session reach directly, and it is Task 7's threat model
  exactly. Run it for arm 4 or not at all.

**Arm 1's negative had four innocent explanations and one control.** For "old token": (1) replay —
the finding; (2) X arrived as a tool result, so injection was never under test; (3) the harness
rebuilds at events and this turn was not one; (4) both copies are present and the model quoted the
staler. Arm 3 kills only (1). Step 0 kills (2), the twice-sampling above kills (3), and the
two-sided nonce below kills (4).

**Step 1 — the correctness arm. No proxy, no measurement, and it runs today.**

0. Pick **S**, a distinctive sentence already in `CLAUDE.md`, and **T**, a nonce token not in it.
   Note the file's byte count.
1. Open two sessions, A and B, in this repo. **Confirm each holds X before editing anything** — ask
   for S verbatim, tools forbidden. Step 0 settled the mechanism (injection at session start), so
   what this confirms is that *these two sessions* actually have it, which is arm 3's precondition
   and the commonest way this design fails silently. A session that cannot quote S is not a control.
2. Edit X **from outside both sessions** — a third terminal, not A and not B — making **two changes
   in one edit**: delete S, add T. Record the wall-clock time and the new byte count.
3. Ask session B what X says, **forbidding tool use in the prompt**, so it must answer from context.
   Ask twice, worded differently. Sample again after a `/compact`.
4. Revert: `git checkout -- CLAUDE.md`, and confirm the byte count matches step 0's.

**Why the nonce is two-sided.** An added token can be supplied by *either* mechanism — a stale copy
does not have it, and a fresh injection does, but so does a fresh injection that arrives *alongside*
the stale copy. A deletion is one-directional: no re-read and no re-injection can supply text that
is no longer on disk, so quoting S is proof of stale context that cannot be manufactured. Together
they turn one guess into a self-diagnosing 2×2 with its own dead-probe cell — the shape Task 3
step 5 already has and this task lacked:

| | **T absent** | **T present** |
|---|---|---|
| **S present** | pure replay | both copies live — stale retained *beside* a fresh one |
| **S absent** | probe dead: B is not answering from X | pure re-read |

The bottom-left cell is the one worth naming: it licenses nothing either way, exactly as `A≈B≈C`
does in Task 3.

**The trap has two legs, and the second is the one the transcript cannot see.** The named leg: B
reaches for `Read` and reports T from disk, which scores identically under both branches — so the
prompt must block tools and the transcript must be checked for a tool call before the answer is
believed. The unnamed leg: asking B about X may itself trigger a **fresh recall injection**, no tool
call, new content. Per §0, injected blocks are not in the JSONL, so *no absence of a tool call
establishes that B answered from pre-edit context*. Step 1 is not fully falsifiable on its own
instrument; the two-sided nonce is what bounds the damage, because that leak lands in the
S-present/T-present cell rather than masquerading as re-read. Same rule as the eval-prompt bullet in
§Verification — do not hand the model the fact under test, and do not let it go fetch it either.

**Read the joint outcome, not four separate arms.** Some combinations are incoherent and mean the
probe is broken rather than answered: arm 3 returning **S present** voids the run (stop — a session
started *after* the edit cannot see deleted text, so the edit is not reaching the harness's read
path); arm 1 reading *pure re-read* while arm 2 shows X's region byte-identical means the
tool-and-injection check failed, not that the harness is inconsistent. Neither is a result.

**Which model runs B — and do not generalize the Haiku line under Cost.** That line scopes Haiku to
**step 3**, on the stated grounds that the question there "is about request bytes and is
model-independent." Step 1 is not that question. Its output is a **model report about its own
context**, and three things in the report are capability-dependent:

- **Obeying "without using any tools"** — the named trap that voids the arm. Weaker
  instruction-following raises the chance B fetches T from disk, which scores identically under both
  branches.
- **Quoting S verbatim** rather than paraphrasing, or a stale copy cannot be told from a
  reconstruction.
- **Reporting a contradiction instead of smoothing it over.** This is the one that decides it. The
  S-present *and* T-present cell requires B to notice two conflicting versions in its own context and
  say so. A model that silently reports whichever it met first collapses that cell into a false
  *pure replay* or a false *pure re-read* — and both look like clean results, so the failure is
  invisible.

**Run B on Sonnet.** Reliable on all three and cheaper than Opus; step 1 has no judgment task
needing the top model. The cost argument for going smaller buys almost nothing — B is ~4 turns on
this repo's ~13K-token always-loaded prefix (§1), which is cents on any model, against a voided run
whose real cost is a coordination round-trip. Keep **Haiku for arm 3**, one near-mechanical turn.

**Optional and near-free:** a second B on Haiku, same prompts, in parallel. Agreement is a
robustness check; disagreement localizes the failure to instruction-following rather than to the
harness, which is worth knowing before building the proxy. Not load-bearing — skip it if the extra
terminal is a nuisance.

**STEP 1 RESULT, 2026-08-28 — the pre-registered binary is false. Replay on ordinary turns, rebuild
at compaction.** X was this repo's `CLAUDE.md`, 1,861 B at `4735508`. S was the second bullet's
bolded opener; T was `NONCE-Q7X4`. Session B ran on **Sonnet**; times are local, transcript
`759b36ac` (UTC, −4).

| Local | Ask | S | T | Reading |
|---|---|---|---|---|
| 23:04:40 | openers list — **pre-edit** | present | — | baseline; B holds X |
| **23:06:40** | **edit lands**, 1,861 → 1,850 B | | | |
| 23:08:38 | openers list again | present | **absent** | **replay** |
| 23:09:35 | second bullet's opener, reworded | present | **absent** | **replay** |
| 23:10:54 | `/compact` | | | summary carries S forward |
| 23:14:54 | full bullet, body demanded | *(in note)* | **present** | **rebuild from disk** |
| ~23:19 | arm 3 — fresh `claude -p`, Haiku | absent | present | control passes |

**Admissible: 0 tool calls across the whole of session B**, checked against the transcript rather
than taken on report — the arm's stated precondition, and the one that voids it silently.

**Observed stale window: ~2m55s across two turns**, closed by the compaction. Nothing here measures
whether it would have expired on its own; it was still stale when the compact ended it.

**Steps 2 and 3 are retired, and by a stronger argument than their gate.** The gate said run the
proxy unless step 1 lands in pure replay. It did — but there is nothing left for the proxy to
measure. Ordinary turns replay, so a write costs other live sessions **zero**. The compaction turn
rebuilds, but it rebuilds whether or not anyone edited, so the marginal cost of the write is zero
there too. **A `distill-lessons` write never costs a concurrent session anything**, at any injection
point, which is the positional-cost question §5 opened with, answered in the negative. Do not build
`capture-proxy.py`.

**§2's compaction quote is now confirmed by observation, not only cited.** The doc's claim that a
`/compact` re-reads the project `CLAUDE.md` from disk is what the 23:14:54 row shows directly.

**The predicted confound landed exactly.** The compact summary carried S forward — B's own earlier
answers — and B's post-compact reply cited "what I quoted earlier in this conversation." So the
S column post-compaction is uninformative by construction and **T is what carried the result**. That
was called before the run, which is the only reason the 23:14:54 row is readable at all.

**Two methodological findings, both worth more than the arm they came from.**

- **The precondition collides with the deletion signal.** Confirming B holds X requires B to quote
  S, which puts S into B's own conversation history — so from the first post-edit ask onward,
  "S present" no longer proves a stale injection. T stayed clean and was sufficient. **Fix: confirm
  the precondition on a *different* bullet than the one you edit.** The procedure above had B quote
  all three openers, which guaranteed the collision.
- **An instruction-shaped nonce trips the model's prompt-injection defenses.** B's reasoning flagged
  `NONCE-Q7X4 replaces this opener for a propagation test` as a possible injection embedded in the
  project instructions, and considered whether to execute or report it. It reported accurately and
  flagged the discrepancy unprompted — arguably better than the design asked for — but that is luck,
  not design. **Make the nonce inert:** a bare token swapped into otherwise natural prose, never a
  sentence that announces itself as a test.

**The Sonnet call is vindicated observably.** The capability the model-choice note said Haiku might
lack — noticing a contradiction rather than smoothing it over — is exactly what B did, in its
reasoning and again in its answer. Had it smoothed, the 23:14:54 row would have read as a clean
single value and the both-copies condition would have been invisible.

---

**~~Step 2 — run it unless step 1 lands in the pure-replay cell.~~ Retired by the step 1 result
above; kept for the reasoning, which still applies if the harness changes.** The gate used to read "only if step
1 says re-read," and that was unsound while the nonce was one-sided: a single added token cannot
tell replay from a stale-copy-plus-fresh-injection, so a false *replay* terminated the whole
investigation. The two-sided nonce is what makes the gate sound — **S present, T absent** is a
trustworthy negative and is the one cell that retires the cost question. The other three all need
the bytes: *pure re-read* to locate the injection point, *both copies live* to see whether the
injected block changed, and *probe dead* because step 1 answered nothing.

Then the instrument is the outgoing request body, not the cache counters. Point `ANTHROPIC_BASE_URL`
at a local logging proxy and diff two consecutive bodies across an edit. This answers directly what
the counters can only imply, because it distinguishes *the file body changed* from *a system-reminder
about the file was injected* — two findings the token counts cannot tell apart.

**Capture a null-edit pair first.** Two consecutive bodies with **no edit between them**, to
establish the natural per-turn diff. Without that baseline every observed difference is
unattributable, and §0 already records ~2K of injected content appearing at a prefix break that the
typed prompt could not account for — so "byte-identical" was never a safe prediction and the arm-2
row above no longer makes it. *"Unchanged" is a null result too, and the comparison is the
instrument.*

**The stub has to be well-formed, or step 2 cannot produce its own pair.** A proxy that logs and
returns nothing costs no tokens — and gets you exactly **one** body, because B's turn then fails and
the session cannot reach the second. The diff needs two successful turns. Return a minimal
well-formed Anthropic-shaped response instead: both turns complete, the session survives, and the
token spend is still zero. Worth stating, because the non-forwarding version is the one the sentence
above describes and it dead-ends at the console.

`ANTHROPIC_BASE_URL`, `HTTPS_PROXY`, `NODE_EXTRA_CA_CERTS` and `DISABLE_PROMPT_CACHING` are all
present as strings in the installed binary `[verified 2026-08-28: 77, 68, 55 and 48 occurrences
respectively, plus 30 for lowercase https_proxy, by grep -oa <name> ~/.local/bin/claude.exe | wc -l]`.
That proves the strings exist, not that any is honoured — the §Verification rule about grep hits
applies to this one too. The arm is self-validating, though: either requests arrive at the proxy or
they do not, and a proxy that logs and returns a stub without forwarding costs nothing at all.

**The counts are method-dependent and the earlier list mixed two methods** — recorded because the
figure is decorative but the mixing is the kind of thing that hardens. This line previously read
*77, 52, 36 and 30*, of which only the first was re-measured; under the single stated method above
the four come out *77, 68, 55 and 48*, so one of four agreed and the list was not internally
consistent with any one method. Nothing downstream turns on the magnitudes — the claim being made is
**presence**, and all five strings are present under both — but quote the command with the number or
the next reader inherits a count they cannot reproduce.

**The built-in request logging looks like it would replace the proxy, and it does not.** Recorded
because it is the obvious thing to try first. Both `ANTHROPIC_LOG=debug` and `claude --debug api`
dump the outgoing request — URL, full headers, timing, and the top-level body shape — and
`ANTHROPIC_LOG=debug` needs no flag alongside it `[verified 2026-08-28 on claude-cli/2.1.227: one
`claude -p` on Haiku, dump present with no --debug]`. But **every field this task needs is elided**:
`messages`, `system` and `tools` render as `[Object ...]` at the inspector's depth limit, so the
dump proves a request was sent and how many system blocks it carried, never what was in them. It
also carries no `usage` block and no cache counters. Shape, not content — which cannot distinguish
a changed file body from an injected notice about the file, the one distinction step 2 exists to
make. Use it to confirm a request fired; use the proxy for the bytes.

Three practical notes on it, since they cost a run each to establish `[all verified 2026-08-28]`.
It writes to **stdout**, not stderr (stderr was 0 B on a split-stream run), which is the likely
reason it seems inert in the interactive TUI — that owns stdout — though this was checked under
`claude -p` and not by driving the TUI. `--debug-file` does **not** capture it: that file receives
the internal `[DEBUG]` startup stream instead, and the API dump still goes to stdout. And it
**breaks `--output-format json` and `stream-json`** by prepending non-JSON to stdout — a parse
failure on the first character. That last one is a live hazard for `scripts/measure-rule-firing.py`,
which reads `stream-json`: if `ANTHROPIC_LOG` is set in the environment when step 5 runs, every
probe response parses as empty and the arms come back indistinguishable, which reads as `A≈B≈C`
— "the probe is dead" — rather than as a broken harness. The script now strips it from the child
environment (`STRIP_ENV`), so this needs no action before a step-5 run.

**One thing it does buy, and it is one-directional.** The dump reports how many system blocks a
request carried. A **change** in that count across an edit is positive evidence that the injected
set moved, obtainable without building anything — so it is worth reading as triage before the proxy
exists. **No** change is uninformative: it cannot see a content change inside an existing block,
which is the likelier shape. A cheap yes, never a trustworthy no.

**Step 2 introduces a second variable with the step-5 failure signature, and `STRIP_ENV` does not
cover it.** `measure-rule-firing.py` strips `CLAUDECODE` and `ANTHROPIC_LOG`. Step 2 deliberately
sets `ANTHROPIC_BASE_URL` (and possibly `HTTPS_PROXY`); if either is still exported when step 5
runs, its 30 probes go to the stub proxy, every response comes back empty, and the arms are again
indistinguishable — `A≈B≈C`, "the probe is dead," from a live harness pointed at a stub. Identical
signature, different cause, and it only exists because Task 9 exists. **Closed 2026-08-28:**
`STRIP_ENV` now holds `CLAUDECODE`, `ANTHROPIC_LOG`, `ANTHROPIC_BASE_URL`, `HTTPS_PROXY` and
`https_proxy`. Both proxy spellings, because both occur in the binary and the cost is asymmetric —
stripping one that is ignored costs nothing, missing one that is honoured costs a 30-probe run.

**Step 3 — scope expansion, only if step 2 says re-read.** Then, and only then, enumerate the
cells: sessions in the same repo, in a worktree of it, and in an unrelated repo, crossed with global
`CLAUDE.md`, project `CLAUDE.md`, `MEMORY.md`, and an individual memory file. Do not run this
grid first. Most of its cells are determined by step 1, and the **unrelated-repo** row is predicted
null by construction — that session never held the content — which makes it a control rather than a
finding. The **worktree** row is no longer in this grid: it is arm 4, promoted because it is the one
cross-session cell where the shared-store scoping makes a non-trivial prediction.

**~~Order, and why the memory file goes first.~~ Retired by step 0's result.** The argument was that
X should be an individual memory file, because it is the only one of the four with a correctness
failure mode, its cost is positional rather than fixed, and it is the exact file `distill-lessons`
writes — the likeliest to bite and the one whose answer changes Task 7. Every clause of that is
about what the answer would *mean*, and none establishes that the arm can produce an answer. Step 0
measured the missing half: the topic file arrives by file tool, so it is the one file class on which
arm 1 **cannot** discriminate.

**X is the project `CLAUDE.md` of this repo.** Injected at session start per §2's first table row,
so the question is live on it; small, so a nonce edit is easy to place and revert; and repo-scoped,
which keeps arm 4's worktree cell meaningful. The consequence argument above still holds for the
memory file — it is simply not answerable by this arm, and Task 7 inherits its write hazard from
step 0's 169 measured writes instead.

**Whatever X is, treat it as live environment state.** §0 tracks every other piece of live state on
this machine with a restore recipe — the `InstructionsLoaded` hook, `~/.claude/lessons/`. A
nonce-edited instruction file is a third with none, and this one is *tracked*, which the other two
are not: X is now the repo's project `CLAUDE.md`, so the nonce edit shows up in `git status` and a
stray `git add -A` commits it. Requirements before step 1 runs: **branch or stash-and-restore rather
than editing in place on a branch you intend to commit**, and **note the edit in §0's live-state
block** with the command that reverts it — `git checkout -- CLAUDE.md` is the whole recovery, which
is a reason to prefer the tracked file over an untracked one. If the optional memory-file cell is
also run, use a **purpose-made** memory file rather than a real one, so a failed restore cannot
corrupt a rule something depends on.

**Interaction with step 5.** Task 3 step 5 swaps three arms over the live `~/.claude/CLAUDE.md` and
restores in a `finally`. Under the re-read branch that perturbs every live session for the duration
of the run, and a hand edit landing mid-run is written onto an arm and lost at the restore. Run step
5 with no other sessions live, whichever way Task 9 comes out.

**What the transcripts cannot do, recorded so nobody spends the afternoon on it again.** The
injected instruction blocks are not stored in the session JSONL: on this session every `claudeMd`
and `system-reminder` hit was assistant text from the conversation itself, not the real injection
`[verified 2026-08-28: parsed the message content of every record in 4489d30b's transcript]`. So the
transcript records neither the block nor its changes, and cannot discriminate the two branches at
any sample size. This is the same wall §0's unexplained-re-render note hit. Steps 1 and 2 are the
way through it.

**What it *can* do, which the paragraph above overstated away.** A tool call **is** in the JSONL.
That is a different question from "what did the injected block say," and it is the one step 0 asks:
present `Read` of X means the tool-result path, absent means the injection path. The transcript is
useless for the block's *content* and sufficient for the *mechanism* — do not let the first fact
retire the second, which is what "cannot discriminate at any sample size" invites.

**Cost.** Step 0 is one transcript grep, free. Step 1 is now six short turns rather than four —
two recalls, one edit, two differently-worded questions, one post-`/compact` resample — and still no
measurement and no spend. Step 2 costs no tokens *if the stub is well-formed*; the earlier "free if
the proxy stubs rather than forwards" undercounted, because a non-forwarding stub yields one body
and the diff needs two. Building the proxy is the real cost of step 2, and the parallel session's
finding above is what makes it unavoidable: the built-in dump elides `messages` and `system`, so
there is no cheaper instrument to fall back on. Step 3, if it is ever reached, runs on Haiku with
one- and two-turn sessions, because the question is about request bytes and is model-independent; at
§1's measured 43,380-token prefix a full rewrite is a few cents, so the grid is order $1.
*Estimated from §1's baseline, not measured — and §1's baseline is itself now stale (see the status
line).*

**Design review, 2026-08-28 — what changed and why, before any arm ran.** A review pass over the
arms, tests and predictions, run against the working tree including the parallel session's
built-in-logging findings. Seven changes, in the order they matter:

1. **Step 0 added.** X's delivery mechanism was never established, and §2's own quote predicts the
   tool-result path — on which arm 1 cannot discriminate and the gated step 2 never runs.
2. **The binary is false and §2 holds the counterexample.** Compaction and path-glob matches are
   documented rebuild events, so the question is *which events*, and every arm is now sampled twice.
3. **Two-sided nonce.** Deletion is one-directional and an addition is not; the 2×2 gives arm 1 a
   dead-probe cell and makes step 2's gate sound, which it was not before.
4. **Arm 4 moved** from an unrelated repo, where its prediction was degenerate, to another worktree
   of this repo, where the shared store makes it non-trivial and Task 7's threat model lives.
5. **The Task 7 gate is two-branch.** Replay is the branch with the lost-update hazard; the old
   wording named only re-read as forcing a protocol, which let a *replay* verdict read as "nothing
   to do."
6. **Arm 2's prediction weakened** from "byte-identical" — §0 already records unexplained injected
   content at prefix breaks — and given a null-edit baseline.
7. **A joint reading rule**, a named X with a restore recipe, and the `ANTHROPIC_BASE_URL` /
   `STRIP_ENV` hazard that step 2 creates for step 5.

The parallel session's finding changed one thing beyond its own paragraph: it retired the cheap
alternative to the proxy, which strengthens the case for building one but does **not** reorder the
steps. The two-sided nonce is what licenses keeping step 1 ahead of step 2 — with the old one-sided
nonce the gate was unsound and the proxy should have run first.

### Task 10: Put `~/.claude` under version control

**Files:** `~/.claude/.gitignore` (new); the initial commit of `~/.claude`.

**Interfaces:** blocks Tasks 4, 5 and 12 — each moves or deletes content in a tree that currently
has no history. Produces the pre-migration baseline every later task's revert depends on.

**Why this is first, and not housekeeping.** The whole model rests on being able to reconstitute the
single-file version later. Today that promise has nothing behind it: `~/.claude` had no repository
until 2026-09-01 `[verified 2026-09-01: git rev-parse --is-inside-work-tree in ~/.claude returned
"fatal: not a git repository"; control: the same command in this repo returns "true"]`, the 19
lesson files carrying the pilot's relocated evidence have no history and no backup, and §0's own
undo recipe is `rm -rf ~/.claude/lessons/`, which would take the evidence and leave the trimmed
rules standing. Commit before anything moves, so the initial commit *is* the baseline.

**DONE 2026-09-01 — `fe46278`, in the `~/.claude` repo rather than this one.** 30 paths, 57.84 KiB
tracked against a 313 M directory, working tree clean, no CR bytes. What follows is the record of
what was decided and how it was checked, not work outstanding.

The state this closed was the dangerous one, not a finished one: `git init` run, nothing committed,
no `.gitignore` — a bare `git add -A` would have committed 242 M of session transcripts and a
credentials file.

Measured composition, 2026-09-01 (`du -sh */` and `ls -la`):

| Path | Size | Track? |
|---|---:|---|
| `projects/` | 242 M | **No** — every transcript ever produced, including anything pasted into a session |
| `file-history/` | 31 M | **No** — editor undo state |
| `plugins/` | 27 M | **No** — installed from marketplaces, reinstallable |
| `debug/` `shell-snapshots/` `telemetry/` `cache/` `uploads/` `sessions/` `session-env/` `backups/` `daemon/` `ide/` `jobs/` | ~12 M | **No** — churn |
| `.credentials.json` | 562 B | **No — a secret** |
| `history.jsonl` `stats-cache.json` `.last-*` `*.bak-*` | ~90 K | **No** — machine state and one-off backups |
| `CLAUDE.md` | 62,370 B | **Yes** — the file this whole plan is about |
| `settings.json` | 7,415 B | **Yes** — carries the hooks and permissions. Scans clean: `grep -inE 'token|secret|key|password|api[-_]?key|bearer'` returns nothing `[2026-09-01]` |
| `lessons/` | 84 K | **Yes** — the lazy evidence tier |
| `hooks/` `skills/` `output-styles/` | ~40 K | **Yes** — authored content |
| `scripts/` | 184 K | **Yes, except `*.exe`** — the debug wrapper's source is already tracked in this repo (`1553b2e`); the binary is a build artifact |
| `plans/` | 222 K | **No** — harness-assigned scratch. `~/.claude/CLAUDE.md` §Plan mode already says a plan that outlives the sitting belongs in the repo that owns the work |

Allowlist rather than blocklist, so a directory the harness adds next month is ignored by default
instead of committed by surprise:

```gitignore
# Ignore everything at the top level, then re-include what is worth keeping.
# Allowlist, not blocklist: a new harness directory is ignored until named here.
/*

!/.gitignore
!/CLAUDE.md
!/settings.json
!/hooks/
!/lessons/
!/rules/
!/skills/
!/output-styles/
!/scripts/

# Build artifact; its source is tracked in claude-skills (1553b2e).
/scripts/*.exe
```

`/*` matches only top-level entries, so re-including a directory re-includes its contents.
`.credentials.json` is covered by `/*` and is never re-included.

**Proof, as an end state rather than a file list.** Two greps and a control, joined with `;` —
`grep -c` exits non-zero on its informative answer:

```sh
cd ~/.claude
git add -A --dry-run > /tmp/staged.txt 2>&1; echo "exit $?"
grep -cE 'projects/|file-history/|plugins/|\.credentials\.json' /tmp/staged.txt   # expect 0
grep -cE 'CLAUDE\.md|lessons/|settings\.json' /tmp/staged.txt                     # positive control: expect > 0
```

The second grep is not decoration. The first is a null, and a null from an empty dry-run file and a
null from a correct `.gitignore` are indistinguishable — the control is what separates them. Then
commit, and confirm the repository is the size the allowlist implies rather than the size of the
directory: `git count-objects -vH` should report single-digit MB, not 313 M.

**One decision left open, deliberately.** This repository has **no remote**, and nothing here needs
one — the baseline does its job locally. If one is ever added, the tracking set changes what that
means: `settings.json` carries machine paths, enabled plugins and marketplace repos, and
`CLAUDE.md` and `lessons/` carry work detail. None of it is a secret, and all of it is personal.
That is a push-time decision, not a tracking-time one, and it is recorded here so it gets made
rather than defaulted into.

### Task 11: Test the routing rule's boundaries before rolling it out

**Files:** none changed. Produces a written result in this section.

**Interfaces:** gates Task 7 — Task 7 writes §3a's routing table into `distill-lessons`, and an
untested table is one every future pass files against by feel. Consumes §3a and §4's destination
list.

**What this measures, and why it is not the question step 5 was asking.** Step 5 asked whether a
trimmed rule still fires. This asks whether a *future pass can predict where a rule goes*. Both
affect retrieval; only the second is cheap, and only the second gets worse silently with every entry
filed across an ambiguous boundary. The destination count goes from 3 (CLAUDE.md / memory /
nowhere) to 7: always-loaded `CLAUDE.md`, `~/.claude/rules/` with `paths:`, a skill,
`~/.claude/lessons/`, the per-project memory store, repo `docs/lessons/`, and nowhere.

`refile-rules` §3 already carries the instrument; it applies to tiers as written:

> Take four or five entries already in the file. From the **destination names alone**, predict which
> tier each one lives in. Then check.

**Sampling, which is where this test can go wrong.** §3's own warning is that predicting on entries
you just wrote measures memory of the session, not the file's structure. Two constraints follow:

1. **Exclude the pilot section entirely.** It has been re-cut three times on this branch; every
   bullet in it is remembered rather than predicted.
2. **Pick mechanically, not by choosing** — every 12th bullet of the remainder. Choosing is how the
   easy ones get sampled.

**Pre-registered failure criterion, written before the run:** 2 or more of 5 unpredictable, or any
two destinations that both attract the same entry, means the routing rule is not real yet. The fix
is to merge destinations before Task 7 writes them down, not to invent a distinction that explains
the split — `refile-rules` §3 names that reflex, and an invented distinction is usually how the
overlap arrived.

**Pre-registered no-power condition:** if all 5 sampled entries land in the same destination, the
test exercised one boundary and separates nothing. Report **no power** and redraw to span at least
three destinations. A no-power run and a clean pass look identical afterwards, and the clean pass is
the one that gets reported.

**The likeliest finding, named in advance so it is not a surprise.** `~/.claude/lessons/` and the
per-project memory store are two lazy evidence tiers with overlapping purpose and different index
mechanisms. §4 gives a real reason for files-over-skills — *"a plain file at a known path"* — but
says nothing about which of these two lazy stores an entry belongs in. If the test finds that
boundary unpredictable, the answer is a stated rule (personal-and-cross-project vs. repo-scoped is
the candidate), not a new tier.

#### Result, 2026-09-01 — and the test found a defect in its own design first

**Sample.** 58 entries outside the pilot section (§Verification → Validating the instrument, lines
31-55, excluded because this branch re-cut it three times). Step 11 rather than the 12 written
above: 58/12 yields four samples, not five, and fudging the offset to reach five would be choosing.
Offsets 11/22/33/44/55 give file lines **27, 77, 93, 107, 146**, spanning five different sections.

**One instrument error, caught and corrected before it produced a result.** The first draw ran
`grep -n` over an `awk`-filtered stream, so its line numbers indexed the *filtered* stream and named
five unrelated entries — one of which was a `##` heading, which is the tell. Filter by line number
after grepping the original file, never grep a filtered stream and read its numbers as file lines.

**Finding 1, structural, and it outranks the sample: the seven destinations are two axes, not one.**
Every entry answers two independent questions —

- **rule tier:** always-loaded `CLAUDE.md` / `~/.claude/rules/` with `paths:` / a skill / nowhere
- **evidence tier:** `~/.claude/lessons/` / the per-project memory store / repo `docs/lessons/` / none

— and under §3b a rule that *stays* always-loaded still produces an evidence destination. So "two
destinations attract the same entry" is true of **every** entry by construction, and the failure
criterion above would have tripped vacuously five times out of five. The defect traces to §3a's
table, which lists **Evidence** as a fourth class beside file-triggered, task-triggered and
momentary, as though it were a peer. It is not a peer; it is the other axis. **Task 7's routing
table must ask two questions, not one** — that is this task's main deliverable to it.

**Finding 2, rule axis: NO POWER, by the condition pre-registered above.** All five classify as
*momentary → stays*, and four of the five are forced rather than close. The one non-forced call is
L27 (*a green check is a fact about a commit*), whose action mentions a ledger and could argue for
the `keep-ledger` skill; the moment of need is broader than that skill's trigger, so it stays.

The pre-registration says to redraw across three destinations. **The redraw would fail, and that is
the result rather than an obstacle.** Task 4 step 1 established the `paths:` destination has no
cargo at global scope; the skill destination already holds the four language skills, whose content
left this file before the plan was written. At global scope the rule axis is **degenerate, not
ambiguous** — one live destination. A boundary cannot be unpredictable when there is nothing to
choose between, so the rule axis needs no fix and Task 7 can write it down as it stands.

**Finding 3, evidence axis: the failure criterion is tripped, four times.**

| Entry | Evidence today | Plausible destinations |
|---|---|---|
| L27 green check vs. branch | the 2026-08-20 `merge/production` incident, uncited | `~/.claude/lessons/`, EH store, EH `docs/lessons/` — **three** |
| L77 outside-repo claims need a source | self-contained; nothing to file | none — not applicable |
| L93 prefix rewrite: read `cache_miss_reason` | `cache-prefix-rewrite-investigation`, **`claude-skills` store** | that store, or `~/.claude/lessons/` — **two** |
| L107 never write a record's own commit state | `feedback-existing-ledger-is-not-current`, **`EH-dataportal` store** | that store, or `~/.claude/lessons/` — **two** |
| L146 join with `;` not `&&` | `feedback-verify-my-own-verification`, **`EH-dataportal` store** | that store, or `~/.claude/lessons/` — **two** |

`[verified 2026-09-01: grep -oE '`[A-Za-z-]+` project store' per sampled line; L93 returns
claude-skills, L107 and L146 return EH-dataportal, L27 and L77 return nothing]`

**Three global rules cite evidence in two different project memory stores, and none cites
`~/.claude/lessons/`** — the tier §3b creates for exactly this. That is the overlap predicted
above, observed, and worse than predicted: it is not two tiers competing but three, one of them
instantiated twice.

**The fix is a stated rule, not a merge, because the tiers differ in who can read them.** Merging
would destroy a real distinction: `~/.claude/lessons/` and the memory stores are machine-local,
`docs/lessons/` is in the repo and visible to the team and to a fresh clone. Two questions settle
it, in this order, and both are answerable without knowing anything about tiers:

1. **Would a colleague on a fresh clone need this?** Yes → repo `docs/lessons/`. This is Task 7's
   audience gate, already written; it separates the repo tier from the two local ones and nothing
   more.
2. **Is the rule that cites it global or project-scoped?** Global → `~/.claude/lessons/`.
   Project → that project's memory store.

Rule 2 is what was missing, and it is derivable rather than chosen: only one memory store loads per
session (§4), so a global rule's evidence in a project store is unreachable from every other
project. The existing global CLAUDE.md rule — *"every citation names the project store that owns
it"* — is a mitigation for that, not a routing rule, and L93/L107/L146 are the drift it mitigates.

**Not fixed here.** Re-homing those three citations is a `reconcile-records` pass over the whole
file, not five sampled lines, and it is not on this plan's main line. Recorded so it is not
rediscovered: **the sweep is "every global rule citing a project store", and the sample says the
rate is 3 in 5.**

### Task 12: Make the lazy tiers reachable

**Files:** `~/.claude/CLAUDE.md` — one line, added near the top; `~/.claude/lessons/` — read only,
to check the slugs resolve.

**Interfaces:** blocks applying any split, Task 5 included. Consumes nothing.

**The gap is not that `[[slug]]` is undefined. It is that it is already defined, and resolves
somewhere else.** `docs/task-3-section-after.md` carries **19** `Evidence: [[slug]]` pointers.
The harness's own memory instructions define that exact syntax for a different store — *"link to
related memories with `[[name]]`, where `name` is the other memory's `name:` slug"* — meaning a
file in the per-project auto-memory store, and it is in live use there: **22 `[[slug]]` links
across this project's memory store** `[verified 2026-09-01: grep -ro over
~/.claude/projects/c--Users-Chris-Documents-Projects-claude-skills/memory returned 22, resolving to
that directory's own files]`. Nothing in `~/.claude/CLAUDE.md` re-points the syntax at the lessons
directory; that file contains **no `[[` at all**, and mentions `lessons` once
`[verified 2026-09-01: grep -c on both; control: grep -c 'Verification' on the same file returns 5,
so the file is being read]`.

So a reader following `[[git-diff-no-index-long-path]]` has a convention that tells them to look in
the project memory store, where the file does not exist `[verified 2026-09-01: 0 of the 19 lesson
slugs resolve to a file in that store; control: effort-switch-cache-lineages.md, a slug that does
resolve there, is found by the same test]`. §4's justification for files-over-skills is
that *evidence does not need finding, because the rule that cites it names it*. A slug under a
colliding convention does not name it.

**The fix is to stop using the wikilink for this, not to disambiguate it.** Write the path:

> Evidence: `~/.claude/lessons/git-diff-no-index-long-path.md`

**This is cheaper than the alternative I first drafted**, which was one always-loaded sentence
defining the convention. Costs, both measured against the pilot's 4,707 B saving: writing the path
adds 16 B per pointer × 19 = **304 B, 6.5% of the saving**, and needs **zero** always-loaded bytes.
The convention line would have cost ~44 tokens of always-loaded space
`[at ~/.claude/CLAUDE.md §Effort's 1.45 tokens/word]` *and* left two conventions sharing one syntax.
A path needs no convention, no index, and no disambiguation, and it survives being pasted into a
context that never read the definition.

**No index file either.** `ls ~/.claude/lessons/` is the index. A maintained index is a second thing
that must be kept true, and a stale one answers "is this covered?" with a confident wrong no.

**Proof: enumerate and compare, never grep once per expected slug.** A per-slug grep cannot return a
slug nobody named, and that failure has no error to notice — `~/.claude/CLAUDE.md` §Validating the
instrument names this exact shape.

```sh
grep -o 'lessons/[a-z0-9-]*\.md' docs/task-3-section-after.md | sed 's|.*/||;s|\.md$||' | sort -u > /tmp/cited.txt
ls ~/.claude/lessons/ | sed 's/\.md$//' | sort -u > /tmp/present.txt
diff /tmp/cited.txt /tmp/present.txt; echo "exit $?"    # expect no output, exit 0
wc -l /tmp/cited.txt /tmp/present.txt                   # expect 19 and 19; a 0 means the extractor broke
grep -c '\[\[' docs/task-3-section-after.md             # expect 0 once converted — no wikilinks left
```

The `wc -l` is the positive control: an empty `cited.txt` diffs clean against an empty
`present.txt`, and that passes while proving nothing.

### Task 13: Close the loop from use

**Files:** `plugins/distill-lessons/skills/distill-lessons/SKILL.md` §4;
`plugins/refile-rules/skills/refile-rules/SKILL.md` §1 and §2;
`~/.claude/hooks/lessons-gate.sh`; `~/.claude/lessons/misses.md` (new).

**Interfaces:** consumes Task 11's boundary result and Task 12's pointer convention. **This is what
replaces step 5** — the instrument that says whether the model is working, drawn from use rather
than from judged responses. Produces the input Task 14 reads.

**Four edits. The third is the one that makes the other three worth anything.**

**1. `distill-lessons` §4 gains a differential under "does a rule for this already exist?"** Its
current text assumes the answer — *"the rule is written, it was loaded, and it did not fire"* —
which was safe under one always-loaded file and is an assumption with three ways to be wrong once
rules are split across tiers. Three rows, not four: a compaction-dropped `paths:` rule shares its
repair with a never-loaded one and is close to undiagnosable in practice, so it is folded in rather
than given a row of its own.

| Why it missed | How to tell | Repair |
|---|---|---|
| Never in context | its tier was never summoned: no `Skill` call, no `Read` on the lesson file, no `path_glob_match` in the `InstructionsLoaded` log for its `.claude/rules/` file | wrong tier. Hand to `refile-rules`; leave the wording alone |
| In context, but trimmed past recognition | the vocabulary that would have matched this situation is in the rule's `~/.claude/lessons/` file, not in the surviving line | restore those specifics to the loaded line — the split took a recognition specific for an evidence one |
| In context, intact | neither of the above | narrow it until a command can check it, per the table already in §4 |

**"Was it in context" is asked first, because it is the only one with a mechanical answer.** For a
`CLAUDE.md` or a `.claude/rules/` file, `grep '<filename>' "$LOG"` on the `InstructionsLoaded` log
and read `load_reason`. For a skill or a lesson file there is no hook — the evidence is this
session's own `Skill` or `Read` call. Either way the answer is a null, so before reporting *never
loaded*, run the same grep against a file known to have loaded this session.

**2. `refile-rules` §2 gains a fifth finding**, and §1's second unprompted trigger splits in two.
The finding: *a rule sits in a tier that is never summoned for the situations it covers* — the
mirror of §2's existing "content in the always-loaded tier that has a perfectly good trigger
elsewhere", and the one the routing rule itself produces. §1 currently routes every failed-to-fire
handoff to the same place; only *never in context* is a move. *In context, intact, and not
narrowable* is retrieval. *Trimmed past recognition* goes back to `distill-lessons` — it is an edit
to one entry, not a structural finding.

**3. `~/.claude/lessons/misses.md`, one line per miss.** This is the part I would not skip. A
diagnosis written into each rule's own evidence file cannot be counted, and 3 of the pilot's 22
bullets have no evidence file at all — they are the judgment-shaped rules, the ones most likely to
miss. One miss is an anecdote. Six misses that all read *never in context, on a skill* is a verdict
on the routing rule rather than on six rules, and only a single file makes that visible.

```
| date | rule (first ~6 words) | tier it lives in | why it missed | repair applied |
```

After ten entries this is the only evidence about the model that came from use rather than from a
judge. Three entries against one rule is a `refile-rules` trigger on its own.

**4. Give `check-memory-budget.sh` a trigger it does not depend on being remembered.** It is the one
instrument here that costs nothing per run, and today it fires only if someone thinks of it — the
left-hand column of `distill-lessons`' own table. `~/.claude/hooks/lessons-gate.sh` is already a
registered `Stop` hook that nudges after 8 commits `[verified 2026-09-01: registered in
settings.json; threshold CLAUDE_LESSONS_COMMIT_THRESHOLD, default 8]`, which fires at precisely the
right moment — a batch of work has landed and a lessons pass is about to run. Emit the budget line
in that nudge. Chain with `;` and not `&&`: the script exits non-zero on its informative answer.

**Version bump.** Editing two `SKILL.md` files means two `.claude-plugin/plugin.json` manifests plus
two frontmatter `version:` fields, which drift in both directions. Run `sh scripts/check-versions.sh`
before committing; chain it with `;`, since a mismatch is its informative non-zero answer.

### Task 14: Replace the chosen ceilings with a saturation reading

**Files:** §3c's ceiling table; `scripts/check-memory-budget.sh` ceiling constants, once there is a
number to put in them.

**Interfaces:** consumes Task 13's miss log and the per-pass record below. Deliberately last: it has
nothing to read until the model has run for several `distill-lessons` passes.

§3c's three ceilings are, in its own words, *chosen, not derived*, and Task 8 showed the global one
unreachable by the mechanism that was supposed to reach it. The replacement is already named in
§3c and comes from `align` (§7): **saturation.** If N consecutive `distill-lessons` passes add no
rule that fires on a situation the store did not already cover, the always-loaded tier is saturated,
and the right ceiling is roughly where it sits.

**The datum is already produced for free.** `distill-lessons` §4 opens with *"does a rule for this
already exist?"*, so every pass answers this about every survivor. Record one line per pass —
date, survivors, how many covered a genuinely uncovered situation — at the bottom of
`~/.claude/lessons/misses.md`, so both series live in one file.

**N is a free parameter, so it gets the treatment §3c's own numbers did not.** Do not pick N in
advance and do not defend one. Collect at least ten passes, then report the observed run-length
series read at **N = 3 and N = 5**, per `~/.claude/CLAUDE.md` §Validating the instrument: a derived
structure is a function of the choices that produced it, and a stopping point visible at one setting
can vanish at another. If the two settings disagree, the honest report is *setting-dependent* and
the ceilings stay placeholders for longer.

---

## 6. Considered and rejected

- **`@path` imports to split CLAUDE.md.** Imported files load at launch. Documented explicitly.
  Buys organization, zero context.
- ~~**A second pointer index in the project CLAUDE.md.**~~ **Reversed 2026-08-25, see §4.** The
  argument was that `MEMORY.md` is already one, with an automated write path, so a parallel index
  costs always-loaded bytes to duplicate an existing tier. What it missed: auto-memory is
  **machine-local**, so the tier it "duplicates" is invisible to the team, to a fresh clone, and to
  a cloud session. A repo-scoped lesson belongs in the repo. `MEMORY.md` keeps the personal ones.
- **A hand-built pointer index for global scope** — hooks in `~/.claude/CLAUDE.md` pointing at
  `~/.claude/lessons/*.md`. Superseded, not wrong: a user-scope **skill** is the same mechanism with
  the same always-loaded cost (name + description) and better matching. §4.
- **A vector/BM25 memory server** — `agentmemory` claims 92% fewer input tokens per session and
  95.2% recall on LongMemEval-S `[vendor's own figure, agent-memory.dev, read 2026-08-25]`. It
  solves session-transcript recall, not durable hand-distilled rules, and adds a running process
  and an index to keep true. The corpus here is ~60 rules, not 50,000 turns.
- **Session-capture systems** — `claude-mem`, `dpt-plugins/remember`,
  `coleam00/claude-memory-compiler`. All capture transcripts automatically and answer "what did we
  do yesterday". The problem here is the opposite: too much already-distilled durable content,
  not too little raw history.
- **`~/.claude/rules/` without `paths:`.** Loads at launch at the same priority as CLAUDE.md.
  Moving content there changes the filename and nothing else.

## 7. Prior art worth reading

- `wrsmith108/claude-md-optimizer` — the closest existing thing. Three tiers
  (Essential / Reference / Redundant); refuses to run if >80% is Essential. Its one transferable
  finding is the **rich abstract**: *"how you write a reference matters as much as whether you
  extract it"* — a pointer carrying concrete facts (framework names, thresholds) let agents answer
  without following the link, cutting sub-document reads from 5 files to 2 on open-ended tasks.
  That is the same shape as §3b's recognition inventory, arrived at independently. It also states
  plainly that `loading_strategy: lazy` is *"unimplemented or aspirational as of 2026"*.
- `daymade/claude-code-skills` → `claude-md-progressive-disclosurer`. Same job, one-shot
  refactoring pass. Its stated principle is worth keeping: *"maximize LLM working efficiency, not
  minimize line count."*
- **`ggrigo/align`** — closest on the *capture* side, and the one with something this spec is
  missing. Three commands: `/align` extracts the claims from an output into a form you rate
  per-claim, `/retro` synthesizes the archive into failure patterns and proposed patches, and
  `/diagnose` *"trace[s] each wrong claim back to the stale instruction that caused it"*.

  That last one **inverts the loop this repo runs.** `reconcile-records` sweeps a store for what
  went false; `align` starts from an observed failure and finds the rule to blame. Three things are
  worth taking:

  - **The `/diagnose` direction is the firing instrument §3b needs.** §3b's whole risk is that a
    trimmed rule still reads true and silently stops firing — which is exactly the failure a
    from-the-output trace detects and a from-the-store sweep cannot. Task 3 currently plans to
    measure firing with `scripts/run-trigger-evals.py`; the diagnose shape is the other half, and it
    works on real sessions instead of on eval phrasings.
  - **The six-shape rating taxonomy** — `correct / wrong / almost / needs-nuance / can't-verify /
    skipped` — because it is what makes per-claim rating cheap: *"the 6-shape taxonomy … is what
    lets per-claim work in 2 minutes."* `can't-verify` is the one this repo's vocabulary lacks and
    keeps needing.
  - **The saturation heuristic**, already borrowed into §3c: *"if ~20 new traces don't surface a new
    failure category, the corpus is saturated."*

  Its storage split (`CLAUDE.md` for generic preferences, `TASKS.md` for task-level corrections, a
  `decisions` collection for specific facts) is §3a's classes arrived at independently, which is
  mild evidence the taxonomy is real and not an artifact of how this file happens to be organized.
  No comparative accuracy metrics are published.

- **`az9713/claude-code-continual-learning-skills`** — lessons stored as skill files under
  `~/.claude/skills/`, retrieved by description matching, written by a `/retrospective` command with
  *"automated reminders prompted before ending substantive sessions"* — the same Stop-hook shape as
  this machine's `lessons-gate.sh`.

  **This is the answer to §4's global-scope gap, and it retired a task.** The spec was going to
  hand-build a pointer index in `~/.claude/CLAUDE.md`; a skill is that index, with harness-side
  description matching instead of the model happening to read a hook line. Its stated principle —
  *"Progressive Disclosure: only loads context when needed"* — is §3a's routing rule under another
  name. No token or firing-rate measurements are claimed, which is the part still missing.

None of these carries a measured firing-rate result — including the two closest to this spec's
central hypothesis. If Task 3 produces one, it is worth publishing.
