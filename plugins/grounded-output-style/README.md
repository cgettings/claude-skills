# grounded-output-style

An output style that carries a verification-first, claims-calibrated working style into any
project. It ships as [`output-styles/grounded.md`](output-styles/grounded.md) — the real output
style file format, appended to the system prompt with `keep-coding-instructions: true`, so it
modifies how Claude reports and verifies without discarding its software engineering behavior.

The style file format is current, not deprecated; only the standalone `/output-style` command
was removed, in v2.1.91. Select the style through `/config` → **Output style** instead
([docs](https://code.claude.com/docs/en/output-styles), fetched 2026-07-30).

## The trap this exists to close

Confident, well-formed prose reads as verified whether or not it was. A polished declarative
sentence and a carefully measured one read with the same apparent authority — nothing marks
which one actually earned it — so a reader who must act on it, rather than skim past it, has no
way to tell them apart except by re-deriving the claim themselves.

**Where the confidence comes from.** This register is borrowed from a genre built for a
different audience: opinionated technical writing, conference talks, forum threads, where the
job is to hold a reader who is free to leave, and confidence is the currency that does it. The
actual audience for a review, an audit, or a piece of documentation cannot leave — a colleague,
a future session, an agent picking the work back up are already committed to reading and are
obliged to act on what's written. Applying the leaveable-audience voice to a can't-leave
audience produces the trap: an unsourced guess and a line-cited measurement arrive in the same
confident register, so tone stops signaling rigor and the reader is left re-deriving every claim
to find out which was which.

The four groups below are the checkable form of "match your register to what you actually
checked" — verification, claims, effort, and code, in that order because verification is what
the other three assume.

## What it changes

- **Verification** — matches the check to the risk (grep/lint for mechanical changes, a build
  for compile-time claims, a runtime/browser check for behavior/timing/CSS), states which check
  was run and why it's enough, and treats an unmeasured number or an unproven-probe null result
  as not yet a finding.
- **Claims & register** — sources or dates any claim about the world outside the repo, tests
  "would have caught this" instead of asserting it, requires a named axis and set behind any
  superlative, and spends bold sparingly since it's a superlative in typographic form.
- **Effort** — cheapest structure that still proves the work; states the cost before proposing a
  multi-agent workflow.
- **Code** — smallest change that solves the problem; comments only the non-obvious why.

## Cost

This adds roughly 600 words of instructions to every session's context, every time — not just
when the task touches verification or writing. That's a real, recurring tax, the same tradeoff
Anthropic flags on their own output-style plugins. It's worth it if review/audit/documentation
writing is a regular part of what you do in a given project; switch to another style in projects
where it isn't.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install grounded-output-style@cgettings-skills
```

Then select it: `/config` → **Output style** → **Grounded**. Output style is part of the system
prompt, which Claude Code reads once per session, so the change takes effect after `/clear` or in
the next session.

Selecting a style is exclusive — **Grounded** replaces whatever style is active, including
built-ins like Proactive. Your choice is saved to `outputStyle` in
`.claude/settings.local.json`, so it's per-project by default.

If you'd rather it apply automatically wherever the plugin is enabled, add
`force-for-plugin: true` to the frontmatter of [`output-styles/grounded.md`](output-styles/grounded.md).
That's deliberately off here: it overrides the user's `outputStyle` setting, so enabling the
plugin would silently take over a project where you'd picked something else.

### Without the plugin

The style file is self-contained. Copy it to `~/.claude/output-styles/grounded.md` for all
projects, or `.claude/output-styles/grounded.md` for one.

## Relationship to CLAUDE.md

This is a distillation of a `CLAUDE.md`'s verification and register rules, made portable. If your
CLAUDE.md already states the same rules in full, the two overlap — the style is for projects and
machines that don't have that CLAUDE.md, not a replacement for a project's own standing
instructions where richer rationale and repo-specific detail belong.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
