import { request } from "@playwright/test";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const AUTH_DIR = path.join(__dirname, ".auth");

// global-setup runs in a fresh module context, so dotenv hasn't necessarily
// been loaded yet. Load it explicitly here too.
dotenv.config({ path: path.join(__dirname, ".env") });

// Authenticate against an Urbit ship via the +code login endpoint.
// Eyre returns a urbauth-<patp> cookie we can persist as Playwright
// storage-state and reuse across all specs without re-logging in.
async function loginShip(name: string, url: string, code: string | undefined) {
  if (!code) {
    throw new Error(
      `Missing ${name.toUpperCase()}_CODE in tests/e2e/.env. ` +
      `Get it by running '+code' in the ship's dojo.`
    );
  }
  const ctx = await request.newContext({ baseURL: url });
  const res = await ctx.post("/~/login", {
    form: { password: code },
    maxRedirects: 0,
  });
  if (res.status() !== 204 && res.status() !== 302 && res.status() !== 200) {
    throw new Error(
      `${name} login failed: ${res.status()} ${await res.text().catch(() => "")}`
    );
  }
  await fs.mkdir(AUTH_DIR, { recursive: true });
  const out = path.join(AUTH_DIR, `${name}.json`);
  await ctx.storageState({ path: out });
  await ctx.dispose();
  console.log(`✓ ${name} logged in (${url}) → ${path.relative(process.cwd(), out)}`);
}

export default async function globalSetup() {
  const hostUrl = process.env.HOST_URL || "http://localhost:8082";
  const subUrl  = process.env.SUB_URL  || "http://localhost:8083";

  await loginShip("host", hostUrl, process.env.HOST_CODE);

  // Sub login is optional — only needed for @cross-ship specs.
  if (process.env.SUB_CODE) {
    await loginShip("sub", subUrl, process.env.SUB_CODE);
  }
}
