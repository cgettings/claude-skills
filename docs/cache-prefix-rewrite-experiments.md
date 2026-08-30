# Finding the mechanism behind unexplained mid-session prefix rewrites

Some Claude Code sessions rebuild their entire cached prompt prefix mid-conversation with no
attributable cause. `scripts/sweep-cache-rewrites.py` establishes that this happens, when, and how
often; it does not establish **why**. This plan is the cheapest ordered path to why.

The constraint is cost, and it is taken seriously here: **Tasks 1 and 2 spend nothing** — they are
re-questions of data already on disk — and each is capable of ending the investigation on its own.
Only Task 3 spends tokens, and only Task 4 costs real build time. Do not start at Task 4 because it
is the one already designed.

**Zero API spend is not zero cost, so every step writes its per-event output to a file and prints
only aggregates.** Tasks 1 and 2 buy no sessions, but they run *inside* one, and whatever an
analysis pulls inline is re-read at cache rates on every later turn of that session — which is the
same charge this investigation is about. The dumps are large: Task 2 emits a 20-record lead-in for
each surviving event: **829 lines for 33 events** `[measured 2026-08-29]`. The answers are small:
counts with denominators. So
each step below names the file it writes and the aggregate it prints, all such files are gitignored,
and the dump is opened only when an aggregate is surprising — with `grep` or `sed -n`, never whole.

Sibling document: `docs/durable-memory-model.md`, on branch `feature-durable-memory-model`, not on
this one. Its §5 Task 9 holds the proxy design that Task 4 below reuses, and its §0 is the ledger
format this document borrows.

---

## 0. Ledger

**Status as of 2026-08-30: three nulls and no mechanism. A manual window reload does not move
the prefix (Task 3, arm F/reload), and reconnects are not enriched before an event (Task 5, null
at n=10). The free checks are now genuinely spent, so Task 4 — the logging proxy — is unparked and
is the next thing that can answer the question. Two cheaper arms remain unrun and are worth doing
first because they are hours cheaper than a proxy: E (permission mode) and F/host-restart.**

| # | Task | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 1 | Re-question the existing corpus | `cf4aae9`, `6229faa` | **DONE 2026-08-29** — steps 1-3; step 4 on hold | Step 1 expectation falsified; step 3 table below |
| 2 | Find what immediately precedes each event | `6229faa` | **DONE 2026-08-29** — returned a null | 5 signatures, all at or below same-session base rate, every probe firing somewhere |
| 3 | Reproduce on demand in a cheap session | `07bca1c`, `d343ce6`, this commit | **ARM F/RELOAD DONE 2026-08-30** — null. Arm F/host-restart predictions written, run pending; arms E and B not run | 5 predictions scored: 1 and 4 hit, 2 missed, 3 N/A; reload independently witnessed |
| 4 | Logging proxy on `ANTHROPIC_BASE_URL` | *no commit yet* | **UNPARKED 2026-08-30** — the free checks are spent and none identified a mechanism | — |
| 5 | Do the rewrites sit on a client reconnect? | `fd87d13` | **DONE 2026-08-30** — null at n=10; version-gated at 2.1.232, so blind on 23 of 33 events | 3/10 against a 0.304 base rate; counter validated against a hand count |

**Task 1 step 4 is on hold, not done.** It asks whether the explained events carry an offset in one
of the three bands. The bands did not survive re-baselining (§1), so there is nothing stable to
check contamination against. Unhold it if a denominator is ever established.

**Environment state — not in this repo, and it goes with the machine.**

- The corpus is `~/.claude/projects/*/*.jsonl`, **367 transcript files / ~13,970 turns and growing**. It is
  live: this plan's own execution adds turns, so every count is only true on its date. Re-running
  the sweep will not reproduce a figure exactly, and that is not a fault.
- **The corpus is now contaminated by this investigation and cannot be treated as independent.**
  Session `2e2d5ebe` on 2026-08-29 ran the sweep repeatedly, edited `~/.claude/CLAUDE.md` three
  times, and wrote to the memory store — three of the things the predicates test. Later runs must
  label it, or the measurement starts counting itself.
- **There is effectively no non-VS Code arm.** By turns rather than by transcript: `claude-vscode`
  13,952 turns over 266 sessions, against 3 turns of `cli`, 5 of `sdk-ts`, 11 of `claude-desktop`
  `[verified 2026-08-29]`. Any entrypoint comparison drawn from this corpus has no power, and a
  zero in the small arms means nothing.
- **Three paths are untracked on this branch only, and `git add -A` would commit them.**
  `.task3-probe/`, `scripts/__pycache__/` and `scripts/plugin update scratch.md` are ignored on
  `feature-durable-memory-model`, whose `.gitignore` carries the rules; this branch's does not
  `[verified 2026-08-29: git show feature-durable-memory-model:.gitignore]`. Stage by path here.
- Commits on this machine are GPG-signed. `git commit` blocks on pinentry outside Claude Code, so
  give it a timeout above the 2-minute default `[2026-08-29: a signed commit blocked 2m, did not
  land, and was misreported as the approval gate]`.

