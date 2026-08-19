---
name: distill-lessons
description: Review a finished stretch of work for durable lessons and write each one to the right place — CLAUDE.md for standing instructions, memory for incidents, nowhere for the rest. Use this whenever a branch, plan, multi-stage task, or long debugging session wraps up; when context is about to be lost to a compaction or session reset; and whenever the user asks "any lessons?", "anything for CLAUDE.md?", "what did we learn?", "anything worth remembering?", "let's debrief", or otherwise asks what should be carried forward from the work. Also use it proactively at the end of substantial work even if the user doesn't ask — lessons left in a plan doc or scratch ledger are read by nobody. Two things this is NOT for — summarizing or recapping what happened, which is a report on the work rather than a decision about what outlives it; and edits already decided on, since "add X to CLAUDE.md" or "remember that I prefer Y" is a direct request to just do it. This pass is for deciding *what* is worth recording.
version: 1.4.0
license: GPL-3.0-or-later
---

# Distill lessons

Work produces two things: the change, and what you learned making it. The change gets committed. The learning usually evaporates — it sits in a plan file or a scratch ledger that only that one workstream will ever open, and the next session rediscovers it the expensive way.

This skill is the discrete step that stops that. It runs *after* the work, not during — but immediately after, before the next thing starts. A lesson recovered a day later keeps the what and loses the *why*, and the why is the entire reusable part.

This is not a recap. Recapping tells someone what happened; this decides what should outlive it. Most of what happened should not outlive it.

The hard part is not noticing lessons. It's throwing most of them away and putting the survivors where they'll actually be read.

## 1. Decide whether there's anything here

There is no target number, in either direction. Yield tracks *when* this pass ran at least as much as how instructive the work was: a proactive pass at a boundary nobody flagged often finds nothing, while a pass someone invoked because the session felt instructive starts from a stronger prior and tends to find more. Both are ordinary results, and neither number tells you anything about the entries themselves.

**The throttle is per candidate, not a quota.** A candidate is worth considering only if you can name what it cost, or would cost next time: time lost, a wrong claim shipped, a bug that survived review, a gap that stayed open. If you can't attach a cost, you're about to spend prompt space on trivia.

A session can be long, difficult, and successful and still produce nothing worth writing down. Say plainly when that is the answer — manufacturing a lesson to look thorough makes every future session read one more line for no benefit. A long list meets the same bar item by item: it asserts that every entry passed, not that the work was unusually instructive.

## 2. Reflect

Look back over the work and ask:

- **What did I get wrong?** Not the typo — the reasoning that produced it. Start with the errors, because they often recur in the same shape, and the entry has a known next occurrence.
- **What context was missing that cost me time?** Something you had to derive empirically that the repo could simply have stated. These make good project entries, and they're easy to miss because by now you know the answer and it feels obvious.
- **What worked that isn't obvious?** A verification approach, an ordering, a cheap proof that replaced an expensive one.
- **What did the user correct me on?** A direct correction is the strongest signal here — no inference required. Capture the principle behind it, not just the specific fix.

Don't answer these from your memory of the session — that memory is a summary you already wrote, and the gap between what you think happened and what happened is where the lessons are. Ground the pass in what's on disk:

- **The work's own artifacts first.** The branch's `git log`, the plan doc, the scratch ledger, the audit file you were working from. Cheap to read, and they are exactly where lessons go to die — the reason this skill exists.
- **The transcript only for what artifacts can't hold.** Artifacts record what was decided; they never record what you got wrong on the way there, or what the user pushed back on. Session logs live at `~/.claude/projects/<project-slug>/*.jsonl` — grep them for the correction, never read one whole.

## 3. Generalize from the instance to the shape

This is the step that decides whether an entry is worth anything.

An instance is what happened. A shape is what will happen again. Only shapes are worth recording as instructions, because the next occurrence will not look like this one.

