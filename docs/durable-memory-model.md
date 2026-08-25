# A durable memory model that stops the always-loaded tier growing

Status: spec, not yet executed. Written 2026-08-25.

The problem this solves: `distill-lessons` routes standing instructions to CLAUDE.md, so every
lesson that qualifies grows a file loaded into every session, forever. `refile-rules` can shrink
that file, but only by moving content to a tier that has a trigger — and it does not say which
tier, because the trigger taxonomy did not exist. This spec supplies it.

---

## 1. Measured baseline

`[measured 2026-08-25, wc on the three files]`

| File | Bytes | Words | Lines |
|---|---:|---:|---:|
| `~/.claude/CLAUDE.md` | 49,553 | 8,158 | 135 |
| `EH-dataportal/CLAUDE.md` | 34,207 | 4,942 | 295 |
| `projects/…/memory/MEMORY.md` | 13,207 | 1,615 | 74 |
| **always-loaded total** | **96,967** | **14,715** | — |
| memory topic files (64, **not** loaded) | 335,538 | — | — |

**No token count is stated here because none was measured.** `/context` reports the real per-file
figure under **Memory files**; run it and record the number in this table before Task 2.

Two caps apply, from the official docs (see §2): `MEMORY.md` loads only its first 200 lines **or**
25KB, whichever comes first. The index is at 74 lines / 13,207 B — averaging 178 B/line, so
**25KB is the binding cap and it arrives at ~140 lines, not 200.** Currently 53% consumed.
Anything past the cap is dropped silently on load.

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
| `.claude/rules/*.md` **with** `paths:` | Claude reads a file matching the glob | zero | deterministic |
| subdirectory `CLAUDE.md` | Claude reads a file in that subdirectory | zero | deterministic |
| Skill `SKILL.md` body | invoked, or judged relevant | name + description | judgment |
| auto-memory topic file | Claude chooses to read it | zero | judgment |
| `MEMORY.md` | every session; first 200 lines **or** 25KB | full text to cap | — |

Three quotes worth carrying, because they each kill an otherwise-obvious idea:

- *"Splitting into `@path` imports helps organization but doesn't reduce context, since imported
  files load at launch."* — imports are an organizing device, never a budget device.
- *"Rules load into context every session or when matching files are opened. For task-specific
  instructions that don't need to be in context all the time, use skills instead."*
- *"Claude Code doesn't load topic files such as `user_role.md` at startup. Claude reads them on
  demand using its standard file tools when it needs the information."*

**There is no retrieval engine behind a bare pointer.** A blog post claims a non-`@` path in
CLAUDE.md becomes "a pointer that the recall system surfaces when it judges the file relevant";
the official docs describe no such mechanism. A pointer is read only if the model reads the hook
line and decides to open the file. That is the same judgment-based trigger `MEMORY.md` already
runs on — which is why §4 does not build a second index for project-scoped content.

**Instrument.** The `InstructionsLoaded` hook *"logs exactly which instruction files are loaded,
when they load, and why"* — documented as being for debugging path-specific rules and lazy-loaded
files. Every lazy-tier claim in this spec is checkable against it. Nothing here should be believed
without it.

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

`refile-rules` §5 bans compression, correctly: *"it buys space by removing the specifics that let
a rule be recognized in a situation, and the loss is invisible afterwards."* Global CLAUDE.md
bans it too: *"read the line with the citation deleted and see whether it still tells you what to
do."*

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

**The test that the split is safe — and it has not been run.** Whether trimmed rules fire as
reliably as full ones is a hypothesis. The repo is already growing the instrument:
`scripts/run-trigger-evals.py` (untracked as of 2026-08-25). Task 3 pilots the split on one
section and measures it. If firing degrades, the split is wrong and this spec's budget claim
collapses with it — say so rather than shipping the trim anyway.

### 3c. A ceiling, not a target

The goal is not a smaller file. It is a file that **stops growing**. A ceiling does that: at the
ceiling, adding a rule requires routing one out, so every addition becomes a routing decision
instead of an append.