**Re-run of the state check, 2026-08-30: reproduces.** `--min-create=0` over 369 files / 14,037
turns gives 114 events, 33 unexplained, self-check 13,591 exact / 171 broken (79:1). Against
2026-08-29's 367 / 13,963 the corpus grew and the counts did not, so the instrument is intact and
the two surviving candidates are unchanged. Output in `.task3-probe/sweep-2026-08-30.txt`.

**Next command — Task 3's two unrun cheap arms, in a fresh scratch session, before Task 4.** Both
are the same shape as the reload arm that already ran, so the predictions, the turn script and the
reader are all reusable; only the trigger changes. Arm F/host-restart is `Developer: Restart
Extension Host`; arm E is a permission-mode change, and leaving plan mode is the transition two of
the three observed events share. **Do not spend a session on an extension update** — §2 records why
that member cannot produce an unexplained event. The version check the F arm needs already exists
and already fired once: `read-session-prefix.py` prints `version` per turn, and Task 3's prediction
4 read it. Its meaning is now sharper than when it was written — a trigger that moves the version
string has tested an already-explained cause and says nothing about the 33, so that is a void arm
rather than a confound to note.

```sh
# after the run, in the new session's transcript:
python scripts/read-session-prefix.py ~/.claude/projects/<scratch-project>/<id>.jsonl
```

Task 4 unparks if both miss. The probe session `6597c649` is finished, is the Task 3 evidence, and
should not be added to.

**Then Task 3, which is the only remaining path.** Its two candidates are E (permission mode,
from Task 1 step 3) and F (extension host restart — window reload, extension restart, or an
extension update followed by a reload; §2). Both are client-side, neither is visible in a
transcript, and F is the one to run first because a single deliberate action tests it.

---

## 1. What is already established

From `scripts/sweep-cache-rewrites.py` at `6229faa` `[verified 2026-08-29: 367 transcript files,
13,963 deduplicated turns, continuity self-check 13,520 exact / 170 broken; at `af0bfe1` the same
instrument reproduced both 2026-08-26 figures — 207,740 and 126,421 — exactly]`:

- **114 rewrite events, 33 unexplained**, spanning 2026-07-28 to 2026-08-26. Explained: TTL, effort
  switch, compaction, Claude Code version bump mid-session, aborted turn immediately prior.
- **Every count here is a lower bound.** `CREATE_MIN` floors the *rebuild*, and it hid this
  session's own compaction — 232,740 collapsing to 27,775 with a 46,219 rebuild. Sweeping the
  floor bounds the damage: 99 / 31 at 50,000 becomes 114 / 33 at 25,000 and is then flat to zero
  `[verified 2026-08-29, `--sensitivity` at `6229faa`]`. The flatness is structural — a prefix over
  `PREV_MIN` that collapses by more than half has a large rebuild by construction.
- **Two of the 33 rebuilt from nothing** (`cache_read == 0`). They have no floor to sit above, so
  they are a separate population and pooling them is what produced every negative offset.

**The banding is baseline-dependent, and that is the finding of Task 1 step 1.** Under the original
per-session start floor the offsets fell into three clean bands. Under a per-version floor, and
again under a per-version-and-project floor, they do not: offsets vary *within* a single version
and project, so the offset is not a pure function of version. **Only 908 survives all three
denominators** — 7 events, three versions, two projects. Whether the wider banding was structure or
an artifact of the first floor is **not settled**, and neither reading should be quoted as though it
were. What the 908 cluster does support is the original premise: a discrete constant recurring
across versions and projects is a *fixed block* above the cache breakpoint, not conversation
content. So the question remains "what fixed block was added, and by what" — but the offset is not
currently a reliable instrument for answering it, and Task 1 step 4 is on hold because of that.

**What the transcript cannot do.** It does not record injected instruction blocks — `grep -c
system-reminder` returns 0 on these files — so the block's *content* is not recoverable from disk
at any sample size. It does record every tool call, timestamp, version, effort, model, and
entrypoint, which is enough to identify the block's *trigger*. Do not let the first fact retire the
second.

---

## 2. Candidate mechanisms

Originally ranked by how cheaply each could be falsified. Three of them now have been.

**A. A deferred tool schema is fetched mid-session, growing the tool-definitions block.**
**FALSIFIED 2026-08-29 by Task 2.** This was the investigation's leading bet: tool definitions sit
above every cache breakpoint, the predicted offset is fixed per tool-set and steps with version,
and the block would be absent from the transcript. All true, and all irrelevant — `ToolSearch`
appears before events at 1.24/hour against a same-session control of 2.17, and first-use-of-any-tool
at 3.73 against 7.13. Both *below* base rate.

**B. The IDE integration injects editor state** — opened file, selection — into the system block.
Predicts events uncorrelated with anything the user typed, which matches. **The corpus cannot test
this and the gap is worse than first recorded**: by turns rather than transcripts it is 13,952
`claude-vscode` against 3 `cli` `[verified 2026-08-29]`. Needs a deliberate pair in Task 3.

