# keep-ledger

Keeps a resumable ledger for work that runs past one sitting — what is done, what proof
actually ran, and the exact next command — in the tracked document that owns the work.

**Why it's separate.** A plan says what to do. It does not say what happened, and after the
first session that is the only thing a reader needs. The gap is invisible while you're in the
session, because you *are* the record; it becomes the whole problem the moment you're not. A
fresh session opens the plan, can't tell done from pending, and has two moves available, both
wrong — redo work that landed, or skip work that didn't.

So the failure this guards against isn't forgetting to keep a ledger. It's keeping one that
lists steps and holds no state.

## When it runs

Twice per piece of work: at the start of anything with more than one step, before the first
step runs — and again on every resume, when a new session, a compaction, or a session-limit
reset means the person reading the plan wasn't the person who wrote it.

It is not for deciding what knowledge is worth keeping, which is
[`distill-lessons`](../distill-lessons). It is also not a session recap or a handover summary:
those describe what happened, and a ledger records only what a future session must act on.

## Siblings

Its pair is [`reconcile-records`](../reconcile-records). A ledger is a status record, so it's
precisely what that pass's first two gates look for — a step whose status has moved on, and work
that ended mid-flight with nothing written down. Keeping one is what gives those gates something
greppable to find, and a found ledger is cheap to correct. The two halves divide by when they run:
this one while the work is live, that one once it has moved on.

## The seven steps

1. **Write it at the start**, not when context starts to feel tight — the moment you need it
   is the moment you can't write it. Scale it to the work: a three-step task's ledger is three
   lines.
2. **Put it in the tracked document that owns the work.** Committed, in the repo, in the file
   a session picking this up would open first. Where nothing owns the work yet, creating that
   document *is* the first entry.
3. **Give every step a status** — done, not started, in progress, parked, BLOCKED on X, on a
   separate track. Parked and blocked aren't synonyms; the difference is who acts next. A step
   marked with neither reads as available, and a session will start it. Record identities and
   derive relationships: a hash is stable, while *unpushed* and *unmerged* are true only until
   something moves. So a DONE row names the commit that holds it, not just the branch — it's a
   fact about that commit and about nothing downstream of it until the branch merges.
4. **Record the proof that ran, not the proof you planned.** The written check is a guess about
   a repo you hadn't run it against yet. When they differ, correct the written one in place and
   say why it couldn't work.
5. **Point at landmarks, not line numbers** — the path plus the symbol, and the exact next
   command with its flags and what a pass looks like. A relationship you were about to write as
   a status takes the same form: the command that derives it, and its expected answer.
6. **Update it as part of the step** — there may be no end of session to do it at. A row can't be
   written by the commit it names, so the work commits first and one ledger commit fills in the
   hashes. Then check it against a cold session: could someone who wasn't here
   run the next step from this document alone? The mechanical form is to write out the literal
   next command; if you can't, the missing fact is what to record. Four things strand a cold
   session and none of them is a step status: a decision taken and what was rejected with it,
   environment state, what was deliberately deferred, and uncommitted state. Asking costs a
   sentence and recording happens only when the answer isn't "nothing", which is the asymmetry that
   makes it affordable every step. Then run it backwards: for each status phrase, name the command
   in the next-command block that would falsify it. The two are adjacent by construction, so if you
   can name one, that phrase is a snapshot in a record's clothes.
7. **On resume, the ledger and `git log` outrank your recollection.** If the ledger and the repo
   disagree, the repo is right, and correcting the ledger is the first edit of the session.
   Resolving the ledger's hashes is the cheapest form of that check.

## The rule worth stating on its own

> A ledger recording the intended check rather than the executed one is worse than a ledger with
> no proof field at all, because the next session follows it.

## Credit

The idea isn't original here. Keeping a ledger for work that spans sessions is common practice and
belongs to nobody, but the *shape* this skill uses came from
[`superpowers`](https://github.com/obra/superpowers) by Jesse Vincent — specifically its
`subagent-driven-development` skill, which is where I first saw a ledger **specified** rather than
recommended. In superpowers 6.2.0 it is the only skill of the fourteen that mentions a ledger at
all: `grep -ci ledger` returns 33 for its `SKILL.md` and 0 for the other thirteen.

Four things here are lifted from it:

- **The resume rule.** "After compaction, trust the ledger and `git log` over your own
  recollection." Step 7 is that sentence with the disagreement case spelled out — if the two
  conflict, the repo wins and correcting the ledger is the first edit of the session.
- **The identity line first.** SDD opens its ledger with `# SDD ledger — plan: <path>`; here that's
  the status-as-of line at the top, which also carries the shape before anyone reads six entries.
- **The `parked` / `BLOCKED` vocabulary**, and the rule that an adjudication is a ledger entry
  rather than a silent discard. Here it's the status table, and the reason parked and blocked
  aren't synonyms — the difference is who acts next.
- **The completion line naming its commit range.** Here it's the line that closes a ledger out and
  converts it into a dated historical record.

**One deliberate departure.** SDD's ledger lives in a git-ignored workspace
(`.superpowers/sdd/<plan-basename>/progress.md`); the skill notes that `git clean -fdx` will
destroy it and to recover from `git log`. This one lives in the tracked document that owns the
work. That isn't a correction of SDD — its ledger serves a controller driving subagents through one
machine-run plan, and a scratch workspace is the right scope for that. This one is for work handed
between sessions and people, where being committed is the only reason it survives at all.

Nothing is copied verbatim. superpowers is MIT-licensed; this is GPL-3.0-or-later.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install keep-ledger@cgettings-skills
```

## What a ledger is not

A second copy of the plan; a session recap; a restatement of `git log`; a home for lessons —
one parked in a ledger is read by the single workstream that opens it, which is the evaporation
[`distill-lessons`](../distill-lessons) exists to prevent. And never a status nobody verified.

## Evals

Eight cases in [`skills/keep-ledger/evals/evals.json`](skills/keep-ledger/evals/evals.json),
six positive and two near-misses. Five need a seeded fixture: a six-step plan with no status
fields (case 1), a ledger whose step 1 prescribes a `docs/` diff that can't work in that repo
and a later step prescribing the same (case 3), a ledger claiming a step is unstarted against
commits showing it landed (case 4), an open ledger with a step another team has taken over
(case 5), and a nine-row ledger whose rows are true of the working tree and false of the branch
they name (case 8). A [`trigger_eval.json`](skills/keep-ledger/evals/trigger_eval.json) carries
twenty-two phrasings, ten positive and twelve negative; seven of the negatives belong squarely to
the three sibling skills, which compete for prompts about a document going wrong.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
