import { test, expect } from "../fixtures/notes";
import { openSubscriberContext } from "../fixtures/notes";

// Regression: notebooks were keyed by host-local id. When two ships
// each created a notebook with the same id, the UI map collapsed
// them. Patched to key by flag.
//
// This spec needs the subscriber ship configured. Tagged @cross-ship.

test.describe("@cross-ship notebook id collision", () => {
  test.skip(!process.env.SUB_CODE, "SUB_CODE not set — skipping cross-ship spec");

  test("two notebooks from different hosts with same id stay separate in UI", async ({ notes, page, browser }) => {
    test.setTimeout(120_000);

    // Each fresh ship's first notebook gets id=1, root folder=2. So
    // both `host` and `sub` will produce flag-distinct but id-identical
    // notebooks. After the host joins the sub's public notebook (or
    // vice versa), the sidebar must show two entries — not one.
    const hostTitle = `e2e-host-${Date.now()}`;
    const subTitle  = `e2e-sub-${Date.now()}`;

    // Sub creates a public notebook. createNotebook returns the actual
    // flag (~ship/numeric-id) — the title is NOT the flag name.
    const sub = await openSubscriberContext(browser);
    const subFlag = await sub.notes.createNotebook(subTitle);
    await sub.notes.selectNotebook(subTitle);
    await sub.notes.ensureVisibility("public");

    // Host creates a notebook of its own (will share id=1 if it's a fresh-ish ship)
    await notes.createNotebook(hostTitle);

    // Host joins sub's notebook by URL — applyRoute → ensureJoinedToFlag
    // opens a "Join shared notebook" modal because we don't have it yet.
    // Modal pops on init *after* loadNotebooks settles; wait for it to
    // render before clicking the Join button.
    const [subHost, subFlagName] = subFlag.split("/");
    await page.goto(`/notes/nb/${encodeURIComponent(subHost)}/${encodeURIComponent(subFlagName)}`);
    const joinBtn = page.locator(".modal-actions button.btn-primary:has-text('Join')");
    await expect(joinBtn).toBeVisible({ timeout: 15_000 });
    await joinBtn.click();

    // Both must be visible in the host sidebar.
    // The remote-host join can take >6s if the host is slow (nomlux
    // compile + clay propagation); joinRemoteAndWait polls 8x750ms then
    // gives up, but the eventual notebooks-changed inbox event still
    // refreshes the sidebar — so allow generous time.
    await expect(page.locator(`.nb-item:has-text('${hostTitle}')`)).toBeVisible({ timeout: 30_000 });
    await expect(page.locator(`.nb-item:has-text('${subTitle}')`)).toBeVisible({ timeout: 30_000 });

    // Cleanup
    await sub.notes.selectNotebook(subTitle);
    await sub.notes.deleteNotebook();
    await sub.context.close();
    await notes.selectNotebook(hostTitle);
    await notes.deleteNotebook();
  });
});