| Instance (nearly useless as a rule) | Shape (reusable) |
|---|---|
| "I said the lag was 1–2 s; it was 29–151 ms" | "Never state a timing you didn't measure — especially one inferred from your own sleep durations, which measure your parameter, not the system" |
| "The test used values that were also the defaults" | "A round-trip test must use values the failure mode can't coincidentally produce" |
| "A smoke-test list's comment said an entry covered the section page; the URL in it was a different page type" | "A test list's comments are unverified claims; confirm the suite covers the path you're changing before leaning on it" |

If you can't state the shape, you have an anecdote. Anecdotes belong in memory (as an incident) or nowhere — not in CLAUDE.md.

## 4. Route each survivor

**First: does a rule for this already exist?**

Check before routing. If the store already covers this ground, the lesson is not the rule — the rule is written, it was loaded, and it did not fire. A second copy produces two rules that will both sometimes fail to fire.

The output is a **revision of the existing entry, never a new one**, and the revision has a preferred shape: narrow the rule until a command can check it.

| Fires only if you remember it | Fires because you can run it |
|---|---|
| "Re-verify claims when you promote them into a commit message" | "A commit message describes its own diff; any sentence asserting something about code *outside* the diff is cut, or backed by a command run before committing" |

The right-hand version isn't better worded. It names an artifact, a boundary, and a check, so failing it is visible at the time — where failing the left-hand one is visible only in hindsight.

One shape to look for while you narrow: a rule stated as a norm, later read back as a description of the world. "Every file opens with a header" is an instruction; it is not evidence that every file has one, even when the inventory sits two sentences below it. Re-reading the source feels like verification and isn't.

Some rules are irreducibly judgment-shaped and can't be made checkable. That is itself the finding — the failure was **retrieval, not wording**. Restating it more forcefully is the second copy wearing a bolder font. Report it as a `refile-rules` trigger and leave the wording alone.

Otherwise, three destinations. Apply the test, not the vibe.

**CLAUDE.md — standing instructions.** Would this change what you *do* on some unrelated future task? It's loaded into every prompt, so it earns its place by changing behavior, not by being true. One line per concept, imperative, no narrative.
- *Project* `CLAUDE.md` if it's tied to this repo's tools, layout, or conventions.
- *User* `~/.claude/CLAUDE.md` if it holds regardless of repo.

**Then ask where you'd be standing when you needed it.** Always-loaded space is for content whose moment of need is a moment you would *not* know to go get it — a verification habit qualifies, because you don't know you're about to assert something unverified. Content with a natural trigger doesn't: an open `.R` file, a workflow YAML, a `.ps1` are perfect triggers, so those conventions belong in an on-demand skill and this file keeps at most a pointer to it.

**Size is a further gate, not a style preference:** an entry can pass the usefulness test and still cost more than it returns. A 90-word bullet added to a 300-word section is a 30% tax on that section, paid forever, on every unrelated task.

**Memory — incidents and context.** Is this the story of what happened, or state a future session would need to pick the work up? Memory holds the narrative, the numbers, the *why* — everything that would bloat CLAUDE.md. Follow whatever memory format the environment specifies — one fact per file, with frontmatter and an index line, is one common shape. If the environment has no memory tier at all, this destination collapses into CLAUDE.md or nowhere; say so plainly rather than inventing a store to write to.

If your memory system keeps an always-loaded index — a file of pointers read every session, with the memories themselves opened only on demand — that index line is a pointer, not a summary. It is loaded every session while the file behind it is not, so a hook that swells into a paragraph moves the cost back into the always-loaded tier and defeats the split it exists to make. Keep it under ~150 characters — enough to decide whether to open the file, never enough to stand in for it. Re-compress the hook whenever you touch the memory; this drift is silent and surfaces months later as a bloated index. Before compressing, confirm the file behind it actually makes the claims you're about to drop — a hook is sometimes *newer* than its file, and grepping for the keyword proves the word is present, not the claim.

**Nowhere.** Can it be easily re-derived from the code, git history, an audit doc, or an existing CLAUDE.md line? Then saving it creates a second copy that will go stale and contradict the first. This is the correct destination for most candidates.

**The split that keeps CLAUDE.md from bloating: the rule goes in CLAUDE.md, the incident goes in memory.** They cross-reference; they don't duplicate. A reader who wants to know *why* a rule exists can follow the link; a reader who just needs the rule isn't made to read the story first.

