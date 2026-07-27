# Broker migration

Moving billing, notifications, and search off the legacy queue onto the shared RabbitMQ broker.

## Why

The legacy queue has one consumer group per service and no dead-letter handling. A poison
message stops that service's consumer and nothing else notices. We have found this three times,
each time from a customer report rather than an alert.

## Plan

1. Stand up the shared broker with per-service vhosts. **Done.**
2. Move `billing`. Lowest volume, and the only one where a replay is harmless. **Done.**
3. Move `notifications`. **Done.**
4. Move `search`. Highest volume; watch consumer lag for a full business day after. **Done.**
5. Retire the legacy queue and delete its config. **Done.**

## Order

Billing first because a duplicated billing event is caught by the idempotency key, so a mistake
there is recoverable. Search last because it is the only one where consumer lag is visible to
users within minutes.

## What we said we'd watch

Consumer lag per service for one business day after each move. Dead-letter queue depth, which
should be zero and is the whole reason for the migration.
