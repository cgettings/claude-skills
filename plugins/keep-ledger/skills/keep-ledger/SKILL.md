---
name: keep-ledger
description: Keep a resumable ledger — what is done, what proof actually ran, and the exact next command — in the tracked document that owns the work, written so a session that was not there can run the next step from it alone. Use when starting anything with more than one step (a plan about to be executed, a staging list, a migration, a multi-stage refactor), and use again when picking such work back up — a new session, a fresh context after a compaction or a session-limit reset, or when the user says "where were we", "pick this back up", "what's left on X", "did we finish Y". Also use when a plan or staging list turns out to list steps with no status. This is not for deciding what knowledge is worth keeping, which is `distill-lessons`, and not for sweeping a record store for what recent work made false, which is `reconcile-records` — though a stale or absent ledger is exactly what that pass is built to catch. It is also not a session recap or a handover summary — those describe what happened, and a ledger records only what a future session must act on.
version: 1.3.0
license: GPL-3.0-or-later
---

# Keep a ledger

A plan says what to do. It does not say what happened — and after the first session, what happened is the only thing a reader needs.

The gap is invisible while you are in the session, because you are the record. It becomes the entire problem the moment you are not: a fresh session opens the plan, cannot tell done from pending, and has two moves available, both wrong — redo work that landed, or skip work that didn't.

So the failure this guards against is not forgetting to keep a ledger. It is keeping one that lists steps and holds no state.

## 1. Write it at the start

Every plan with more than one step gets a ledger, and it gets one before the first step runs — not when the context starts to feel tight.

The moment you need it is the moment you cannot write it. A session that hits a limit does not get a turn to summarize itself first; a compaction does not ask. Whatever is on disk survives and nothing else does.

Scale the ledger to the work rather than exempting the work. A three-step task's ledger is three lines with a status each, and costs about as much to write as saying you'll do it later. Ceremony out of proportion to the job is how a standing rule quietly stops being followed.

## 2. Put it in the tracked document that owns the work

Committed, in the repo, in the file a session picking this up would open first — the plan, the scoping memo, the design doc, the staging list. Not a scratch directory, not a git-ignored workspace, not a chat message.

One case is the whole argument. A staging list living as §11 of a tracked scoping memo survived the session that wrote it, the branch, and three separate records passes, and was still the first thing a later session opened — because it was committed. Nothing in a scratch directory has that property: it is invisible to `git log`, absent from the next clone, and unreadable by anyone who wasn't in the room.

Where no document owns the work yet, creating one **is** the first entry of the ledger. The smallest thing that can be committed beats the best thing that can't.

## 3. Give every step a status

The vocabulary, and the distinctions that matter:

| Status | Says |
|---|---|
| **DONE `<date>`** | Landed, and names the commit that holds it. Carries its proof (step 4) and, if the prescribed proof was wrong, the correction |
| **Not started** | Available. A session may pick it up |
| **In progress** | Someone is mid-flight; name what is half-done |
| **Parked** | A choice that was made and can be unmade. Say what would unpark it |
| **BLOCKED on X** | Something outside this work must happen first |
| **On a separate track** | Another person or workstream owns it. Say what the second-lander must re-read rather than assume |

Parked and blocked are not synonyms, and the difference is who acts next. A step marked with neither reads as available, and a session will start it.

**Record identities; derive relationships.** A ledger holds two kinds of fact and they age completely differently. An identity — a commit hash, a file path, the date an event happened — is stable: `3ce4b8f2b3` is that commit through a push, a merge, someone else's rebase, and the deletion of the branch it sat on. A relationship is two refs evaluated at a moment: *unpushed*, *unmerged*, *no PR open*, *8 commits ahead*. Each is true only until something moves, and each is falsified by a different event, which the phrase gives no hint of — so nobody knows what to re-check or when. Write the identity down; leave the relationship to be derived (§5).

**So a DONE row names the commit that holds it.** DONE is a relationship, and it survives this vocabulary because the hash and the date turn it into an identity: `A @ 3ce4b8f2b3` says what landed and when, and lets a reader derive the part they actually need at the moment they need it — `git merge-base --is-ancestor 3ce4b8f2b3 production`, which exits non-zero for *no*. The branch name stays in the cell as the readable locator; the hash is the half that still resolves without it. What the row itself claims stays narrow: a fact about that commit, and about nothing downstream of it until the branch merges.

