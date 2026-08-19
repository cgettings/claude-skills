# distill-lessons

Reviews a finished stretch of work for durable lessons and writes each one where it will
actually be read.

**What it isn't.** Not a session recap, not a post-mortem, not a handover summary. Those
describe what happened. This decides what's worth carrying forward — and throws away most of
it. There's no target number: yield tracks when the pass ran at least as much as how instructive
the work was, and saying "nothing" is an ordinary outcome rather than a failure.

## When it runs

When a branch, plan, multi-stage task, or long debugging session wraps up; when context is
about to be lost to a compaction or session reset; and whenever someone asks "any lessons?",
"anything for CLAUDE.md?", or "what did we learn?". It also fires proactively at the end of
substantial work, because lessons left in a plan doc or scratch ledger are read by nobody.

Two things it deliberately does *not* fire on: a request to recap what happened, which is a
report rather than a decision about what outlives the work; and an edit already decided on
("add X to CLAUDE.md"), which is a direct request to just do it.

## The six steps

1. **Decide whether there's anything here** — the throttle is per candidate, not a quota. Each one
   needs a nameable cost, or it's trivia.
2. **Reflect**, grounded in artifacts on disk rather than recall — the branch's `git log`, the
   plan doc, the scratch ledger, and the transcript only for what artifacts can't hold.
3. **Generalize** each candidate from an instance to a reusable shape. If you can't state the
   shape, you have an anecdote.
4. **Route the survivors** — but first check whether a rule for this already exists. If it does, the
   lesson isn't the rule; the rule is written and it didn't fire, and a second copy makes two rules
   that will both sometimes fail to fire. The output there is a revision of the existing entry,
   narrowed until a command can check it — never a new entry. Otherwise: CLAUDE.md for standing
   rules, memory for incidents and methods, nowhere for most of them.
5. **Verify each claim** before it becomes durable, especially forward-looking ones.
6. **Propose the exact wording as a diff**, with each CLAUDE.md addition's measured size against
   the section it joins.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install distill-lessons@cgettings-skills
```

## Siblings

Its pair is [`refile-rules`](../refile-rules). This pass decides what is worth recording and where
it goes; that one repairs the *where* when the structure can no longer hold it. Filing is when a
store's boundaries actually get tested — you are in the file, trying to put something in it — so if
two sections could plausibly hold an entry, or a rule that already existed couldn't be narrowed
into a checkable form, that's reported as a finding about the file and handed over. This pass never
reorganizes anything itself.

[`reconcile-records`](../reconcile-records) is a neighbour, not a required next step. It corrects
what went false rather than adding what's new, and its own triggers already include the boundary
you're standing on. Recommend it when there's reason to think this work falsified something.

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
weighted toward near-misses — the prompts that look like a trigger and aren't. Two must not invoke
the workflow at all (cases 3 and 4); one must not comply with a save request as given (case 6); and
one runs the pass and correctly concludes there is nothing to record (case 2).

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