**Methods and recipes need the same split, and are the likeliest to get it wrong.** Step 2 explicitly asks what verification approach or cheap proof worked — but a recipe is neither a standing instruction nor an incident, so the routing above has no obvious slot for it, and the default pull is toward CLAUDE.md because a method *reads* like guidance. Put the **trigger** in CLAUDE.md and the **method** in memory: one line naming when you'd reach for it and where it lives, with the commands, the gotchas, and the approaches that failed behind that pointer. The trigger stays loaded so you know the method exists; the method itself costs nothing until the day it's needed.

Check the destination before writing, whichever it is: re-read the relevant CLAUDE.md section and search existing memories for the same ground. If something already covers it, extend or correct that instead of adding a second entry. Duplicates are worse than nothing — they drift apart and later readers can't tell which is current.

While you're in there, notice whether the file made the choice easy. If two sections could plausibly hold the entry, or you settle it by feel, that's a finding about the destination rather than a detail of your entry — a boundary you can't file against is one that retrieval can't search against either. Filing is the moment structural drift becomes visible, and this pass is the only one standing in the file when it does. Note it and name `refile-rules`. Don't reorganize here.

**Two weak candidates sometimes make one strong entry.** If several instances share a shape, record the shape once rather than each instance separately — the merged form is usually more useful than any of its parts, and it's the version that will match the next occurrence, which won't look like any of them.

## 5. Verify each claim before it becomes durable

Promotion into a permanent document is the moment to re-check what you're asserting. Once written, a claim reads as established and steers decisions without anyone re-testing it.

Pay particular attention to claims about the future — performance numbers, cost estimates, "option X was rejected because it needs Y." These get written with far less rigor than claims about current behavior, even though steering future work is their entire purpose. Measure the number. Re-derive the mechanism. Name it specifically, because a rationale that names its mechanism can be checked and "too invasive" cannot.

**Rigor tends to follow correction history rather than checkability.** The claims you hedge carefully are the ones that have already failed visibly and been corrected; the categories that have not yet embarrassed anyone go in flat and unqualified, in the same voice as a measurement. That is a diagnosis, not a character flaw — it means you cannot find the weak claims by asking which ones feel uncertain. Sort by *kind* instead. Four kinds get written far more confidently than they were checked:

| Kind | What makes it weak | What redeems it |
|---|---|---|
| **A claim about a system outside the repo** — a vendor, a crawler, a browser, a spec, what other teams do | It cannot be re-checked from the repo at all, and it decays on a schedule nobody tracks | A source or a date. "Google documents that the most restrictive robots directive wins" is the form |
| **A counterfactual** — "linting would have caught this", "a test here would have failed" | It reads as a finding but names a run nobody performed | Run the tool against the code that had the bug, or cut the sentence |
| **A superlative** — "highest-leverage", "the biggest item here" | It asserts a ranking across a set, on an axis nobody scored | Name the axis and the set compared, or write "worth doing" |
| **A generalization about how work goes** — "the normal fate of a stopgap nobody wrote an intent down for" | Identical grammar to an earned one; the difference is entirely whether a case exists | The incident, printed beside it or linked from it |

The counterfactual is the one worth running rather than reasoning about. An audit asserted that a single `eslint` pass "would have caught most of" four named bugs. The config it was describing enabled exactly one rule: the `ReferenceError` was caught, a duplicate key was not because that rule was off, an operator-precedence bug was covered by no enabled rule, and a wrong `getElementById` string is uncatchable by any linter in principle. One of four — in a sentence that also called it the highest-leverage gap. Neither claim survived being checked, and checking cost one file read.

Sourced and unsourced claims coexist happily in the same document and the same voice, so nearby rigor is not evidence. In the section that produced the example above, three claims cited Google's published guidance by name while six others in the same register — "how nearly every AI/LLM crawler operates today", "`geo.*` meta tags haven't influenced Google ranking in well over a decade", the latter temporal and undated — cited nothing. The correct form was available and in use in the same section.

