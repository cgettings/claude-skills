# retrieval-bench

Benchmark harness for the retrieval service. Cases live in `cases/`, one YAML file each.

## Conventions

- A case is added, never edited — a changed case makes every historical run incomparable.
- Run with `bench run --all`; a single case with `bench run --case <name>`.
- The suite is 25 cases and takes about four minutes end to end, so run it before pushing.

## Notes

Longer write-ups live in `docs/`. See `docs/benchmarks.md` for the suite's history and what the
pass-rate numbers do and don't mean.
