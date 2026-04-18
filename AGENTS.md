# Notes Agent Development Guide

## Overview

`%notes` is an Urbit Gall agent for collaborative markdown notebooks. The frontend is a single-file HTML/CSS/JS app served inline from Hoon. See `SPEC.md` for the full product spec and roadmap, and `README.md` for the user-facing overview.

## Desk Structure

```
desk/
  app/notes.hoon           # Gall agent (state, pokes, peeks, watches, HTTP handler)
  app/notes-ui/index.html  # Working copy of the UI (source of truth for edits)
  sur/notes.hoon           # Type definitions (state-0..4, actions, commands, updates, visibility)
  lib/notes-json.hoon      # JSON encoding/decoding for all types
  lib/notes-ui.hoon        # Generated file — the UI served to the browser
  mar/notes/action.hoon    # Client action mark
  mar/notes/command.hoon   # Server command mark (action + actor)
  mar/notes/response.hoon  # Response mark (for watch paths)
  mar/notes/update.hoon    # Durable update mark
  desk.bill                # Agent manifest (just %notes)
  desk.docket-0            # App metadata (title, color, site path, version)
  sys.kelvin               # Kelvin version
```

There's also a companion macOS menubar app at `app/src-tauri/` (Tauri v2). See `.github/workflows/desktop-app.yml` for the release pipeline — push a tag like `app-v0.1.0` to build a universal `.dmg` and draft a GitHub Release.

## UI Workflow (Critical)

The agent imports the UI as a cord at compile time:

```hoon
/=  index  /lib/notes-ui
```

**This means `app/notes-ui/index.html` is NOT what the browser sees.** The served HTML comes from `lib/notes-ui.hoon`. These two files must stay in sync.

### Edit → Sync → Deploy workflow

1. Edit `desk/app/notes-ui/index.html` (the working copy)
2. Generate the hoon lib wrapper:
   ```sh
   { printf "^-  @t\n'''\n"; cat desk/app/notes-ui/index.html; printf "'''\n"; } > desk/lib/notes-ui.hoon
   ```
