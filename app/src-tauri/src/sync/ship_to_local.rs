use std::collections::HashMap;
use std::path::{Path, PathBuf};

use sha2::{Digest, Sha256};
use tracing::{debug, info, warn};

use crate::urbit::client::UrbitClient;
use crate::urbit::types::{Event, Folder};

use super::path_mapper;
use super::state::{FolderSync, NoteSync, NotebookSync, SyncState};

/// Perform a full initial sync for a notebook: scry everything, write to disk.
pub async fn initial_sync(
    client: &UrbitClient,
    flag: &str,
    notebook_title: &str,
    sync_root: &Path,
    state: &mut SyncState,
) -> Result<(), SyncError> {
    info!("Initial sync for notebook {}", flag);

    info!("Scrying folders for {}", flag);
    let folders_vec = client.get_folders(flag).await?;
    info!("Got {} folders", folders_vec.len());

    info!("Scrying notes for {}", flag);
    let notes_vec = client.get_notes(flag).await?;
    info!("Got {} notes", notes_vec.len());

    let folders = path_mapper::folder_map(folders_vec);
    let notes = path_mapper::note_map(notes_vec);

    let notebook_dir = path_mapper::sanitize_filename(notebook_title);

    // Create notebook directory
    let nb_path = sync_root.join(&notebook_dir);
    std::fs::create_dir_all(&nb_path)?;

    // Build folder sync entries and create directories
    let mut folder_syncs: HashMap<u64, FolderSync> = HashMap::new();
    for (fid, folder) in &folders {
        let rel_path = path_mapper::folder_path(*fid, &folders);
        let rel_str = rel_path.to_string_lossy().to_string();

        // Create directory on disk (skip root folder which has empty path)
        if !rel_str.is_empty() {
            let abs_path = nb_path.join(&rel_path);
            std::fs::create_dir_all(&abs_path)?;
        }

        folder_syncs.insert(
            *fid,
            FolderSync {
                folder_id: *fid,
                name: folder.name.clone(),
                parent_folder_id: folder.parent_folder_id,
                local_path: rel_str,
            },
        );
    }

    // Write notes and build note sync entries
    let mut note_syncs: HashMap<u64, NoteSync> = HashMap::new();
    let mut used_paths: HashMap<String, Vec<String>> = HashMap::new(); // dir -> filenames

    for (nid, note) in &notes {
        let rel_path = path_mapper::note_path(&notebook_dir, note, &folders);
        let rel_str = rel_path.to_string_lossy().to_string();

        // Disambiguate if needed
        let dir = rel_path
            .parent()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_default();
        let filename = rel_path
            .file_name()
            .map(|f| f.to_string_lossy().to_string())
            .unwrap_or_default();

        let existing = used_paths.entry(dir.clone()).or_default();
        let final_filename = path_mapper::disambiguate(&filename, existing);
        existing.push(final_filename.clone());

        let final_rel = if dir.is_empty() {
            final_filename.clone()
        } else {
            format!("{}/{}", dir, final_filename)
        };

        // Write the markdown file
        let abs_path = sync_root.join(&final_rel);
        if let Some(parent) = abs_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&abs_path, &note.body_md)?;

        let hash = content_hash(&note.body_md);
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        note_syncs.insert(
            *nid,
            NoteSync {
                note_id: *nid,
                title: note.title.clone(),
                folder_id: note.folder_id,
                revision: note.revision,
                content_hash: hash,
                local_path: final_rel,
                last_synced_at: now,
            },
        );

        debug!("Wrote note {} -> {}", note.title, rel_str);
    }

    // Get notebook_id from first note or folder, or use 0
    let notebook_id = notes
        .values()
        .next()
        .map(|n| n.notebook_id)
        .or_else(|| folders.values().next().map(|f| f.notebook_id))
        .unwrap_or(0);

    state.notebooks.insert(
        flag.to_string(),
        NotebookSync {
            notebook_id,
            title: notebook_title.to_string(),
            local_dir: notebook_dir,
            folders: folder_syncs,
            notes: note_syncs,
        },
    );
    state.touch();
    state.save(sync_root)?;

    info!(
        "Initial sync complete for {}: {} folders, {} notes",
        flag,
        folders.len(),
        notes.len()
    );

    Ok(())
}

