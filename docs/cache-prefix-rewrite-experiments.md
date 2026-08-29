# Finding the mechanism behind unexplained mid-session prefix rewrites

Some Claude Code sessions rebuild their entire cached prompt prefix mid-conversation with no
attributable cause. `scripts/sweep-cache-rewrites.py` establishes that this happens, when, and how
often; it does not establish **why**. This plan is the cheapest ordered path to why.

The constraint is cost, and it is taken seriously here: **Tasks 1 and 2 spend nothing** — they are
re-questions of data already on disk — and each is capable of ending the investigation on its own.
Only Task 3 spends tokens, and only Task 4 costs real build time. Do not start at Task 4 because it
is the one already designed.

Sibling document: `docs/durable-memory-model.md`, on branch `feature-durable-memory-model`, not on
this one. Its §5 Task 9 holds the proxy design that Task 4 below reuses, and its §0 is the ledger
format this document borrows.

---

## 0. Ledger

**Status as of 2026-08-29: nothing started. The instrument exists (`af0bfe1`), the phenomenon is
measured, the cause is unknown.**

| # | Task | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 1 | Re-question the existing corpus | — | **Not started** — costs nothing, blocks nothing | — |
| 2 | Find what immediately precedes each event | — | **Not started** — costs nothing | — |
| 3 | Reproduce on demand in a cheap session | — | **BLOCKED on Tasks 1-2** naming a candidate | — |
| 4 | Logging proxy on `ANTHROPIC_BASE_URL` | — | **Parked** — unparked only if Tasks 1-3 fail to identify the block | — |

**Environment state — not in this repo, and it goes with the machine.**

- The corpus is `~/.claude/projects/*/*.jsonl`, **367 transcript files / ~13,880 turns and growing**. It is
  live: this plan's own execution adds turns, so every count is only true on its date. Re-running
  the sweep will not reproduce a figure exactly, and that is not a fault.
- Commits on this machine are GPG-signed. `git commit` blocks on pinentry outside Claude Code, so
  give it a timeout above the 2-minute default `[2026-08-29: a signed commit blocked 2m, did not
  land, and was misreported as the approval gate]`.

**Next command — Task 1 step 1, which costs nothing and may end the investigation:**

```sh
python scripts/sweep-cache-rewrites.py --all > sweep-all.txt; wc -l sweep-all.txt
# save it, then read the file rather than the pipe. sweep-all.txt is gitignored below.
# expect ~99 events, ~31 unexplained, self-check >= 20:1 (counts drift; the corpus is live)
```

---

## 1. What is already established

From `scripts/sweep-cache-rewrites.py` at `af0bfe1` `[verified 2026-08-29: 367 transcript files,
13,862 deduplicated turns, continuity self-check 13,420 exact / 169 broken, positive control
reproduced both 2026-08-26 figures — 207,740 and 126,421 — exactly]`:

- **99 rewrite events. 68 explained** — TTL (23), effort switch (15), compaction (10), Claude Code
  version bump mid-session (8), aborted turn immediately prior (5).
- **31 unexplained**, spanning 2026-07-28 to 2026-08-26.
- On the unexplained events the prefix collapses to that session's own start floor **plus a fixed
  offset that steps with version**: 908 exactly (9 events, v2.1.220-223), ~3,770 (4 events,
  v2.1.223-235), ~5,550 (6 events, v2.1.236-246). Three more sit near zero, two are negative, and
  seven of the 31 have no usable start floor.

**What that shape implies, and it is the premise this plan tests.** A discrete constant that steps
with version is a *fixed block* sitting above the cache breakpoint, not conversation content. The
break sits at the top of the message array. So the question is not "what did the user do" but
"what fixed block was added to the request, and by what".

**What the transcript cannot do.** It does not record injected instruction blocks — `grep -c
system-reminder` returns 0 on these files — so the block's *content* is not recoverable from disk
at any sample size. It does record every tool call, timestamp, version, effort, model, and
entrypoint, which is enough to identify the block's *trigger*. Do not let the first fact retire the
second.

---

## 2. Candidate mechanisms

Ranked by how cheaply each can be falsified, not by likelihood.

**A. A deferred tool schema is fetched mid-session, growing the tool-definitions block.** Tool
definitions sit above every cache breakpoint, so adding one invalidates the whole prefix. This
predicts an offset that is fixed per tool-set and steps with version as schemas change, which is
the observed shape. It also predicts the block is absent from the transcript, since tool
definitions are not recorded there. Falsifiable for free by Task 2: a `ToolSearch` call, or the
first use of an MCP tool, immediately before the event.