**C. Skill entry or exit rewrites injected content.** **FALSIFIED 2026-08-29 by Task 2**: 0.93/hour
before events against 2.46 in the same sessions, and Task 1 step 3 agrees at 0.31 against 0.53. The
2026-08-26 observation of 3 invalidations from 11 skill exits does not survive a base rate.

**D. An MCP server reconnects or re-registers mid-session**, changing the tool block. **FALSIFIED
for tool *calls*, untouched for tool *availability*.** Any MCP use runs 0.62/hour against 2.57, and
first MCP use is 0 of 33 with a live probe (119 control hits). But a re-registration emits no
`tool_use` record at all, so this predicate never tested it. See F.

**E. The six ruled out on 2026-08-26, re-tested at n=33 — and one did not stay ruled out.**
Skill exit, global `CLAUDE.md` edit and memory-store write all fire *below* the same-session base
rate, which is a stronger confirmation than zero would have been. TTL and effort switch score zero
**by construction, not by test**: the classifier removes them before an event can reach the
unexplained set. **Permission mode sits at 8.1x on n=3** — `plan→auto`, `auto→acceptEdits`,
`plan→acceptEdits`, all genuine transitions rather than the empty-history artifact the predicate
could have produced. Treat it as a lead, not a finding: one of the three is a `cache_read == 0`
event, the control was refined after seeing the data, `permissionMode` appears on only ~1,357
records, and direction of causation is untested. Two of three involve leaving plan mode, which is
a mechanism rather than a bare correlation.

**F. The extension host restarts, re-registering the IDE connection and changing the tool block.**
Proposed 2026-08-29. A *family*, not one event — a manual window reload, an extension restart, an
extension updating and then reloading, or a VS Code update. They share the mechanism that matters:
the client re-registers its tools, and the tool block sits above every cache breakpoint.

**One member is excluded by construction and should not be bought a session, added 2026-08-30.**
`classify()` appends a `version X->Y` cause on any change, so a **Claude Code extension update
cannot be behind any of the 33**: it is an explained cause before it can reach the residual set.
14 of the 114 events are version-classified and **0 of the 33 are** `[verified 2026-08-30, and the
field is populated on both sides of all 13,802 boundaries, so the test fires rather than comparing
two nulls; 34 boundaries carry a change]`. This is the same structure Task 1 Step 3 records for
TTL and effort switch — zero by construction is not evidence — and the family's member list did
not say so. **What survives is the version-silent half:** a VS Code application update, or a host
restart that leaves the Claude Code version string untouched. That is what `Developer: Restart
Extension Host` tests on demand.

**A side observation from the same check, and it is the only direct evidence that this machine
replaces hosts mid-session at all.** Four of the version transitions are *downgrades*
(`2.1.224->2.1.220`). A version going backwards is a client being replaced rather than upgraded —
two clients at different versions writing one transcript. Those events sit outside the residual
set, so this is not evidence *for* F as an explanation of the 33; it establishes only that the
family's premise — that a host swap happens here — is real rather than assumed.

**Its on-demand member is now falsified, and the reason it looked untestable was a wrong
reading of the transcript.** Task 3 ran a manual window reload mid-session on 2026-08-30 and the
prefix did not move: `cache_read` 52,670 against 52,487 + 183 expected, exact, with the reload
independently witnessed in the record stream. Details and scope limits in Task 3's result table.

**Two of the three reasons this family was called untestable from disk do not survive.** Task 2
testing tool *calls* against a mechanism that changes tool *availability* still stands, and the
entrypoint comparison still has no control arm. The third was false:

- **`bridge-session` records recur within a transcript, and they mark the reconnect.** The reload
  emitted three of them in a cluster, at the same shape the session emits at startup. Corpus-wide,
  99 transcripts carry at least one and the counts run to 139 in a single file `[verified
  2026-08-30]`.
- **The id does rotate, in about a fifth of them.** 80 transcripts carry one distinct
  `bridgeSessionId`, **19 carry two** — dated 2026-08-12 to 2026-08-22, so all of them predate the
  2026-08-29 check that reported "91 transcripts carry one bridge id each, none carries two"
  `[verified 2026-08-30]`. That claim was wrong when it was made; corpus growth does not explain
  it. **Retract it wherever it has been quoted.** The measurement to trust is the record cluster
  rather than the id, since the probe's own reload kept its id.

That gives the family a free check it was thought not to have — Task 5.

It fits the shape better than A did — invisible in transcripts, uncorrelated with
anything typed, commoner in long sessions, and a block whose size would step with version as IDE
tool schemas change. **The reload null narrows what "fits the shape" can mean:** a restart that
changes no request bytes changes no cache, so the live version of F is a restart that changes what
the client *injects*, not the restart itself.

