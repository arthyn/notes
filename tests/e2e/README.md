# Playwright E2E tests

Browser-driven end-to-end tests for `%notes`. Points at real ships you
specify via env vars — no mocks, no embedded harness. Run locally
against any ship that has `%notes` installed.

## Setup (one-time)

```sh
npm install
npx playwright install chromium
cp tests/e2e/.env.example tests/e2e/.env
```

Edit `tests/e2e/.env` and fill in:

- `HOST_URL` — host ship's web URL (e.g. `http://localhost:8082`)
- `HOST_PATP` — the @p (e.g. `~sidwyn-nimnev-nocsyx-lassul`)
- `HOST_CODE` — login code from the ship's dojo: type `+code` and paste
- `SUB_URL` / `SUB_PATP` / `SUB_CODE` — same for the subscriber ship.
  Leave `SUB_CODE` blank to skip cross-ship specs.

## Run

```sh
# All specs (skips @cross-ship if SUB_CODE missing)
npm run test:e2e

# Just cross-ship specs
npm run test:e2e:cross-ship

# Headed (watch the browser drive the UI)
npm run test:e2e:headed

# Interactive UI mode
npm run test:e2e:ui
```

A run does:

1. `globalSetup` POSTs `+code` to each ship's `/~/login`, saves the
   `urbauth-<patp>` cookie under `tests/e2e/.auth/` for the test
   contexts to reuse.
2. Each spec opens a fresh page at `/notes/`, dismisses the alpha
   disclaimer, and runs through the helpers in `fixtures/notes.ts`.
3. Cross-ship specs additionally open a second browser context for the
   subscriber via `openSubscriberContext(browser)`.

Specs run **sequentially** (`workers: 1`) — they mutate ship state and
shouldn't race each other.

## What's here

| Spec | Coverage |
|---|---|
| `notebook-crud.spec.ts` | create / rename / delete; visibility toggle (regression for sidebar lock-icon optimistic re-render) |
| `folder-and-note-crud.spec.ts` | folder + note creation, save, persistence on reload |
| `notebook-id-collision.spec.ts` | @cross-ship — joining two notebooks with the same numeric id from different hosts |
| `cross-ship-invite.spec.ts` | @cross-ship — invite flow live (regression for the `%notify-invite` bug) |
| `cross-ship-edit.spec.ts` | @cross-ship — sub's edits propagate to host without refresh |

## Selectors

These tests use existing IDs and class names (`#editor`, `.nb-item`,
etc) since the UI doesn't have `data-testid` attributes yet. As specs
grow, add `data-testid` on critical interaction targets so refactors
don't quietly break the suite.

## Cleanup

Specs delete the notebooks they create. If a run crashes mid-test,
manually delete leftover `e2e-*` notebooks from the ship UI to keep
state tidy.