**B. The IDE integration injects editor state** — opened file, selection — into the system block.
This predicts events uncorrelated with anything the user typed, which matches. **The corpus cannot
test this**: 353 of 363 sessions are `claude-vscode` against 7 `cli` `[verified 2026-08-29: counted
the first `entrypoint` field per transcript]`, so there is no baseline to compare against. It needs
a deliberate CLI session in Task 3, not corpus analysis.

**C. Skill entry or exit rewrites injected content.** Partially observed already: on 2026-08-26,
11 skill exits produced 3 invalidations, one of them 3,177 tokens. That it is *partial* is the
interesting part — if exiting a skill invalidated reliably it would already be classified, so
something distinguishes the 3 from the 8.

**D. An MCP server reconnects or re-registers mid-session**, changing the tool block. Same
signature as A, different trigger, and distinguishable from A only by what precedes the event.

**E. The six already ruled out on 2026-08-26** — TTL, effort switch, permission mode, skill exit,
a global `CLAUDE.md` edit landing on disk, a memory-store write. **They were ruled out against two
events.** There are now 31 and a script. Re-testing them at n=31 is free and is Task 1 step 3; a
mechanism that explains a subset would shrink the unexplained category without any new experiment.

---

## Task 1: Re-question the existing corpus

Costs nothing, runs locally, and can end the investigation. Every step is a re-analysis of data
already on disk.

**Files:**
- `scripts/sweep-cache-rewrites.py` — the instrument; extend it rather than writing a second one
- `~/.claude/projects/*/*.jsonl` — read-only corpus

**Interfaces:** consumes nothing. Produces the residual set of events that survive every free
explanation, which is the input to Task 2.

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

**Proof:** the four step outputs, each a count with its denominator, written into §1 of this
document with the date. No claim about mechanism is licensed by this task — it only narrows.

---

## Task 2: Find what immediately precedes each event

Costs nothing. This is the task most likely to identify the mechanism outright, because it tests
candidates A, C and D at once.

**Files:**
- `scripts/sweep-cache-rewrites.py` — add an antecedent dump behind a flag
- `~/.claude/projects/*/*.jsonl`

**Interfaces:** consumes Task 1's residual event set. Produces either a named trigger, which sends
you to Task 3 to confirm it, or a null, which sends you to Task 3 to test candidate B.

**Step 1 — dump the antecedents.** For each surviving event, emit every record between the previous
assistant turn and the rewriting turn, with `type`, tool name, and any `subtype`. Include the 20
records before that window, because the trigger may precede the last clean turn.

**Step 2 — look for the four signatures**, in this order: a `ToolSearch` call or first use of a
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

**Proof:** for each candidate signature, its frequency before events against its frequency before
matched non-events, both with denominators. A candidate is named only if the two differ.

---

## Task 3: Reproduce on demand in a cheap session

**BLOCKED until Tasks 1-2 name a candidate, or return a null that makes candidate B the only one
left.** The question is about request structure and is model-independent, so this runs on
`claude-haiku-4-5`, not on Opus.

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

**Step 3 — trigger the candidate once**, mid-session, changing nothing else. For candidate A, force
a deferred tool schema fetch. For B, run the identical script under `cli` and under
`claude-vscode` — this is the one pair the corpus cannot supply, and the arms must differ only in
entrypoint. For C, enter and exit a skill.

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
  by ordinary use, but every added session is uncontrolled, and n=31 already shows a clean banded
  structure. More of the same data answers nothing new.
- **Reading the transcripts for the injected block.** Settled and recorded: the blocks are not in
  the JSONL `[verified 2026-08-28: parsed the message content of every record in 4489d30b's
  transcript]`. This is the wall Task 4 exists to go around, not a gap to try harder at.
- **Comparing IDE against CLI sessions in the existing corpus.** Cannot work at 353 against 7. It
  becomes Task 3 Step 3 instead, as a deliberate pair.
- **Asking the model what changed.** A session cannot see its own injected blocks any more reliably
  than the transcript records them, and a self-report would be unfalsifiable.

## 4. What this plan does not cover

The 68 *explained* events are out of scope except for Task 1 Step 4, which only checks whether the
unknown block contaminates them. Their causes are known and none of them is a defect.
