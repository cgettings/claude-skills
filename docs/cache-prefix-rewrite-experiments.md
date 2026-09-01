# Finding the mechanism behind unexplained mid-session prefix rewrites

Some Claude Code sessions rebuild their entire cached prompt prefix mid-conversation with no
attributable cause. `scripts/sweep-cache-rewrites.py` establishes that this happens, when, and how
often; it does not establish **why**. This plan is the cheapest ordered path to why.

The constraint is cost, and it is taken seriously here: **Tasks 1 and 2 spend nothing** — they are
re-questions of data already on disk — and each is capable of ending the investigation on its own.
Only Task 3 spends tokens. **Task 4 was the one that would have cost real build time, and it was
retired unbuilt on 2026-08-30** when the field it was going to reconstruct turned out to be in the
transcript already (Task 6). The ordering principle survives its own best example: the expensive
instrument was the one already designed, and being designed is not a reason to reach for it.

**Zero API spend is not zero cost, so every step writes its per-event output to a file and prints
only aggregates.** Tasks 1 and 2 buy no sessions, but they run *inside* one, and whatever an
analysis pulls inline is re-read at cache rates on every later turn of that session — which is the
same charge this investigation is about. The dumps are large: Task 2 emits a 20-record lead-in for
each surviving event: **829 lines for 33 events** `[measured 2026-08-29]`. The answers are small:
counts with denominators. So
each step below names the file it writes and the aggregate it prints, those files land in `.task3-probe/`, which is gitignored,
and the dump is opened only when an aggregate is surprising — with `grep` or `sed -n`, never whole.

Sibling document: `docs/durable-memory-model.md`, on branch `feature-durable-memory-model`, not on
this one. Its §5 Task 9 holds the proxy design Task 4 was built on before that task was retired
unbuilt, and its §0 is the ledger
format this document borrows.

---

## 0. Ledger

**Status as of 2026-08-30: the residual set is not unexplained. The API labels 27 of the 33, and
the label was in the transcript from the start.** `message.diagnostics.cache_miss_reason` gives
**`tools_changed` 13, `messages_changed` 9, `system_changed` 5, absent 6** — see Task 6. The field
validates on the explained population: all 16 `effort` switches read `unavailable`, all 3 model
changes read `model_changed`, 29 of 30 TTL events read `previous_message_not_found`.

**Three consequences, in order of how much they change.** **Candidate A is reopened and is the
commonest cause in the residual set** — it was rejected on a `ToolSearch` call-frequency proxy while
the direct field said `tools_changed`; D is reopened with it. **`messages_changed` is a class §2
never contained**, and **Task 7 has now retired its leading explanation**: the undetected
compaction family (§1.5, open item 1) is real but marks nothing the classifier misses, and all
nine prefixes grew rather than shrank, which no compaction does. **Task 4 is retired**: it existed to recover from request bytes a fact the server
states in a field.

**The free routes to `messages_changed` are now exhausted.** Task 7 excluded compaction and Task 7b
showed the transcript cannot reach what replaces it: the injected-block subtypes are too rare for a
9-window probe to resolve at any effect size. What is left for that class is an instrument that sees
the request, which is the retired proxy, or nothing.

**A new instrument arrived the same day: a per-session client debug log on disk (Task 9).** It does
not read the prefix and does not revive Task 4, but it joins to the transcript exactly on
`requestId` and it names the client-side tool, skill, MCP and permission changes that are the
plausible mechanism behind `tools_changed` and `system_changed` -- 18 of the 33. It is not
retroactive, so it can only explain events from here on.

Tasks 1, 2, 3 and 5 stand as run, but read their nulls narrowly — each tested a *trigger* predicate
against a residual set that was never causeless. Arm B still has no non-VS Code entrypoint and is
not in the critical path.

| # | Task | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 1 | Re-question the existing corpus | `cf4aae9`, `6229faa` | **DONE 2026-08-29** — steps 1-3; step 4 on hold | Step 1 expectation falsified; step 3 table below |
| 1.5 | Task 1 Step 5 — re-test E over every mode-change boundary | `be911f6` | **DONE 2026-08-30** — E not supported | 58 mode-alone boundaries; pooled 8/58 vs control 55/6,130, but median gap 487 s vs 13 s and no gap band with a readable n survives. Both pre-registered no-power conditions cleared |
| 2 | Find what immediately precedes each event | `6229faa` | **DONE 2026-08-29** — returned a null | 5 signatures, all at or below same-session base rate, every probe firing somewhere |
| 3a | Task 3 arm F/window-reload | `07bca1c`, `d343ce6` | **DONE 2026-08-30** — null; **narrowed 2026-08-31** to reloads that hold the permission mode fixed | Session `6597c649`: turn 7 read 52,670 = 52,487 + 183, exact. Predictions 1, 4 hit; 2 missed; 3 N/A. The arm ran at `acceptEdits` on all 7 turns, so it never had a mode to lose. Session `d3567442` re-initialised out of `auto` into `acceptEdits` at 21:46:06Z and took a `system_changed` rewrite 7 s later — reload plus a mode change does rewrite, at n=1. See Task 9's 9b result |
| 3b | Task 3 arm F/host-restart | `d7cba60` predictions, `41e34cd` result | **DONE 2026-08-30** — null | Session `1b26f4d4`: turn 7 read 52,895 = 52,750 + 145, exact; `bridges_before` `t1:2 … t7:3`. All 4 predictions hit |
| 3c | Task 3 arm F/quit-relaunch | `41e34cd` predictions, `ff2767a` result | **DONE 2026-08-30** — null | Session `06de8063`: turn 7 read 52,907 = 52,725 + 182, exact; resumed in place, same file and same `bridgeSessionId`; `bridges_before` `t1:2 … t7:3`. Predictions 1, 3, 4, 5 hit; 2 missed; 6 N/A |
| 3d | Task 3 arm E (permission mode), on Haiku | `ff2767a` predictions, `8e072c6` result | **VOID 2026-08-30** for its two plan boundaries; one clean null beside them | Session `9e76ff00`: labels `acceptEdits→plan→default→acceptEdits`, so predictions 1, 3, 4 hit. Both rewrites carry `haiku/None → sonnet-5/high`, an already-explained cause. Boundary 6→7 mode-alone, read 54,230 = 52,472 + 1,758, exact |
| 3e | Task 3 arm B (cli vs claude-vscode) | *no commit* | **Not started** — needs a non-VS Code entrypoint | — |
| 3f | Task 3 arm E re-run, on a model whose plan mode is mode-alone | *no commit* | **NOT WORTH BUYING 2026-08-30** — Step 5 put E's signal down to gap composition. Unblock only if a mode-linked block turns up; Task 4, which was that route, is retired, so the live route is the 5 `system_changed` events in Task 6. The two-turn pre-flight below still applies if it ever runs | **The unblock condition is arguably met as of 2026-08-31 and is not being called met.** `d3567442`'s `system_changed` sits 7 s after `auto → acceptEdits`, which is a mode-linked block by inference — the log never dumps the system prompt, so "the auto-mode block left the prompt" is read off the mode field plus the server's label, and something unlogged could have moved instead. Buying the arm also costs more than it did: see Task 9 §1 on why no session on this machine can *start* in auto while the wrapper is configured |
| 4 | Logging proxy on `ANTHROPIC_BASE_URL` | *no commit* — never built | **RETIRED 2026-08-30** — superseded by Task 6. It existed to recover injected block identity from request bytes; `cache_miss_reason` states it directly, retroactively, corpus-wide | — |
| 5 | Do the rewrites sit on a client reconnect? | `fd87d13` | **DONE 2026-08-30** — null at n=10; version-gated at 2.1.232, so blind on 23 of 33 events | 3/10 against a 0.304 base rate; counter validated against a hand count |
| 6 | Join the server's `cache_miss_reason` onto the events | `b1d62da` | **DONE 2026-08-30** — 27 of 33 labelled | `scripts/join-cache-miss-reason.py --min-create=0`: 376 files, 14,344 turns, 116 events, 33 unexplained. Instrument validated on the explained set (16/16 effort to `unavailable`, 3/3 model to `model_changed`) |
| 7 | Audit the compaction classifier against the client's real compaction family | `5e6e3d9` scripts, `ded2f92` write-up | **DONE 2026-08-30** — compaction is not the explanation | Two arms. Markers: the classifier is blind to `SessionStart:compact` (15/12 sessions) and queued `/compact` (11/8), and both are redundant with the two it sees — 0 of 9 events have any `compact`-bearing record in the boundary window; positive control 15 boundaries classify as `compaction`. Arithmetic: all 9 prefixes **grew**, +1,219 to +6,990 against session medians 821–1,313, 0 of 9 shrank |
| 7b | What arrives at the 9 `messages_changed` boundaries | `a8478d7` | **DONE 2026-08-30** — null on the common shapes, **no power** on the named ones | Pooled, `queue-operation` 9/9 vs 60/1,253 (20.9x) and `system` 8/9 vs 53 (21.0x) — both are window duration: event median gap 292 s against a control median of 13 s, and stratified the ratio decays 22.5x → 3.73x → 1.55x → 1.46x. The six named attachment subtypes expect 0.007–0.043 hits in 9 windows, under 1 even at tenfold, so their zero says nothing |
| 8 | The 6 events carrying no diagnostics | *no commit* | **NOT STARTED** — genuinely open; the only members of the original 33 still causeless | — |
| 9a | Is there a key that joins the debug log to the transcript? | *no commit* — verified ad hoc, script owed | **DONE 2026-08-30** — the join is exact | 23 of 24 `req_` ids shared between `~/.claude/debug/fac8c194….txt` and its own transcript's `requestId`; the 1-and-1 residual is the live edge, both files being appended to mid-check. The debug log's `x-client-request-id` is a *different*, client-side UUID and does **not** join |
| 9b | Positive control: does a rewrite with a known cause leave any debug-log signature? | *no commit* | **DONE 2026-08-31** — the log sees one of the two classes, and the design as written would have measured its own blind spot | Answered off a session already on disk rather than a bought trigger. `d3567442` (EH-dataportal) carries both: `system_changed` at 21:46:13Z with a full teardown/re-init signature, `messages_changed` at 20:52:05Z with nothing distinguishing it from an ordinary turn. **Do not run the forced effort switch** — the log records no effort, reasoning or thinking field anywhere, so its null would have been the instrument's blind spot read as the answer. Result under Task 9 |
| 9c | `tools_changed` (13 of 33) against the log's tool-loading lines | *no commit* | **UNBLOCKED 2026-08-31 — and the lead candidate is weaker than when it was written** | `Dynamic tool loading:` moved 48 → 47 in `d3567442`, at the `system_changed` boundary and not at a `tools_changed` one — the opposite of 9c's pre-registered prediction, at n=1. It tracks the re-init and nothing else: the mode returned to `auto` and the pool stayed at 47, and the MCP set was constant across both inits, so the drop has no identified cause. The other candidates are untested and one is now known-constant: `Loaded 5 unique skills` was identical all 12 times in that log, including across the re-init. Keep the **gap-stratified** design, which is the condition that turned Task 7b's 20.9x into 1.55x |
| 9d | `system_changed` (5 of 33) against permission and hook lines | *no commit* | **UNBLOCKED 2026-08-31 — swap the primary candidate** | `Applying permission update:` aligns with neither event in `d3567442`: the nearest to the 21:46:13Z `system_changed` is 21:47:36Z, **83 s after it**. The line that did carry the information is `[session-notices] … mode=`, which tracks the transcript's per-turn `permissionMode` label. Same stratified design as 9c, at a fifth of the n — see the power table in Task 9 before reading any null here |
| 9e | Do the non-main-loop calls share the prefix? | *no commit* | **PARKED — no free instrument** | The log shows a session makes ~40 `/v1/messages` calls of which only ~23 are `source=sdk`; the rest are `side_query` and one-offs (`generate_session_title`, `growthbook`, `payload`). The whole existing corpus has only ever seen the sdk turns. Unparks only if some instrument can show whether a side query shares the cached prefix — the debug log carries no bodies and no token counts, so it cannot |