Two limits, and both bite. A hash cited for *what it identifies* is stable — "these seven commits are the task work"; a hash cited for *what it is currently the tip of* is a relationship in an identity's clothes, and it moves on the next commit. Pin the range, not the tip. And only relationships the repo can answer are derivable at all: **Parked**, **BLOCKED on X**, and **On a separate track** are relationships too, no command returns them, and that is exactly why a ledger has to hold them.

| # | Step | Commit | Status | Proof that ran |
|---|---|---|---|---|
| 4 | Duplicate `id` in the nav partial | `A @ d0fc7e1753` | **DONE 2026-08-21** | axe `duplicate-id`, 0 violations over 4 pages |
| 5 | Duplicate `id` in the masthead | `A @ d0fc7e1753` | **DONE 2026-08-21** | same run |
| 9 | Unused print stylesheet import | *no commit* — the partial emits zero CSS | **DONE 2026-08-21** | `sass` build of the partial alone, 0 bytes out |

One commit closing several steps is ordinary: the hash is not a unique key, and two rows carrying the same one record that they were a single authoring error. A step that closes with no commit at all says so in that cell, in words. **The cell is never left blank** — blank has one meaning and needs to keep it, which is the gap between the work landing and the ledger commit that records where.

The incident: nine rows like these, each **DONE**, dated, and carrying a proof of zero axe violations over four pages — beside a Branch column reading `A` and a working tree holding all of it. `git status --porcelain` returned 16 modified files; `git log` showed nothing since the branch point. The paragraph above the table did say "nothing is committed yet", so the fact was on the page. It was not in the field carrying the verdict, and the field carrying the verdict is the one that gets acted on.

Open the ledger with one line giving the shape before anyone reads six entries — and give it the same scope the rows carry, because a correction made in a row does not travel up to it: **Status as of 2026-08-06: step 1 done on `A`, unmerged; step 2 on a separate track; steps 3–6 untouched.**

Close it, when the whole thing lands, with one line: done, the date, the commit range. That converts a live record into a dated historical one — which `reconcile-records` will then correctly leave alone instead of trying to freshen.

**A status you did not check is worse than none.** Confirm from the repo — the commits, the file, the test run — never from your memory of the session or from the user's summary of it.

## 4. Record the proof that ran, not the proof you planned

This is the field that makes a wrong ledger dangerous rather than merely thin.

A step's proof is written when the step is planned and executed when the step is done, and those are not the same claim. The written one is a guess about a repo you had not yet run it against. **A ledger recording the intended check rather than the executed one is worse than a ledger with no proof field at all, because the next session follows it.**

So when the check that ran differs from the check that was written, correct the written one in place and say why it could not work. Do not quietly swap it: the reason the prescribed check failed is usually a property of the repo that will trip a later step the same way.

The incident this comes from: a step prescribed "a clean build plus a `git diff` of `docs/`". That cannot work in that repo, because `docs/` holds a stale build from a different environment and the diff is dominated by the environment difference rather than by the change. What ran instead was two full production builds into separate temp directories, diffed with `diff -r` — 2,766 files and 1,158 pages each, differing only in three build-timestamp lines. The corrected entry says all of that, and says to use the same A/B form for the later step that needs the same diff.

Write it in the house form — `[verified <date>: how]` — naming the command, its flags, and the numbers that came back. Same vocabulary as the audit docs, on purpose.

## 5. Point at landmarks, not line numbers

The next session's copy of the file has moved. Address things that survive an edit: the path plus the symbol, the function, the heading. Carry a line number if it helps, never as the only locator, and say when it moved — *now at `assets/js/nr-topic-spa/url.js:21` after the module split*.

The same standard applies to what runs next. Write the exact command with its flags and what a pass looks like. "Run the characterization check" is a lookup task handed to the next session; `npm run characterize:nr -- --check`, zero diffs expected, is not.

It applies again to every relationship you were about to write as a status (§3). Write the command that derives it, and what its answer looks like:

```
git log --oneline BASE..HEAD                             # the task commits
git rev-list --left-right --count origin/BRANCH...HEAD   # 0 0 means pushed
gh pr list --head BRANCH                                 # a PR, and against which base
```

## 6. Update it as part of the step, then check it against a cold session

The ledger is updated as part of the step, not at an end of session that may never arrive; a ledger written from recollection is written by the least reliable witness available.

A row naming its own commit cannot be written by that commit, so the order is fixed: **the work commits first, then one ledger commit fills in the hashes.** Batch it — seven task commits followed by one ledger commit naming all seven, rather than alternating. That ledger commit does not name itself and has no need to: the row names the *work's* commit, which is what a later session has to find, and a commit holding only bookkeeping is not.

