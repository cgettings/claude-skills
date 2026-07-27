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
| `distill-1` | TZ pin visible in the workflow (so it routes to "nowhere"); `--runInBand` only in a commit message and no document; node 18→22 in the matrix. **Transcript half not yet built — see below.** |
| `distill-3` | A `CLAUDE.md` with a Testing section for the requested line to join |
| `distill-5` | A finished three-service migration in the history and a plan doc with every stage ticked |
| `distill-6` | A `scripts/deploy.sh` whose relative paths make the repo-root requirement genuinely re-derivable |

`distill-2` and `distill-4` need no fixture — they're trigger-discrimination cases and live in
`../trigger_eval.json`.

## distill-1 is half-built

The case tests two things: reconstructing candidates from artifacts, and recovering the user's
rejected suggestion from the session transcript. Only the first half exists here.

The second half needs a `~/.claude/projects/<slug>/*.jsonl` containing an assistant suggestion
to loosen an assertion and the user rejecting it. That is not built, and a thin one would be
worse than none — a transcript the agent can succeed without really reading makes the case look
passed while testing nothing, and unlike the other cases there's no baseline signal that would
expose it.

Until it exists, grade case 1 on the artifact expectations only, and treat the two transcript
expectations as not covered.

## Running the control

A fixture that no one fails is a dead instrument. The evidence a fixture works is the
`without_skill` run failing. Read that column before reading anything else.
