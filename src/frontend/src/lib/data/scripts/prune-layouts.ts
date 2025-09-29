import fs from "node:fs/promises";
import path from "node:path";
import { existingTablas } from "../existing-tablas";

const DRY = process.env.DRY_RUN === "1";

const LAYOUTS_PATH =
  process.env.LAYOUTS_PATH ||
  "src/frontend/src/lib/assets/Layouts/tabla_metadata.json";

type RawLayout = {
  tabla_number: number;
  characters: Record<string, string>;
  background?: string;
  [k: string]: unknown;
};

async function main() {
  const abs = path.resolve(process.cwd(), LAYOUTS_PATH);
  const raw = await fs.readFile(abs, "utf8");
  const data = JSON.parse(raw) as RawLayout[];

  const keep: RawLayout[] = [];
  const remove: RawLayout[] = [];
  for (const d of data) {
    (existingTablas.has(d.tabla_number) ? keep : remove).push(d);
  }

  keep.sort((a, b) => a.tabla_number - b.tabla_number);

  console.log(
    `layouts total=${data.length}, keep=${keep.length}, remove=${remove.length}`,
  );

  if (DRY) {
    console.log(
      "[dry] would remove tabla_numbers:",
      remove.map((x) => x.tabla_number).join(", "),
    );
    return;
  }

  const ts = new Date().toISOString().replace(/[-:]/g, "").replace(/\..+$/, "");
  const dir = path.dirname(abs);

  await fs.writeFile(
    path.join(dir, `tabla_metadata.backup.${ts}.json`),
    raw,
    "utf8",
  );
  await fs.writeFile(abs, JSON.stringify(keep, null, 2) + "\n", "utf8");
  await fs.writeFile(
    path.join(dir, `tabla_metadata.removed.${ts}.json`),
    JSON.stringify(remove, null, 2) + "\n",
    "utf8",
  );

  console.log(`updated ${LAYOUTS_PATH}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
