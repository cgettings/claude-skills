# Setup notes

Scratch notes from getting this running on a new machine. Not maintained as carefully as the
README — if the two disagree, check the git dates.

## Docker

```
docker compose up
```

That's the whole happy path. Two things that cost time and aren't obvious:

**After changing `go.mod` or `go.sum`, rebuild with `docker compose build --no-cache`.** The
layer cache keys on the `COPY . .` step, which happens after the dependency download, so a
lockfile change doesn't invalidate the layer that would have to be rebuilt. You get a container
running the old dependencies with no error anywhere — the build succeeds, the tests pass against
the wrong versions, and you find out when something fails in CI.

**Colima users need `DOCKER_HOST` exported.** Compose finds the socket through the context, but
the test helper shells out to `docker` directly and doesn't.

## Postgres

Connection string is in `.env.example`. Copy it to `.env`; compose reads it automatically.

The seed is idempotent in the sense that it won't run twice, not in the sense that it can be
re-run safely — it has no `ON CONFLICT` clauses and will fail on the second attempt.