**Task 1 step 4 is on hold, not done.** It asks whether the explained events carry an offset in one
of the three bands. The bands did not survive re-baselining (§1), so there is nothing stable to
check contamination against. Unhold it if a denominator is ever established.

**Environment state — not in this repo, and it goes with the machine.**

- The corpus is `~/.claude/projects/*/*.jsonl`, **374 transcript files / 14,228 turns and growing**
  `[measured 2026-08-30, the last run of the day; it was 367 / ~13,970 on 2026-08-29]`. It is live:
  this plan's own execution adds turns, so every count is only true on its date. Re-running the
  sweep will not reproduce a figure exactly, and that is not a fault.
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
  `[verified 2026-08-30: git check-ignore exits 1 on .task3-probe/ here]`. Stage by path here.
  `.task3-probe/` holds ten files `[verified 2026-08-30: `ls -1 | wc -l`]`, including `cache-miss-reason-join.txt` (Task 6's per-event detail) and
  `sweep-2026-08-30.txt`, the 69-row `arm-e-mode-effort-crosstab.txt` behind the arm E result, and a
  `CLAUDE.md.live-backup` this plan did not create. All of it is machine-local evidence rather than
  input — nothing here should be blocked by its absence, and none of it should be committed.
- Commits on this machine are GPG-signed. `git commit` blocks on pinentry outside Claude Code, so
  give it a timeout above the 2-minute default `[2026-08-29: a signed commit blocked 2m, did not
  land, and was misreported as the approval gate]`.
- **The probe sessions live in `~/.claude/projects/c--Users-Chris-Documents-Projects-rewrite-testing/`
  and none of them may be added to.** Each is one arm's evidence; a further turn fuses two triggers
  into one continuity sequence. Which is which: `6597c649` = arm F/window-reload, 7 turns, cold
  start; `1b26f4d4` = arm F/host-restart, 7 turns, warm start; `06de8063` = arm F/quit-relaunch,
  7 turns, warm start; `9e76ff00` = arm E on Haiku, 7 turns, void for its plan boundaries and
  carrying an unanswered `AskUserQuestion` at turn 5; `157ef24e` = discarded, 1 turn, contaminated,
  and now the control for the first-turn growth measurement in Task 3. The scratch project
  directory `~/Documents/Projects/rewrite-testing` is empty and must stay empty — a project
  `CLAUDE.md` appearing there would change the prefix under the probe.
- **Do not write to `~/.claude/CLAUDE.md` or `MEMORY.md` while a probe session is open.** Both are
  always-loaded, so an edit lands inside the arm's measurement window. This happened on 2026-08-30:
  a lessons pass edited the instructions file at 02:58:13Z, eight minutes into session `157ef24e`,
  which was discarded for it. Hold any `distill-lessons` or `reconcile-records` pass until the open
  arm is scored.

**Re-run of the state check, 2026-08-30: reproduces.** `--min-create=0` over 369 files / 14,037
turns gives 114 events, 33 unexplained, self-check 13,591 exact / 171 broken (79:1). Against
2026-08-29's 367 / 13,963 the corpus grew and the counts did not, so the instrument is intact.
Output in `.task3-probe/sweep-2026-08-30.txt`. **Superseded by the last run of the same day** — over
374 / 14,228 it reads 115 / 33, the one added event being arm 3d's own effort switch, correctly
classified; see Task 1 Step 5's result. Two candidates survived when this paragraph was written and
none does now.

**Next command -- ambient collection for 9c and 9d. 9b is answered and must not be bought.** The
gate came free from `d3567442`, a session already on disk (Task 9's 9b result): the log leaves a
legible signature at a `system_changed` boundary and none at a `messages_changed` one, so the
family is alive but half-blind. **Do not run 9b as it was written** -- a forced effort switch
probes a field this log never records, and its null would have read as "the log cannot see
rewrites". What 9c and 9d need now is *events inside debug-logged sessions*, and that is ambient
collection at 28.9 and 75.2 sessions per event -- so the standing step is to re-run Task 6's join
restricted to sessions that have a `~/.claude/debug/<id>.txt`, and read the boundary window of
whatever it returns. **Confirm that session's own log exists and is non-trivial before reading any
null from it**; a missing log is a broken instrument, not an absent event. Task 8's 6 events stay
genuinely open but are the rarest class in the corpus (62.7 sessions per expected event) and have
no instrument the others lack. **Stratify every rate by gap
before reading it** -- that is what turned Task 7b's two 21x hits into a null, and it is the third
time on this plan that an unstratified window rate has misreported. **Do not build the proxy** --
Task 4 is retired, the debug log carries no request bodies, and §1.5 says why.

```sh
cd ~/Documents/Projects/claude-skills

# the finding this hand-off rests on: coverage first, then the distribution.
# 33 unexplained is stable; the EVENT total drifts upward as the live corpus grows
# (115 and 116 on 2026-08-30, 116 again at Task 7) -- the drift is not a fault.
python scripts/join-cache-miss-reason.py --min-create=0 | head -22

# Task 7, to re-derive it. Prints its own positive control (expect: 15 boundaries
# classify as `compaction`) and the arithmetic arm (expect: 0 of 9 shrank).
python scripts/audit-compaction-markers.py > .task3-probe/task7-run.txt 2>&1 ; \
  tail -20 .task3-probe/task7-run.txt

# Task 7b, and its control arm. Run the gap one whenever you read the pooled one:
# pooled says 20.9x, stratified says 1.55x on n=5, and the second is the answer.
python scripts/audit-boundary-arrivals.py > .task3-probe/task7b-run.txt 2>&1 ; \
  python scripts/audit-boundary-arrivals-gap.py > .task3-probe/task7b-gap.txt 2>&1 ; \
  tail -30 .task3-probe/task7b-gap.txt

# the nine events, each line naming its transcript and timestamp -- the input to
# the next step, which is to diff their first user message's attachment records
grep messages_changed .task3-probe/cache-miss-reason-join.txt | grep UNEXPLAINED

# the older state, if a Step 5 figure needs re-deriving
python scripts/sweep-cache-rewrites.py --min-create=0 --step6 > .task3-probe/step5-rerun.txt 2>&1 ; \
  sed -n '/rewrite events:/p;/Task 1 Step 5/,$p' .task3-probe/step5-rerun.txt
```

**Five scripts carry Tasks 7 and 7b**: `audit-compaction-markers.py` (the audit), `-values.py`
(distinct values on the blind paths), `-coverage.py` (whether the blind markers mark anything
new), `audit-boundary-arrivals.py` (what arrives at the 9) and `-gap.py` (its duration control).
Each takes no arguments or one `--reason=LABEL`, and each rejects an unrecognised argument rather
than treating it as none — so each is re-runnable against `tools_changed` or `system_changed`,
which is the cheapest way to ask the same questions of the other two classes. Their outputs land
in `.task3-probe/`, which is machine-local evidence and not to be committed.

**Arm 3f is not worth buying on current evidence** and its row says so. If Task 4 ever turns up a
block that moves with permission mode, the arm becomes worth running again — and if it does, two
things carry over. Do not run it on Haiku: entering plan mode there swaps in `claude-sonnet-5` at
effort `high`, which is what voided 3d. Sonnet is the cheaper candidate, **but whether *its* plan
mode is mode-alone is untested** — every corpus plan boundary is an Opus session, so there is no
evidence either way and it must not be assumed.

**Pre-flight for 3f if it is ever unblocked: two turns, not seven.** The fault that voided 3d was
discoverable before the arm was spent. One ordinary turn, shift+tab into plan mode, one more turn,
then read the `model` and `effort` columns of `read-session-prefix.py`. **If either moves across
that boundary the model is unusable for this arm** — stop there rather than spending the remaining
five turns.

**Reading a probe transcript, for whichever arm comes next:**

```sh
# 1. find the new transcript: none of 6597c649, 1b26f4d4, 06de8063, 9e76ff00, 157ef24e
ls -t ~/.claude/projects/c--Users-Chris-Documents-Projects-rewrite-testing/*.jsonl

# 2. per-turn continuity, and it prints the model and effort columns that caught 3d's fault.
#    Use THIS script, not the sweep: the sweep's PREV_MIN/CREATE_MIN floors are both 50,000 and
#    the probe prefix is ~53,000, so a real rebuild would sit on the threshold.
python scripts/read-session-prefix.py '<the new transcript, as a WINDOWS path>'

# 3. the per-turn permissionMode label, which is what makes a null readable.
#    Positive control: this returns 7 `acceptEdits` lines on 06de8063 [verified 2026-08-30].
python -c "import json,sys; [print('rec %3d  %s' % (i, r.get('permissionMode'))) for i,r in enumerate(json.loads(l) for l in open(sys.argv[1],encoding='utf-8') if l.strip()) if isinstance(r,dict) and r.get('permissionMode')]" '<WINDOWS path>'

# 4. the bridge cluster -- how the three F arms established that their trigger fired at all
python -c "import importlib.util as u; sp=u.spec_from_file_location('sw','scripts/sweep-cache-rewrites.py'); m=u.module_from_spec(sp); sp.loader.exec_module(m); t,_=m.session_turns(r'<WINDOWS path>'); print(' '.join('t%d:%d'%(i,x['bridges_before']) for i,x in enumerate(t,1)))"
```

**Read the cause column before reading the result.** A `REWRITE` cell naming an effort, model,
version or TTL cause is an already-explained event and voids that boundary rather than confirming
the arm — which is the whole of what happened to 3d, and it is invisible if you read only the
continuity column.

**Hand Python a Windows path, never a `/c/...` one.** Git Bash's form reaches a Windows interpreter
as a relative path and raises `FileNotFoundError` on a file that exists `[2026-08-30]`.

Arm B (3e) stays blocked on a non-VS Code entrypoint and is not in the critical path.

**Do not spend a session on an extension update.** §2 records why that member cannot produce an
unexplained event: a trigger that moves the version string tests an already-explained cause, which
voids an arm rather than confounding it.

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

**~~What the transcript cannot do.~~ FALSE, corrected 2026-08-30 — see §1.5.** The claim was that
the transcript does not record injected instruction blocks, on the evidence that `grep -c
system-reminder` returns 0 on these files, and therefore that the block's *content* is not
recoverable from disk at any sample size. **The transcripts do record injected blocks**, as
`attachment` records: 18,988 of them across 376 files in 24 subtypes, several carrying the injected
text verbatim — `mcp_instructions_delta` in `addedBlocks`, `agent_listing_delta` in `addedLines`,
`nested_memory` in both `content` and `rawContent`. The grep searched for a string this format does
not use, and a narrow search's zero was promoted into a property of the format. **Retract it
wherever it has been quoted**: it is the sole justification for Task 4 existing, and it retired the
cheapest instrument in the inventory before an inventory had been taken. The rest of the paragraph
stands — the transcript also records every tool call, timestamp, version, effort, model and
entrypoint, which is enough to identify the block's *trigger*.

---

## 1.5. The instrument inventory

**This section exists because it was missing, and its absence cost the investigation two candidates
and nearly cost it a build.** §2 enumerates candidate *mechanisms*; there was never a corresponding
list of candidate *instruments*, so every task varied the hypothesis against the one instrument
already in hand. When §1 declared the transcript unable to carry injected content, the plan reached
for the most expensive instrument buildable — a local HTTP proxy — with nothing enumerated in
between. Two tiers sat in that gap, and the transcript itself had not been exhausted.

**Enumerating is mechanical and free, and needs no hypothesis.** `claude --help`; the binary's own
string namespaces (`grep -oa 'tengu_[a-z0-9_]*'` returns **1,856** event names, `grep -oa
'OTEL_[A-Z_]*'` the telemetry surface); and `ls ~/.claude`. **Do this before enumerating mechanisms,
not after they run out.** The failure mode it prevents is specific: a grep run in the *confirmation*
direction — once per member of a set already chosen — cannot surface a member nobody named. The
enumeration direction is the same tool at the same cost.

| # | Instrument | Sees | Blind to | Cost | Retroactive |
|---|---|---|---|---|---|
| I1 | Session transcripts `~/.claude/projects/*/*.jsonl` | turn usage, every tool call, **injected blocks as `attachment` records**, mode/version/effort/model/entrypoint | request bytes as sent; system-block assembly | free | **yes, full corpus** |
| I2 | Telemetry spill `~/.claude/telemetry/1p_failed_events.*.json` | `tengu_*` events with env, betas, auth, per-event metadata | anything that uploaded successfully | free | no — biased remnant |
| I3 | OTEL export (`CLAUDE_CODE_ENABLE_TELEMETRY`) | the full `tengu_*` stream, live | nothing the client does not instrument | one env var | no |
| I4 | `--debug [filter]`, `--debug-file`, `ANTHROPIC_LOG=debug` | request URL, headers, timing, body *shape*, system-block **count** | `messages`, `system`, `tools` contents (elided as `[Object ...]`); no `usage` | one flag | no |
| I5 | Hooks | anything, at defined lifecycle events | what no hook event fires on | small script | no |
| I6 | Per-PID session records `~/.claude/sessions/<pid>.json` | `sessionId`, `cwd`, `startedAt`, `version`, `kind`, `entrypoint`, `peerFeatures` | anything mid-session | free | partial — live PIDs only |
| I7 | `~/.claude/history.jsonl` | user prompt display text, timestamp, project, sessionId | everything else | free | yes |
| I8 | Logging proxy on `ANTHROPIC_BASE_URL` | the actual request bytes | nothing, but costs a build | a day + SSE relay risk | no |

**I1 is the instrument this plan wrote off, and it is the richest one.** 376 files, **84,165
top-level records**, 19 record types `[verified 2026-08-30]`. **18,988 are `attachment` records** —
more than the 16,406 `user` turns — in 24 subtypes, of which these carry injected content:

| subtype | n | carries |
|---|---|---|
| `output_style` | 8,848 | the injected style block |
| `total_tokens_reminder` | 6,174 | the `<total_tokens>` literal |
| `deferred_tools_delta` | 409 | `addedNames`, `removedNames`, `readdedNames`, `wireHiddenNames` |
| `skill_listing` | 395 | the skill roster |
| `hook_additional_context` | 393 | hook-injected text |
| `mcp_instructions_delta` | 387 | `addedBlocks` — the literal instruction text |
| `agent_listing_delta` | 385 | `addedLines` — the literal roster text |
| `command_permissions` | 249 | `allowedTools` |
| `edited_text_file` | 175 | `snippet` |
| `nested_memory` | 2 | `content` **and** `rawContent`, plus `contentDiffersFromDisk` |

**Two of these are the direct record for candidates §2 A and D, which were falsified by proxy.**
A was rejected on `ToolSearch` *call* frequency while `deferred_tools_delta` records the schema
arrivals themselves; D was rejected on MCP tool *calls*, and §2 says in as many words that "a
re-registration emits no `tool_use` record at all, so this predicate never tested it" —
`mcp_instructions_delta` is that record. Neither falsification tested its candidate.

**I1 has a parsing trap that silently halves the corpus.** Records are not one-per-line: some are
pretty-printed across many lines. A line-oriented `json.loads` pass drops **102,219 lines** and
still returns plausible counts `[verified 2026-08-30: 84,165 records via the sweep's records()
against a naive per-line pass that failed on 102,219 lines]`. Always parse through
`sweep-cache-rewrites.py`'s `records()`, which uses `raw_decode`. This is also why `grep -c
system-reminder` was never a sound test of what the format holds.

**I2 is proof of schema, not a corpus.** 3 files / 456 KB / **187 records from 3 sessions**, and
they are there *because they failed to upload* — a biased remnant, not a log. It cannot be mined for
the 33 events. What it does establish, from real records, is the event shape and that these fire:
`tengu_claudemd__initial_load` (`file_count 3`, `total_content_length 55539`, `automem_count 1`),
`tengu_cache_eviction_hint` (`scope`, `last_request_id`), `tengu_config_cache_stats` (`cache_hits`,
`cache_misses`, `hit_rate`). Every record's `betas` list includes
`mid-conversation-system-2026-04-07`.

**Two parsing traps, and both return a clean false zero rather than an error.** These files are
multi-document despite the `.json` extension, so `json.load` raises `Extra data: line 2` and a
reader that swallows it reports no records at all — use `sweep-cache-rewrites.py`'s `records()`,
as with I1. And the event name lives at **`event_data.event_name`**, not at any top-level key, so
a census keyed on `name` or `eventName` returns the right record count with zero names attached.
That second one is the dangerous shape: 187 matches the figure above exactly, which reads as the
reader being validated when only the reader was `[both hit 2026-08-30, during Task 7]`.

**I3 is where the unexamined surface is.** Of the 1,856 instrumented events, **249 match
prefix-relevant terms**. These are grep hits — the names exist, and nothing here establishes that
any fires or what it carries:

- Directly on this question: `tengu_prompt_cache_break`, `tengu_prompt_cache_diagnosis_received`,
  `tengu_prompt_cache_diagnostics`, `tengu_api_cache_breakpoints`, `tengu_cache_eviction_hint`,
  `tengu_sysprompt_block`, `tengu_sysprompt_boundary_found`,
  `tengu_sysprompt_missing_boundary_marker`, `tengu_sysprompt_using_tool_based_cache`.
- Named injection paths: `tengu_lsp_diagnostics_injected`, `tengu_memdir_pinned_injected`,
  `tengu_hook_plugin_injected`, `tengu_mid_conv_system_fallback_retry`,
  `tengu_deferred_tool_schema_not_sent`, `tengu_reload_plugins_cache_impact`.
- **A compaction family the sweep's classifier does not know about**:
  `tengu_time_based_microcompact`, `tengu_partial_compact`, and ten
  `tengu_precomputed_compact_*` events (`ready`, `consumed`, `discarded`, `rehydrated`,
  `rehydrate_rejected`, `persisted`, …). See the open item below.

`tengu_prompt_cache_diagnosis_received` is the highest-value name in the list, because a
server-supplied miss reason has already been witnessed once on this machine: the
`claude-p-resume-prefix-divergence` memory records that "the API labels the miss `system_changed`".

**Open items, each with the command that settles it.**

1. **SETTLED 2026-08-30 by Task 7 — the classifier's blind spot is real and marks nothing, and
   the 9 `messages_changed` events are not compactions.** The original item is kept below
   because its reasoning still holds; only its conclusion moved. **Does the sweep's compaction
   classifier see a microcompact or a partial compact?** It keys on
   `isCompactSummary is True` or a `system` record whose `subtype` contains `compact`
   (`sweep-cache-rewrites.py`, `session_turns`). Corpus-wide there are only **15 `compact_boundary`
   subtypes and 15 `isCompactSummary` records**
   `[re-measured 2026-08-30 over 377 files; it was 15 and 14 on 376]` — against a binary that instruments at least twelve
   distinct compaction events. If a microcompact writes neither, it rewrites the prefix and reaches
   the residual set as unexplained. **This was the leading alternative explanation for the 33,
   and it was free to test; Task 7 ran it and it is not supported.** Note it also predicts the Step 5 gap result: a *time-based* microcompact is
   driven by idle duration, so the 487 s median idle that Step 5 divided out as composition would be
   the mechanism rather than a confound.
2. **The `--debug` category list.** The filter is free-form and the identifiers are minified, so the
   set is not recoverable from the bundle `[checked 2026-08-30: no DEBUG_CATEG*, debugCategor*,
   debugFilter* or isDebugEnabled* symbols survive minification]`. `--help` names `api`, `hooks`,
   `1p` and `file` as examples only. Settle it by running one throwaway with
   `--debug --debug-file <path>` and reading the category prefixes actually emitted.
3. **Which of the 249 events fire, and what they carry.** One throwaway session with
   `CLAUDE_CODE_ENABLE_TELEMETRY=1 OTEL_LOGS_EXPORTER=console`, output redirected to a file. This is
   a positive control for I3, not an experiment.

**Not instruments, but state worth knowing exists**: `file-history/` (1,401 files / 31 MB),
`shell-snapshots/` (53 / 3.3 MB), `plans/`, `backups/`, `cache/`, `uploads/`, `ide/*.lock`. None
carries prompt-prefix information.

---

## 2. Candidate mechanisms

Originally ranked by how cheaply each could be falsified. Three of them now have been.

**A. A deferred tool schema is fetched mid-session, growing the tool-definitions block.**
**REOPENED 2026-08-30, and it is the commonest cause in the residual set.** The server labels
**13 of the 33 `tools_changed`** (Task 6) — the tool block is what moved. The 2026-08-29
falsification stands as a fact about its own predicate and not about the candidate: `ToolSearch`
appears before events at 1.24/hour against a control of 2.17, and first-use-of-any-tool at 3.73
against 7.13, both below base rate. **Tool *calls* were never the mechanism.** A schema arriving
changes the block whether or not anything calls it, and `attachment` records of subtype
`deferred_tools_delta` — 409 corpus-wide, carrying `addedNames` and `removedNames` — are the direct
record the predicate should have used. What is open is which arrivals coincide with the 13.

**B. The IDE integration injects editor state** — opened file, selection — into the system block.
Predicts events uncorrelated with anything the user typed, which matches. **The corpus cannot test
this and the gap is worse than first recorded**: by turns rather than transcripts it is 13,952
`claude-vscode` against 3 `cli` `[verified 2026-08-29]`. Needs a deliberate pair in Task 3.

**C. Skill entry or exit rewrites injected content.** **FALSIFIED 2026-08-29 by Task 2**: 0.93/hour
before events against 2.46 in the same sessions, and Task 1 step 3 agrees at 0.31 against 0.53. The
2026-08-26 observation of 3 invalidations from 11 skill exits does not survive a base rate.

**D. An MCP server reconnects or re-registers mid-session**, changing the tool block. **REOPENED
2026-08-30 alongside A**, and for the same reason: the 13 `tools_changed` events do not distinguish
a deferred-schema arrival from an MCP re-registration, so both candidates are live and the test that
separates them has not been run. The call-frequency figures stand and remain irrelevant — any MCP
use runs 0.62/hour against 2.57, first MCP use is 0 of 33 with a live probe (119 control hits), and
this document already recorded that "a re-registration emits no `tool_use` record at all, so this
predicate never tested it." `mcp_instructions_delta`, 387 records carrying `addedBlocks`, is the
record it should have used (§1.5).

**E. The six ruled out on 2026-08-26, re-tested at n=33 — and one did not stay ruled out.**
Skill exit, global `CLAUDE.md` edit and memory-store write all fire *below* the same-session base
rate, which is a stronger confirmation than zero would have been. TTL and effort switch score zero
**by construction, not by test**: the classifier removes them before an event can reach the
unexplained set. **Permission mode sits at 8.1x on n=3** — `plan→auto`, `auto→acceptEdits`,
`plan→acceptEdits`, all genuine transitions rather than the empty-history artifact the predicate
could have produced. Treat it as a lead, not a finding: one of the three is a `cache_read == 0`
event, the control was refined after seeing the data, `permissionMode` appears on only ~1,357
records, and direction of causation is untested. Two of three involve leaving plan mode, which is
a mechanism rather than a bare correlation. **This is the last surviving lead as of 2026-08-30.**
Its arm ran the same day and was void for the two plan-mode boundaries — on Haiku, entering plan
mode swaps in `claude-sonnet-5` at effort `high`, which is an already-explained cause — while its
one mode-alone boundary returned a clean null. What the arm did produce is a better population: the
lead rests on n=3 only because the predicate looked at boundaries that had already survived the
classifier, and the corpus holds 74 mode-change boundaries. **Task 1 Step 5 asked the larger
question on 2026-08-30 and E did not survive it.** Over 58 mode-alone boundaries the pooled rate is
15x control — and mode changes sit at a median 487 s of idle against 13 s at a control boundary, so
the populations differ in the one variable that drives rewrites on its own. Stratified by gap, no
band with a readable denominator shows an effect, and the three unexplained events are the same
three the 8.1x rested on, all at 26-35 minutes idle. **Not supported, and not falsified** — the
bands where it could still hide have single-digit denominators.

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

**Closed 2026-08-30, after three arms.** Window reload, extension-host restart and full
quit-relaunch each produced the reconnect signature and each left the prefix exactly where continuity
predicts; Task 5 found reconnects no commoner before an unexplained event than before an ordinary
turn. The quit arm is the one that matters most, because it tested *resumption from disk* rather
than reconnection with the conversation still in memory, and that was the last version-silent
mechanism the family had. What remains untested is a VS Code application update, which cannot be
triggered on demand — and the update member that can be, a Claude Code extension update, is excluded
by construction above. Treat F as falsified for the 33 unless the application-update remnant is
reached some other way. Task 4's request-body diff was that other way and is retired; what replaces
it is narrower and free — F now has to account for a specific 5 of the 33, the ones the server labels
`system_changed` (Task 6), rather than for the residual set as a whole.

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

**Step 5 — re-test candidate E over every mode-change boundary, not over the three that reached the
residual set. Added 2026-08-30 by the arm E run, costs nothing, and it should run before any further
session is bought.** The 8.1x rests on n=3 because the predicate only ever looked at boundaries that
had already survived the classifier. Asked directly, the corpus holds **69 permission-mode-change
boundaries across 276 sessions** `[verified 2026-08-30]`, which is a population large enough to
settle E either way for free.

Four things this step must do, each of them a trap the earlier passes already paid for:

1. **Use the sweep's own classifier, not a hand-rolled threshold.** The scratch cross-tab that found
   the 69 used `read < 0.5 x expected` and disagrees with `read-session-prefix.py` on a boundary
   both of them saw. Reuse `session_turns` and the real cause assignment; do not re-implement.
2. **Separate mode-alone boundaries from the rest before counting anything.** A boundary carrying an
   effort or model change tests an explained cause, and pooling the two is exactly what made the
   arm E session unreadable. The split is an exact field read and costs nothing.
3. **Report against a same-session base rate, per turn-boundary** — the control that made Task 2 and
   Task 5 sound. A raw rate over 69 boundaries is not a result.
4. **State the direction problem rather than resolving it by assertion.** A mode change and a
   rewrite can both be downstream of the user starting something new. Nothing in the corpus
   separates those, and the write-up should say so.

**Expected if E is real:** mode-alone boundaries rewrite above the same-session base rate, and the
`plan → X` subset above the rest. **Expected if E is the n=3 artifact it might be:** at or below
base rate once the effort-carrying boundaries are removed, which retires the last candidate and
unparks Task 4 unconditionally.

**Pre-registered before the code was written, 2026-08-30.** Task 5's lesson is that a null and a
no-power are indistinguishable after the fact, so the no-power conditions are named first:

1. **Population and its blind spot.** `PREV_MIN` is 50,000, so no boundary in a session below that
   prefix can register as an event at all. Report how many of the 69 clear it *before* reporting any
   rate. **If fewer than 20 mode-alone boundaries clear `PREV_MIN`, this step has no power and the
   answer is "no power", not "no effect"** — the same distinction Task 5 turned on.
2. **The split is reported, never pooled.** Mode-alone boundaries against those also carrying an
   effort, model or version change. The second group is void by construction — it tests an explained
   cause, which is exactly what happened to arm 3d — and it is reported as a count, not as data.
3. **Control: same-session boundaries with no mode change, also above `PREV_MIN`,** per turn
   boundary. **If the control rate exceeds 0.5 the predicate separates nothing** and the result is
   again no-power.
4. **The `plan -> X` subset is expected to be underpowered and must not be read as a null.** The
   scratch cross-tab found nine mode-alone plan boundaries corpus-wide, before any `PREV_MIN`
   filter. Report its n beside its rate, and if the n is single-digit say so in place of a verdict.
5. **Report both outcome definitions.** A rewrite event by the sweep's own criteria, and that subset
   which classifies `UNEXPLAINED`. On a mode-alone boundary the two can differ only by TTL,
   compaction or an aborted turn, so print those exclusions rather than letting them vanish.
6. **Direction of causation is not resolvable here** and the write-up says so rather than implying
   it. A mode change and a rewrite can both be downstream of the user starting something new.

### Result, 2026-08-30 — E is not supported once the gap is controlled, and the pooled figure saying otherwise is composition

Run as `python scripts/sweep-cache-rewrites.py --min-create=0 --step6`, output saved to
`.task3-probe/step5-run-2026-08-30.txt`. The headline sweep is unchanged by the edit — 115 events,
33 unexplained, against 114 / 33 earlier the same day; the one added event is arm 3d's own effort
switch, correctly classified rather than landing in the residual set.

**Both pre-registered no-power conditions cleared**, so this is a readable result and not a
no-power: 58 mode-alone boundaries against the pre-registered floor of 20, and a control rate of
0.009 against the ceiling of 0.5. Population: **74 mode-change boundaries over 170 labelled
sessions**, 71 above `PREV_MIN`, of which 58 are mode-alone and 13 also move effort, model or
version — that second group tests an explained cause and is counted, never pooled.

**Pooled, E looks stronger than the lead that motivated the step.**

| population | rewrite events | of those, UNEXPLAINED |
|---|---|---|
| mode-alone changes | 8 / 58 = 0.138 | 3 / 58 = 0.052 |
| of those, `plan → X` or `X → plan` | 3 / 9 | 2 / 9 |
| control, no mode change, firing sessions | 55 / 6,130 = 0.009 | 15 / 6,130 = 0.002 |

That is roughly 15x on events and 21x on unexplained, on a denominator of 58 rather than 3.

**It does not survive the first thing that should have been checked.** A permission-mode change is
overwhelmingly a *resumption* event — median gap **487 s** at a mode-alone change against **13 s** at
a control boundary. Idle time drives rewrites on its own through the TTL, so the two populations
were never comparable and the ratio above is measuring when people change modes, not what changing
mode does.

| gap band (s) | mode-alone change | no mode change |
|---|---|---|
| 0-60 | 0 / 5 | 15 / 5,511 = 0.003 |
| 60-300 | 0 / 18 | 8 / 401 = 0.020 |
| 300-1800 | 3 / 28 = 0.107 | 14 / 174 = 0.080 |
| 1800-3600 | 2 / 4 | 2 / 27 = 0.074 |
| 3600+ | 3 / 3 | 16 / 17 = 0.941 |

**Within band, nothing readable survives.** The two bands holding the largest mode-change
denominators return zero — 0 of 5 under a minute and 0 of 18 between one and five minutes, both
*below* control. The 300-1800 band is 0.107 against 0.080 on a numerator of three. The 1800-3600
band is two events on four boundaries and 3600+ saturates on both sides at the TTL. The pooled 15x
is composition: mode changes concentrate in the long-gap bands, where the base rate is high anyway.

**The three unexplained events are the same three the 8.1x rested on.** `plan→auto` (`033b909f`),
`auto→acceptEdits` (`88bc769a`), `plan→acceptEdits` (`f8b4f730`) — the identical transition set. This
step added no new event; what it added is a denominator and a control, which is the whole of its
contribution. Their gaps are **2,129 s, 2,099 s and 1,591 s** — 26 to 35 minutes of idle, inside the
window where the classifier has no TTL rule to catch them and the user has plainly been away. Three
of the eight mode-alone events carry `TTL-1h` outright, one a compaction and one an aborted turn,
which is the same story told in the classifier's own vocabulary.

**What this licenses and what it does not.** E is **not supported**; it is not falsified. The bands
where an effect could still hide are exactly the ones with single-digit denominators, and the
stratification treats the gap as a confounder — which assumes the pause precedes the mode change
rather than following from it. That is the reasonable reading for someone stepping away and coming
back, and it is not established. **The consequence for spending is unambiguous even so: arm 3f is
not worth a session on this evidence, and Task 4 is unparked unconditionally.**

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
(extension host restart) and E (permission mode). F closed on 2026-08-30 across three arms, so E is
the only one left to run — Step 3's ordering below is kept as written at the time.** Run F first — one deliberate action tests it,
and no amount of further analysis will. The question is about request structure and is
model-independent, so this runs on `claude-haiku-4-5`, not on Opus.

**Corrected 2026-08-30: the model-independence claim holds for F and is false for E.** All three F
arms ran clean on Haiku. Arm E did not, because this client substitutes `claude-sonnet-5` at effort
`high` when a Haiku session enters plan mode — which converts a mode-alone trigger into an effort
switch, one of the five already-explained causes, and voids the arm. Any arm whose trigger touches
plan mode must run on the model the corpus events ran on, with effort pinned. See the arm E result.

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

**Narrowed 2026-08-31, and the narrowing is not a retraction.** This arm ran at `acceptEdits` on
all 7 turns, so it tested a reload that held the permission mode fixed. A reload that *moves* the
mode does rewrite: `d3567442` re-initialised out of `auto` at 21:46:06Z and took a `system_changed`
rewrite 7 s later — see Task 9's 9b result for the full window. So the null here reads "process
replacement alone does not rewrite the prefix", which is also what 3b and 3c returned, and not
"a reload cannot rewrite the prefix".

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

### Result, 2026-08-30 — arm F/host-restart returned a null, all four predictions hit

Session `1b26f4d4`. Turns 2-6 exact (creates 228, 202, 127, 169, 145); turn 7 read 52,895 against
52,750 + 145 expected, exact; same file, `2.1.251` throughout; and `bridges_before` reads
`t1:2 … t7:3` — **byte-identical to the reload arm's signature**. Prediction 2 was written as a
null and came back a null; predictions 1, 3 and 4 hit; 5 did not apply.

**Prediction 4 is what makes this readable, and it worked as designed rather than by luck.** The
restart produced the same reconnect signature as the window reload, so the trigger reached the same
mechanism. This is "it fired and nothing happened", not "it never fired".

**Two arms, one conclusion, and the mechanism argument predicted both.** Caching is keyed on the
request bytes; neither a window reload nor a host restart changes the bytes the client will send
next, and neither moved the prefix. Together with Task 5 — reconnects not enriched before an event
— **F is falsified in every member that can be tested without a version bump.** Its update member
is excluded by construction (§2). A VS Code application update is the only untested remnant, and
arm F/quit-relaunch below is the closest thing to it that can be triggered on demand.

**An incidental measurement, and it is clean: the always-loaded file's growth is +1.48 tokens per
word.** Session `157ef24e` (02:50:28Z) was discarded as contaminated; it turned out to be the
control arm for the thing that contaminated it. It and `1b26f4d4` (03:02:49Z) both start **warm at
`cache_read` 24,939** — same cached block, same version, same project, 12 minutes apart — and
straddle a `~/.claude/CLAUDE.md` edit at 02:58:13Z that added 192 words. First-turn
`cache_creation`: **26,801 → 27,085, +284 tokens**. The two first prompts differ by three
characters, so about one token of that is prompt. `MEMORY.md` was untouched and the memory files
behind it are not loaded, so the instructions file is the only always-loaded change between them.
This puts a measured token figure on a rule that until now cited byte sizes only.

---

### Predictions for arm F/quit-relaunch, written 2026-08-30 before the run

**The trigger: quit every VS Code window, then reopen both.** Run the probe in a new session in the
scratch directory.

**This arm flips the direction of the prediction, and the reason is the point.** The two nulls so
far both tested **reconnection with the conversation still in memory** — the process never died, so
the client never had to rebuild anything. A full quit kills the process; on relaunch the client must
reconstruct the conversation **from disk**. That is *resumption*, not reconnection, and it is the
first arm with a documented prefix-divergence precedent behind it: `claude -p --resume` renders a
different prefix than an interactive client (`claude-p-resume-prefix-divergence` memory,
`claude-skills` store). It is also the closest on-demand approximation of the one F member left
untested, a VS Code application update.

1. **Baseline holds.** Turns 2-6 exact, creates order 10^2.
2. **The first post-relaunch turn rewrites.** `cache_read` collapses — to 0, or to the ~24,939 warm
   tool block — and `cache_creation` is roughly the whole prefix, 53,000-54,000. Stated as a hit
   this time, against two consecutive nulls.
3. **Validity, and this is the arm's largest risk: does it append to the same transcript?** A full
   quit may not restore the session at all. **A new session file voids the arm** — `cache_read == 0`
   on a first turn is expected by construction. But record which happened, because *"the relaunch
   cannot resume in place"* is itself a result: a mechanism that cannot produce a mid-transcript
   turn cannot explain any of the 33.
4. **Version stays `2.1.251`.** A move voids the arm rather than confounding it (§2).
5. **At least one `bridge-session` record on the post-relaunch turn.** Zero means the client did not
   re-attach and the arm did not reach the mechanism the other two reached, which makes a null
   uninformative rather than confirming.
6. **If 2 hits, read two things before anything else:** the offset against 908 (§1), and whether
   `cache_read` collapses to 0 or to 24,939. The second distinguishes *the whole prefix was
   rebuilt* from *the conversation was rebuilt above a surviving tool block*, and those are
   different mechanisms.

```text
turns 2-6:  ok / still there? / yes / fine / good
--- quit every VS Code window, reopen both ---
turn 7:     still there?
```

### Result, 2026-08-30 — arm F/quit-relaunch returned a null, and it resumed in place

Session `06de8063`, 7 turns, warm start at `cache_read` 24,939.

| # | Prediction | Outcome |
|---|---|---|
| 1 | Baseline holds, creates order 10^2 | **HIT** — turns 2-6 all exact; creates 255, 183, 133, 138, 182 |
| 2 | The first post-relaunch turn rewrites, 53-54K | **MISS** — turn 7 read 52,907 against 52,725 + 182 expected. Exact. Nothing collapsed |
| 3 | Validity: does it append to the same transcript? | **HIT**, and the arm's largest risk did not materialise — see below |
| 4 | Version stays `2.1.251` | **HIT** — throughout |
| 5 | A `bridge-session` record on the post-relaunch turn | **HIT** — three of them; `bridges_before` reads `t1:2 … t7:3` |
| 6 | If 2 hits, read the offset and the collapse floor | **N/A** — no rewrite to measure |

**Prediction 3 was the risk that would have voided the arm, and it came back the informative way.**
A full quit of every VS Code window ends the process; the relaunch reattached to `06de8063` rather
than opening a fresh transcript, so the resumption path this arm was built to test actually ran. The
`bridgeSessionId` is also unchanged across the quit — `cse_01UzPspyvRRphHMQGwmbA1zv` on both sides —
which retires the id as a reconnect signal for a second reason, the record cluster again being the
measurement to trust (Task 5, Step 1).

**This is the strongest of the three F nulls, because it is the only one that tested resumption
rather than reconnection.** The reload and host-restart arms left the conversation in memory, so the
client never had to rebuild anything and the mechanism argument predicted their nulls. This one
killed the process: the client reconstructed the conversation from disk, which is the path with a
documented prefix-divergence precedent behind it (`claude-p-resume-prefix-divergence`,
`claude-skills` store). It still sent the same bytes — 52,907 exactly where continuity predicts, on
a 53,073-token prefix.

**Three arms, three identical bridge signatures, and the base rate now argues the check is real
rather than decorative.** Each probe session carries exactly one `bridge-session` cluster, on the
trigger boundary and on none of the other five. Task 5 measured the per-boundary rate at 0.304 over
sessions that can fire; if clusters fell at random, the chance of exactly one landing on the trigger
boundary is 0.304 x 0.696^5 ≈ 0.05 per arm, ≈ 1e-4 across three. Read this as an argument and not a
measurement — the base rate is borrowed from a different population, long working sessions rather
than seven-turn probes. What it supports is that the cluster tracks the trigger and not the 87-second
pause beside it, which no arm has yet separated by design.

**Scope.** n=1 per member, a 52-53K prefix against corpus events at 78K-200K, one operator, one
machine, all on `2.1.251`.

**A second post-edit replicate turns the first-turn growth figure into a range and puts a noise floor
under it.** `06de8063`'s first prompt is byte-identical to `1b26f4d4`'s — same version, same project,
same warm `cache_read` of 24,939, and `~/.claude/CLAUDE.md` untouched between them `[verified
2026-08-30: mtime 02:58:13Z, both sessions later]`. First-turn `cache_creation` is 27,077 against
27,085: **8 tokens apart on identical inputs.** So against the pre-edit control `157ef24e` (26,801)
the 192-word edit measures +276 and +284 — 1.44 to 1.48 tokens per word — and the session-to-session
jitter on an unchanged prefix is about 8 tokens, not the ~1 token of prompt difference the first
measurement assumed. What varies is untested; a per-session identifier in the system block is the
obvious candidate, since this scoring session's own prompt carries its session UUID inside a
scratchpad path. It does not threaten the 908 cluster in §1, which is two orders of magnitude above
it.

---

### Predictions for arm E (permission mode), written 2026-08-30 before the run

**Run it in a NEW session in the same scratch directory.** E is what is left: Task 1 step 3 put
permission-mode transitions at 8.1x the same-session base rate on n=3, and every other candidate is
either falsified or untestable here.

**State the lead's weaknesses before predicting from it.** The 8.1x rests on three events; one of
them is a `cache_read == 0` event with no floor; the control was refined after the data had been
seen; and the direction of causation is untested, since a rewrite and a mode change could both be
downstream of a third thing. What makes it worth a session anyway is that two of the three are
`plan -> X`, which is a mechanism and not a bare correlation.

**The instrument, validated before the arm rather than after** `[verified 2026-08-30]`:

- `permissionMode` rides on `user` records, one per turn, and all four probe sessions carry it — 7
  of 7 turns each, reading `acceptEdits` throughout. The label is emitted in exactly this session
  shape, so a transition will be visible per turn.
- There is also a dedicated `permission-mode` **record type**, and it cannot be used here: 10
  records across 7 sessions, all on `2.1.212`-`2.1.221`, none on a current client. It is
  version-gated the opposite way `bridge-session` is (Task 5), so building the validity check on it
  would produce a structural blind rather than a null.

**Three transitions in one session, not one.** Each is a separate turn boundary and continuity is
read per pair, so one session buys three triggers without fusing them. Cycle the permission mode
with shift+tab once before each of turns 4, 6 and 7. Do not assert which mode each cycle lands in —
read it off the per-turn label afterwards. The corpus's three events are `plan->auto`,
`auto->acceptEdits` and `plan->acceptEdits`, and a three-step cycle covers that family whatever
order the client cycles in.

1. **Baseline holds.** Turns 2-3, `cache_read[i] == crea[i-1] + read[i-1]` exact, creates order
   10^2. Two clean pairs is thinner than the F arms' five; three prior sessions ran perfectly clean
   baselines, so this is a considered trade for the extra triggers rather than an oversight.
2. **At least one of the three transition boundaries rewrites** — turn 4, 6 or 7 reads a collapsed
   `cache_read`, 0 or ~24,939, with `cache_creation` near the whole prefix. Stated as a hit against
   three consecutive nulls, because E is the only candidate left carrying a positive signal.
3. **Validity: the transitions are recorded.** The per-turn `permissionMode` label changes at turns
   4, 6 and 7. If it reads `acceptEdits` on all seven, the trigger never reached the client state
   the corpus predicate is defined on, and a null on 2 is uninformative rather than confirming —
   the role prediction 4 played in arm F/host-restart. Redo the arm; do not interpret it.
4. **Validity: same session file, same `version` `2.1.251`.** Either move voids the arm (§2).
5. **If 2 hits, read three things in this order:** *which* transition did it, since a `plan->X`
   boundary firing where `auto->acceptEdits` does not is sharper than any of them firing; the offset
   against 908 (§1); and whether `cache_read` collapses to 0 or to 24,939, which separates a
   whole-prefix rebuild from a rebuild above a surviving tool block.
6. **A miss on 2 does not clear E, and the successor is named now.** Shift+tab changes the mode and
   nothing else, while `ExitPlanMode` changes the mode *and* injects a plan document plus an
   approval. Two of the three corpus events are plan exits and may be the second form. A null here
   sends you to an `ExitPlanMode` arm; only a null there unparks Task 4.

```text
turn 2:  ok
turn 3:  still there?
--- shift+tab once ---
turn 4:  yes
turn 5:  fine
--- shift+tab once ---
turn 6:  good
--- shift+tab once ---
turn 7:  still there?
```

Predictions 1, 2 and 4 read off `python scripts/read-session-prefix.py '<WINDOWS path>'`. Prediction
3 reads off this, which prints one line per labelled record and returned 7 `acceptEdits` lines on
`06de8063` as its positive control `[verified 2026-08-30]`, and which is also how the run below was
found to have moved a second variable:

```sh
python -c "import json,sys; [print('rec %3d  %s' % (i, r.get('permissionMode'))) for i,r in enumerate(json.loads(l) for l in open(sys.argv[1],encoding='utf-8') if l.strip()) if isinstance(r,dict) and r.get('permissionMode')]" '<WINDOWS path>'
```

### Result, 2026-08-30 — arm E is void for plan mode, and returns one clean null beside it

Session `9e76ff00`, 7 turns. All three cycles landed: `acceptEdits → plan → default → acceptEdits`,
with the label changing on turns 4, 6 and 7 exactly as the script intended.

| # | Prediction | Outcome |
|---|---|---|
| 1 | Baseline holds, turns 2-3 exact, creates order 10^2 | **HIT** — 267, 182 |
| 2 | At least one transition boundary rewrites | **HIT on the counter, void on interpretation** — two of three rewrote, and both carry an effort *and* model switch |
| 3 | Validity: the labels change at turns 4, 6, 7 | **HIT** — the arm reached the client state the corpus predicate is defined on |
| 4 | Same session file, `version` `2.1.251` | **HIT** — throughout |
| 5 | If 2 hits, read which transition, the offset, the collapse floor | Read below; the answer is a cache lineage, not a new mechanism |
| 6 | A miss on 2 names the `ExitPlanMode` successor | Superseded — the design fault below has to be fixed before that arm means anything |

**The probe was run on the one model where plan mode is not mode-alone.** Entering plan mode
swapped `claude-haiku-4-5-20251001` / effort `None` for `claude-sonnet-5` / effort `high`, and
leaving it swapped back. Effort switch is one of the five causes the classifier removes before an
event can reach the residual set, so by §2's own rule — written for the extension-update member — a
trigger that moves an already-explained cause **voids that arm rather than confounding it**.
Boundaries 3→4 and 5→6 say nothing about the 33.

**This is a fault in Task 3's model choice and it is corrected in place.** Task 3 states the
question "is about request structure and is model-independent, so this runs on `claude-haiku-4-5`,
not on Opus". That holds for F, and it is false for E: this client substitutes a planning model when
the session model is Haiku. The corpus settles it — of the ten plan-involving boundaries outside
this probe, **nine carry identical model and effort on both sides and the tenth carries an effort
change with the same model; no corpus session swaps the model at a plan boundary, and both probe
boundaries do** `[verified 2026-08-30, per-boundary rows in
`.task3-probe/arm-e-mode-effort-crosstab.txt`]`. The events E rests on are mode-alone. The probe's
were not, so it was not measuring them.

**One boundary in the arm is clean, and it is a real result.** Turn 6 → 7 is `default → acceptEdits`
with the same model, the same effort and nothing else moving, and continuity held exactly: read
54,230 against 52,472 + 1,758. That is a null for candidate E's non-plan member at n=1, closest
corpus analogue `auto → acceptEdits`. It is the only part of this session that tests E at all.

**The two rewrites are a textbook effort-lineage switch, and the return leg measures the claim.**
Turn 4 built a 71,787-token `claude-sonnet-5` / `high` prefix from `cache_read` 0. Turn 6 returned to
`haiku` / `None` and read **52,472** — exactly where that lineage stopped at turn 3 (52,290 + 182) —
paying 1,758 to re-add the excursion's two turns. Both halves of `effort-switch-cache-lineages`
(`claude-skills` store) in one seven-turn session: the cold switch rebuilds from the floor, the
return costs only the delta.

**A second explained cause is stacked on the 5→6 boundary.** At turn 5 the model called
`AskUserQuestion` and the operator interrupted it rather than answering (records 55-57). An aborted
turn immediately prior is also a classified cause, so that boundary carried two of them. It changes
no verdict, and it leaves two things to fix: the turn script needs a line telling the operator what
to do if the model calls a tool, and this interrupt shape produces no zero-usage assistant record,
which is what the sweep's `abort_after` detector keys on — so the sweep would not have flagged it.

**What the cross-tab does and does not offer.** It found **69 permission-mode-change boundaries
across 276 sessions**, two of them this probe's, against the n=3 the 8.1x lead rests on. That is a
far larger population for a free re-analysis, and Task 1 Step 5 below is written to use it. It is
not itself that analysis: its outcome column is a crude `read < 0.5 x expected` predicate with no
TTL or compaction exclusion and no base rate, and it disagrees with `read-session-prefix.py` on this
session's own 5→6 boundary. The model and effort columns are exact field reads and are what the
paragraphs above rest on; the rewrite counts in that file are not to be quoted.

---

**Step 2 — establish a quiet baseline.** In a scratch directory, run five or six trivial turns with
no tool use and confirm the prefix is stable — `cache_read[i] == crea[i-1] + read[i-1]` on every
pair. **If the baseline rewrites on its own, stop: the effect is not the thing you were going to
trigger.**

**Step 3 — trigger one candidate**, mid-session, changing nothing else.

- **F — done, three arms, all null (3a, 3b, 3c).** Reload the VS Code window, then send one more
  trivial turn. The family has several members and they are separate arms, not one test: a manual
  reload, an extension restart, and an extension update followed by a reload. Run the manual reload
  first because it is the only one that can be triggered on demand. If it reproduces, the others are
  variants of a known mechanism rather than open questions. *In the event none reproduced, and the
  quit-relaunch arm added a fourth member the list did not have — resumption from disk.*
- **E — next, and the predictions are written above.** Change permission mode mid-session — leaving
  plan mode is the transition two of the three observed events share — then send one trivial turn.
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

**RETIRED 2026-08-30, unbuilt, and superseded by Task 6.** It was unparked that morning on the
grounds that every free question had been asked. That was false: the transcript carried
`message.diagnostics.cache_miss_reason`, which names the block that moved, on 82% of the residual
set. The proxy would have reconstructed from request bytes a fact the server states in a field.

**Kept for the reasoning, and for one lesson that generalises past it.** The task existed because
§1's "the transcript cannot record injected blocks" was believed, and that claim rested on a single
narrow grep. **The cost of an unexamined instrument claim is every task built downstream of it** —
here, a planned build plus five tasks whose nulls were all measured against a residual set that was
never causeless. The design below is still the right design *if* request bytes are ever genuinely
needed; nothing currently needs them.

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

## Task 6: Ask the server why the cache missed

**Opened and closed 2026-08-30, and it retires Task 4.** The API returns a diagnosis of the cache
miss on the assistant message itself: `message.diagnostics.cache_miss_reason`, an object of
`{"type": ..., "cache_missed_input_tokens": N}`. The sweep never read the field, so the entire
residual "UNEXPLAINED" set was constructed without consulting the one thing that names the cause.

**Files:**
- `scripts/join-cache-miss-reason.py` — new; mirrors `session_turns()` and adds `diag`
- `.task3-probe/cache-miss-reason-join.txt` — per-event detail, written and not read into session

**Interfaces:** consumes the same turn construction and the same `classify()` as the sweep, so its
event set is the sweep's event set. Produces a cause per event, or the absence of one.

**Why the field was invisible until now.** It rides on `message.diagnostics`, a key the sweep does
not touch — it reads `message.usage` and nothing else on the message. Enumerating the assistant
record's keys is what surfaced it, which is §1.5's method applied to a record type rather than to
a binary. `grep -c system-reminder` had already been read as settling what the transcript holds.

**Reading rule, pre-registered before the run.** Coverage is read first and the distribution second.
The predictions written down were: some of the 33 carry a reason; those that do read `system_changed`
or `tools_changed`; and **if 0 of 33 carry the field the result is "no coverage", not "no cause"** —
the same no-power distinction Task 5 turned on. Corpus-wide the field is on 1.1% of turns, so
sparseness was the live risk.

### Result, 2026-08-30 — 27 of 33 labelled, and candidate A is the commonest

```
files=376  turns=14344  events=116  unexplained=33
COVERAGE  diagnostics present on 27 of 33 unexplained events (82%)
          and on 156 of 14344 turns corpus-wide (1.1%)

cache_miss_reason on the UNEXPLAINED events        on ALL 116 rewrite events
   tools_changed      13                              previous_message_not_found  30
   messages_changed    9                              system_changed              21
   system_changed      5                              unavailable                 16
   None                6                              tools_changed               16
                                                      messages_changed            16
                                                      None                        14
                                                      model_changed                3
```

**The instrument validates on the explained population, which is what licenses reading the residual
set from it.** The server's label and the sweep's independent classifier agree wherever the sweep
already knew the answer: **all 16 `effort X->Y` events read `unavailable`** and every `unavailable`
in the corpus is an effort switch; **all 3 model changes read `model_changed`** and every
`model_changed` is a model change; 29 of 30 `previous_message_not_found` are TTL events. Three
independent exact correspondences on causes derived from different fields. `unavailable` also
corroborates the `effort-switch-cache-lineages` memory directly — a switch to a level with no live
entry has no lineage to read, and that is what the server calls it.

**Predictions 1 and 2 hit; the no-power condition did not fire** (27 of 33, not 0).

**What the label does and does not settle.** It names *which block* moved — tools, system, or
messages. It does not name what moved it. So §1's question splits cleanly and only the second half
survives: 13 events asking what changes a tool roster mid-session, 9 asking what edits message
history without writing a compact boundary, 5 asking what changes the system block, 6 unlabelled.

**Read every earlier null narrowly from here.** Tasks 1, 2, 3 and 5 tested *trigger* predicates
against a set assumed causeless. It never was. A null from those tasks says the predicate did not
fire before these events; it does not say the events lacked a cause, and it never did.

---

## Task 7: Audit the compaction classifier against the client's real compaction family

**The question.** 9 of the 33 read `messages_changed`. §1.5 open item 1 names the leading
explanation: the sweep's classifier keys on `isCompactSummary is True` or a `system` record whose
`subtype` contains `compact`, and the binary instruments at least twelve distinct compaction events.
A compaction writing neither marker rewrites the prefix and lands in the residual set unexplained.

**Method, and why it is shaped this way.** §1.5's own lesson is that a grep run once per member of
a set already chosen cannot surface a member nobody named. So step 1 runs in the enumeration
direction: inventory every marker the corpus actually holds, then ask which ones the classifier
sees — not the reverse.

1. Enumerate every record shape carrying `compact` anywhere in a key or a string value,
   corpus-wide, through `records()`. Report the distinct shapes and their counts.
2. Score each shape against the classifier's two predicates. Anything unscored is a blind spot.
3. **Positive control**, without which step 4's null is unreadable: confirm the classifier fires --
   at least one boundary in the corpus must classify as `compaction`.
4. Join: for each of the 9 events, inventory every record in the window between the two turns and
   ask whether any unrecognised marker sits there.

### Predictions for Task 7, written 2026-08-30 before the probe was written

1. Step 1 finds at least one `compact`-bearing shape beyond the two the classifier keys on.
2. Step 3's positive control fires: at least one boundary classifies as `compaction`.
3. Under the compaction hypothesis, at least one of the 9 carries an unrecognised marker in its
   window. Under the alternative, zero do.

**The no-power condition, pre-registered.** A compaction that writes *no* transcript record is
invisible to I1 by construction, so a zero at step 4 does not discriminate on its own. The arm that
does is arithmetic on the turn totals, and it needs its own limit stated: a compaction removes
content, so the event's `total` should fall below the previous turn's. **If the event totals instead
sit inside the same-session per-turn growth distribution, nothing was removed** -- and the test can
only exclude removals larger than ordinary turn growth. A microcompact trimming less than that is
undetectable here and the result must say so.

**One observation is already in hand and is recorded as an observation, not a prediction.** The
nine join lines print `read`, `crea` and `prev_total`. Summing `read + crea` against `prev_total`
on each gives a value *larger* on all nine -- 93,647 vs 91,950 at the smallest, 371,525 vs 370,244
at the largest. That is the shape of a prefix that grew, not one that was trimmed. It was read off
the join output before the probe was written, and the base rate that makes it a result rather than
an anecdote has not yet been measured.

### Result, 2026-08-30 — compaction is not what the 9 `messages_changed` events are

**Two independent arms, both negative, and the marker arm alone could not have carried it.**
`scripts/audit-compaction-markers.py`, `-values.py` and `-coverage.py`, over 377 files and
84,702 records.

**Arm 1 — markers. The classifier has a blind spot and it marks nothing.** Enumeration finds
three `compact`-bearing *key* paths corpus-wide (`$.compactMetadata`, its
`preCompactDiscoveredTools` child, and `$.isCompactSummary`) and the classifier sees all three.
1,025 further records carry `compact` only inside a string, and of those exactly two shapes are
structural rather than prose: an `attachment` whose `hookName` is **`SessionStart:compact`**
(15 records / 12 sessions) and a `queue-operation` whose content is **`/compact`** (11 / 8).
Both are blind to the classifier — and both are redundant. The hook is exactly co-extensive
with the two visible markers: 15 records over the same 12 sessions, and the per-session counts
agree shape for shape on every one of them — nine sessions at 1:1:1 and three at 2:2:2. `/compact` adds one session, `8a12352c`, which holds two queued
`/compact` operations and no compaction record of any shape — a command typed, not a
compaction observed. **The blind spot marks zero additional compactions in this corpus.**

**The positive control fires**: 15 boundaries classify as `compaction`, over 12 sessions. So the
step-4 null is readable, and it is total — **0 of 9** events have *any* `compact`-bearing
record in the boundary window, visible or blind, structural or prose. One of the nine sessions
(`4b6a0b14`) did compact and the classifier caught it — at the 01:35:29 boundary, against an
event at 03:21:47 `[verified 2026-08-30]`.

**Prediction 1 hits in the letter and misses in the substance** — blind shapes exist, and they
mark nothing new. Prediction 2 hit. Prediction 3 returned the alternative's zero.

**Arm 2 — arithmetic, which is what actually carries the result.** The pre-registered no-power
condition applies in full: a compaction writing no transcript record is invisible to I1 by
construction, so arm 1 cannot exclude one. Arm 2 does not depend on markers. **All nine prefixes
grew**, by +1,219 to +6,990 tokens, against same-session median per-turn growth of 821 to 1,313
— every event is above its own session's median and six of the nine are above its q3. **0 of 9
shrank.** A compaction removes content; nothing was removed.

**The limit this arm has, stated because net delta is the only observable.** It excludes a
removal accompanied by ordinary growth. It cannot exclude a large removal masked by a
simultaneously large insertion.

**The telemetry check, recorded so it is not run twice: it settles nothing.** I2's spill parses
to 187 records / 3 sessions / 35 distinct `event_name` values, the positive control fires (all
three names §1.5 quotes are present), and no compaction-family name appears. That is not
evidence — §1.5 already establishes I2 as a biased remnant of *failed uploads*, the three
sessions are dominated by startup events, and nothing says any of them compacted. Both parsing
traps this ran into are recorded in §1.5's I2 row, where the next reader of those files will be
standing; the census returned a clean false zero twice before its positive control caught it.

### What the nine look like instead — an observation, not a tested result

Cache retention at the nine collapses to **22,572–30,319 tokens against prefixes of
91,950–370,244**, i.e. 7.0%–32.7% surviving. That floor is not a fraction of the conversation:
on the seven of nine whose session opened warm it tracks that session's own first-turn read
(18,801–24,723, the already-warm tool-definition block) plus a consistent 3,771–5,596 — the
other two opened cold and read 0, so they carry no comparison. Across the nine the floor rises
with the calendar rather than with the prefix: 22,572 on 9 August, ~30,300 on 26 August. So the rewrite begins at or just
below the tool-definitions breakpoint and everything after it is rebuilt, while the total
simultaneously grows by more than an ordinary turn.

**Insertion near the head of the messages array is what those two facts jointly suggest**, and
the first user message is where the always-loaded files are injected. **Untested, and it must
not be promoted until it is.** The check is free and I1 holds the records: diff the first user
message's `attachment` records across each of the nine boundaries — §1.5 lists ten subtypes
that carry injected content, and `deferred_tools_delta`, `mcp_instructions_delta`,
`agent_listing_delta` and `skill_listing` all record arrivals rather than steady state.

---

## Task 7b: What arrives at the 9 `messages_changed` boundaries

**Task 7's successor, and free.** Task 7 excluded compaction and left one reading in its place: the
nine rewrite everything below the tool-definitions breakpoint while the prefix *grows* by more than
an ordinary turn, which is the shape of an insertion rather than a removal. I1 records injected
content as `attachment` records — §1.5 lists ten subtypes that carry it — so the question is
answerable from disk.

**Why this is not a re-run of Task 2.** Task 2 asked what precedes an event and returned a null, but
it ran before the server labels existed and pooled all 33. The 9 are a homogeneous set selected on
the server's own account of *which block moved*, and stratifying a null by a cause discovered
afterwards is a different question from the one that returned it.

**One mechanical constraint shapes the prediction, and it is worth stating before the numbers.** An
attachment appended to the current turn lands at the *end* of the messages array, and appending
does not invalidate a prefix. For `messages_changed` to fire above the breakpoint, an *earlier*
message must have changed — so the subtype to look for is one whose content is re-rendered from
disk on each request, not one that merely arrives. §1.5 records that `nested_memory` carries
`contentDiffersFromDisk` alongside both `content` and `rawContent`, which is exactly that shape.

**Method.** For each of the 9, inventory every record type and `attachment` subtype in the boundary
window `(prev.t, cur.t]`, scored as presence-per-window rather than record count so one burst cannot
carry a subtype. Control: every other boundary in those same 9 sessions, same measure. Report each
subtype as event-windows/9 against control-windows/N.

### Predictions for Task 7b, written 2026-08-30 before the probe was written

1. `output_style` and `total_tokens_reminder` appear in nearly every window in **both** arms — they
   are 8,848 and 6,174 records corpus-wide. They are pre-registered as **no-power**: a subtype
   present in ≥8 of 9 event windows *and* ≥50% of control windows separates nothing, whatever its
   ratio, and must be reported as no-power rather than as a hit.
2. If the insertion reading is right, at least one subtype that is re-rendered rather than appended
   is enriched at the 9 against control.
3. Under the alternative, every subtype sits at its same-session base rate.

**A second no-power condition, on n.** With 9 events a subtype appearing in fewer than 3 event
windows has no readable rate; report it as underpowered, not as absent. This is the condition that
decides whether a null here is worth anything at all.

### Result, 2026-08-30 — a null on the common shapes, and no power at all on the named ones

**Read the second half first: this probe does not test the insertion reading.** The subtypes the
hypothesis named are far too rare for 9 windows to see. Against a same-session control of 1,253
boundaries, `deferred_tools_delta` appears in 2, `mcp_instructions_delta` in 1,
`agent_listing_delta` in 1, `skill_listing` in 6, `hook_additional_context` in 3 and `nested_memory`
in none. **Expected hits in 9 windows: 0.007 to 0.043 — and still below 1 if the effect were
tenfold.** Six of the seven named subtypes cannot produce a countable hit at any effect size this
design could resolve. Their zero at the 9 events is a no-power, and prediction 2 fails without
saying anything. `[computed 2026-08-30 from the control rates above]`

**The first half is a real null, and it took a control arm to get there.** Pooled, two shapes looked
overwhelming: `queue-operation` at 9 of 9 event windows against 60 of 1,253 controls (20.9x), and
`system` at 8 of 9 against 53 (21.0x). **Both are window duration.** The event windows run 45–904 s
with a median of 292; a control boundary in these same sessions has a median gap of **13 s**, and
1,053 of the 1,253 sit under 30 s. Stratified by gap, the ratio decays monotonically —
`queue-operation` 22.5x, 3.73x, 1.55x, 1.46x as the band widens — and in the 180–600 s band where
five of the nine events actually live it is 5/5 against 22/34, which is 1.55x and carries a
one-in-nine chance of arising from the base rate alone. The long-gap control rate tells the same
story from the other side: users type ahead during long turns, 65% and 68% of the time.

The `system` records are all one subtype, `stop_hook_summary` — 8 of the 9 events, and the only
other subtypes anywhere in the control set are a single `compact_boundary` and a single
`local_command`. `attachment/total_tokens_reminder` sits at 0.82–1.08x in every band, exactly as
pre-registered.

**What this does and does not retire.** It retires *a common injected block arriving at these
boundaries and not at others* — that would have shown up, and nothing did. It leaves the insertion
reading untouched, because the instrument cannot reach it. **The free routes to that reading are now
exhausted**, and the honest statement is that this transcript cannot distinguish an insertion at the
head of the messages array from any other change to it. Say so rather than recording a null.

**This arm's own lesson, and it is the third time on this plan.** The pre-registration named a
no-power condition on *n* and missed the one that actually bit — unequal window durations, which had
already cost this investigation a finding at Task 1 Step 5. A rate over a window is a rate per unit
time or it is a statement about the window. The check is one line of stratification and it should be
in every predicate this plan writes from here.

---

## Task 9: The client debug log, and what it can actually be asked

*Name collision, and this store has had one before: the sibling `docs/durable-memory-model.md`
has its own §5 Task 9, which is the proxy design. Both references to it in this file name the
document explicitly; an unqualified "Task 9" here always means the debug log.*

**New instrument as of 2026-08-30.** Claude Code now writes a per-session debug log to
`~/.claude/debug/<session-id>.txt`, with `~/.claude/debug/latest` symlinked to the running
session's. Nine exist, all dated 2026-08-30, ~93 KB for one working session.

**It is not the retired proxy, and Task 4 stays retired.** The log carries no request bodies, no
token counts, no cache-control or breakpoint markers, and no injected-block content. Swept for
`cache_creation`, `cache_read`, `cache_miss_reason`, `ephemeral`, `breakpoint`, `system-reminder`,
`input_tokens` and `effort`, every count is **0** `[verified 2026-08-30]`. Nothing here reads the
prefix. What it holds is client-side operational state: API dispatch, stream timing, tool and skill
loading, MCP, hooks, permission updates.

**Read the sweep method before trusting any count from this file.** The log echoes tool inputs
verbatim on `[auto-mode] new action being classified` lines, so a keyword search finds *its own
probe*. The first run of the sweep above returned exactly 1 for eight different cache terms; all
eight hits were the grep command that was looking for them, and the true count was 0. Any sweep of
a debug log must exclude the self-echo lines first, and a count of 1 on a term you just typed is
the tell. This is a live instance of the null-from-an-unvalidated-instrument rule, caught only
because eight unrelated terms returning the same suspicious 1 does not happen by chance.

**The echo is gated on auto mode, which is why a log can look clean and not be.** Those lines are
emitted by the auto-mode action classifier, so they appear only while the session is in auto. In
`d3567442` there are 14 of them, spanning 20:45:20Z to 21:56:56Z, and **zero** in the
`acceptEdits` window from 21:46:06Z to 21:47:45Z `[verified 2026-08-31]`. So "this log does not
echo tool inputs" is a claim about which mode the session happened to be in, never about the log
format — check for `new action being classified` in the specific file before trusting a count from
it, rather than generalising from another session.

### The join, which is the reason this is worth anything

The transcript's `requestId` (`req_011Cea…`, server-side) appears in the debug log, so the two
join exactly rather than by nearest timestamp: **23 of 24 ids shared** on this session, the
1-and-1 residual being the live edge with both files still being appended to. Timestamps agree in
format and clock (both UTC `…Z`), so the join is checkable two ways.

Note the near-miss: the log's own `x-client-request-id` is a client-generated UUID that appears
nowhere in the transcript. Joining on that field returns nothing and would read as "the log does
not join", which is the wrong conclusion from the right-looking query.

### The corpus is not retroactive, and this is the binding constraint

Every one of the 33 residual events comes from a session with no debug log, and no debug log can
be made for a session that has ended. **The log can only ever explain a future event.** So the
question is how long it takes to catch one, and the base rates answer it directly — 376 sessions
carrying 116 events:

| Class | n of 376 | Sessions per expected event |
|---|---|---|
| Any rewrite | 116 | 3.2 |
| Unexplained (the 33) | 33 | 11.4 |
| `tools_changed` | 13 | 28.9 |
| `messages_changed` | 9 | 41.8 |
| No diagnostics (Task 8) | 6 | 62.7 |
| `system_changed` | 5 | 75.2 |

**Pre-registered, before any of this runs:** at 9 debug-logged sessions the expected number of
unexplained events captured is **0.8**. Passive collection is not a strategy for the rare classes —
`system_changed` needs on the order of 75 logged sessions for one event. Either force a trigger, or
accept that 9c and 9d are months of ambient collection. Writing this table now is the thing Task 7b
did not do until after its null.

### What has to be settled before 9b runs

Three unknowns, none of them derivable from the repo, each capable of voiding a capture:

1. **SETTLED 2026-08-30 - persistent, and it covers 97.4% of the corpus's session population.**
   The extension passes `--debug --debug-to-stderr`, and the second flag suppresses the on-disk log
   outright. Measured against native binary 2.1.251: `--debug` alone writes a 41,519-byte file,
   `--debug --debug-to-stderr` writes none, and adding an explicit `--debug-file` does not override
   it - stderr wins, so no appended flag can undo it. The flag therefore has to be removed before
   the binary sees it, which `~/.claude/scripts/claude-debug-wrapper.c` does: a shim substituted
   via VS Code's `claudeCode.claudeProcessWrapper` setting, which strips the token. **It used to
   append `--debug` unconditionally as well, and that broke every `claude plugin …` call the
   extension makes** - the subcommand trees reject the flag and exit before doing anything
   (`claude plugin list --debug` -> exit 1, `error: unknown option '--debug'`; without it, exit 0
   `[verified 2026-08-31]`). Rebuilt 2026-08-31 to gate the append on `--debug-to-stderr` being
   present, which is true of the session launch and of nothing else. It covers exactly the
   `entrypoint=claude-vscode` sessions, which are
   **375 of 385 corpus-wide (97.4%)** `[measured 2026-08-30 over every transcript under
   ~/.claude/projects]`; the other 10 are `cli`, `sdk-ts` and `claude-desktop`. The power table
   above needs no adjustment for coverage. The tradeoff is that debug lines no longer reach the
   VS Code Output panel.

   **It introduces one failure mode the power table assumes away.** If an extension update changes
   the flags the wrapper matches on, logging stops and `~/.claude/debug/` simply stays empty, which
   is indistinguishable from a session that had no rewrite. **Before reading any null from 9b, 9c
   or 9d, confirm that session's own log exists and is non-trivial** - a missing log is a broken
   instrument, not an absent event. Note also that a rebuilt wrapper is picked up only by new
   sessions: Windows blocks overwriting a running .exe, so the swap is a rename and live sessions
   keep the old image.

   **The wrapper costs auto permission mode, and that is a confound this investigation now carries
   on every VS Code session.** Merely *configuring* `claudeCode.claudeProcessWrapper` is enough:
   the extension passes `resolvePermissionModeInCli: !y$("claudeProcessWrapper")` and the SDK reads
   that as `mode ?? (resolveInCli ? undefined : "default")`, so with a wrapper set the extension
   always names a mode on the command line and the CLI's own `permissions.defaultMode` never gets
   to resolve. `auto` is not in `claudeCode.initialPermissionMode`'s enum
   (`default | manual | acceptEdits | plan | bypassPermissions`), so no setting can name it either
   — clearing that setting yields `default`, not `auto`. The extension also skips its one-time
   `clearPersistedPermissionModeForAutoDefault` migration when a wrapper is configured.
   `[read from extension.js 2.1.251, 2026-08-31; the live process line confirms it —
   `--permission-mode acceptEdits` against `"defaultMode": "auto"` in ~/.claude/settings.json]`
   The consequence for this plan: **no debug-logged session on this machine can start in auto**,
   auto can only be entered mid-session, and every re-init drops back out of it — which is what
   9b's `system_changed` event turned out to be.

2. **Whether the log rotates or truncates.** A capped log silently drops the oldest lines, which on
   a long session is exactly the boundary being hunted. Check a long session's log against its own
   first turn before trusting a window.
3. **Whether `source=side_query` calls appear in the transcript at all.** If they do not — and the
   count gap of ~40 log requests against ~23 sdk turns says they do not — then every per-session
   rate this investigation has computed is a rate per *sdk turn*, not per API call.

### Result, 2026-08-31 — 9b answered off a session already on disk, and the bought version is retired

**The design as written would have probed the log's blind spot.** 9b proposed forcing an effort
switch, whose server cause is `unavailable`. The log records no effort, reasoning or thinking field
anywhere. That probe returns a null whichever way the mechanism works, and the null reads as "the
log cannot see rewrites at all" — which is the gate's own failure condition. It is retired unrun.

**A better-shaped control was already on disk.** Session `d3567442-c7fb-4680-9871-a5581164e122`
(EH-dataportal, 2026-08-31) carries one event of each of the two classes 9c and 9d target, joined
to its debug log by 9a's `requestId` key:

| Event | Server label | `cache_read` | Debug-log signature in the window |
|---|---|---|---|
| 20:52:05Z | `messages_changed`, 125,528 missed | 175,364 → 164,922 | **None.** Nothing separates it from an ordinary turn |
| 21:46:13Z | `system_changed`, 137,065 missed | 200,357 → 24,765, 163,581 re-created | **Unmistakable.** Full teardown and re-init |

`[verified 2026-08-31 by re-reading both files: the two `cache_miss_reason` records in the
transcript, and the named lines in `~/.claude/debug/d3567442….txt`]`

**So the answer to the gate is "one of two", and that is the finding.** A rewrite with a known
cause *can* leave a legible signature, so 9c and 9d are not dead — but the `messages_changed`
member left none, which is the same class Task 7b already failed to characterise from the
transcript side. Two instruments have now returned nothing on it.

**What the `system_changed` window actually holds.** `21:45:45` MCP servers terminated, LSP down,
`CCRClient: Epoch mismatch (409, reason=session_not_active), shutting down`; `21:46:03` full
re-init — plugins, MCP reconnect, skills reload, hooks re-registered; `21:46:04` `Reattaching to
persisted bridge session … at seq 104`; `21:46:06` the engine turn counter resets 5 → 1 and the
request dispatches. **This was not a process restart:** `configureGlobalMTLS starting` appears
exactly once in the whole file, at 14:41 — so it is a headless engine session re-created inside a
live process.

**Exactly two things moved across the re-init, and neither is a tool or a skill.** Everything the
log names on both sides held identical: `Loaded 5 unique skills (5 unconditional, 0 conditional,
managed: 0, user: 5, project: 0, additional: 0)` — 12 times, byte-identical, including at
21:46:05; `Initialized versioned plugins system with 19 plugins`; `Total plugin output styles
loaded: 1`; `Hooks: Found 0 total hooks in registry` — 53 times; `effectiveWindow=980000` — 53
times; model `claude-sonnet-5`; and the MCP set (context7 and playwright reconnected, `github`
failing identically on both inits for a missing `GITHUB_PERSONAL_ACCESS_TOKEN`). The two that
moved:

| | before | after |
|---|---|---|
| permission mode | `auto`, all 5 preceding turns | `acceptEdits` at 21:46:06.638Z |
| deferred tool pool | `Dynamic tool loading: 0/48` | `0/47` from 21:46:06.651Z |

**The tool-pool drop tracks the re-init, not the mode — and that kills the tempting reading.** The
obvious story is that losing auto mode dropped a tool. It does not survive: the mode was back to
`auto` by ~21:47:45 and the pool was still `0/47` at 21:56:58Z, the last reading in the window
`[verified 2026-08-31]`. So the 48 → 47 drop has no identified cause; the MCP set was constant
across both inits, which was the other candidate.

**The mode is the mechanism the server's label points at; the reload is only the trigger.** Auto
mode injects a system-prompt block, so losing it changes the system prompt, which is what
`system_changed` names. That reconciles this event with Tasks 3b and 3c, which replaced the process
twice and returned exact nulls: **process replacement on its own does not rewrite the prefix; this
one did because it also dropped the mode.** Two caveats, both load-bearing. The log never dumps the
system prompt, so "the auto-mode block was removed" is an inference from the mode field being the
only system-relevant change plus the server's label — something unlogged could have moved. And the
mode → tool-pool link is a co-occurrence at n=1, not a demonstrated mechanism.

**The drop is at re-init only and it did not persist**, which matters for anyone designing the
reload arm. `[session-notices] mode=` reads `auto` at 20:35, 20:44, 20:52, 21:38 and 21:43,
`acceptEdits` at 21:46:06 — and by 21:48:58 a permission decision reads `mode=auto` again
(`Slow permission decision: 73769ms for Bash (mode=auto, behavior=allow)`, so the mode was back
before ~21:47:45). The transcript's per-turn `permissionMode` label does **not** show the return:
only six records in the whole 357-record file carry that field at all, the last of them the
21:46:06Z one, and it is never emitted again even though the session runs on to 21:57:08Z
`[verified 2026-08-31]`. Two instruments, two different answers, and the disagreement is a
sampling artefact rather than a contradiction — the label is stamped at a turn boundary and the
mode moved inside a turn. **For mode state within a turn, read the debug log, not the transcript
label.** This is a caveat on every null Task 1 Step 5 and arm E drew from that field.

**Consequence for 3a.** The window-reload arm's null stands for what it tested and is narrower
than "a reload does not rewrite". `6597c649` ran at `acceptEdits` on all 7 turns and never had a
mode to lose. Testing reload-qua-reload needs a reload that keeps the mode — and §1 above says why
that cannot be arranged from a cold start on this machine while the wrapper is configured.

---

## 3. Considered and rejected

- **Re-running the sweep on more data and waiting for the pattern to sharpen.** The corpus grows
  by ordinary use, but every added session is uncontrolled. **"The corpus has been asked every free
  question it can answer" stood here until 2026-08-30 and was false** — `cache_miss_reason` sat
  unread in every transcript (Task 6); what had been exhausted was the set of questions anyone had
  thought to ask. More of the same data still answers nothing new -- and since
  2026-08-29 the corpus also contains this investigation's own sessions, so added data is no
  longer independent of the measurement.
- **~~Reading the transcripts for the injected block.~~ WRONG, corrected 2026-08-30.** The bullet
  read: "the blocks are not in the JSONL `[verified 2026-08-28: parsed the message content of every
  record in 4489d30b's transcript]`. This is the wall Task 4 exists to go around." The blocks are in
  the JSONL, as `attachment` records (§1.5) — the 2026-08-28 check parsed *message content*, which
  is the one place they are not. A verification scoped to the wrong container returns a clean null,
  and this one closed off the cheapest instrument in the inventory for two days.
- **Comparing IDE against CLI sessions in the existing corpus.** Cannot work: by turns it is
  13,952 `claude-vscode` against 3 `cli`. It becomes Task 3 Step 3 instead, as a deliberate pair.
- **Asking the model what changed.** A session cannot see its own injected blocks any more reliably
  than the transcript records them, and a self-report would be unfalsifiable.

## 4. What this plan does not cover

The 81 *explained* events are out of scope except for Task 1 Step 4, which only checks whether the
unknown block contaminates them -- and that step is on hold, since the bands it would check against
did not survive re-baselining. Their causes are known and none of them is a defect.
