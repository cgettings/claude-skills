# orders-api

Order intake and fulfilment. Go 1.22, Postgres, everything runs in compose.

## Running locally

```
docker compose up
```

The API binds `localhost:8080` and Postgres `localhost:5432`. If either port is already taken
compose fails with a bind error rather than picking another port, which is deliberate — a
service on an unexpected port is worse than one that didn't start.

First run seeds the database from `db/seed.sql`. It takes about a minute and only happens when
the volume is empty, so if you want it again you have to `docker compose down -v` first.

## Tests

`go test ./...` against the compose Postgres. There is no in-memory fake; the queries use enough
Postgres-specific syntax that a fake would pass while production failed.

## Layout

- `cmd/` — entrypoints
- `internal/` — everything else, no external imports
- `db/` — migrations and seed data