**One sub-variant has been tested and is not supported.** If updates drove it, events would cluster
shortly after a version first appears on this machine. They do not: median age 16.3 h for the 33
unexplained against 16.8 h across 13,679 other turns, with near-identical bucket distributions
`[verified 2026-08-29]`. That disfavours *update-then-reload* specifically and leaves manual reload
and extension restart untouched, since both predict the uniform scatter observed. **Read the null
narrowly**: `version` is the Claude Code version, and whether a VS Code extension update bumps that
field is unestablished — if it does not, the proxy never tracked the thing it stood in for.

**Run this family first in Task 3**, because one deliberate action tests it and no analysis will.

---

## Task 1: Re-question the existing corpus

Costs nothing, runs locally, and can end the investigation. Every step is a re-analysis of data
already on disk.

**Files:**
- `scripts/sweep-cache-rewrites.py` — the instrument; extend it rather than writing a second one
- `~/.claude/projects/*/*.jsonl` — read-only corpus
- `task1-residual.json` — written, not read into the session. The residual event set, one object per
  event, so Task 2 consumes a file rather than a number retyped from a summary

**Interfaces:** consumes nothing. Produces the residual set of events that survive every free
explanation, which is the input to Task 2. Each step prints its counts; the per-event detail behind
those counts stays in `task1-residual.json`.

**Step 1 — is the offset a pure function of version?** Group the unexplained events by
`version` and report the offset distribution within each. **Expected if the block is version-fixed:
zero variance within a version.** Any residual variance names a second variable, and that variable
is the finding.

**Step 2 — establish a defensible baseline.** The current "start floor" is the first turn's
`cache_read`, which is 0 for a genuinely cold session and elevated when a session starts warm. That
is why seven of 31 events are unusable and two are negative. Replace it with the *minimum
`cache_read` observed across all sessions on that version*, which is a property of the version
rather than of one session, and recompute every offset. **Expected: the seven unusable events
become usable and the two negatives resolve.** If they do not, the offset is not measured against
the right thing and Steps 1 and 3 are reading noise.

**Step 3 — re-test the six ruled-out explanations at n=31.** Each was checked against two events.
Write each as a predicate over an event and report how many of the 31 it explains. **Expected:
zero, since these were eliminated.** A non-zero count is a better result than a new experiment, and
it is free. All six are detectable from the corpus, with one narrow blind spot `[verified
2026-08-29: field and tool-call counts over all 367 transcripts]`:

| Explanation | How to detect it |
|---|---|
| TTL | turn gap; already in the classifier |
| Effort switch | `effort` field; already in the classifier |
| Permission mode | `permissionMode` field — present on 1,357 records, values `auto` (973), `acceptEdits` (343), `plan` (28), `default` (13) |
| Skill exit | `Skill` tool_use blocks — 218 in the corpus, from 2026-07-28 |
| Global `CLAUDE.md` edit | `Edit`/`Write` tool_use with a `file_path` ending `CLAUDE.md` — 237 in the corpus |
| Memory-store write | `Edit`/`Write` tool_use with `/memory/` in `file_path` — 222 in the corpus |

**The last two need cross-session correlation, which is what makes them worth re-testing.** The
sweep reads every transcript, so an edit made by a *different* Claude session is visible and can be
matched by timestamp against the rewriting session. That is a check the original two-event pass
could not perform. **The blind spot: a hand edit made outside Claude Code leaves no trace in any
transcript** — the 2026-08-26 em-dash normalization was exactly that, so this predicate has a
floor and cannot return a clean zero.

**Step 4 — check the explained events for contamination.** The classifier assigns a cause when one
is *present*, not when it is *sufficient*. Report how many of the 68 explained events carry an
offset in one of the three bands. **If a TTL-attributed event also lands on the 5,550 band, the
same unknown block is present there too** and the true count is above 31, which changes the scope
of everything downstream.

**Proof — what ran, 2026-08-29 at `cf4aae9` and `6229faa`.** Step 1: offsets vary within a single
version and project, so the expectation of zero within-version variance is **falsified**; only 908
survives all three denominators. Step 2: the per-version-and-project floor rescued the two -6,990
events into the 908 band but did not rescue the rest, and two events turned out to have
`cache_read == 0` and no floor at all. Step 3: table in §2 candidate E — three of the six confirmed
below base rate, permission mode at 8.1x on n=3. Step 4 on hold. No claim about mechanism is
licensed by this task — it only narrows.

---

## Task 2: Find what immediately precedes each event

Costs nothing. This is the task most likely to identify the mechanism outright, because it tests
candidates A, C and D at once.

**Files:**
- `scripts/sweep-cache-rewrites.py` — add an antecedent dump behind a flag. The flag writes to a
  path and prints only the tally; it must not stream the dump to stdout
- `~/.claude/projects/*/*.jsonl`
- `task1-residual.json` — read
- `task2-antecedents.txt` — written, not read into the session

**Interfaces:** consumes Task 1's residual event set. Produces either a named trigger, which sends
you to Task 3 to confirm it, or a null, which sends you to Task 3 to test candidate B.

