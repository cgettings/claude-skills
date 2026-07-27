# Fixtures

`evals.json`'s `files` field is inert — `skill-creator`'s `run_eval.py` never reads it. What the
runner does instead is spawn the executor with `cwd` set to the nearest ancestor directory
containing `.claude/`. So a fixture for this skill can't be a list of input files: the skill
reads `git log`, plan docs, `CLAUDE.md`, and session transcripts, none of which are expressible
as an attachment. A fixture has to be a project, and the eval has to run inside it.

```
./build.sh --case distill-5 --out /tmp/fix
cd /tmp/fix        # run the eval from here
```

The emitted directory is disposable. `--out` is wiped before each build.

## Why a generator rather than checked-in directories

A fixture's git history is load-bearing — case 1's `--runInBand` lesson exists only in a commit
message and in no document, which is the point — and a nested `.git` can't be committed to this
repo without submodule contortions. So what's checked in is the plain text under `<case>/tree/`
plus the history recipe in `build.sh`.

Source trees keep the memory directory at `claude/`, not `.claude/`, because this repo's
`.gitignore` excludes `.claude/`. `build.sh` renames it.

## The cases

| Case | What the fixture has to make true |
|---|---|
| `distill-1` | TZ pin visible in the workflow (so it routes to "nowhere"); `--runInBand` only in a commit message and no document; node 18→22 in the matrix; plus a session transcript carrying the rejected suggestion |
| `distill-3` | A `CLAUDE.md` with a Testing section for the requested line to join |
| `distill-5` | A finished three-service migration in the history and a plan doc with every stage ticked |
| `distill-6` | A `scripts/deploy.sh` whose relative paths make the repo-root requirement genuinely re-derivable |

`distill-2` and `distill-4` need no fixture — they're trigger-discrimination cases and live in
`../trigger_eval.json`.

## distill-1's transcript

The skill looks for transcripts at `~/.claude/projects/<slug>/*.jsonl`, where the slug is the
project path with its separators flattened and the drive letter lowercased —
`C:\Users\Chris\x` becomes `c--Users-Chris-x`. That is outside the fixture directory, so
`build.sh` writes `fixture-transcript.jsonl` into the fixture and prints the install command
rather than writing into your real `~/.claude` by default. Pass `--install-transcript` to have
it do the copy.

Install it deliberately and remove it afterwards. That directory holds your actual session
history, and an installed fixture transcript is indistinguishable from a real one.

The transcript is a full session, not a stub: thirteen turns covering the flaky suite, the
parallel-worker cause, the `--runInBand` fix, and the timezone pin. It mentions `--runInBand`
and `TZ: UTC` even though git also records them, because a real transcript of that session
would — the point is not to force the agent through the transcript for those. What lives *only*
here is the assistant offering to loosen the balance assertion to a one-unit tolerance and the
user refusing, on the grounds that exact balancing is the product and loosening the assertion
would ship the bug and destroy the detector in the same move. No artifact records that, and
recovering the principle behind it is what case 1's transcript expectations test.

## Running the control

A fixture that no one fails is a dead instrument. The evidence a fixture works is the
`without_skill` run failing. Read that column before reading anything else.
