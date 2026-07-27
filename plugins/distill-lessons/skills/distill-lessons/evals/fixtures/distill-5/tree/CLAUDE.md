# platform

Three services plus shared infrastructure. Each service owns its own config under `services/`.

## Conventions

- Config is YAML, one file per service, no inheritance. Duplication beats a lookup chain.
- A service names its queue in its own config; nothing derives it from the service name.
- Never edit a config for a service you don't own without telling the owner.

## Docs

- `docs/broker-migration.md` — the plan for moving off the legacy queue.