**Step 1 — dump the antecedents to `task2-antecedents.txt`.** For each surviving event, emit every
record between the previous assistant turn and the rewriting turn, with `type`, tool name, and any
`subtype`. Include the 20 records before that window, because the trigger may precede the last clean
turn. One line per record, prefixed with the event id, so the file is greppable per signature —
that is what makes Step 2 a `grep -c` against the file instead of a read of it.

**Step 2 — count the four signatures in that file**, in this order: a `ToolSearch` call or first use of a
previously-unused tool (candidate A); an MCP tool call, especially a first one (D); a skill
entry or exit (C); anything else common to a majority. **All three named signatures exist in the
corpus and span the event window, so a null here is a real null rather than a dead probe**
`[verified 2026-08-29: ToolSearch 117 calls, first 2026-07-28T02:26:56Z; mcp__* 777 calls across 15
distinct tools, first 2026-07-28; Skill 218 calls, first 2026-07-28 — against a first
unexplained event of 2026-07-28T03:26:28Z]`.

**Step 3 — control for base rate, which is the step that makes this sound.** A trigger appearing
before 20 of 31 events proves nothing if it also appears before 20 of any 31 randomly chosen turns.
Compute the same signature frequency over an equal number of *non-event* turn boundaries drawn from
the same sessions. **The comparison is the instrument; a raw count is not a result.**

**Step 4 — state the stop condition.** If no signature clears its base rate, say so explicitly and
record that Task 2 returned a null, rather than proceeding as though it had been skipped.

**Proof — what ran, 2026-08-29 at `6229faa`: a null, and it is recorded as a result.** Per hour of
window, unexplained against same-session control: ToolSearch 1.24 / 2.17, any MCP tool 0.62 / 2.57,
first MCP use 0.00 / 1.05, Skill 0.93 / 2.46, first use of any tool 3.73 / 7.13. Every signature at
or below base rate, and every probe fires somewhere, so none of those is a dead-probe zero. This
falsifies candidates A, C and D. It does **not** reach a mechanism that changes tool availability
without emitting a `tool_use` — see candidate F. The 829-line dump stayed in
`task2-antecedents.txt`; only the table above entered the session.

---

## Task 3: Reproduce on demand in a cheap session

**Unblocked 2026-08-29. Tasks 1 and 2 eliminated A, C and D and left exactly two candidates: F
(extension host restart) and E (permission mode).** Run F first — one deliberate action tests it,
and no amount of further analysis will. The question is about request structure and is
model-independent, so this runs on `claude-haiku-4-5`, not on Opus.

**Do not run this in a long session.** The measurement is a prefix rewrite, and triggering one in a
large context is what it costs: session `2e2d5ebe` reached 154,482 tokens on 2026-08-29, where a
rewrite would run about $1.55 — arithmetic from the 363,713 tokens ≈ $3.64 recorded in
`~/.claude/CLAUDE.md`, not a measurement. In a scratch directory at a small prefix the same
experiment costs cents, and the signal is cleaner for having less in front of it.

**Files:**
- a scratch directory outside every repo, so no project `CLAUDE.md` loads and the prefix stays small
- `scripts/sweep-cache-rewrites.py` — the corpus-wide instrument, for the before/after state check
- `scripts/read-session-prefix.py` — added 2026-08-30, and it is the one Steps 2 and 4 read. The
  sweep cannot answer Task 3: its `PREV_MIN`/`CREATE_MIN` floors are both 50,000 and this probe
  session runs a 51,743-token prefix on purpose, so a real rebuild sits on the threshold and the
  floor, not the data, decides the answer. This prints every turn with no floor and states the
  continuity identity per pair. It imports the sweep's parser rather than reimplementing it, so
  the three traps in that docstring still apply. **Positive control, both branches, on a
  held-out session** `[2026-08-30: on `047c3934` it reports 14 rewrites / 1 gap / 432 clean over
  448 turns — 447 pairs, accounted exactly — and reproduces the sweep's first unexplained event
  at 2026-07-28T03:26:28 to the token: collapse 18,700, rebuild 140,126]`. It also separates a
  collapse from a `read` that *exceeds* the accounted prefix, which is a turn missing from the
  sequence and not a rewrite — reading one of those as a hit is the false positive a small probe
  session is most exposed to.

**Interfaces:** consumes the candidate named by Task 2. Produces either a reproduction, which ends
the investigation, or a failure to reproduce, which unparks Task 4.

**Step 1 — write the expected observations down before running anything.** Numbered predictions:
which turn should rewrite, roughly what `cache_creation` should appear, and what the offset should
be. A run that surprises you is diagnosable only against predictions made in advance.

**Predictions, written 2026-08-30 before turn 2 of session `6597c649` in
`~/.claude/projects/c--Users-Chris-Documents-Projects-rewrite-testing/`. Arm: F, manual VS Code
window reload.** Turn 1 is already on disk and is the reference point: `cache_creation` 51,743,
`cache_read` 0, model `claude-haiku-4-5-20251001`, version `2.1.251`, one trivial no-tool turn.
The scratch directory is empty and holds no project `CLAUDE.md`, so the 51,743 is the global file
plus tool definitions and nothing project-specific moves under it.