**On the generalization row: this does not reverse step 3.** Step 3 tells you to generalize from the instance to the shape, and step 4 splits the rule into CLAUDE.md and the incident into memory. Read carelessly, "print the incident beside the generalization" contradicts both. It doesn't — step 4 already has the two cross-referencing rather than duplicating, and **the cross-reference is the anchor**. A rule in CLAUDE.md that links to the memory holding its case is anchored. What fails this gate is a generalization with neither the incident beside it nor a link to it: a claim about how software work goes, asserted from nothing, in the voice of experience.

If you find an earlier claim was wrong, correct it in place and say it was wrong. A quietly softened figure still misleads.

## 6. Propose, then apply

Show the user what you intend to write before writing it: for each destination, the path, a one-line reason, and the exact added lines as a diff. Seeing the real wording is what lets them judge it — a summary of what you plan to add is not reviewable.

**The diff is where register is judgeable against the real wording, so judge it here.** Step 5 asks whether each claim is true; this asks what the wording does to a reader. Run one test over every device in the proposed lines: does it pay a reader who has already decided to read? These entries go to an audience that cannot leave — a colleague, or you in four months, obliged to act on the line. A phrase that *compresses* something true earns its space, because they unpack it and find the finding. A phrase that *sustains attention* is borrowed from writing for readers who could close the tab, and it buys nothing while raising apparent certainty.

Two guards, and they bind as hard as the test itself:

- **Confidence about what was done and observed stays flat and declarative.** A record padded with "may" and "appears to" is harder to act on, and it launders the same distinction in the other direction — hedging a measurement makes it read like a guess, which is the failure this section exists to prevent, mirrored. Hedge what is uncertain. Assert what you ran.
- **Vivid phrasing that compresses something true nearby is kept, not trimmed.** "A test whose pass and fail states are indistinguishable is worse than no test" is doing work, and the incident sits in the next sentence. Trimming it to "unclear test outcomes are a problem" loses the trigger and gains nothing. This is a calibration, never a ban on writing well.

**For every CLAUDE.md addition, give its size against the section it joins** — words added, section length, the ratio. Measure it; don't estimate it. Do this in the proposal rather than after, because bloat is nearly invisible in a diff read line by line and obvious the moment it's a ratio. If the number is embarrassing, the entry wants to be a memory with a one-line pointer, not a bullet.

Then ask which to apply. Two reasons this matters: they know things you don't about what's already tribal knowledge, and a project CLAUDE.md is usually shared with a team, so it's their call what lands in it.

Mention what you considered and dropped, with the reason. That's often the most useful part of the report — it shows the filter ran, and they can overrule it.

If step 4 turned up a problem with the *destination* — two sections that could hold the same entry, or a rule that already exists and couldn't be narrowed into a checkable form — report it as its own line rather than folding it into the entry that surfaced it. It isn't a lesson and it isn't yours to fix here; it's `refile-rules`' input, and it will be lost if it arrives as an aside.

## What not to record

- Anything the repo already states — code structure, past fixes, git history, existing CLAUDE.md lines.
- Facts that only mattered inside this conversation.
- Restatements of general good practice ("write tests", "handle errors") with nothing situation-specific.
- The same lesson in both CLAUDE.md and memory at full length.
- Praise for how the work went.

If the user asks you to save something in these categories, don't refuse and don't comply mechanically — ask what was non-obvious about it, and record *that* instead. Usually there's a real lesson underneath a request to "remember this."

## Siblings

**`refile-rules` is this skill's pair.** This pass decides what is worth recording and where it goes; that one repairs the *where* when the destination's structure can no longer hold it. The handoff runs one way, from here — step 4 is standing in the destination file at the moment that file's boundaries get tested, and step 6 reports what the attempt to file revealed. Nothing here reorganizes anything itself.

`reconcile-records` is a neighbour rather than a required next step. It asks whether what is already written went *false* — a status line that has moved on, a number this work re-measured, a note the code now states better. Its own triggers already include the boundary you are standing on, so it does not need a handoff from here. Recommend it when you have reason to think this work falsified something already written. Finishing this pass is not that reason.