A rebase, a squash-merge, or an amend invalidates every hash in the ledger, so refresh the column in the same operation that rewrote them. A stale hash is worse than the bare branch name it replaced: it reads as precise and resolves to nothing. This is the one case where the phrase form is cheaper, and worth saying plainly — the hash column shifts the cost of keeping a status true rather than removing it, and a rebase is when the whole table's bill arrives at once.

**Then ask one question before moving on: could a session that was not here run the next step from this document alone?** Finishing a plan in one sitting is a common case, not a safe assumption, and the ledger is written against the case where it isn't.

The question has a mechanical form, and it is cheaper than it sounds: **write out the literal next command.** If you cannot write it without a fact the ledger does not hold, that fact is what to record. Nothing else needs auditing.

Then run it backwards, over the same two sections: **for each status phrase, name the command in the next-command block that would falsify it.** If you can name one, that phrase is a snapshot in a record's clothes. The overlap is not a coincidence to watch for — the next-command block exists to change the state the status block describes, so the two are adjacent by construction and one action apart by design. A resume block reading `# expect 8 commits` was falsified by committing the ledger correction written directly above it.

The incident: *unpushed, no PR* went into a ledger and two memory records at about 11:00 and was false inside the half hour, because the user pushed — which is what the ledger's own next-command block had told them to do. Three files went false at once, from a single action the document itself had asked for. A relationship does not merely go stale; it spawns copies that then go stale independently. Every hash in those same records needed no correction at all.

Four things strand a cold session, and none of them is a step status — which is how a ledger can look complete and still fail:

- **A decision taken, and what was rejected with it.** A session that does not know an option was considered and dropped will re-argue it or quietly undo it. Record the choice and the reason once.
- **Environment state.** The branch, the worktree, a seeded fixture, a temp directory, a service left running, a checkout that is not where someone would assume. None of it is in the repo, and all of it goes with the session.
- **What was deliberately deferred, and what would un-defer it.** Otherwise it reads as an oversight — or as done.
- **Uncommitted state.** What is in the working tree and why it has not been committed.

**Asking costs a sentence; recording happens only when the answer isn't "nothing".** That asymmetry is what makes the check affordable every step, and it is why the check does not license a ledger out of proportion to the work. §1 still holds: a three-step task's ledger is still three lines with a status each.

## 7. On resume, the ledger and `git log` outrank your recollection

Read the ledger first, then check its status line against the commits before touching anything. If the two disagree, the repo is right, and correcting the ledger is the first edit of the session rather than something to do once the real work is done.

The hashes are what make that check mechanical. `git cat-file -e <hash>^{commit}` says whether a row still points at anything — one that no longer resolves means the history moved under the ledger, not that the step came undone — and `git branch -a --contains <hash>` says where the work has reached since, which is the question a DONE row deliberately does not answer.

This binds hardest exactly where it feels least necessary. After a compaction, "recollection" is a summary you wrote about a session, at a remove from the session. A user's recap is honest and abbreviated. Neither is evidence; the commits are.

## What a ledger is not

- **A second copy of the plan.** It points at the plan's steps and records their state. Two copies drift, and a reader can't tell which is current.
- **A session recap.** Nobody picking the work up needs the narrative. Record only what they must act on.
- **A restatement of `git log`.** What the commits already say, leave to them. The ledger holds what they can't: status, the proof that ran, and what comes next. The hash in a DONE row is not an exception to this — it is the join key into the log, not a copy of what the log holds.
- **A home for lessons.** What you learned belongs where it will actually be read, and `distill-lessons` decides where that is. A lesson parked in a ledger is read by the one workstream that opens the ledger — which is the failure that skill exists to fix.
- **A status nobody verified.** Repeated because it is the cheapest thing here to get wrong and the most expensive downstream.

## Credit

The ledger's shape — the identity line, the `parked` / `BLOCKED` vocabulary, the completion line
with its commit range, and the resume rule — is adapted from `subagent-driven-development` in
[superpowers](https://github.com/obra/superpowers) (MIT). This plugin's README says what was
borrowed and the one place it deliberately departs.

## Siblings

**`reconcile-records` is this skill's pair.** A ledger is a status record, which makes it exactly the artifact that pass is built to check: a step whose status has moved on is its first gate, and work that ended mid-flight with nothing written down is its second. Keeping one is what gives those gates something greppable to find. Run that pass at the work's next boundary — it will find the ledger, and a found ledger is cheap to correct.

`distill-lessons` and `refile-rules` are the other pair, and neither takes input from here. A lesson parked in a ledger is read by the one workstream that opens the ledger, which is the failure the first of those exists to fix.