1. **The baseline does not rewrite.** Over turns 2-6, `cache_read[i] == crea[i-1] + read[i-1]`
   holds exactly on all five pairs, and each `cache_creation[i]` is order 10^2-10^3 — one user
   turn plus one reply. Nothing in the baseline clears the sweep's 25,000 rebuild floor.
2. **The reload turn rewrites.** `cache_read` collapses to 0 or to a small floor, and
   `cache_creation` is roughly the whole accumulated prefix, 52,000-55,000.
3. **The offset is zero or +908.** Rebuild size minus the prior accumulated prefix total lands at
   one of those two; 908 is the only constant that survived all three denominators (§1). A
   *negative* offset falsifies more than this arm: it means the rewrite drops content rather than
   inserting a fixed block, which is the premise §1 rests on.
4. **The reload continues the session** — it appends to `6597c649….jsonl` and `version` stays
   `2.1.251`. This is the arm's validity check, not a result. A new session file means the reload
   started a fresh session, where `cache_read == 0` on turn 1 is expected by construction and says
   nothing about F; a changed `version` confounds the run with the known version-bump
   explanation. Either one voids the arm — redo it, do not interpret it.
5. **A miss on 2 is a result with a successor, not a dead end.** If the post-reload turn continues
   the prefix cleanly, F's on-demand member is falsified and the other two F members are the next
   arms rather than variants of a settled mechanism. Record the miss before moving to E.

**The F family has a second on-demand member, and it is the sharper one.** `Developer: Restart
Extension Host` restarts the host without reloading the webview, so running it after the window
reload separates *the extension host restarted* from *the whole window reloaded*. It is a second
arm, not a substitute: run the window reload first as the plan says, then this one to narrow
whichever half did the work.

**Turn script for the operator — this session cannot type into the one under test.** Send each as
a plain typed turn in the Haiku window; do not send them from another agent, since an injected
message is not the same prefix content as a typed one.

```text
turn 2:  ok
turn 3:  still there?
turn 4:  yes
turn 5:  fine
turn 6:  good
--- reload the VS Code window here (Developer: Reload Window) ---
turn 7:  still there?
```

### Result, 2026-08-30 — arm F/window-reload returned a null

**The predictions were on disk before the run, and the commit is not what proves it.** Prediction
write 02:09:31Z, first probe turn of the run 02:14:03Z, commit `07bca1c` 02:18:39Z — so the turns
fall *between* the write and the commit, and priority is established by the session transcripts,
not by the commit timestamp. Recorded because the natural reading of a `git log` here is the wrong
one.

| # | Prediction | Outcome |
|---|---|---|
| 1 | Baseline holds, creates order 10^2-10^3 | **HIT** — turns 2-6 all exact; creates 282, 172, 132, 158, 183 |
| 2 | The reload turn rewrites, rebuild 52-55K | **MISS** — turn 7 read 52,670 against 52,487 + 183 expected. Exact. Nothing collapsed |
| 3 | Offset 0 or +908 | **N/A** — no rewrite to measure |
| 4 | Same file, same version | **HIT** — same `6597c649…jsonl`, `2.1.251` throughout. The arm is valid, so the null is readable |
| 5 | A miss on 2 sends you to the other F members | **In force** |

**The reload is witnessed independently of the operator's report, which matters because prediction
4 could not check whether the trigger was actually pulled.** Between turn 6 (02:14:38) and turn 7
(02:15:12) the transcript carries `last-prompt`, `ai-title`, `atis-latch` and **three
`bridge-session` records** — the same shape the session emits at startup, and the only such cluster
in the file. That is a client re-attach. It does not identify *which* command produced it, so read
it as "the client reconnected", not as "Developer: Reload Window ran".

**What this does and does not settle.** One reload, one session, n=1, at a 51,743-token prefix
against corpus events that sit at 78K-200K. It falsifies the on-demand member of F at this size,
and it does not reach `Developer: Restart Extension Host`, an extension update, or a VS Code
update. **A mechanism argument now predicts that null, and it was not made before the run:** prompt
caching is keyed on the request bytes, and a client restart does not by itself change the bytes the
client will send next. So the F member worth testing is not "the host restarted" but "the restart
changed what the client injects" — which reframes the remaining arms rather than merely queueing
them.

**Recommended next, and it is free: Task 5 below, before buying another arm.** The reload left a
disk-visible marker, which is the thing this investigation has been short of.

### Predictions for arm F/host-restart, written 2026-08-30 before the run

**Run it in a NEW session, not in `6597c649`** — that transcript is the reload arm's evidence and
adding to it would fuse two triggers into one continuity sequence. Same scratch directory is fine.

