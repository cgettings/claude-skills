# A durable memory model that stops the always-loaded tier growing

**Status as of 2026-08-28.** Tasks 1 and 2 are done and Task 1's **premise held**: `paths:` is
honoured at user scope, so §4's global routing lane is real rather than assumed. §1's *method* stands,
but its **numbers are a 2026-08-25 baseline, not current** — the live global `CLAUDE.md` has since
grown from 49,553 B to **55,978 B**, and nothing has re-measured its token share. Task 3's split is
rebuilt against the drifted file and still proved lossless, but **not applied**: its step 5, the
firing measurement, has not run, and **Tasks 5 and 6** are gated on that one result. Task 4 is
unblocked and untouched; Tasks 5-8 are not started. **Task 9 was added, designed, revised and
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
| 3 | Pilot the recognition/evidence split on one section | `c9b7204` write-up, `9dd9eb8` instruments, `e7ddc91` + `08239e7` re-cuts | **Steps 1-4 DONE (re-proved 2026-08-28), step 5 BLOCKED** | split built and proved lossless: 17 bullets, **11,350 -> 8,310 B (-26.8%)**, all 14 relocated originals verbatim in `~/.claude/lessons/`, 3 no-evidence bullets byte-identical. Verifier itself validated by 6-arm fault injection, and check 4 re-injected on 2026-08-28. Guard has fired twice; both re-cuts are in the commit cell. **Firing not measured** — see the step-5 note in §5 Task 3 |
| 4 | Route the file-triggered content | — | **Not started** — unblocked by Task 1 | — |
| 5 | Roll the split across the rest of global CLAUDE.md | — | **BLOCKED on Task 3** | — |
| 6 | Same for the project CLAUDE.md | — | **BLOCKED on Task 3**, and needs the team's agreement | — |
| 7 | Make the routing rule enforceable at write time | — | **Not started, but unblocked** — Task 9 settled its write protocol: **read-before-write or a lock**, for correctness. No batching or write boundary is needed; the write is free to concurrent sessions | — |
| 8 | Make the ceiling check mechanical | — | **Not started** | — |
| 9 | Does an instruction-file edit reach a running session? | — | **DONE 2026-08-28.** Answer: **replay on ordinary turns, rebuild at compaction** — the pre-registered binary was false. Steps 2-3 retired, not skipped: nothing is left for the proxy to measure | Step 0: `scripts/probe-memory-delivery.py`, 281 transcripts / 182,561 lines, 0 unreadable, **63 `Read` calls on topic files** ⇒ moved X to the project `CLAUDE.md`. Step 1: 2 sessions, 4 asks + `/compact` + arm 3, **0 tool calls** in B (transcript-checked), stale window **~2m55s across 2 turns**. Full timeline in §5 Task 9 |

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
now exists and holds **14 files / 20,461 B** — the evidence moved out of the pilot section, each
containing its original bullet verbatim. Nothing loads them; they are read only when a rule's
`[[pointer]]` is followed. **`~/.claude/CLAUDE.md` itself is UNCHANGED** — the split is built and
proved but deliberately not applied, because the firing test that would license applying it has not
run. Derive that rather than trusting this line, because the probe below copies each arm over that
file and restores it afterwards: the guard command returns 11,350 while the section is unsplit and
8,310 once it is not. To undo the lessons directory: `rm -rf ~/.claude/lessons/`.

**One thing owed, and it is not a step in this document.** The `keep-ledger` 1.3.1 release that
this work's lessons pass produced is **settled**: `efd2637` merged to `main` as PR #8 on
2026-08-26 `[verified 2026-08-28: git merge-base --is-ancestor efd2637 origin/main, exit 0]`.
Nothing here depends on it and it needs no further action.

Still owed: a `reconcile-records` sweep of this project's memory store and `README.md`,
**deferred until step 5 lands**, because that run moves the same numbers again — one of the four
memory files was spot-checked (`eval-suites-have-no-behavioural-runner`, current) and the other
three were not. The 2026-08-28 re-cut adds to what that sweep must reconcile: §1's byte figures for
the global `CLAUDE.md` (49,553 B, measured) against the file as it now stands (**56,836 B**, after
the 2026-08-28 lessons pass added 858 B).

**Also owed, and held deliberately: one lessons-pass bullet that would fire the step-5 guard.** The
2026-08-28 pass produced three entries for the global `CLAUDE.md`. Two were applied — they land in
`Choosing and running the check` and `Session workflow`, and the guard still reads 11,350. The
third lands in **`Validating the instrument`, which is the Task 3 pilot section**, so applying it
would move the section a third time and force a third re-cut of `task-3-section-{before,after}.md`
and the 14 lesson files, immediately before step 5 — the exact incident §0 records twice already.
It is held until step 5 has run, and its text is parked here so the deferral cannot quietly become
a loss:

> - **A precondition check that reads the same field the measurement reads contaminates it.**
>   Verify the precondition on a different instance than the one you perturb. Confirming a session
>   held a file meant asking it to quote the sentence that would later be deleted — which put that
>   sentence in the session's own history, so "still present" afterwards no longer proved stale
>   context. The added-token half of the nonce stayed clean and carried the result; the deleted
>   half was dead on arrival `[2026-08-28]`.

Apply it **after** step 5, then re-cut. Applying it before means doing the re-cut twice.

