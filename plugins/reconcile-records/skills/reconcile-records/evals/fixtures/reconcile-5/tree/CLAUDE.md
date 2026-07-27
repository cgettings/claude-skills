# search-service

Elasticsearch behind a thin Go API. Index rebuilds are the operationally interesting part.

## Conventions

- Shard count, batch size, and target environment all come from `ops/reindex.env`. Never
  hardcode them.
- Mapping changes require a full rebuild; synonym changes take effect at the next rebuild.
- Staging and prod deliberately differ in shard count — see the memory index before "fixing" it.

## Status

Ongoing workstreams are tracked in `.claude/memory/`, one file each, indexed in `MEMORY.md`.
