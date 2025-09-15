const cardMods = import.meta.glob("$lib/assets/Cards/Character_*.png", { eager: true });
const tablaMods = import.meta.glob("$lib/assets/Tablas/tabla_*.png",   { eager: true });

// extract trailing number for sorting
function idFromPath(p: string): number {
  const m = p.match(/(?:character|tabla)_(\d+)\.png$/);
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

export const cardImages  = toSortedUrls(cardMods);   // should be 54
export const tablaImages = toSortedUrls(tablaMods);  // should be 1026

if (import.meta.env.DEV) {
  console.log("[gallery] cards:", cardImages.length);
  console.log("[gallery] tablas:", tablaImages.length);
}
