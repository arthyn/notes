import { defineConfig, devices } from "@playwright/test";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, ".env") });

const HOST_URL = process.env.HOST_URL || "http://localhost:8082";

export default defineConfig({
  testDir: path.join(__dirname, "specs"),
  fullyParallel: false, // shared ship state — run sequentially
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: 1, // ditto — one ship-mutating spec at a time
  // Each spec may chain several waits (selectNotebook, createNote with
  // remote-host round-trip, forceSave, page.reload). 30s default isn't
  // enough; 90s gives room for nomlux's slow compile.
  timeout: 90_000,
  reporter: [["list"], ["html", { open: "never", outputFolder: path.join(__dirname, "playwright-report") }]],
  outputDir: path.join(__dirname, "test-results"),

  use: {
    baseURL: HOST_URL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    // Eyre cookie auth — populated by global-setup
    storageState: path.join(__dirname, ".auth/host.json"),
  },

  globalSetup: path.join(__dirname, "global-setup.ts"),

  projects: [
    {
      name: "host",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
