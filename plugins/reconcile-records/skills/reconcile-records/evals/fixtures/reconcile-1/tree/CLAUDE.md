# ingest-pipeline

Nightly ingest for the partner feeds. Python 3.11, no framework.

## Layout

- `src/` — the pipeline stages. One module per stage since the refactor.
- `ops/` — cron wrappers and environment files. Not imported by anything in `src/`.

## Conventions

- Stages take and return a dataframe. No stage reads from disk except `ingest`.
- Partner names are lowercased at the boundary and never re-cased downstream.
- Run `pytest -q` before pushing; the nightly job has no staging environment.

## In flight

- The stage split is on a branch and not yet in main — see the memory index for status.
