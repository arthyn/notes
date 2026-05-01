import { test, expect } from "../fixtures/notes";
import { openSubscriberContext } from "../fixtures/notes";

// End-to-end: host invites sub, sub accepts, notebook appears on sub.
// Regression for the bug where %notify-invite was getting collapsed
// into the notebook-scoped %invite arm and silently failing on the
// recipient.

test.describe("@cross-ship invite flow", () => {
  test.skip(!process.env.SUB_CODE, "SUB_CODE not set — skipping cross-ship spec");

  test("host invites sub → sub sees invite live → accept makes notebook appear", async ({ notes, cleanup, page, browser }) => {
    test.setTimeout(120_000);

    const title = `e2e-invite-${Date.now()}`;
    const subPatp = process.env.SUB_PATP || "";
    expect(subPatp).toMatch(/^~/);
    cleanup.add("host: delete invite notebook", () => notes.tryDelete(title));

    // Open sub context BEFORE the host sends the invite, so the SSE
    // subscription is live and we exercise the live-delivery path.
    const sub = await openSubscriberContext(browser);
    cleanup.add("sub: leave invite notebook + close ctx", async () => {
      await sub.notes.tryDelete(title);
      await sub.context.close();
    });
    // Make sure sub doesn't have a leftover invite from a prior run
    await sub.page.locator(`.invite-item:has-text('${title}')`).count();

    // Host: create + make public + invite sub
    await notes.createNotebook(title);
    await notes.selectNotebook(title);
    await notes.toggleVisibility(); // private → public

    // Open invite modal (the dedicated button next to the gear), type
    // sub's patp, send. Modal validates as you type — Send stays disabled
    // until the patp is well-formed and not already a member.
    await page.locator("#notebook-invite-btn").click();
    await page.locator("#m-ship").fill(subPatp);
    await page.locator("#m-ship-submit:not([disabled])").click();

    // Sub: invite shows up live in the inbox (no refresh)
    await expect(sub.page.locator(`.invite-item:has-text('${title}')`)).toBeVisible({ timeout: 15_000 });

    // Sub: accept — notebook appears in sidebar
    await sub.page.locator(`.invite-item:has-text('${title}') button:has-text('Accept')`).click();
    await expect(sub.page.locator(`.nb-item:has-text('${title}')`)).toBeVisible({ timeout: 15_000 });
    // Cleanup runs via the cleanup fixture (afterEach).
  });
});
