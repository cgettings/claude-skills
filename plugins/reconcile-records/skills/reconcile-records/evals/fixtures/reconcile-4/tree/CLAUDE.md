# orders-api

Go 1.22, Postgres, compose for everything local.

## Conventions

- `internal/` imports nothing outside the module.
- Migrations are append-only and numbered; never edit one that has run anywhere.
- Tests run against real Postgres, not a fake. See the README for why.

## Docs

- `README.md` — how to run it, for someone who has just cloned it.
- `docs/setup-notes.md` — scratch notes from a first-time setup, less carefully maintained.