3. Bump `++dummy` in `desk/app/notes.hoon` to force a recompile (the agent won't pick up UI changes unless the hoon source changes):
   ```hoon
   ++  dummy  'describe-your-change-v1'
   ```
4. Rsync to the dev ship and commit:
   ```sh
   rsync -avL desk/ ~/bospur-davmyl-nocsyx-lassul/notes/
   ```
   **Do NOT use `--delete`** — rsync without delete to avoid wiping ship-side files.
5. Build and commit via MCP (bospur):
   ```
   mcp__bospur__build-file  desk=notes  path=/app/notes/hoon
   mcp__bospur__commit-desk  desk=notes
   ```
6. Hard-refresh the browser (Cmd+Shift+R) to see changes.

### Important: triple-quote safety

`lib/notes-ui.hoon` wraps the HTML in a Hoon triple-quoted cord (`'''`). If the HTML ever contains `'''` the build will break. Grep for it before generating.

## Dev Ship

The dev moon is `~bospur-davmyl-nocsyx-lassul`. It has a `%notes` desk mounted at `~/bospur-davmyl-nocsyx-lassul/notes/`. Use the bospur MCP tools to build, commit, poke, and scry the agent.

## Agent Architecture

### State

Current state is `state-4:notes`:

```
+$  state-4
  $:  %4
      books=(map flag [=net =notebook-state])
      next-id=@ud
      published=(map [=flag note-id=@ud] @t)
      visibilities=(map flag visibility)
  ==
```

- `books` — map of notebook flag → `[net notebook-state]`. `net` discriminates `%pub` (we host) vs `%sub` (we subscribe).
- `next-id` — single counter on this ship for all locally-created notebooks / folders / notes (remote notebooks bring foreign IDs).
- `published` — compound-keyed on `[flag note-id]` so per-notebook note-id collisions don't clobber each other.
- `visibilities` — per-notebook `%public` / `%private` (missing = private by default).

Each `notebook-state` contains `notebook`, `notebook-members`, `folders`, `notes`. Each notebook has a root folder (`name="/"`). Notes belong to folders via `folder-id`.

Migrations: `state-1 → state-2 → state-3 → state-4`. See `+load` in `app/notes.hoon`.

### API Surface

**Scry paths** (all prefixed with `/v0/`):
- `/v0/notebooks` — list all notebooks (includes visibility)
- `/v0/notebook/~ship/name` — single notebook
- `/v0/folders/~ship/name` — folders in notebook
- `/v0/notes/~ship/name` — notes in notebook
- `/v0/members/~ship/name` — members of notebook
- `/v0/published` — list of `{host, flagName, noteId}` pairs

**Poke mark**: `%notes-action` with a JSON `routed-action` envelope. An optional `_flag` field routes the action to a specific notebook (required when a notebook-id could mean different notebooks on different hosts, i.e., subscribed remote notebooks). Without `_flag` the agent falls back to `find-flag-by-nid`.

Action types exposed on the wire (see `sur/notes.hoon` for full shapes):
- Notebook: `create-notebook`, `rename-notebook`, `delete-notebook`, `set-visibility`, `join`, `leave`, `join-remote`, `leave-remote`
- Folder: `create-folder`, `rename-folder`, `move-folder`, `delete-folder`
- Note: `create-note`, `update-note` (with `expectedRevision`), `rename-note`, `move-note`, `delete-note`, `batch-import`, `batch-import-tree`
- Publish (host-only, not forwarded to remote hosts): `publish-note`, `unpublish-note`

**Watch paths**:
- `/v0/notes/~ship/name/stream` — SSE stream for the UI (snapshot + updates)
- `/v0/notes/~ship/name/updates` — subscription path other ships watch when joining as a remote subscriber

**HTTP routes** (served under `/notes`):
- `/notes/pub/~host/name/<noteId>` — serve a published note's stored HTML
- Anything else → serve the UI `index`

### Notebook flag

Notebooks are identified by a "flag" `[ship name]`. Formatted as `~host/name` in URLs and scry paths. The flag is the stable identity across ships.

### Visibility

`%private` (default) rejects `%join` / `%join-remote` from ships that aren't already in `notebook-members`. `%public` accepts any join. Only the owner can toggle via `%set-visibility`.

## Frontend Architecture

The UI is a single HTML file with inline CSS and JS. No build step, no framework.

### Routing

URL scheme: `/notes/nb/<host>/<flagName>[/f/<folderId>][/n/<noteId>]`.

- Every selection change (notebook / folder / note) pushes a new URL via `pushRoute()`.
- `popstate` (browser back/forward) calls `applyRoute()` which re-hydrates state to match the URL.
- Deep-link refresh works because the agent serves the UI for any `/notes/*` that isn't a `/notes/pub/...` URL, and `applyRoute` rehydrates from scry.
- A synchronous IIFE at the top of the script sets `data-view` on `.layout` before first paint so mobile doesn't flash the wrong slide panel on load.

### Layout (3-column desktop, slide-panel mobile)

Desktop:
- **Left sidebar**: notebooks list + add/import/desktop-sync actions + brand/version. Collapsible via a toggle button; widths persist to `localStorage`.
- **Middle column**: file-browser-style list — folders and notes interleaved. Header has back/up/label, action buttons (gear, +folder, +note) on the right.
- **Right editor**: markdown editor with preview toggle, save status, rev indicator.
- 3px drag handles between columns (`rgba(124,106,247,0.4)` on hover). Widths persisted in `localStorage`.

Mobile:
- Three-panel slide navigation via `data-view` attribute on `.layout` (`notebooks` / `notes` / `editor`).
- In-app back buttons navigate via URL so browser back/forward + refresh stay in sync.
- Sidebar actions (add notebook / import / desktop sync) collapse into a hamburger in the brand row; tap expands the existing `.sidebar-actions` cluster above the brand.
- Notebook actions (gear / +folder / +note) move to a contextual bottom footer (`.notes-panel-footer`) via a small JS reparent on resize.
- Gear menu opens upward and left-aligns with the button on mobile.

### Icons

Inline SVG sprite defined right after `<body>`. Icons are referenced via `<svg class="icon"><use href="#i-name"/></svg>`. The JS helper `icon('name')` returns the SVG markup for use in render functions.

Available: `notebook`, `folder`, `doc`, `folder-plus`, `doc-plus`, `plus`, `arrow-up`, `download`, `folder-down`, `eye`, `ellipsis`, `globe`, `gear`, `lock`, `sidebar`, `chevron-right`, `sync`, `menu`.

`.icon` has `opacity: 0.65` by default; `.icon-btn:hover .icon` bumps to `0.95`.

### Key state variables (JS)

- `activeNotebookId` / `activeNotebookFlag` — selected notebook
- `activeFolderId` — current folder (set to root folder id when notebook selected)
- `activeNoteId` — note open in editor
- `notebooks`, `folders`, `notes` — client-side caches loaded via scry
- `publishedIds` — Set of `pubKey(flag, noteId)` strings for quick lookup
- `dirty`, `savedRevision`, `saving`, `autoCreating`, `conflictActive` — editor state machine

### Rendering

- `renderNotebooks()` — sidebar notebook list (shows lock on private notebooks)
- `renderItems()` — combined folder+notes list in the middle column (date + body preview under note titles)
- `updateHeader()` — middle column header (folder/notebook name, up button, action visibility)

Navigation: `navigateToFolder(id)` / `folderUp()`.

### Editor behavior

- **Auto-save**: editor/title input triggers a 1.5s debounced `autoSave()`. Uses `expectedRevision` for conflict detection. Ctrl/Cmd+S force-saves.
- **Auto-create on type**: if the user starts typing with no note selected, `triggerAutoCreate()` pokes `create-note` and the typed content is preserved and promoted into the new note when it lands.
- **Conflict banner**: if a remote `note-updated` arrives while `dirty`, or `autoSave` fails and a re-scry shows the remote rev ahead, a banner shows above the editor with "Keep mine" (adopt remote rev + re-save) or "Use remote" (discard local, reload). `conflictActive = true` blocks auto-save until resolved.
- **Revision display**: the editor toolbar has a `rev N` label that stays in sync with `savedRevision`.

### Alpha disclaimer

First load shows a modal-locked disclaimer warning about alpha data-loss risk. Acknowledgement persists in `localStorage['alpha-disclaimer-acknowledged']`.

### Eyre Channel

The UI creates an Eyre channel for subscriptions. It subscribes to the active notebook's stream and handles snapshot/update events to keep the UI in sync. `setConnectionState("connected" | "reconnecting" | "disconnected")` updates the sidebar section label (amber for reconnecting, danger for disconnected).

### Keyboard shortcuts

- `Ctrl/Cmd+S` — force-save
- `Ctrl/Cmd+Alt+N` — new note (regular `Cmd+N` is reserved by browsers)
