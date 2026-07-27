# checkout-service

Payment capture and refunds. Deploys are scripted; nothing is done by hand.

## Conventions

- Amounts in minor units, currency always explicit alongside.
- Refunds are idempotent on the provider reference; never generate a new one to retry.
- `config/deploy.yaml` is environment-specific and is not committed for production.

## Deploying

`scripts/deploy.sh` builds and ships the current commit.
