import { existingTablas } from "$lib/data/existing-tablas";

const cardMods = import.meta.glob("$lib/assets/Cards/Character_*.png", {
  eager: true,
});
const tablaMods = import.meta.glob("$lib/assets/Tablas/tabla_*.jpg", {
  eager: true,
});

// extract trailing number for sorting
function idFromPath(p: string): number {
  const m = p.match(/(?:character|tabla)_(\d+)\.jpg$/i);
  return m ? Number(m[1]) : -1;
}

function toSortedUrls(mods: Record<string, unknown>): string[] {
  const entries = Object.entries(mods)
    .map(([path, mod]) => ({ path, url: (mod as { default: string }).default }))
    .sort((a, b) => idFromPath(a.path) - idFromPath(b.path));

  // hard de-dupe
  const seen = new Set<string>();
  const urls: string[] = [];
  for (const e of entries) {
    if (!seen.has(e.url)) {
      seen.add(e.url);
      urls.push(e.url);
    }
  }
  return urls;
}

const filteredTablaMods = Object.fromEntries(
  Object.entries(tablaMods).filter(([path]) =>
    existingTablas.has(idFromPath(path)),
  ),
);

export const cardImages = toSortedUrls(cardMods);
export const tablaImages = toSortedUrls(filteredTablaMods);

export const tablaUrlById: Map<number, string> = new Map(
  Object.entries(filteredTablaMods)
    .map(([path, mod]) => [
      idFromPath(path), 
      (mod as { default: string }).default  // ← FIX: Extract .default
    ] as [number, string])
    .filter(([id]) => id > 0),
);

export const getTablaUrl = (id: number, fallback = "/Tablas/placeholder.jpg") =>
  tablaUrlById.get(id) ?? fallback;

if (import.meta.env.DEV) {
  console.log("[gallery] cards:", cardImages.length);
  console.log("[gallery] tablas:", tablaImages.length);
}