**Next command — Task 3 step 5, and it is now the only candidate.** Task 9 is done; the two-way
choice this block used to describe is closed. **Do not re-run any part of Task 9** — its steps 2 and
3 are retired on the result, not left undone, and §5 Task 9 says why.

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
# expect 11350 — if not, the section moved and section-before.md must be re-cut before anything else
```

**This guard has now fired twice**, and the second time cost more than the first. On 2026-08-25 a
lessons pass appended a sentence to one bullet between the fixtures being cut and step 5 being
reached, and the section read 11,069 B against an expected 10,858 B; the re-cut is `e7ddc91`. On
2026-08-28 it read 11,350 B against 11,069 B, and the +281 B was **two independent drifts, not one**
— which is the part worth carrying forward, because the mechanical one was invisible in the byte
delta. A whole-file normalization had replaced **every em dash with an ASCII hyphen** (48 across the
fixtures; the live file now holds zero U+2014 and kept U+2192, U+2026 and U+00A7, so it was
dash-specific), *shrinking* the section by 54 B, while one bullet gained 335 B of new evidence. Net
+281 B, and a re-cut that touched all 17 bullets and all 14 lesson files rather than one of each,
because check 4 tests the original verbatim and "the original" had changed everywhere.

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
# results  -> docs/task-3-firing-results.json
# scratch  -> .task3-probe/ (gitignored)
# expect   -> "RESTORED OK", then an Opus-vs-Haiku agreement rate over a random 10 of the 30
```

Agreement below 90% means stop and re-judge everything on Opus before reading any arm difference:
that number is a fact about the judge, not about the split. Read the arms by the three-way rule in
§5 Task 3 — `A≈B>C` licenses applying the split, `A>B≈C` says §3b is wrong and everything
downstream stops, `A≈B≈C` means the probe is dead and licenses nothing either way. Whichever it
is, three things here go stale the moment it runs and are updated in the same step: this block,
the Task 3 row's status cell, and §5 Task 3's "written and unrun".

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
| Language & platform conventions | **file-triggered** | `~/.claude/rules/` with `paths:`, one file per platform |
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

Chosen as the pilot because it is the largest single subsection in the file at **11,350 B**
`[re-measured three times: 10,166 B when this task was written, 10,858 B after the 2026-08-25
lessons pass — which §1 describes — 11,069 B after an amendment that evening, and 11,350 B on
2026-08-28 after a dash normalization and a second amendment]` — bigger than six of the nine top-level sections —
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

   What step 5 needs instead is a **behavioural probe**, written and unrun at
   `scripts/measure-rule-firing.py`. Three arms differing only in this section of
   `~/.claude/CLAUDE.md`: **A** full (11,350 B), **B** split (8,310 B), **C** deleted — built from
   `docs/task-3-section-{before,after}.md` and verified to differ by exactly 3,040 B and 11,350 B
   `[checked 2026-08-25, re-checked after the e7ddc91 re-cut]`. Arm C is load-bearing: without
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

**Steps 1-4 result, 2026-08-25.** Inventory: `task-3-split-inventory.md`, built before any edit. The
section is **17 bullets** (14 top-level, 3 nested), not the flat list it reads as. **Three of the 17
carry no evidence specifics at all** — no date, no number, no incident — and are kept byte for byte;
that is the first real bound on the yield, since the section's size is not uniformly evidence.
The other 14 split to `~/.claude/lessons/<slug>.md`, each holding its original bullet **verbatim**,
which turns "every evidence item is locatable" from a judgment call into a substring test.

**Measured: 11,350 → 8,310 B, −3,040 B, −26.8%.** `[re-measured 2026-08-28 after the second
re-cut; earlier figures were 10,858 → 8,048 B (−25.9%) and 11,069 → 8,106 B (−26.8%)]` The yield
ratio has now held at 26.8% across two independent drifts of the source section, which is weak
evidence that it is a property of the section's evidence density rather than of one cut. Proved by five checks — bullet count preserved,
the three unchanged bullets byte-identical, all 14 pointers resolving, all 14 originals verbatim in
their lesson files, and a 1:1 pointer↔file mapping with no orphans.

**The verifier was itself validated before its passes were believed**, by injecting six faults and
confirming each is caught and names its own finding. That found three real bugs in it: it read the
real `~/.claude/lessons/` while the control perturbed a copy, so two arms silently tested nothing;
and two checks crashed instead of reporting, which exits non-zero and reads as a catch. Had it been
trusted on its first all-pass, this task would have reported a clean proof from an instrument with
two dead arms.

**Not applied.** `~/.claude/CLAUDE.md` is untouched. The split is `docs/task-3-section-after.md`,
its pre-split source is `docs/task-3-section-before.md`, and applying it is gated on step 5.
`scripts/verify-split.py` re-proves the whole thing from those two files plus `~/.claude/lessons/`
in about a second, and exits non-zero on any failure — that being its informative answer, chain it
with `;`.

### Task 4: Route the file-triggered content

**Files:** `~/.claude/CLAUDE.md` §Language & platform conventions; new
`~/.claude/rules/{powershell,windows-cli,git-tooling}.md`.

**Interfaces:** consumed Task 1's yes/no, which came back **yes**. Produces the first real reduction
in the global file, and it is the one reduction that does not depend on Task 3.

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

### Task 5: Roll the split across the rest of global CLAUDE.md

Gated on Task 3. Per section, same procedure. Two classes, proved two ways, per `refile-rules` §6.

### Task 6: Same for the project CLAUDE.md, plus the repo lesson tier

Gated on Task 3. **Ask before applying** — the project file is team-shared and its organization is
the team's call. Propose the manifest; do not apply it unilaterally.

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

### Task 8: Make the ceiling check mechanical

**Files:** `scripts/check-memory-budget.sh`, beside the existing `scripts/check-versions.sh`.

Report bytes for each always-loaded file against §3c's ceiling, and `MEMORY.md` against both the
200-line and 25KB platform caps. Non-zero exit when a ceiling is passed. The point is not to block
a commit — it is that passing the ceiling surfaces as a routing decision instead of silently.

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
