# storefront

Next.js storefront. Playwright for e2e, pnpm throughout.

## Conventions

- Server components by default; `"use client"` only where an event handler needs it.
- Prices come from the API already formatted. Do not format them again client-side.
- No `any` in `src/`; the lint rule is an error, not a warning.

## Testing

- `pnpm test` — unit, vitest.
- `pnpm e2e` — Playwright against a dev server it starts itself.

## Docs

Longer notes in `docs/`. Anything that changes what you *do* belongs here instead.
