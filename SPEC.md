# Urbit Notebook App Spec (Obsidian + iA Writer style)

## Goal
Build a Urbit-native writing app with:
- plain Markdown compatibility
- shared notebooks (like Tlon channels)
- folder-first organization (tags later)
- clean, focused writing UX

Working name: **%scribe** (placeholder)

---

## Product Principles
1. **Markdown-first, no lock-in**
   - Note body is stored as raw Markdown text.
   - App metadata stays outside the Markdown body by default.
2. **Collaboration is core**
   - Notebooks are shared containers with explicit membership and roles.
3. **Simple hierarchy first**
   - Folders + notes first; tags deferred to v2.
4. **Writer UX matters**
   - Fast editor, minimal chrome, keyboard-driven where possible.

---

## v1 Scope

### Included
- Notebook creation + membership + roles
- Folder CRUD within a notebook
- Note CRUD in folders
- Plain Markdown editor + preview
- Realtime update subscriptions for collaborative edits/state refresh
- Wiki-links (`[[Note Name]]`) and standard links (`[text](path.md)`)
- Backlinks index (derived)
- Import/export of Markdown folder trees

### Deferred (v2+)
- Tags and tag views
- Graph visualization
- Rich plugin system
- Advanced conflict-free co-editing (CRDT)
- Full mobile-native UX parity

---

## User Model

### Actors
- **Owner**: full control, manage roles, delete notebook
- **Editor**: create/edit/move/delete folders and notes
- **Viewer**: read-only

### Core Objects
- **Notebook**: shared space (channel-like)
- **Folder**: hierarchical path container
- **Note**: Markdown document

---

## Data Model (Gall state)

> Hoon types intentionally omitted here; this is product-level schema.

### notebook
- `id` (stable ID)
- `title`
- `created_at`, `updated_at`
- `owner` (ship)
- `members` (map ship -> role)
- `root_folder_id`

### folder
- `id`
- `notebook_id`
- `name`
- `parent_folder_id` (null for root)
- `path` (normalized, derived/cacheable)
- `created_at`, `updated_at`
- `created_by`

### note
- `id`
- `notebook_id`
- `folder_id`
- `title`
- `slug` (optional, for path stability)
- `body_md` (raw Markdown)
- `created_at`, `updated_at`
- `created_by`, `updated_by`
- `revision` (monotonic version)

### derived indexes
- `path -> folder_id`
- `path -> note_id`
- `outbound_links[note_id] -> set(note_id|unresolved-link)`
- `backlinks[note_id] -> set(note_id)`
- optional search index cache

---

## Markdown Compatibility Contract

1. **Body fidelity**
   - Store and return note content exactly as Markdown text.
2. **Link handling**
   - Parse and preserve both `[[Wiki Links]]` and Markdown links.
   - Do not rewrite links unless user performs move/rename action.
3. **No required frontmatter**
   - Keep metadata in Gall state.
   - Optional frontmatter export flag can be added later.
4. **Import/export parity**
   - Export as plain `.md` tree that Obsidian can open directly.

---

## Permissions & Auth

- Every mutating action checks sender role against notebook ACL.
- View actions (peek/watch) require membership.
- Owner can grant/revoke editor/viewer roles.
- Server-side validation for all paths and IDs.

---

## API Contract (agent surface)

## Pokes (mutations)
- `%create-notebook [title]`
- `%rename-notebook [notebook-id title]`
- `%invite-member [notebook-id ship role]`
- `%remove-member [notebook-id ship]`
- `%set-role [notebook-id ship role]`

- `%create-folder [notebook-id parent-folder-id name]`
- `%rename-folder [notebook-id folder-id name]`
- `%move-folder [notebook-id folder-id new-parent-folder-id]`
- `%delete-folder [notebook-id folder-id recursive=?]`

- `%create-note [notebook-id folder-id title body-md]`
- `%update-note [notebook-id note-id body-md expected-revision]`
- `%rename-note [notebook-id note-id title]`
- `%move-note [notebook-id note-id folder-id]`
- `%delete-note [notebook-id note-id]`

- `%reindex-links [notebook-id note-id?]`
- `%import-markdown-tree [notebook-id tarball-or-structured-payload]`

## Peeks (queries)
- `/notebooks`
- `/notebook/<id>/tree`
- `/notebook/<id>/folder/<id>`
- `/notebook/<id>/note/<id>`
- `/notebook/<id>/note/<id>/backlinks`
- `/notebook/<id>/search?q=<term>`

