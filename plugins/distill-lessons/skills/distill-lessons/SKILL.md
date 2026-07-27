---
name: distill-lessons
description: Review a finished stretch of work for durable lessons and write each one to the right place — CLAUDE.md for standing instructions, memory for incidents, nowhere for the rest. Use this whenever a branch, plan, multi-stage task, or long debugging session wraps up; when context is about to be lost to a compaction or session reset; and whenever the user asks "any lessons?", "anything for CLAUDE.md?", "what did we learn?", "anything worth remembering?", "let's debrief", or otherwise asks what should be carried forward from the work. Also use it proactively at the end of substantial work even if the user doesn't ask — lessons left in a plan doc or scratch ledger are read by nobody. Two things this is NOT for: summarizing or recapping what happened, which is a report on the work rather than a decision about what outlives it; and edits already decided on, since "add X to CLAUDE.md" or "remember that I prefer Y" is a direct request to just do it. This pass is for deciding *what* is worth recording.
---

# Distill lessons

Work produces two things: the change, and what you learned making it. The change gets committed. The learning usually evaporates — it sits in a plan file or a scratch ledger that only that one workstream will ever open, and the next session rediscovers it the expensive way.

This skill is the discrete step that stops that. It runs *after* the work, not during — but immediately after, before the next thing starts. A lesson recovered a day later keeps the what and loses the *why*, and the why is the entire reusable part.

This is not a recap. Recapping tells someone what happened; this decides what should outlive it. Most of what happened should not outlive it.

The hard part is not noticing lessons. It's throwing most of them away and putting the survivors where they'll actually be read.

## 1. Decide whether there's anything here

Most stretches of work yield **zero to two** durable lessons. A session can be long, difficult, and successful and still produce nothing worth writing down — that's the normal case, not a failure.

A candidate is worth considering only if you can name what it cost, or would cost next time: time lost, a wrong claim shipped, a bug that survived review, a gap that stayed open. If you can't attach a cost, you're about to spend prompt space on trivia.

Say plainly when the answer is nothing. Manufacturing a lesson to look thorough makes every future session read one more line for no benefit.

## 2. Reflect

Look back over the work and ask:

- **What did I get wrong?** Not the typo — the reasoning that produced it. Errors are the richest source because they recur in the same shape.
- **What context was missing that cost me time?** Something you had to derive empirically that the repo could simply have stated. These are the highest-value project entries, and they're easy to miss because by now you know the answer and it feels obvious.
- **What worked that isn't obvious?** A verification approach, an ordering, a cheap proof that replaced an expensive one.
- **What did the user correct me on?** Direct correction is the strongest signal available. Capture the principle behind it, not just the specific fix.

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

Three destinations. Apply the test, not the vibe.

**CLAUDE.md — standing instructions.** Would this change what you *do* on some unrelated future task? It's loaded into every prompt, so it earns its place by changing behavior, not by being true. One line per concept, imperative, no narrative.
- *Project* `CLAUDE.md` if it's tied to this repo's tools, layout, or conventions.
- *User* `~/.claude/CLAUDE.md` if it holds regardless of repo.

**Memory — incidents and context.** Is this the story of what happened, or state a future session would need to pick the work up? Memory holds the narrative, the numbers, the *why* — everything that would bloat CLAUDE.md. Follow whatever memory format the environment specifies — one fact per file, with frontmatter and an index line, is one common shape. If the environment has no memory tier at all, this destination collapses into CLAUDE.md or nowhere; say so plainly rather than inventing a store to write to.

If your memory system keeps an always-loaded index — a file of pointers read every session, with the memories themselves opened only on demand — that index line is a pointer, not a summary. It is loaded every session while the file behind it is not, so a hook that swells into a paragraph moves the cost back into the always-loaded tier and defeats the split it exists to make. Keep it under ~120 characters — enough to decide whether to open the file, never enough to stand in for it. Re-compress the hook whenever you touch the memory; this drift is silent and surfaces months later as a bloated index. Before compressing, confirm the file behind it actually makes the claims you're about to drop — a hook is sometimes *newer* than its file, and grepping for the keyword proves the word is present, not the claim.

**Nowhere.** Can it be easily re-derived from the code, git history, an audit doc, or an existing CLAUDE.md line? Then saving it creates a second copy that will go stale and contradict the first. This is the correct destination for most candidates.

**The split that keeps CLAUDE.md from bloating: the rule goes in CLAUDE.md, the incident goes in memory.** They cross-reference; they don't duplicate. A reader who wants to know *why* a rule exists can follow the link; a reader who just needs the rule isn't made to read the story first.

Check the destination before writing, whichever it is: re-read the relevant CLAUDE.md section and search existing memories for the same ground. If something already covers it, extend or correct that instead of adding a second entry. Duplicates are worse than nothing — they drift apart and later readers can't tell which is current.

**Two weak candidates sometimes make one strong entry.** If several instances share a shape, record the shape once rather than each instance separately — the merged form is usually more useful than any of its parts, and it's the version that will match the next occurrence, which won't look like any of them.

## 5. Verify each claim before it becomes durable

Promotion into a permanent document is the moment to re-check what you're asserting. Once written, a claim reads as established and steers decisions without anyone re-testing it.

Pay particular attention to claims about the future — performance numbers, cost estimates, "option X was rejected because it needs Y." These get written with far less rigor than claims about current behavior, even though steering future work is their entire purpose. Measure the number. Re-derive the mechanism. Name it specifically, because a rationale that names its mechanism can be checked and "too invasive" cannot.

If you find an earlier claim was wrong, correct it in place and say it was wrong. A quietly softened figure still misleads.

## 6. Propose, then apply

Show the user what you intend to write before writing it: for each destination, the path, a one-line reason, and the exact added lines as a diff. Seeing the real wording is what lets them judge it — a summary of what you plan to add is not reviewable.

Then ask which to apply. Two reasons this matters: they know things you don't about what's already tribal knowledge, and a project CLAUDE.md is usually shared with a team, so it's their call what lands in it.

Mention what you considered and dropped, with the reason. That's often the most useful part of the report — it shows the filter ran, and they can overrule it.

## What not to record

- Anything the repo already states — code structure, past fixes, git history, existing CLAUDE.md lines.
- Facts that only mattered inside this conversation.
- Restatements of general good practice ("write tests", "handle errors") with nothing situation-specific.
- The same lesson in both CLAUDE.md and memory at full length.
- Praise for how the work went.

If the user asks you to save something in these categories, don't refuse and don't comply mechanically — ask what was non-obvious about it, and record *that* instead. Usually there's a real lesson underneath a request to "remember this."

## After this pass

Adding is only half of keeping a record useful. The work you just finished is also the best evidence that something already written is now *wrong* — a status line that has moved on, a number this work re-measured, a note the code now states better.

That is a different pass with a different bar, and it belongs to `reconcile-records`. Run it after this one, **including when this one found nothing** — work invalidates records whether or not it teaches anything.
