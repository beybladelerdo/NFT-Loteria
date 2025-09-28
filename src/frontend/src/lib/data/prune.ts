import { existingTablas } from "$lib/data/existing-tablas";
import fs from "node:fs/promises";
import path from "node:path";

const ROOT = path.resolve(process.cwd(), "src/frontend/src/lib/assets/Tablas");
const RX = /^tabla_(\d+)\.png$/i;
const DRY = process.env.DRY_RUN === "1";

async function main() {
  await fs.access(ROOT).catch(() => {
    console.error(`Tablas folder not found at: ${ROOT}`);
    process.exit(1);
  });

  const files = await fs.readdir(ROOT);
  let keep = 0, remove = 0;

  for (const f of files) {
    const m = f.match(RX);
    if (!m) continue;
    const id = Number(m[1]);

    if (existingTablas.has(id)) {
      keep++;
      continue;
    }

    remove++;
    const p = path.join(ROOT, f);
    if (DRY) {
      console.log("[dry] would remove", p);
    } else {
      await fs.rm(p);
      console.log("removed", p);
    }
  }

  console.log(`done. keep=${keep}, remove=${remove}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});