import { test, expect } from "../fixtures/notes";
import { openSubscriberContext } from "../fixtures/notes";

// Sub edits a note; host's stream propagates the update;
// host's UI shows the new title and body without refresh.

test.describe("@cross-ship edit propagation", () => {
  test.skip(!process.env.SUB_CODE, "SUB_CODE not set — skipping cross-ship spec");

  test("sub's note edits propagate to host live", async ({ notes, cleanup, page, browser }) => {
    test.setTimeout(180_000);

    const title = `e2e-edit-${Date.now()}`;
    const subPatp = process.env.SUB_PATP || "";
    cleanup.add("host: delete edit notebook", () => notes.tryDelete(title));

    // Host creates + publicizes + invites
    await notes.createNotebook(title);
    await notes.selectNotebook(title);
    await notes.toggleVisibility();
    await page.locator("#notebook-invite-btn").click();
    await page.locator("#m-ship").fill(subPatp);
    await page.locator("#m-ship-submit:not([disabled])").click();

    // Sub joins
    const sub = await openSubscriberContext(browser);
    cleanup.add("sub: leave edit notebook + close ctx", async () => {
      await sub.notes.tryDelete(title);
      await sub.context.close();
    });
    await sub.page.locator(`.invite-item:has-text('${title}') button:has-text('Accept')`).click();
    await expect(sub.page.locator(`.nb-item:has-text('${title}')`)).toBeVisible({ timeout: 15_000 });
    await sub.notes.selectNotebook(title);

    // Sub creates a note and edits it
    const noteTitle = "Shared note";
    const noteBody = "first draft";
    await sub.notes.createNote(noteTitle);
    await sub.notes.editNoteBody(noteBody);
    await sub.notes.forceSave();

    // Host: navigate into the same notebook, see the note
    await page.goto(`/notes/`);
    await notes.selectNotebook(title);
    await expect(page.locator(`.item-row:has-text('${noteTitle}')`)).toBeVisible({ timeout: 15_000 });

    // Sub edits the body; host's UI must update WITHOUT a manual refresh.
    // We click the note on host first so the stream change drives it.
    await page.locator(`.item-row:has-text('${noteTitle}')`).click();
    const newBody = "updated content from subscriber";
    await sub.notes.editNoteBody(newBody);
    await sub.notes.forceSave();
    await expect(page.locator("#editor")).toHaveValue(newBody, { timeout: 15_000 });
    // Cleanup runs via the cleanup fixture (afterEach).
  });
});
