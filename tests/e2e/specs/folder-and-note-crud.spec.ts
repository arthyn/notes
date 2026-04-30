import { test, expect } from "../fixtures/notes";

test.describe("folder + note CRUD (single ship)", () => {
  test("create folder, create note, save, content persists on reload", async ({ notes, page }) => {
    const nb = `e2e-fn-${Date.now()}`;
    const folder = "Docs";
    const noteTitle = "First note";
    const noteBody = "# Heading\n\nSome content.";

    await notes.createNotebook(nb);
    await notes.selectNotebook(nb);
    await notes.createFolder(folder);

    // Navigate into the folder. Constrain to is-folder so a note with the
    // same name (later) can't shadow the click target.
    await page.locator(`.item-row.is-folder:has-text('${folder}')`).click();

    await notes.createNote(noteTitle);
    await notes.editNoteBody(noteBody);
    await notes.forceSave();

    // Reload — body should still be there
    await page.reload();
    await notes.selectNotebook(nb);
    // After selectNotebook, the notes-list re-renders multiple times as
    // loadFolders + loadNotes settle. A normal .click() can detach
    // mid-action; dispatchEvent fires a synthetic click that doesn't
    // require actionability/stability. We're testing whether the click
    // wires up correctly — not the visual hover state.
    await page.locator(`.item-row.is-folder:has-text('${folder}')`).dispatchEvent("click");
    await page.locator(`.item-row.is-note:has-text('${noteTitle}')`).dispatchEvent("click");
    await expect(page.locator("#editor")).toHaveValue(noteBody);

    await notes.deleteNotebook();
  });
});