/// Reconcile diffs between ship state and local filesystem on startup.
/// Handles: new notes on ship, deleted notes on ship, content changes both ways.
pub async fn reconcile(
    client: &UrbitClient,
    flag: &str,
    sync_root: &Path,
    state: &mut SyncState,
) -> Result<(), SyncError> {
    let nb = match state.notebooks.get(flag) {
        Some(nb) => nb,
        None => return Ok(()),
    };
    let notebook_dir = nb.local_dir.clone();
    let notebook_id = nb.notebook_id;

    // Scry current state from ship
    let ship_folders_vec = client.get_folders(flag).await?;
    let ship_notes_vec = client.get_notes(flag).await?;

    let ship_folders = path_mapper::folder_map(ship_folders_vec);
    let ship_notes: HashMap<u64, crate::urbit::types::Note> =
        ship_notes_vec.into_iter().map(|n| (n.id, n)).collect();

    info!(
        "Reconcile {}: {} ship notes, {} local notes",
        flag,
        ship_notes.len(),
        nb.notes.len()
    );

    let mut changes = 0;

    // Collect local note IDs and paths before mutating state
    let local_note_ids: Vec<u64> = nb.notes.keys().cloned().collect();
    let local_notes_snapshot: HashMap<u64, (String, String)> = nb
        .notes
        .iter()
        .map(|(nid, ns)| (*nid, (ns.content_hash.clone(), ns.local_path.clone())))
        .collect();

    // Drop the immutable borrow of nb so we can mutate state below
    drop(nb);

    // 1. Notes on ship but not in local state → write to disk
    for (nid, ship_note) in &ship_notes {
        if !local_notes_snapshot.contains_key(nid) {
            let rel_path = path_mapper::note_path(&notebook_dir, ship_note, &ship_folders);
            let abs_path = sync_root.join(&rel_path);
            if let Some(parent) = abs_path.parent() {
                std::fs::create_dir_all(parent)?;
            }
            std::fs::write(&abs_path, &ship_note.body_md)?;

            let rel_str = rel_path.to_string_lossy().to_string();
            let hash = content_hash(&ship_note.body_md);

            if let Some(nb) = state.notebooks.get_mut(flag) {
                nb.notes.insert(
                    *nid,
                    NoteSync {
                        note_id: *nid,
                        title: ship_note.title.clone(),
                        folder_id: ship_note.folder_id,
                        revision: ship_note.revision,
                        content_hash: hash,
                        local_path: rel_str,
                        last_synced_at: now(),
                    },
                );
            }
            info!("Reconcile: new ship note → local: {}", ship_note.title);
            changes += 1;
        }
    }

    // 2. Notes in local state but no longer on ship → delete local file
    for nid in &local_note_ids {
        if !ship_notes.contains_key(nid) {
            if let Some(nb) = state.notebooks.get_mut(flag) {
                if let Some(ns) = nb.notes.remove(nid) {
                    let abs_path = sync_root.join(&ns.local_path);
                    if abs_path.exists() {
                        std::fs::remove_file(&abs_path)?;
                        info!("Reconcile: note deleted on ship → removed local: {}", ns.title);
                        changes += 1;
                    }
                }
            }
        }
    }

    // 3. Notes that exist both places → check for content changes
    let mut updates: Vec<(u64, String)> = Vec::new();

    for (nid, (stored_hash, local_path)) in &local_notes_snapshot {
        if let Some(ship_note) = ship_notes.get(nid) {
            let ship_hash = content_hash(&ship_note.body_md);
            let abs_path = sync_root.join(local_path);

            if abs_path.exists() {
                let local_content = std::fs::read_to_string(&abs_path)?;
                let local_hash = content_hash(&local_content);

                if local_hash != *stored_hash && ship_hash == *stored_hash {
                    // Local changed, ship unchanged → will be pushed by FS watcher
                    info!("Reconcile: local change detected for {}", ship_note.title);
                } else if ship_hash != *stored_hash && local_hash == *stored_hash {
                    // Ship changed, local unchanged → pull from ship
                    std::fs::write(&abs_path, &ship_note.body_md)?;
                    updates.push((*nid, ship_hash));
                    info!("Reconcile: ship change → updated local: {}", ship_note.title);
                    changes += 1;
                } else if ship_hash != *stored_hash && local_hash != *stored_hash {
                    if ship_hash == local_hash {
                        // Both changed to same content
                        updates.push((*nid, ship_hash));
                    } else {
                        // Conflict
                        let conflict = conflict_path(&abs_path);
                        std::fs::write(&conflict, &local_content)?;
                        std::fs::write(&abs_path, &ship_note.body_md)?;
                        updates.push((*nid, ship_hash));
                        warn!("Reconcile: conflict for {} — local saved as .conflict.md", ship_note.title);
                        changes += 1;
                    }
                }
            } else {
                // Local file missing — rewrite from ship
                if let Some(parent) = abs_path.parent() {
                    std::fs::create_dir_all(parent)?;
                }
                std::fs::write(&abs_path, &ship_note.body_md)?;
                updates.push((*nid, ship_hash));
                info!("Reconcile: restored missing local file: {}", ship_note.title);
                changes += 1;
            }
        }
    }

    // Apply hash/revision updates
    if let Some(nb) = state.notebooks.get_mut(flag) {
        for (nid, new_hash) in &updates {
            if let Some(ns) = nb.notes.get_mut(nid) {
                ns.content_hash = new_hash.clone();
                if let Some(ship_note) = ship_notes.get(nid) {
                    ns.revision = ship_note.revision;
                }
                ns.last_synced_at = now();
            }
        }

        // Update folder state too
        nb.folders.clear();
        for (fid, folder) in &ship_folders {
            let rel_path = path_mapper::folder_path(*fid, &ship_folders);
            let rel_str = rel_path.to_string_lossy().to_string();

            if !rel_str.is_empty() {
                let abs_path = sync_root.join(&notebook_dir).join(&rel_path);
                let _ = std::fs::create_dir_all(&abs_path);
            }

            nb.folders.insert(
                *fid,
                FolderSync {
                    folder_id: *fid,
                    name: folder.name.clone(),
                    parent_folder_id: folder.parent_folder_id,
                    local_path: rel_str,
                },
            );
        }
    }

    state.touch();
    state.save(sync_root)?;

    info!("Reconcile complete for {}: {} changes", flag, changes);
    Ok(())
}

