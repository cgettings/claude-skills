# grounded-output-style

A `SessionStart` hook that carries a verification-first, claims-calibrated working style into
any project. Claude Code's literal output-style file format is deprecated — the CLI's own
changelog points instead to `--system-prompt-file`, `--append-system-prompt`, CLAUDE.md, or
plugins. This plugin is that last option, built the same way Anthropic's own
`explanatory-output-style` and `learning-output-style` rebuild their deprecated styles: a hook
that injects instructions at session start rather than a static style file.

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
writing is a regular part of what you do in a given project; disable it in projects where it
isn't.

## Install

```
/plugin marketplace add cgettings/claude-skills
/plugin install grounded-output-style@cgettings-skills
```

Disable per-project with `/plugin` if you only want it active where verification writing is
frequent.

## Relationship to CLAUDE.md

This is a distillation of a `CLAUDE.md`'s verification and register rules, made portable. If your
CLAUDE.md already states the same rules in full, the two overlap — the hook is for projects and
machines that don't have that CLAUDE.md, not a replacement for a project's own standing
instructions where richer rationale and repo-specific detail belong.

## License

GPL-3.0-or-later. Copyright (C) 2026 Chris Gettings. Full text in [LICENSE](LICENSE).
