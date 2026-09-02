# claude-skills

Rules that fire while working in this repo. General working rules live in `~/.claude/CLAUDE.md`;
incidents and methods live in this project's memory store.

- **A plugin's version lives in two files, and nothing keeps them equal.**
  `.claude-plugin/plugin.json` is what the plugin system reads on install and update; the skill's
  frontmatter `version:` is the second copy. They have drifted apart in at least four episodes
  since 2026-07-29, in both directions — `keep-session-warm` sat at manifest 1.1.0 against skill
  1.0.0 for five commits, so "remember to bump the manifest too" catches only half the cases. Run
  `sh scripts/check-versions.sh` before committing anything that touches a version. It exits
  non-zero on a mismatch, which is its informative answer, so chain it with `;` rather than `&&`.

- **Seven JSON files here reformat if you parse and re-serialize them.** The five
  `.claude-plugin/plugin.json` manifests (12 lines becomes 17–18, from single-line `keywords`) and
  both `trigger_eval.json` files (25 becomes 90, from one object per line). Edit those by targeted
  string replacement, asserting the match count first. `.claude-plugin/marketplace.json` and the
  four `evals/evals.json` are plain `indent=2` and safe to round-trip `[verified 2026-08-21:
  round-tripped every tracked .json with indent=2 and compared bytes]`. Method and measurements:
  the `json-roundtrip-reformats-hand-formatted-files` memory.

- **Scripted edits of any file here need `newline=''` on both read and write.** Python's text mode
  translates `\n` to `\r\n` on Windows, and `core.autocrlf=input` means git normalises it away on
  commit — so the diff looks clean while the working tree carries CR bytes. Check with
  `tr -dc '\r' < file | wc -c`, never with the diff. See the
  `scripted-edits-mangle-files-on-windows` memory.

- **A skill's version bump is judged on what changed in the instructions, not on whether anything
  broke.** There is no caller to break, so **major** here means the change replaces a decision
  procedure or loosens a prohibition — someone following the old text now gets a *wrong* answer
  rather than an incomplete one. `distill-lessons` 1.4.0 → 2.0.0 (three flat routing destinations
  became two axes) and `refile-rules` 1.1.0 → 2.0.0 (§5's byte-for-byte default gained a fourth
  permitted edit) were both proposed as minor bumps and corrected on review `[2026-09-01]`.
