import { existingTablas } from "./existing-tablas";
import layouts from "../assets/Layouts/tabla_metadata.json";

type RawLayout = {
  tabla_number: number;
  characters: Record<string, string>;
  background?: string;
  [k: string]: unknown;
};

export type TablaLayout = {
  chars: number[];
  rarity: string;
};

function charNum(file: string): number {
  const m = file.match(/(\d+)\.png$/i);
  if (!m) throw new Error(`Cannot parse character number from "${file}"`);
  return Number(m[1]);
}

export const TABLA_LAYOUTS_MAP: Record<number, TablaLayout> = (() => {
  const map: Record<number, TablaLayout> = {};

  for (const d of layouts as RawLayout[]) {
    if (!existingTablas.has(d.tabla_number)) continue;

    const chars = Array.from({ length: 16 }, (_, i) => {
      const key = `position_${i + 1}`;
      const file = d.characters[key];
      if (typeof file !== "string") {
        throw new Error(`Missing ${key} for tabla ${d.tabla_number}`);
      }
      return charNum(file);
    });

    map[d.tabla_number] = {
      chars,
      rarity: d.background ?? "",
    };
  }

  return map;
})();

export const TABLA_IDS: number[] = Object.keys(TABLA_LAYOUTS_MAP)
  .map(Number)
  .sort((a, b) => a - b);

export const TABLA_COUNT = TABLA_IDS.length;

export function getTablaLayout(id: number): TablaLayout | undefined {
  return TABLA_LAYOUTS_MAP[id];
}
