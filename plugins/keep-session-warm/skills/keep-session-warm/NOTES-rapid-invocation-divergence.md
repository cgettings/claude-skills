---
status: raw notes, not yet reconciled into SKILL.md
date: 2026-08-08
---

# Rapid manual invocation causes self-inflicted "Diverged" verdicts

## Observation

During a manual test session (haiku → sonnet, VS Code entrypoint), running
`keepwarm-start` / `keepwarm-status` / `keepwarm-stop` back-to-back — plus
unrelated interactive turns like "say hello" — in quick succession produced
an oscillating pattern: `Warm` → stop → (more turns) → `Diverged` → retry
same args → `Warm` again.

Session id: `e7992a27-cfd3-4dfa-a157-2aab519543d0`. Transcript:
`C:\Users\Chris\.claude\projects\c--Users-Chris-Documents-Projects-Claude\e7992a27-cfd3-4dfa-a157-2aab519543d0.jsonl`

## Working theory

`Test-ClaudeCacheLineage.ps1` (and the probe inside `Start-ClaudeKeepwarm.ps1`)
measures cache read/write by resuming the *same* session id and appending a
synthetic turn ("Acknowledge and take no action" was visible in the
transcript immediately preceding a later real user turn). That probe turn
is written into the same transcript file the live interactive session is
also appending to.

Each slash command in this test session (`/keepwarm-start`,
`/keepwarm-status`, `/keepwarm-stop`, plain chat messages) is itself a new
turn appended to that transcript. So the prefix the probe is measuring
against is a moving target: if any turn — probe-injected or genuine user
message — lands between one probe's baseline measurement and the next
probe's read, the next probe sees a prefix that has already grown past what
it expected, and reports `Diverged` even though nothing about Entrypoint,
Effort, or the model actually changed.

Two transcript entries even show a `queue-operation` enqueue/dequeue pair
at the identical millisecond (`2026-08-08T03:28:54.569` / `.570`), which is
circumstantial evidence of concurrent-ish write activity around that window.

This was **not** reproduced with an isolated single start after a genuine
idle gap — it only showed up under rapid manual cycling, which is exactly
the scenario the skill already warns about for the ping-vs-live-session
case (`SKILL.md` / `keepwarm-stop.md`: "the scheduled ping and a live
session both append to the same transcript file with nothing coordinating
them"). This looks like the same failure mode, just triggered by manual
testing cadence rather than by a background scheduled task.

## Confirmed from source (2026-08-09)

The theory's central mechanism is no longer an inference from transcript
timestamps. `Ping-ClaudeSession.ps1:189` builds the command line as
`claude -p --resume <SessionId> <Prompt> --output-format json` and invokes it
at line 201. There is no side channel: a probe is an ordinary resume, so it
appends real turns to the same transcript file the live session is appending
to. That is the same single-writer collision `SKILL.md` §5 and
`keepwarm-stop.md` already warn about for the scheduled-ping case — the notes
below are that failure mode reached through manual cadence rather than through
a background task.

What this does **not** settle is whether the resulting `Diverged` verdict is
correct-but-unhelpful or a false negative; that remains open below.

## Open questions for later write-up

- Is there a way to make the probe non-destructive to the prefix (e.g. read
  the transcript directly instead of resuming), which would remove this
  failure mode entirely for the interactive-testing case?
- Should `keepwarm-check`/`keepwarm-start` documentation warn explicitly
  against rapid manual re-invocation, the way it already warns about
  scheduled-ping-vs-live-session collision?
- Worth confirming whether a `Diverged` verdict under this scenario is
  "correct but unhelpful" (prefix genuinely did move, so scheduling would
  have wasted money) vs. a false negative (prefix would have still mostly
  matched, just not byte-for-byte).

## Source conversation

Full back-and-forth (multiple start/status/stop cycles, verdicts, and the
investigation) is in the transcript above, roughly lines 200-277.
