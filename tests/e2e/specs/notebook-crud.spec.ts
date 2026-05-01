import { test, expect } from "../fixtures/notes";

test.describe("notebook CRUD (single ship)", () => {
  test("create + rename + delete", async ({ notes, cleanup, page }) => {
    const original = `e2e-${Date.now()}`;
    const renamed  = `${original}-renamed`;
    cleanup.add("delete original/renamed", () => notes.tryDelete(renamed));
    cleanup.add("delete original (pre-rename)", () => notes.tryDelete(original));

    await notes.createNotebook(original);
    await notes.expectNotebookExists(original);

    await notes.selectNotebook(original);
    await notes.renameNotebook(renamed);
    // `:has-text` is substring match — `original` is a prefix of `renamed`.
    // Use exact-match `:text-is` so we only count entries with the bare original title.
    await expect(page.locator(`.nb-item .nb-name:text-is('${original}')`)).toHaveCount(0);

    await notes.deleteNotebook();
    await expect(page.locator(`.nb-item .nb-name:text-is('${renamed}')`)).toHaveCount(0, { timeout: 5000 });
  });

  test("visibility toggle updates lock icon optimistically", async ({ notes, cleanup }) => {
    // Regression: the optimistic path used to call updateHeader() but not
    // renderNotebooks(), so the sidebar lock icon stayed until the stream
    // echo arrived. Patched to call renderNotebooks() inline.
    const title = `e2e-vis-${Date.now()}`;
    cleanup.add("delete vis notebook", () => notes.tryDelete(title));

    await notes.createNotebook(title);
    await notes.selectNotebook(title);
    await notes.expectLockVisible(title, true); // private by default

    await notes.toggleVisibility();
    await notes.expectLockVisible(title, false);

    await notes.toggleVisibility();
    await notes.expectLockVisible(title, true);

    await notes.deleteNotebook();
  });
});