| File | Ceiling | Note |
|---|---:|---|
| `~/.claude/CLAUDE.md` | 25,000 B | from 49,553 |
| project `CLAUDE.md` | 20,000 B | from 34,207 |
| `MEMORY.md` | 20,000 B | hard cap is 25,000; this leaves headroom |

**These numbers are chosen, not derived.** No measurement establishes 25,000 B as better than
30,000. Anthropic's own guidance is *"Longer files consume more context and reduce adherence"* and
*"target under 200 lines"* — a direction, not a threshold, and unusable here directly since these
files run 116–367 B/line (project 116, `MEMORY.md` 178, global 367), so "200 lines" spans a 3x
range in actual context cost. Task 3 measures what the split actually yields on a real section;
revise the ceilings against that result rather than defending these.

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

### The global-scope gap

Auto-memory is per-repository. `autoMemoryDirectory` is settable at user scope, so a shared store
*is* now possible — but **only one store loads per session**: a user-scope setting gives every
project the same store, and a project-scope override gives that project its own. You get global or
project, never both. `[from the docs' settings-precedence description, 2026-08-25; not yet tested]`

So cross-project lessons have no lazy, judgment-triggered store equivalent to `MEMORY.md`.
**For global scope, and only global scope, build the pointer index the original proposal
described**: hooks in `~/.claude/CLAUDE.md` pointing at `~/.claude/lessons/*.md`. Accept that it
fires on model judgment. It is the same trigger quality `MEMORY.md` already runs on, and there is
no better one available at that scope.

For project scope, **do not build a second index.** `MEMORY.md` is already exactly this, with an
automated write path. Adding a parallel one in CLAUDE.md duplicates it and costs always-loaded
bytes to do so.

---

## 5. Migration

Each task states the observable end state it is proved by, not the files it touches.

### Task 1: Falsify the premise the global lazy tier rests on

**Files:** `~/.claude/rules/probe-lazy.md` (new, temporary); `~/.claude/settings.json` (add an
`InstructionsLoaded` hook).

**Interfaces:** produces a yes/no on whether `paths:`-scoped rules work at **user** scope. Every
later task consumes it.

The docs describe `paths:` under project rules and describe `~/.claude/rules/` as the user-level
version of the same directory. They do not state that a user-scope rule honors `paths:`. If it
does not, user rules load unconditionally and §4's global routing is dead.

1. Write `~/.claude/rules/probe-lazy.md` with `paths: ["**/*.probe-ext"]` and a unique sentinel
   string in the body.
2. Register the `InstructionsLoaded` hook, logging to a file.
3. Start a session, touch nothing. **Expected:** the log does not name `probe-lazy.md`.
4. In the same session, read a file named `x.probe-ext`. **Expected:** the log now names it.
5. Positive control — required, because step 3 is a null result: with `paths:` removed, step 3's
   log **must** name the file. Without this, "did not load" and "the hook never fired" are
   indistinguishable.

**Stop and report before Task 2 regardless of outcome** — a negative result changes §4, not just
this task.

### Task 2: Record the real baseline

**Files:** this document, §1.

**Interfaces:** produces the token figures every later measurement is compared against.

Run `/context`, record per-file token counts under **Memory files** into §1's table beside the
byte counts. Record the commit hash of each file's current state. Commit this document with those
numbers before any file is edited — a baseline taken after the first edit is not a baseline.

### Task 3: Pilot the recognition/evidence split on one section

**Files:** `~/.claude/CLAUDE.md` §Verification → Validating the instrument;
`~/.claude/lessons/` (new).

Chosen as the pilot because it is the largest single subsection in the file at **10,166 B**
`[measured 2026-08-25]` — bigger than six of the nine top-level sections — and because it is the
densest in evidence specifics, so it is where the split has the most to prove and the most to
lose. The other two Verification subsections are 5,418 B and 5,267 B.

**Interfaces:** produces a measured before/after byte count and a firing-rate result. Tasks 5 and 6
are gated on it.