**The honest prior is that this arm returns a null, and saying so before the run is the point.**
`Developer: Reload Window` restarts the extension host as part of what it does, and it moved
nothing. Caching is keyed on the request bytes, and neither action changes the bytes the client
will send next. **The arm is still worth running because the containment is not clean:** a window
reload recreates the webview *and* the host, while a host restart kills the host under a surviving
webview. That is a different partition, not a smaller one, and it is the only member of F left that
can be triggered on demand without moving the version string.

1. **Baseline holds.** Turns 2-6, `cache_read[i] == crea[i-1] + read[i-1]` exact on every pair,
   creates order 10^2-10^3.
2. **The restart turn does not rewrite** — continuity holds across it, as it did across the reload.
   Stated as the expected outcome, against the arm's own hypothesis.
3. **Validity: same session file, same `version`.** A new file voids the arm; so does a version
   move, and now for a sharper reason than last time — a trigger that moves the version has tested
   an already-explained cause (§2), so the run says nothing about the 33 and is not a confound to
   note but an arm to re-run.
4. **A `bridge-session` cluster appears between the turns either side of the restart.** The reload
   produced three. **This is the check the reload arm got only by luck, and it is what makes a null
   readable:** if no cluster appears, the restart did not re-attach the bridge, so the arm did not
   reach the mechanism the reload arm reached, and prediction 2's null is uninformative rather than
   confirming. Read `bridges_before` on the post-restart turn.
5. **A miss on 2 is the interesting branch.** If the prefix *does* rewrite where a full reload did
   not, a host restart under a surviving webview is a real mechanism, and the offset should then be
   checked against 908 — the one constant that survived all three denominators in §1.

```text
turns 2-6:  ok / still there? / yes / fine / good
--- Developer: Restart Extension Host ---
turn 7:     still there?
```

Read it with `python scripts/read-session-prefix.py <new transcript>`, which prints the version
column prediction 3 needs; `bridges_before` for prediction 4 comes from `session_turns`.

**Step 2 — establish a quiet baseline.** In a scratch directory, run five or six trivial turns with
no tool use and confirm the prefix is stable — `cache_read[i] == crea[i-1] + read[i-1]` on every
pair. **If the baseline rewrites on its own, stop: the effect is not the thing you were going to
trigger.**

**Step 3 — trigger one candidate**, mid-session, changing nothing else.

- **F, and run it first.** Reload the VS Code window, then send one more trivial turn. The family
  has several members and they are separate arms, not one test: a manual reload, an extension
  restart, and an extension update followed by a reload. Run the manual reload first because it is
  the only one that can be triggered on demand. If it reproduces, the others are variants of a
  known mechanism rather than open questions.
- **E.** Change permission mode mid-session — leaving plan mode is the transition two of the three
  observed events share — then send one trivial turn.
- **B.** Run the identical script under `cli` and under `claude-vscode`. This is the one pair the
  corpus cannot supply, and the arms must differ only in entrypoint.

**A trigger that fires nothing is a result only if the session could have shown it.** Confirm the
baseline from Step 2 is still running in the same session before reading a negative.

**Step 4 — read the counters, not the vibe.** Run the sweep over the new transcript and check the
prediction from Step 1.

**Cost: order $0.10-$1, estimated and not measured** — a few short Haiku sessions against a small
prefix, at Haiku 4.5 `$1`/`$5` per Mtok `[claude-api skill pricing table, read 2026-08-29]`. Named
as an estimate on purpose; do not cite it as a measurement.

**Proof:** the prediction list from Step 1 with each item marked hit or miss, plus the sweep output
over the new transcript.

---

## Task 4: The logging proxy

**Parked.** Unpark only if Tasks 1-3 identify no block. It is parked rather than pending because
its cost is build time, and Tasks 1-2 may make it unnecessary for free.

**Files:**
- a new local stub server, path to be chosen when the task starts
- `docs/durable-memory-model.md` §5 Task 9 step 2, on branch `feature-durable-memory-model` — the
  design, retired for that task's purposes and explicitly kept for the reasoning

**Interfaces:** consumes the null results of Tasks 1-3. Produces the actual bytes, which is the only
instrument that distinguishes *the file body changed* from *a system-reminder about it was
injected*.

Point `ANTHROPIC_BASE_URL` at a local logging proxy and diff two consecutive request bodies across
the trigger. Two constraints carried over from the original design, both of which cost a run to
rediscover:

- **Capture a null-edit pair first** — two consecutive bodies with no change between them, to
  establish the natural per-turn diff. Without it every observed difference is unattributable, and
  "byte-identical" was never a safe prediction.
- **The stub must return a well-formed Anthropic-shaped response.** A proxy that logs and returns
  nothing costs no tokens and yields exactly one body, because the next turn fails. The diff needs
  two successful turns.

**Proof:** the diff of two request bodies across the trigger, with the null-edit pair beside it as
the control.

---

## Task 5: Do the rewrites sit on a client reconnect?

