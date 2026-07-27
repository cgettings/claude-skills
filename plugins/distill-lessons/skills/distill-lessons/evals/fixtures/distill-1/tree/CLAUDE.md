# ledger-api

Double-entry ledger. Node, Jest, Postgres.

## Conventions

- Money is integer minor units. Never a float, never a string, anywhere.
- Every posting is balanced at write time; there is no repair job and there will not be one.
- Migrations are append-only.

## Testing

`npm test` runs the suite against the fixture database in `test/fixtures/`.

Tests share that database rather than each building their own — building it per test file
pushed the suite past ten minutes, which is long enough that people stopped running it.
