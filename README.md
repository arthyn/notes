# %notes — Urbit Notebook Agent

A prototype Urbit-native writing app. Shared notebooks with plain Markdown, folder organization, and a built-in editor UI served directly from the agent.

**Spec:** [SPEC.md](SPEC.md)

## What it does

- **Notebook CRUD** — create, rename, delete notebooks with membership and roles (owner/editor/viewer)
- **Public / private visibility** — notebooks default to private; a private notebook rejects `%join` requests from non-members
- **Shared notebooks across ships** — host/subscriber model with per-notebook join/leave; each notebook is addressed by a flag (`~host-ship/name`)
- **Folder hierarchy** — nested folders within notebooks; tap a folder to navigate in
- **Markdown notes** — plain Markdown body, revision-tracked, with auto-save + conflict detection
- **Conflict banner** — when a remote edit lands while you're dirty (or the save is rejected), a banner offers "Keep mine" / "Use remote"
- **Publish to web** — publish a rendered note at `/notes/pub/~host/name/<id>` (per-notebook scoped URL); toggle on/off per note
- **Batch import** — flat file import or recursive folder-tree import (uses `webkitdirectory`)
- **Notebook export** — dump a notebook to a `.zip` of `.md` files preserving the folder tree; no external deps (inline zip encoder)
- **Markdown preview** — inline parser with headings, bold/italic, code blocks, lists, tables, links, images
- **Routable UI** — `/notes/nb/<host>/<name>[/f/<fid>][/n/<nid>]` — browser back/forward, refresh, and deep links all work
- **Resizable + collapsible columns** — 3px drag handles with persisted widths; sidebar collapses via a toggle button
- **Mobile-friendly** — three-panel slide navigation, larger tap targets, contextual bottom footer per screen, hamburger for sidebar actions
- **HTTP / REST API** — full surface at `/notes/~/v1` with request-id correlated responses; per-ship `X-Api-Key` lets bots and MCP servers act on behalf of the host. OpenAPI 3.1 spec served at [`/notes/openapi.json`](docs/openapi.yaml)
- **SSE subscriptions** — real-time event stream for UI sync; per-request streams for awaiting v1 action results ([docs/asyncapi.yaml](docs/asyncapi.yaml))
- **Desktop sync companion** — Tauri macOS menubar app (`app/src-tauri`) mirrors notes to a folder of `.md` files (builds via `.github/workflows/desktop-app.yml`)
- **Self-hosted UI** — HTML served directly from the agent at `/notes`

## Status

This is an **alpha prototype** — the backend + UI loop works end-to-end on Urbit, multi-ship sharing works, but expect bugs and possible data loss. Keep backups of anything irreplaceable.