**Opened 2026-08-30 by Task 3, and it costs nothing.** The reload that failed to move the prefix
did leave a marker — a cluster of `bridge-session` records. If those mark client reconnects
generally, the corpus can be asked directly whether the 33 unexplained events sit on one, which is
the question candidate F was thought to be unable to answer from disk.

**Files:**
- `scripts/sweep-cache-rewrites.py` — a sixth signature in the existing `--step2` machinery
- `task2-antecedents.txt` — written, not read into the session

**Interfaces:** consumes the Task 1 residual event set and Task 3's marker. Produces a hit, which
gives F a disk-visible correlate and points Task 4 at a specific pair of turns to diff, or a null,
which removes the last free check and unparks Task 4 unconditionally.

**Step 1 — position the records, do not timestamp them.** `bridge-session` records carry no
`timestamp` field `[verified 2026-08-30: the probe's five all have `timestamp: None`]`, so the
probe's own cluster was located by file position, between records 62 and 71. The predicate is
therefore "does a `bridge-session` record fall between the previous assistant turn and the
rewriting turn", by file order. **This also means Task 2's per-hour normalisation cannot be
reused** — normalise per turn-boundary instead, since a positional signal has no duration to
divide by. Reusing the hourly denominator here would be the free-parameter error twice over.

**Step 2 — run it against the same-session base rate**, the same control that made Task 2 sound.

**Step 3 — expect the base rate to be high, and say so before running.** Counts run to 139
records in a single transcript, so a majority of *all* boundaries may carry one. A signature that
saturates is uninformative rather than confirming, and the pre-registered reading is: if the
control rate is above roughly half, this check has no power and the result is "no power", not
"no effect". That distinction is the whole point of writing it down first.

**Proof:** hit rate against same-session base rate, per turn-boundary, with the control rate
stated even when the arm is a null.

### Result, 2026-08-30 — a null on 10 of 33 events, and silent on the other 23

**Instrument validated against a hand count first.** `session_turns` now carries a positional
`bridges_before` per turn. On the probe session it returns 2, 0, 0, 0, 0, 0, 3 — matching the
record listing counted by hand before the counter was written, including the reload cluster on
turn 7. The headline sweep is unchanged by the edit: 114 events, 33 unexplained.

| population | unexplained | control | per boundary |
|---|---|---|---|
| all host sessions | 3 / 33 | 436 / 3784 | 0.091 vs **0.115** |
| sessions that can fire | 3 / 10 | 436 / 1436 | 0.300 vs **0.304** |

**Both settings of the population boundary agree, and the restricted row is the one to read.**
3 of 10 against an expected 3.0. Reconnects are no commoner before an unexplained event than
before an ordinary turn.

**The saturation risk pre-registered in Step 3 did not materialise** — the control rate is 0.304,
well under the 0.5 at which the predicate would have separated nothing. So the probe had power in
principle, and this is a null rather than a no-power.

**But the probe is version-gated, and that is the finding with consequences.** `bridge-session`
records exist only from **2.1.232** onward: 77 of 77 sessions at or above it carry at least one,
3 of 197 below `[verified 2026-08-30, derived in `--step5` rather than asserted]`. So 23 of the 33
events ran on a client that never emitted the record and are **structurally blind, not
reconnect-free**. The tempting read — "23 events had no reconnect anywhere in their session" —
would have been a finding, and it is wrong.

**State the n beside the null: 10.** At a 0.304 base rate this excludes a large effect and nothing
finer. It does not retire candidate F, and it should not be quoted as though it did.

**This is the one question in §3's "wait for more data" bucket that genuinely gains power by
waiting**, because every new session is above the gate — but only for events that arise in sessions
uninvolved in this investigation, which is the same contamination §3 names. Not a recommendation to
wait; a note that the arithmetic here differs from the general case.

---

## 3. Considered and rejected

- **Re-running the sweep on more data and waiting for the pattern to sharpen.** The corpus grows
  by ordinary use, but every added session is uncontrolled, and the corpus has now been asked
  every free question it can answer. More of the same data answers nothing new -- and since
  2026-08-29 the corpus also contains this investigation's own sessions, so added data is no
  longer independent of the measurement.
- **Reading the transcripts for the injected block.** Settled and recorded: the blocks are not in
  the JSONL `[verified 2026-08-28: parsed the message content of every record in 4489d30b's
  transcript]`. This is the wall Task 4 exists to go around, not a gap to try harder at.
- **Comparing IDE against CLI sessions in the existing corpus.** Cannot work: by turns it is
  13,952 `claude-vscode` against 3 `cli`. It becomes Task 3 Step 3 instead, as a deliberate pair.
- **Asking the model what changed.** A session cannot see its own injected blocks any more reliably
  than the transcript records them, and a self-report would be unfalsifiable.

## 4. What this plan does not cover

The 81 *explained* events are out of scope except for Task 1 Step 4, which only checks whether the
unknown block contaminates them -- and that step is on hold, since the bands it would check against
did not survive re-baselining. Their causes are known and none of them is a defect.