1. For each bullet, write down its recognition inventory (trigger vocabulary + action) and its
   evidence inventory (dates, numbers, incident, disconfirmed alternatives) **before** editing —
   `refile-rules` §5's inventory rule, applied per-bullet.
2. Rewrite each bullet to recognition + action + a `[[pointer]]`. Move evidence to
   `~/.claude/lessons/<slug>.md`.
3. Every evidence item is locatable in the lesson file, or named here as a deliberate drop with a
   reason. No item is excused by the result reading better.
4. Measure: section bytes before and after.
5. **Measure firing**, via `scripts/run-trigger-evals.py`: same eval set against the full section
   and the split section. A trim that reads well and fires worse is a loss.

**If firing degrades, stop.** §3b is wrong and §3c's ceilings are unreachable by this route. Say
so here and report before continuing.

### Task 4: Route the file-triggered content

**Files:** `~/.claude/CLAUDE.md` §Language & platform conventions; new
`~/.claude/rules/{powershell,windows-cli,git-tooling}.md`.

**Interfaces:** consumes Task 1's yes/no. Produces the first real reduction in the global file.

Separate the file-triggered rules from the shell-composition rules first (§4's caveat), then move
only the former, **byte for byte** — this is `refile-rules`' moves class and gets its mechanical
proof: sort the rule lines before and after and diff the sorted forms; the only differences may be
the ones a manifest names.

Proof of the end state, not of the file list: with a `.ps1` open, the PowerShell rules are in
context per the `InstructionsLoaded` log; at launch with nothing open, they are not.

### Task 5: Roll the split across the rest of global CLAUDE.md

Gated on Task 3. Per section, same procedure. Two classes, proved two ways, per `refile-rules` §6.

### Task 6: Same for the project CLAUDE.md

Gated on Task 3. **Ask before applying** — the project file is team-shared and its organization is
the team's call. Propose the manifest; do not apply it unilaterally.

### Task 7: Make the routing rule enforceable at write time

**Files:** `plugins/distill-lessons/skills/distill-lessons/SKILL.md`;
`plugins/refile-rules/skills/refile-rules/SKILL.md`.

**Interfaces:** consumes §3a and §3b. Without this task the files grow back.

`distill-lessons` currently decides *whether* a lesson is a standing instruction. It must also
decide *which tier*, using §3a's four classes, and must split recognition from evidence at
write time rather than leaving a full-evidence bullet for a later `refile-rules` pass to move.

`refile-rules` §5 gains the recognition/evidence distinction as a named permitted edit shape,
with §3b's test as its bar.

### Task 8: Make the ceiling check mechanical

**Files:** `scripts/check-memory-budget.sh`, beside the existing `scripts/check-versions.sh`.

Report bytes for each always-loaded file against §3c's ceiling, and `MEMORY.md` against both the
200-line and 25KB platform caps. Non-zero exit when a ceiling is passed. The point is not to block
a commit — it is that passing the ceiling surfaces as a routing decision instead of silently.

---

## 6. Considered and rejected

- **`@path` imports to split CLAUDE.md.** Imported files load at launch. Documented explicitly.
  Buys organization, zero context.
- **A second pointer index in the project CLAUDE.md.** `MEMORY.md` already is one, with an
  automated write path and a documented 25KB cap. A parallel index costs always-loaded bytes to
  duplicate a tier that exists. Kept for **global** scope only, where no equivalent exists (§4).
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
- `ggrigo/align` — closest on the *capture* side: rates each claim in an output, then `/diagnose`
  traces each wrong claim back to the stale instruction that caused it. That inverts the loop this
  repo runs — `reconcile-records` sweeps for what went false; `align` starts from an observed
  failure and finds the rule to blame. Worth reading before the next `reconcile-records` revision.
- `az9713/claude-code-continual-learning-skills` — lessons stored as skill files under
  `~/.claude/skills/`, retrieved by description matching. The nearest implementation of the
  lessons-as-skills idea. No token or firing-rate measurements are claimed.

None of these carries a measured firing-rate result. If Task 3 produces one, it is worth
publishing.