The roadmap in [SPEC.md](SPEC.md#editor--ui-roadmap) tracks planned polish and features (wiki-links/backlinks, search, quick switcher, editor font controls, zen mode, light mode, Landscape theme integration, folder rename/delete, formatting shortcuts).

## Install

Requires a running Urbit ship on kelvin 409/410.

### From source

This repo only tracks files unique to `%notes`. The `%base` helpers we import (`default-agent`, `dbug`, `verb`, plus standard mars) and the docket types are vendored from upstream via [peru](https://github.com/buildinspace/peru) and are pinned in `peru.yaml`. After cloning, fetch them with:

```sh
./scripts/sync-deps.sh
```

This requires `peru` on your PATH (`pip install peru` or `brew install peru`). The script drops the pinned files into `desk/lib`, `desk/mar`, and `desk/sur`; they are gitignored so they never end up in a commit.

### Install onto a ship

```
|merge %notes our %base
```

Rsync the desk contents into your ship's mounted `%notes` desk, then:

```
|commit %notes
|install our %notes
```

The UI will be available at `http://localhost:8080/notes` (adjust port to your ship's eyre binding).

## API

The v1 HTTP API is the canonical surface — every write returns a typed response correlated by `request-id`, and reads cover the same shapes as the legacy scries. Specs live at [docs/openapi.yaml](docs/openapi.yaml) (and a generated `docs/openapi.json` served live at `/notes/openapi.json`) and [docs/asyncapi.yaml](docs/asyncapi.yaml) for the SSE streams. The legacy `%notes-action` poke and `/x/v0/*` scries documented below still work for in-Urbit callers.

### v1 HTTP API (`/notes/~/v1`)

Auth: an eyre session cookie **or** the `X-Api-Key` header. Each ship mints a key on first install — fetch it from `/x/v0/api-key.json` (cookie-gated, local only), or call `regenerate-api-key` / `clear-api-key` via the v1 POST.

**Submit any action** — JSON envelope, `requestId` optional (server mints one if absent or malformed):

```
POST /notes/~/v1
{"requestId": "0v1.foo...", "action": {"create-notebook": "My Notebook"}}
```

The connection stays open until the action terminates; the body is the typed response (`%ok` / `%notebook` / `%api-key` / `%error` / `%pending` on timeout). If you'd rather poll, `GET /notes/~/v1/request/<uv>` returns the current state of a known request.

**REST writes** — convenience endpoints for cheap models / hand-rolled clients:

```
POST   /notes/~/v1/notebooks                              {"title": "..."}
POST   /notes/~/v1/notebooks/~host/<name>/notes           {"folder": N, "title": "...", "body": "..."}
POST   /notes/~/v1/notebooks/~host/<name>/folders         {"parent": N|null, "name": "..."}
PUT    /notes/~/v1/notebooks/~host/<name>/notes/<id>      {"body": "...", "expectedRevision": N}
DELETE /notes/~/v1/notebooks/~host/<name>/notes/<id>
```

**GET reads** — JSON, same shapes as the scries (but our.bowl identity, so a bot with the key sees what the owner sees):

```
GET /notes/~/v1/notebooks
GET /notes/~/v1/notebooks/~host/<name>
GET /notes/~/v1/notebooks/~host/<name>/folders
GET /notes/~/v1/notebooks/~host/<name>/folders/<id>
GET /notes/~/v1/notebooks/~host/<name>/notes
GET /notes/~/v1/notebooks/~host/<name>/notes/<id>
GET /notes/~/v1/notebooks/~host/<name>/notes/<id>/history
GET /notes/~/v1/notebooks/~host/<name>/members
GET /notes/~/v1/invites
```

### Pokes (via eyre channel)

Mark: `notes-action` (JSON). Optional `_flag` field on any action routes it to a specific notebook (prevents id collisions across ships).

Notebook-level:
```json
{"create-notebook": "My Notebook"}
{"rename-notebook": {"notebookId": 1, "title": "New"}}
{"delete-notebook": {"notebookId": 1}}
{"set-visibility": {"notebookId": 1, "visibility": "public"}}
{"join": {"notebookId": 1}}
{"leave": {"notebookId": 1}}
{"join-remote": {"ship": "~sampel", "name": "book"}}
{"leave-remote": {"ship": "~sampel", "name": "book"}}
```

Folder:
```json
{"create-folder": {"notebookId": 1, "parentFolderId": null, "name": "Chapter 1"}}
{"rename-folder": {"notebookId": 1, "folderId": 2, "name": "New"}}
{"move-folder": {"notebookId": 1, "folderId": 2, "newParentFolderId": 5}}
{"delete-folder": {"notebookId": 1, "folderId": 2, "recursive": true}}
```

Note:
```json
{"create-note": {"notebookId": 1, "folderId": 2, "title": "Intro", "bodyMd": "# Hello"}}
{"update-note": {"notebookId": 1, "noteId": 3, "bodyMd": "# Updated", "expectedRevision": 0}}
{"rename-note": {"notebookId": 1, "noteId": 3, "title": "New Title"}}
{"move-note": {"noteId": 3, "notebookId": 1, "folderId": 4}}
{"delete-note": {"noteId": 3, "notebookId": 1}}
{"batch-import": {"notebookId": 1, "folderId": 2, "notes": [{"title": "Note", "bodyMd": "..."}]}}
{"batch-import-tree": {"notebookId": 1, "parentFolderId": 2, "tree": [...]}}
```

Publishing (host-only, not forwarded to remote hosts):
```json
{"publish-note": {"notebookId": 1, "noteId": 3, "html": "<article>...</article>"}}
{"unpublish-note": {"notebookId": 1, "noteId": 3}}
```

API key (local-only — cookie-authenticated callers can rotate or clear):
```json
{"regenerate-api-key": null}
{"clear-api-key": null}
```

### Scries (via `/~/scry/notes/`)

```
/v0/notebooks.json                    — all notebooks (includes visibility)
/v0/notebook/<ship>/<name>.json       — single notebook
/v0/folders/<ship>/<name>.json        — folders in notebook
/v0/folder/<ship>/<name>/<id>.json    — single folder
/v0/notes/<ship>/<name>.json          — notes in notebook
/v0/note/<ship>/<name>/<id>.json      — single note
/v0/note-history/<ship>/<name>/<id>.json  — revision archive for a note
/v0/members/<ship>/<name>.json        — members of notebook
/v0/invites.json                      — pending invites we've received
/v0/published.json                    — list of {host, flagName, noteId}
/v0/api-key.json                      — our X-Api-Key (cookie-gated, local only)
```

### Subscriptions

Subscribe to `/v0/notes/<ship>/<name>/stream` for real-time UI updates:
- `notebook-created`, `notebook-renamed`, `notebook-deleted`, `notebook-visibility-changed`
- `folder-created`, `folder-renamed`, `folder-moved`, `folder-deleted`
- `note-created`, `note-updated`, `note-renamed`, `note-moved`, `note-deleted`
- `member-joined`, `member-left`

`/v0/inbox/stream` carries top-level events (invite received/removed, notebooks-changed). Remote subscribers watch `/v0/notes/<ship>/<name>/updates` for replication.

For the v1 HTTP API, each in-flight action has its own SSE path `/v1/request/<uv>` that receives one terminal `notes-response-1` fact when the action finalizes. See [docs/asyncapi.yaml](docs/asyncapi.yaml) for the full stream contract.

### Published notes (HTTP)

Published notes are served as standalone HTML at:

```
/notes/pub/~host-ship/<name>/<noteId>
```

## Desk Structure

```
app/notes.hoon                — Gall agent (eyre binding, v1 HTTP handler, SSE, request-id lifecycle, state migrations)
app/notes-ui/index.html       — source HTML for the UI (working copy — edit here)
sur/notes.hoon                — types: notebook/folder/note, ACUR shapes, v1 request/response, state-N for migrations
lib/notes-json.hoon           — JSON encoding/decoding for all types
lib/notes-ui.hoon             — generated cord of index.html (what the agent actually serves)
lib/notes-openapi.hoon        — generated cord of the OpenAPI spec (served at /notes/openapi.json)
mar/notes/action.hoon         — legacy client action mark (still wired)
mar/notes/action-1.hoon       — v1 client action mark (request-id wrapped)
mar/notes/command.hoon        — legacy cross-ship command mark
mar/notes/command-1.hoon      — v1 cross-ship command mark
mar/notes/response.hoon       — legacy response mark
mar/notes/response-1.hoon     — v1 response mark (terminal body for a request-id)
mar/notes/response-update-1.hoon — v1 update mark (per-request facts)
mar/notes/{notebooks,notebook,folders,folder,notes,note,note-history,members,invites,published}.hoon
                              — typed peek marks (each has noun + json grow arms)
docs/openapi.yaml             — OpenAPI 3.1 spec for /notes/~/v1
docs/asyncapi.yaml            — AsyncAPI 3.0 spec for the SSE streams
scripts/build-notes-openapi.sh — regenerate lib/notes-openapi.hoon from docs/openapi.yaml
scripts/build-notes-ui.sh     — regenerate lib/notes-ui.hoon from app/notes-ui/index.html
desk.bill / desk.docket-0 / sys.kelvin
```

See [AGENTS.md](AGENTS.md) for the development workflow (editing the UI, the `++dummy` recompile trick, regenerating the OpenAPI lib, syncing to a moon).

## License

MIT
