import { existingTablas } from "$lib/data/existing-tablas";
import fs from "node:fs/promises";
import path from "node:path";

const ROOT = path.resolve(process.cwd(), "src/frontend/src/lib/assets/Tablas");
const DRY = process.env.DRY_RUN === "1";

const MIN_ID = 1;
const MAX_ID = 1026;


const EXTS = [".png", ".jpg"];

async function fileExists(p: string) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function removeIfExists(p: string) {
  if (!(await fileExists(p))) return false;
  if (DRY) {
    console.log("[dry] would remove", p);
    return true;
  }
  await fs.rm(p);
  console.log("removed", p);
  return true;
}

async function main() {
  await fs.access(ROOT).catch(() => {
    console.error(`Tablas folder not found at: ${ROOT}`);
    process.exit(1);
  });

  let keep = 0;
  let remove = 0;

  for (let id = MIN_ID; id <= MAX_ID; id++) {
    if (existingTablas.has(id)) {
      keep++;
      continue;
    }
    const targets = EXTS.map((ext) => path.join(ROOT, `tabla_${id}${ext}`));
    for (const p of targets) {
      const removed = await removeIfExists(p);
      if (removed) remove++;
    }
  }

  console.log(`done. keep=${keep}, removed_files=${remove}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
