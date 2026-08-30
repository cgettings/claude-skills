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

**Status as of 2026-08-29: the free half is spent. Tasks 1 and 2 are done and between them
eliminated most of the candidate field — including this investigation's own leading bet. No
mechanism is identified. Everything that survives needs Task 3, which is now cheap and specific.**

| # | Task | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 1 | Re-question the existing corpus | `cf4aae9`, `6229faa` | **DONE 2026-08-29** — steps 1-3; step 4 on hold | Step 1 expectation falsified; step 3 table below |
| 2 | Find what immediately precedes each event | `6229faa` | **DONE 2026-08-29** — returned a null | 5 signatures, all at or below same-session base rate, every probe firing somewhere |
| 3 | Reproduce on demand in a cheap session | *no commit yet* | **Not started** — unblocked, two named candidates | — |
| 4 | Logging proxy on `ANTHROPIC_BASE_URL` | *no commit yet* | **Parked** — unparked only if Task 3 fails to identify the block | — |

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
- Commits on this machine are GPG-signed. `git commit` blocks on pinentry outside Claude Code, so
  give it a timeout above the 2-minute default `[2026-08-29: a signed commit blocked 2m, did not
  land, and was misreported as the approval gate]`.

**Next command — reproduce the current state before adding to it. Costs nothing:**

```sh
python scripts/sweep-cache-rewrites.py --step2 --step3 --min-create=0 > sweep-now.txt 2>&1
sed -n '/rewrite events/,/^$/p;/Task 2/,$p' sweep-now.txt
# expect ~114 events, ~33 unexplained, self-check >= 20:1 (counts drift; the corpus is live)
# expect Task 2 to still return a null and Task 3's two candidates to still be the only ones left
```

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

**Undefeated but unsupported, and the distinction matters** — it survives because it is largely
untestable from disk, not because evidence favours it. Three reasons no free check reaches the
family: Task 2 tests tool *calls* while a restart changes tool *availability*; `bridgeSessionId`
never rotates within a transcript, so it cannot mark a reconnect `[verified 2026-08-29: 91
transcripts carry one bridge id each, none carries two]`; and the entrypoint comparison has no
control arm. It fits the shape better than A did — invisible in transcripts, uncorrelated with
anything typed, commoner in long sessions, and a block whose size would step with version as IDE
tool schemas change.

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
- `scripts/sweep-cache-rewrites.py` — read the resulting transcript with the same instrument

**Interfaces:** consumes the candidate named by Task 2. Produces either a reproduction, which ends
the investigation, or a failure to reproduce, which unparks Task 4.

**Step 1 — write the expected observations down before running anything.** Numbered predictions:
which turn should rewrite, roughly what `cache_creation` should appear, and what the offset should
be. A run that surprises you is diagnosable only against predictions made in advance.

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