/// Apply a live SSE event to the local filesystem.
/// Returns the set of paths that were written (for suppression).
pub fn apply_event(
    event: &Event,
    flag: &str,
    sync_root: &Path,
    state: &mut SyncState,
) -> Result<Vec<PathBuf>, SyncError> {
    let mut written_paths = Vec::new();

    let nb = match state.notebooks.get_mut(flag) {
        Some(nb) => nb,
        None => {
            warn!("Received event for unknown notebook {}", flag);
            return Ok(written_paths);
        }
    };

    match event {
        Event::NoteCreated { note, .. } => {
            let folders: HashMap<u64, Folder> = nb
                .folders
                .iter()
                .map(|(id, fs)| {
                    (
                        *id,
                        Folder {
                            id: fs.folder_id,
                            notebook_id: nb.notebook_id,
                            name: fs.name.clone(),
                            parent_folder_id: fs.parent_folder_id,
                            created_by: String::new(),
                            created_at: 0,
                            updated_at: 0,
                        },
                    )
                })
                .collect();

            let rel_path = path_mapper::note_path(&nb.local_dir, note, &folders);
            let abs_path = sync_root.join(&rel_path);

            if let Some(parent) = abs_path.parent() {
                std::fs::create_dir_all(parent)?;
            }
            std::fs::write(&abs_path, &note.body_md)?;
            written_paths.push(abs_path);

            let hash = content_hash(&note.body_md);
            let now_ts = now();
            let rel_str = rel_path.to_string_lossy().to_string();

            nb.notes.insert(
                note.id,
                NoteSync {
                    note_id: note.id,
                    title: note.title.clone(),
                    folder_id: note.folder_id,
                    revision: note.revision,
                    content_hash: hash,
                    local_path: rel_str,
                    last_synced_at: now_ts,
                },
            );
            info!("Created note: {}", note.title);
        }

        Event::NoteUpdated { note, .. } => {
            if let Some(ns) = nb.notes.get_mut(&note.id) {
                let new_hash = content_hash(&note.body_md);

                // Check if local file was also modified (conflict detection)
                let abs_path = sync_root.join(&ns.local_path);
                if abs_path.exists() {
                    let local_content = std::fs::read_to_string(&abs_path)?;
                    let local_hash = content_hash(&local_content);

                    if local_hash != ns.content_hash && new_hash != local_hash {
                        // Conflict: local was modified AND remote is different
                        let conflict_path = conflict_path(&abs_path);
                        std::fs::write(&conflict_path, &local_content)?;
                        written_paths.push(conflict_path);
                        warn!("Conflict detected for {}, saved local as .conflict.md", ns.title);
                    }
                }

                std::fs::write(&abs_path, &note.body_md)?;
                written_paths.push(abs_path);

                ns.revision = note.revision;
                ns.content_hash = new_hash;
                ns.last_synced_at = now();

                debug!("Updated note: {} (rev {})", note.title, note.revision);
            }
        }

        Event::NoteRenamed {
            note_id, title, ..
        } => {
            if let Some(ns) = nb.notes.get_mut(note_id) {
                let old_abs = sync_root.join(&ns.local_path);
                let new_filename = format!("{}.md", path_mapper::sanitize_filename(title));
                let new_abs = old_abs.with_file_name(&new_filename);

                if old_abs.exists() && old_abs != new_abs {
                    std::fs::rename(&old_abs, &new_abs)?;
                    written_paths.push(old_abs);
                    written_paths.push(new_abs.clone());
                }

                // Update state path
                let new_rel = new_abs
                    .strip_prefix(sync_root)
                    .unwrap_or(&new_abs)
                    .to_string_lossy()
                    .to_string();
                ns.title = title.clone();
                ns.local_path = new_rel;

                info!("Renamed note to: {}", title);
            }
        }

        Event::NoteMoved {
            note_id,
            folder_id,
            ..
        } => {
            if let Some(ns) = nb.notes.get_mut(note_id) {
                let old_abs = sync_root.join(&ns.local_path);
                let filename = old_abs
                    .file_name()
                    .map(|f| f.to_string_lossy().to_string())
                    .unwrap_or_default();

                // Build new directory path from the target folder
                let folder_rel = nb
                    .folders
                    .get(folder_id)
                    .map(|f| f.local_path.clone())
                    .unwrap_or_default();

                let mut new_rel = PathBuf::from(&nb.local_dir);
                if !folder_rel.is_empty() {
                    new_rel.push(&folder_rel);
                }
                new_rel.push(&filename);

                let new_abs = sync_root.join(&new_rel);
                if let Some(parent) = new_abs.parent() {
                    std::fs::create_dir_all(parent)?;
                }

                if old_abs.exists() && old_abs != new_abs {
                    std::fs::rename(&old_abs, &new_abs)?;
                    written_paths.push(old_abs);
                    written_paths.push(new_abs);
                }

                ns.folder_id = *folder_id;
                ns.local_path = new_rel.to_string_lossy().to_string();

                info!("Moved note {} to folder {}", ns.title, folder_id);
            }
        }

        Event::NoteDeleted { note_id, .. } => {
            if let Some(ns) = nb.notes.remove(note_id) {
                let abs_path = sync_root.join(&ns.local_path);
                if abs_path.exists() {
                    std::fs::remove_file(&abs_path)?;
                    written_paths.push(abs_path);
                }
                info!("Deleted note: {}", ns.title);
            }
        }

        Event::FolderCreated { folder, .. } => {
            let folders: HashMap<u64, Folder> = nb
                .folders
                .iter()
                .map(|(id, fs)| {
                    (
                        *id,
                        Folder {
                            id: fs.folder_id,
                            notebook_id: nb.notebook_id,
                            name: fs.name.clone(),
                            parent_folder_id: fs.parent_folder_id,
                            created_by: String::new(),
                            created_at: 0,
                            updated_at: 0,
                        },
                    )
                })
                .collect();

            // Build path including the new folder's parent chain
            let mut all_folders = folders;
            all_folders.insert(folder.id, folder.clone());

            let rel_path = path_mapper::folder_path(folder.id, &all_folders);
            let rel_str = rel_path.to_string_lossy().to_string();

            if !rel_str.is_empty() {
                let abs_path = sync_root.join(&nb.local_dir).join(&rel_path);
                std::fs::create_dir_all(&abs_path)?;
                written_paths.push(abs_path);
            }

            nb.folders.insert(
                folder.id,
                FolderSync {
                    folder_id: folder.id,
                    name: folder.name.clone(),
                    parent_folder_id: folder.parent_folder_id,
                    local_path: rel_str,
                },
            );

            info!("Created folder: {}", folder.name);
        }

        Event::FolderRenamed {
            folder_id, name, ..
        } => {
            if let Some(fs) = nb.folders.get_mut(folder_id) {
                let old_abs = sync_root.join(&nb.local_dir).join(&fs.local_path);
                let new_name = path_mapper::sanitize_filename(name);
                let new_abs = old_abs.with_file_name(&new_name);

                if old_abs.exists() && old_abs != new_abs {
                    std::fs::rename(&old_abs, &new_abs)?;
                    written_paths.push(old_abs);
                    written_paths.push(new_abs);
                }

                fs.name = name.clone();
                // Update local_path - replace the last component
                let parent = PathBuf::from(&fs.local_path)
                    .parent()
                    .map(|p| p.to_path_buf())
                    .unwrap_or_default();
                fs.local_path = if parent.as_os_str().is_empty() {
                    new_name
                } else {
                    format!("{}/{}", parent.display(), new_name)
                };

                info!("Renamed folder to: {}", name);
            }
        }

        Event::FolderMoved {
            folder_id,
            new_parent_folder_id,
            ..
        } => {
            // Get old path before modifying
            let old_local_path = nb
                .folders
                .get(folder_id)
                .map(|f| f.local_path.clone())
                .unwrap_or_default();
            let folder_name = nb
                .folders
                .get(folder_id)
                .map(|f| f.name.clone())
                .unwrap_or_default();

            let old_abs = sync_root.join(&nb.local_dir).join(&old_local_path);

            // Build new parent path
            let new_parent_path = nb
                .folders
                .get(new_parent_folder_id)
                .map(|f| f.local_path.clone())
                .unwrap_or_default();

            let new_rel = if new_parent_path.is_empty() {
                path_mapper::sanitize_filename(&folder_name)
            } else {
                format!(
                    "{}/{}",
                    new_parent_path,
                    path_mapper::sanitize_filename(&folder_name)
                )
            };

            let new_abs = sync_root.join(&nb.local_dir).join(&new_rel);

            if old_abs.exists() && old_abs != new_abs {
                if let Some(parent) = new_abs.parent() {
                    std::fs::create_dir_all(parent)?;
                }
                std::fs::rename(&old_abs, &new_abs)?;
                written_paths.push(old_abs);
                written_paths.push(new_abs);
            }

            if let Some(fs) = nb.folders.get_mut(folder_id) {
                fs.parent_folder_id = Some(*new_parent_folder_id);
                fs.local_path = new_rel;
            }

            info!("Moved folder {}", folder_name);
        }

        Event::FolderDeleted { folder_id, .. } => {
            if let Some(fs) = nb.folders.remove(folder_id) {
                let abs_path = sync_root.join(&nb.local_dir).join(&fs.local_path);
                if abs_path.exists() {
                    // Only remove if empty; otherwise leave it (notes should have been deleted first)
                    if std::fs::read_dir(&abs_path)
                        .map(|mut d| d.next().is_none())
                        .unwrap_or(true)
                    {
                        let _ = std::fs::remove_dir(&abs_path);
                        written_paths.push(abs_path);
                    } else {
                        warn!("Folder {} not empty, leaving on disk", fs.name);
                    }
                }
                info!("Deleted folder: {}", fs.name);
            }
        }

        Event::NotebookRenamed { title, .. } => {
            let old_dir = nb.local_dir.clone();
            let new_dir = path_mapper::sanitize_filename(title);
            let old_abs = sync_root.join(&old_dir);
            let new_abs = sync_root.join(&new_dir);

            if old_abs.exists() && old_abs != new_abs {
                std::fs::rename(&old_abs, &new_abs)?;
                written_paths.push(old_abs);
                written_paths.push(new_abs);
            }

            nb.title = title.clone();
            nb.local_dir = new_dir;

            info!("Renamed notebook to: {}", title);
        }

        // Events we don't need to handle for filesystem sync
        Event::NotebookCreated { .. }
        | Event::MemberJoined { .. }
        | Event::MemberLeft { .. } => {}
    }

    state.touch();
    state.save(sync_root)?;

    Ok(written_paths)
}

/// Generate a .conflict.md path from an original path
fn conflict_path(original: &Path) -> PathBuf {
    let stem = original
        .file_stem()
        .map(|s| s.to_string_lossy().to_string())
        .unwrap_or_default();
    original.with_file_name(format!("{}.conflict.md", stem))
}

/// SHA-256 hash of content as hex string
pub fn content_hash(content: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(content.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn now() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

#[derive(Debug, thiserror::Error)]
pub enum SyncError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Urbit error: {0}")]
    Urbit(#[from] crate::urbit::client::UrbitError),
}
