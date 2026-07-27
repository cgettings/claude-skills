# Fixtures

`evals.json`'s `files` field is inert — `skill-creator`'s `run_eval.py` never reads it. What the
runner does instead is spawn the executor with `cwd` set to the nearest ancestor directory
containing `.claude/`. So a fixture for this skill can't be a list of input files: the skill
reads `git log`, branch state, `CLAUDE.md`, and a memory tier, none of which are expressible as
an attachment. A fixture has to be a project, and the eval has to run inside it.

```
./build.sh --case reconcile-1 --out /tmp/fix
cd /tmp/fix        # run the eval from here
```

The emitted directory is disposable. `--out` is wiped before each build.

## Why a generator rather than checked-in directories

A fixture's git history is load-bearing — case 1 exists to test whether the agent verifies a
merge from the branch instead of believing the user — and a nested `.git` can't be committed to
this repo without submodule contortions. So what's checked in is the plain text under
`<case>/tree/` plus the history recipe in `build.sh`.

Commit dates are pinned so builds are reproducible and any "verified &lt;date&gt;" style record
lines up with real history.

Source trees keep the memory directory at `claude/`, not `.claude/`, because this repo's
`.gitignore` excludes `.claude/`. `build.sh` renames it.

## The cases

| Case | What the fixture has to make true |
|---|---|
| `reconcile-1` | `pipeline-refactor` really is merged into `main`; a memory file still calls it unmerged and warns people off `src/pipeline.py` |
| `reconcile-2` | Three present-tense claims of "25 cases" and two dated ones, plus 40 real case files (22/12/6) so both the total and the per-type split are countable rather than taken from the prompt |
| `reconcile-4` | Docker documented in README and setup notes; the compose command is shared, but each document holds one claim the other lacks |
| `reconcile-5` | A decoy that fires: the reshard changed staging 12→16, so two records are genuinely stale and a scoped sweep finds a real correction — while the rebuild's status stays unrecorded |

`reconcile-3` needs no fixture — it's a trigger-discrimination case and lives in
`../trigger_eval.json`.

## Why case 5 has a decoy

An empty store lets the agent stop for an honest reason: it looked, found nothing, said so. That
is not much of a test. The reshard makes the sweep productive — there is a real number to fix,
in two places including the index hook — so the agent can finish with a genuine correction and a
thorough-looking report, and still lose the only perishable thing in the session.

`analyzer-rollout-status` is deliberately the same shape as the entry that should be written
(staging done, prod pending on something). The form is inferable from a neighbour without any
document spelling out the schema, which is why `CLAUDE.md` describes where status lives but not
what a status entry contains.

## Running the control

A fixture that no one fails is a dead instrument. The evidence a fixture works is the
`without_skill` run failing: missing the stale line in case 1, deleting the dated sentence in
case 2, inventing a per-type split in case 2, and in case 5 stopping after the shard fix. Read
that column before reading anything else.