## Watches (subscriptions)
- `/notebook/<id>/events` (high-level domain events)
- `/notebook/<id>/tree` (structure updates)
- `/notebook/<id>/note/<id>` (note updates)

---

## Event Model

Emit typed events for UI sync:
- `notebook-created`
- `member-added|member-removed|role-changed`
- `folder-created|renamed|moved|deleted`
- `note-created|updated|renamed|moved|deleted`
- `links-reindexed`

Each event includes:
- `notebook_id`
- `entity_id`
- `actor`
- `timestamp`
- `revision` / `sequence`

---

## Front-end Spec (glob)

## Routes
- `/n/:notebookId`
- `/n/:notebookId/f/*folderPath`
- `/n/:notebookId/n/:noteId`

## Layout
- Left: notebook + folder tree
- Center: editor (focus mode toggle)
- Right: backlinks / outline / note info (collapsible)

## Editor behavior (v1)
- Markdown source mode + preview mode
- Autosave (debounced)
- optimistic UI with revision checks
- keyboard shortcuts:
  - create note/folder
  - quick switch note
  - toggle preview/focus

## Collaboration behavior
- subscribe to notebook + current note streams
- when remote update arrives:
  - if local clean: apply immediately
  - if local dirty: show non-destructive “remote update available” merge prompt

---

## Storage & Path Rules

- Canonical path separator: `/`
- Folder and note names normalized (trim, Unicode-safe)
- Disallow path traversal tokens (`..`, empty segments)
- On move/rename:
  - update derived path index
  - schedule backlink/link reindex

---

## Import / Export

## Export v1
- Export notebook as directory tree of `.md` files
- Preserve folder structure
- Optional manifest JSON with IDs/revisions (for round-trip integrity)

## Import v1
- Import `.md` tree into selected notebook/folder
- Create missing folders
- Notes keyed by relative path + title
- Run post-import link indexing

---

## Conflict Strategy (v1)

Not full CRDT yet. Use pragmatic revision control:
- each note update includes `expected-revision`
- if mismatch:
  - reject write with conflict payload
  - client offers merge UI (manual resolution)

This keeps behavior predictable until real-time co-editing lands.

---

## Desk Structure (proposed)

```
scribe/
  desk.bill
  desk.docket-0
  sys.kelvin
  app/
    scribe.hoon
  sur/
    scribe.hoon
  mar/
    scribe/
      action.hoon
      event.hoon
      query.hoon
  lib/
    scribe/
      path-utils.hoon
      links.hoon
      perms.hoon
      search.hoon
  gen/
    scribe/
      create-notebook.hoon
      import-tree.hoon
      export-tree.hoon
  tests/
    app/
      scribe.hoon
```

---

## MVP Milestones

## M1: Core backend
- state schema
- notebook/member ACL
- folder + note CRUD
- basic peeks

## M2: Editor UI
- folder tree
- note editor + preview
- autosave and optimistic writes

## M3: Collaboration sync
- watch paths + event feed
- remote update handling

## M4: Linking + backlinks
- parser + derived indexes
- backlinks panel

## M5: Import/export
- markdown tree import/export
- compatibility validation with Obsidian round-trip

---

## Test Plan

### Backend
- ACL tests by role
- path normalization + traversal rejection
- revision conflict behavior
- folder move/rename consistency
- backlink index correctness

### Frontend
- route-state sync
- autosave + retry
- conflict prompt behavior
- subscription reconnection handling

### Compatibility
- import from Obsidian sample vault
- export and reopen in Obsidian
- link preservation checks

---

## Open Questions

1. Should notebook membership be invite-only, or can links grant join requests?
2. Do we want per-folder permissions in v1.1, or keep notebook-wide ACL for simplicity?
3. How much metadata (if any) should be embedded on export?
4. Should unresolved wiki-links auto-create stub notes on click?

---

## Implementation Order (practical)

1. `sur` types + marks
2. Gall state + ACL + CRUD
3. basic tree/note peeks
4. event watch path
5. React shell + editor
6. link parser/backlinks index
7. import/export
8. polish + tests

---

## Non-Goals (for now)
- Obsidian plugin parity
- end-to-end encrypted notebook sharing semantics
- block-based editor
- AI writing/copilot features

Keep v1 tight: **great writing + reliable shared Markdown notebooks**.
