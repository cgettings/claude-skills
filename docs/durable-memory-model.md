# A durable memory model that stops the always-loaded tier growing

**Status as of 2026-08-25.** §1 and §2 are measured and current. Task 1 is done and **the premise
held**: `paths:` is honoured at user scope, so §4's global routing lane is real rather than assumed.
Task 2 is done. Tasks 3-8 are not started, and everything after Task 3 is gated on it — Task 3 is
the one thing here that is still a hypothesis.

## 0. Ledger

| # | Task | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 1 | Falsify the user-scope `paths:` premise | `0f82133` — no code commit; the result **is** §5 Task 1 below | **DONE 2026-08-25** | `InstructionsLoaded` hook log + model self-report, 2 sessions, 4 arms, 5 controls, all passed. Verbatim log line in §5 Task 1 |
| 2 | Record the real baseline | `0f82133` — no code commit; the result **is** §1 below | **DONE 2026-08-25** | differential token measurement, 11 `claude -p` runs, each arm controlled by the same hook log. Method, and the two arms it voided, in §1 |
| 3 | Pilot the recognition/evidence split on one section | `c9b7204` | **Steps 1-4 DONE, step 5 BLOCKED 2026-08-25** | split built and proved lossless: 17 bullets, **10,858 -> 8,048 B (-25.9%)**, all 14 relocated originals verbatim in `~/.claude/lessons/`, 3 no-evidence bullets byte-identical. Verifier itself validated by 6-arm fault injection. **Firing not measured** — see the step-5 note in §5 Task 3 |
| 4 | Route the file-triggered content | — | **Not started** — unblocked by Task 1 | — |
| 5 | Roll the split across the rest of global CLAUDE.md | — | **BLOCKED on Task 3** | — |
| 6 | Same for the project CLAUDE.md | — | **BLOCKED on Task 3**, and needs the team's agreement | — |
| 7 | Make the routing rule enforceable at write time | — | **Not started** | — |
| 8 | Make the ceiling check mechanical | — | **Not started** | — |

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
now exists and holds **14 files / 19,677 B** — the evidence moved out of the pilot section, each
containing its original bullet verbatim. Nothing loads them; they are read only when a rule's
`[[pointer]]` is followed. **`~/.claude/CLAUDE.md` itself is UNCHANGED** — the split is built and
proved but deliberately not applied, because the firing test that would license applying it has not
run. To undo: `rm -rf ~/.claude/lessons/`.

**Next command.** Task 3 step 5 — the firing measurement, the one gate everything downstream sits
on. The probe is written and unrun at `scripts/measure-rule-firing.py` (see the step-5 note in §5
Task 3 for what it does, how to read each outcome, and why the originally-named instrument could
not). It refuses to run if the section is not found exactly once in the live file, so the check
below is what it does first anyway:

```sh
awk '/^### Validating the instrument/,/^### Verifying a claim/' ~/.claude/CLAUDE.md | head -n -1 | wc -c
# expect 10858 — if not, the section moved and section-before.md must be re-cut before anything else
```

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
two rules and took it to **50,686 B (+1,133, +2.3%)**. The token count was **not** re-measured, and
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

Chosen as the pilot because it is the largest single subsection in the file at **10,858 B**
`[re-measured 2026-08-25 after the day's lessons pass; it was 10,166 B when this task was written,
and the pass that grew it is described under §1]` — bigger than six of the nine top-level sections —
and because it is the densest in evidence specifics, so it is where the split has the most to prove
and the most to lose. The other two Verification subsections are unchanged at 5,418 B and 5,246 B.

Measure the section again at the moment you start, rather than trusting either number: it grew
6.8% in a day, and a before/after against a stale "before" reports the wrong reduction.

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
   `~/.claude/CLAUDE.md`: **A** full (10,858 B), **B** split (8,048 B), **C** deleted — built from
   `docs/task-3-section-{before,after}.md` and verified to differ by exactly 2,810 B and 10,858 B
   `[checked 2026-08-25]`. Arm C is load-bearing: without a floor, A≈B cannot be told apart from a
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

   **Cost, revised 2026-08-25 against real pricing** (Opus 5 `$5`/`$25` per Mtok, cache read 0.1x,
   write 1.25x — the earlier `~$5-8` here was computed against a wrong `$15`/Mtok input rate):
   **~$2 if the prefix cache holds, ~$11 if it never hits.** The probe leg is ~71% of that and is
   irreducible — 30 cold sessions x ~43K of fixed prefix *is* the experiment; only fewer arms or
   fewer repeats would move it, and both weaken the design. Estimated from §1's measured
   43,380-token baseline, which was measured in-repo while the probe runs from a workdir, so it is
   conservative — an estimate, not a measurement.

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

**Measured: 10,858 → 8,048 B, −2,810 B, −25.9%.** Proved by five checks — bullet count preserved,
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
