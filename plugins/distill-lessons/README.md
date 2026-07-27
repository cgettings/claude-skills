# distill-lessons

Reviews a finished stretch of work for durable lessons and writes each one where it will
actually be read.

**What it isn't.** Not a session recap, not a post-mortem, not a handover summary. Those
describe what happened. This decides what's worth carrying forward — and throws away most of
it. Most sessions yield zero to two durable lessons, and saying "nothing" is a normal outcome
rather than a failure.

## When it runs

When a branch, plan, multi-stage task, or long debugging session wraps up; when context is
about to be lost to a compaction or session reset; and whenever someone asks "any lessons?",
"anything for CLAUDE.md?", or "what did we learn?". It also fires proactively at the end of
substantial work, because lessons left in a plan doc or scratch ledger are read by nobody.

Two things it deliberately does *not* fire on: a request to recap what happened, which is a
report rather than a decision about what outlives the work; and an edit already decided on
("add X to CLAUDE.md"), which is a direct request to just do it.

## The six steps

1. **Decide whether there's anything here** — a candidate needs a nameable cost, or it's trivia.
2. **Reflect**, grounded in artifacts on disk rather than recall — the branch's `git log`, the
   plan doc, the scratch ledger, and the transcript only for what artifacts can't hold.
3. **Generalize** each candidate from an instance to a reusable shape. If you can't state the
   shape, you have an anecdote.
4. **Route the survivors** — CLAUDE.md for standing rules, memory for incidents and methods,
   nowhere for most of them.
5. **Verify each claim** before it becomes durable, especially forward-looking ones.
6. **Propose the exact wording as a diff**, with each CLAUDE.md addition's measured size against
   the section it joins.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install distill-lessons@cgettings-skills
```

Designed to run back to back with [`reconcile-records`](../reconcile-records), which corrects
what this work made false. That pass runs even when this one finds nothing.

## Assumptions about your setup

- **CLAUDE.md** — standard, and required for the "standing instructions" destination.
- **A memory tier** — optional. If your setup has one, the skill follows whatever format it
  specifies. If not, that destination collapses into CLAUDE.md or nowhere, and the skill says
  so rather than inventing a store to write to.
- **An always-loaded memory index** — optional. The hook-length rule only applies if your
  memory system has one.
- **Session transcripts** at `~/.claude/projects/<project-slug>/*.jsonl` — used only to recover
  user corrections, which artifacts never record.

## Evals

Six cases in [`skills/distill-lessons/evals/evals.json`](skills/distill-lessons/evals/evals.json),
weighted toward near-misses — the prompts that look like a trigger and aren't. Three of the six
must *not* invoke the workflow.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
