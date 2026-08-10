# `keep-session-warm` — retired 2026-08-09

**Status: withdrawn from the `cgettings-skills` marketplace. The tool did not do
what it claimed, and the shortfall is structural rather than a bug.**

It shipped on the premise that a scheduled `claude -p --resume` ping would keep a
Claude Code session's prompt cache warm across a gap, so the next interactive turn
would be served as a cache read instead of paying a full-prefix rewrite. Live
measurement on 2026-08-09 showed the ping maintains a *different* cache entry from
the one an interactive session resumes into, and that no available configuration
brings the two together.

## What was measured

Two interactive VS Code sessions on Haiku 4.5, `b6ff4e93` and `cf9026f0`, started
in this repository for the test, each with one turn. Then `claude -p --resume`
pings against them from PowerShell in the same directory, with
`CLAUDE_CODE_ENTRYPOINT=claude-vscode` and `--effort medium` — the same values the
plugin pinned.

| what ran | read | write | prefix | read fraction | cost |
|---|---|---|---|---|---|
| `cf9026f0` own interactive turn | 19,740 | 18,023 | 37,763 | — | — |
| `b6ff4e93` own interactive turn | 19,740 | 17,903 | 37,643 | — | — |
| plain ping → `cf9026f0` | 18,269 | 18,395 | 36,664 | 0.498 | $0.0390 |
| ping with `--ide` → `b6ff4e93` | 18,269 | 18,268 | 36,537 | 0.500 | $0.0387 |
| 2nd consecutive plain ping → `cf9026f0` | 36,664 | 99 | 36,763 | 0.997 | $0.0041 |

Three findings, in the order they matter.

**A ping rewrites half the prefix of a real interactive session.** Read fraction
0.498 on the first ping — the API reported `cache_miss_reason=system_changed`. This
is not a degraded case; it is what every first ping does.

**18,269 is a hard constant, which is what kills the repair path.** The same value
appears on every `claude -p` first-resume measured that day: in a bare `$env:TEMP`
throwaway with no CLAUDE.md, no plugins and no MCP servers, *and* in this
repository with all three. The shared segment therefore sits upstream of every
project-specific thing, so aligning tool rosters, MCP config, plugins or settings
sources cannot extend it. `--ide` was tested directly and returned a byte-identical
read.

**Pings warm each other, not the session.** The second ping read 36,664 — exactly
what the first ping wrote — at read fraction 0.997. That is the healthy `OK`
line the plugin's log reported all along. The line was accurate. It described a
cache entry the interactive client never reads.

The interactive base (19,740) and the headless base (18,269) differ in length, so
the two are distinct entries from early in the prefix.

## Why the economics don't survive either

A warm ping read 36,664 tokens and cost $0.0041 all-in, output included. The most
a ping could possibly do for an interactive turn is refresh shared blocks worth
about 18K of reads — under half that prefix, so under $0.002 by the same
measurement. **The ping costs about twice the benefit it could deliver at best**,
and the ratio does not improve on a larger model, because both sides scale with it.

`SKILL.md` computed a ~20-ping break-even against a single full-prefix rewrite.
The arithmetic was right; the rewrite it was weighed against is not one the
keepwarm prevents.

## What was ruled out, and how

- **`CLAUDE_CODE_ENTRYPOINT`** — inert. Five probes across two variables on one
  throwaway, plus a mismatched-entrypoint case on three more, all returned read
  fraction 1.00. The plugin's central documented claim was that this variable
  splits the cache lineage.
- **`--effort`** — inert, same sweep. Also: a `claude -p` session records no
  `effort` field in its transcript at all, and passing `--effort` does not change
  that, so `Resolve-ClaudeSessionContext.ps1` resolved it to `$null` for every
  headless session.
- **Roster composition** (`--ide`, MCP config, plugins, settings sources) — ruled
  out by the 18,269 constant above, and `--ide` tested directly.
- **Any other invocation mode** — `-p/--print` *is* the non-interactive mode.
  `--remote-control` starts an interactive session; `--no-session-persistence`
  cannot resume. There is no headless invocation that renders the interactive
  prefix.

The instrument was validated rather than assumed: the first `--resume` after a
`claude -p` create reliably reported a real `cache_miss_reason=system_changed` with
a multi-thousand-token write (read 18,269 / write 14,409 on one run). The null
results above are therefore real nulls, not a dead probe.

## What was true and is worth keeping

- The divergence *detection* was sound. On the one real overnight run
  (`2f3996cb`, 2026-08-08), the scheduled ping read 0 and wrote 58,782, classified
  the result a MISS, unregistered its own scheduled task and logged why. The
  branch did the right thing for a reason nobody had intended.
- A ping does not damage the session it targets. Immediately after each probe on
  `2f3996cb`, the interactive turns read 55,280 and 60,359 warm. The two lineages
  coexist.
- Prompt-cache economics for *this session's own* turns are unaffected by any of
  this; see the `effort-switch-cache-lineages` notes, which concern a different
  mechanism and still hold.

## Two incidental findings

**Transcript files are not uniformly JSONL.** Session `2f3996cb`'s transcript is
pretty-printed JSON objects concatenated, 2,855 lines for 97 objects. Any tool
parsing `~/.claude/projects/**/*.jsonl` line-by-line — as
`Resolve-ClaudeSessionContext.ps1` did with `Get-Content -Tail 200` — yields zero
records against that shape and cannot distinguish it from an empty result.

**A `ValidateSet`-typed PowerShell parameter validates on every assignment, not
only at binding.** `if (-not $Effort) { $Effort = $context.Effort }` throws when the
right-hand side is `$null`, before any later code runs. Guard the assignment:
`if (-not $Effort -and $context.Effort)`.

## Where the code and evidence went

The plugin directory was removed from `main` and its entry removed from
`.claude-plugin/marketplace.json`. The code remains in git history: **`d110749` is
the last commit containing it**, so `git show d110749:plugins/keep-session-warm/skills/keep-session-warm/SKILL.md`
or `git checkout d110749 -- plugins/keep-session-warm` recovers any of it.

Four live test scripts were written against the tool before it was withdrawn
(`New-ThrowawaySession.ps1`, `Test-LiveLineageVerdicts.ps1`, `Test-LiveStartGate.ps1`,
`Test-LiveMissAbort.ps1`), passing 6, 18 and 9 assertions respectively. They are the
source of the measurements above and are preserved in history alongside the plugin.

Total spend across all live testing: approximately $0.56.

## If you are still running one

A commit to this repository does not uninstall anything. Locally you would also
want to remove `"keep-session-warm@cgettings-skills"` from `enabledPlugins` in
`~/.claude/settings.json`, delete
`~/.claude/plugins/cache/cgettings-skills/keep-session-warm`, and check for a live
scheduled task with `Get-ScheduledTask -TaskName 'ClaudeKeepwarm-*'`.
