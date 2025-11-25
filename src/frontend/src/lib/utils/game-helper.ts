import type { GameService, Rarity } from "$lib/services/game-service";
import type { Identity } from "@dfinity/agent";

export type OptionIdentity = Identity | undefined | null;

export type GameDetailData = NonNullable<
  Awaited<ReturnType<GameService["getGameDetail"]>>
>;
export type PlayerSummary = GameDetailData["players"][number];

export type TablaInGame = PlayerSummary["tablas"][number];

export const unwrapOpt = <T>(opt: [] | [T]): T | null =>
  opt.length ? opt[0] : null;

export const shortPrincipal = (text: string) =>
  text.length > 9 ? `${text.slice(0, 5)}…${text.slice(-4)}` : text;

export const modeLabel = (mode?: GameDetailData["mode"]) => {
  if (!mode) return "Unknown";
  if ("line" in mode) return "Line";
  if ("blackout" in mode) return "Blackout";
  return "Unknown";
};

export const statusLabel = (status?: GameDetailData["status"]) => {
  if (!status) return "Unknown";
  if ("lobby" in status) return "Lobby";
  if ("active" in status) return "Active";
  if ("completed" in status) return "Completed";
  return "Unknown";
};

export const tokenSymbol = (token?: GameDetailData["tokenType"]) => {
  if (!token) return "-";
  if ("ICP" in token) return "ICP";
  if ("ckBTC" in token) return "ckBTC";
  if ("gldt" in token) return "GLDT";
  return "-";
};

export const tokenDecimals = (token?: GameDetailData["tokenType"]) => {
  if (!token) return 8;
  if ("ICP" in token) return 8;
  if ("ckBTC" in token) return 8;
  if ("gldt" in token) return 8;
  return 8;
};

export const profileName = (profile?: GameDetailData["host"]) => {
  if (!profile) return "Unknown";
  const username = unwrapOpt(profile.username);
  return username ?? shortPrincipal(profile.principal.toText());
};

export const playerName = (player: PlayerSummary) => {
  const username = unwrapOpt(player.username);
  return username ?? shortPrincipal(player.principal.toText());
};

export const TOTAL_CARDS = 54;
export const REFRESH_INTERVAL = 5000;

export const MAX_DECIMALS = 8;

export function formatSmart(n: number, max = MAX_DECIMALS): string {
  if (!Number.isFinite(n)) return "0";
  let s = n.toFixed(max);
  if (s.indexOf(".") >= 0) s = s.replace(/\.?0+$/, "");
  return s;
}

export function outerBg(r: Rarity): string {
  if ("legendary" in r)
    return "from-yellow-200/35 via-fuchsia-300/20 to-yellow-200/35";
  if ("epic" in r)
    return "from-purple-700/35 via-fuchsia-500/15 to-purple-700/35";
  if ("rare" in r)
    return "from-[#ff6ec7]/30 via-[#ff6ec7]/10 to-[#ff6ec7]/30";
  if ("uncommon" in r)
    return "from-[#F4E04D]/30 via-[#F4E04D]/10 to-[#F4E04D]/30";
  return "from-[#C9B5E8]/25 via-transparent to-[#C9B5E8]/25";
}

export function outerFX(r: Rarity): string {
  if ("legendary" in r)
    return "before:absolute before:inset-0 before:rounded-2xl before:pointer-events-none before:bg-[conic-gradient(from_0deg,rgba(255,215,0,.25),rgba(255,105,180,.15),rgba(255,215,0,.25))] before:animate-[spin_9s_linear_infinite] after:absolute after:inset-0 after:rounded-2xl after:pointer-events-none after:bg-[radial-gradient(circle_at_20%_15%,rgba(255,255,255,.18),transparent_35%),radial-gradient(circle_at_80%_85%,rgba(255,255,255,.10),transparent_40%)]";
  if ("epic" in r)
    return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(157,78,221,.22),transparent_60%)]";
  if ("rare" in r)
    return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(255,110,199,.25),transparent_60%)]";
  return "";
}

export function panelRing(r: Rarity): string {
  if ("legendary" in r)
    return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-yellow-300";
  if ("epic" in r)
    return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-purple-400";
  if ("rare" in r)
    return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-pink-300";
  if ("uncommon" in r)
    return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-amber-300";
  return "";
}

export function tablaBg(r: Rarity): string {
  if ("legendary" in r)
    return "from-yellow-300/25 via-fuchsia-300/15 to-yellow-300/25";
  if ("epic" in r)
    return "from-purple-500/25 via-pink-400/10 to-purple-500/25";
  if ("rare" in r) return "from-[#FF6EC7]/20 via-transparent to-[#FF6EC7]/20";
  if ("uncommon" in r)
    return "from-[#F4E04D]/20 via-transparent to-[#F4E04D]/20";
  return "from-[#C9B5E8]/15 via-transparent to-[#C9B5E8]/15";
}

export function tablaPulse(r: Rarity): string {
  if ("legendary" in r)
    return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-gradient-to-r before:from-yellow-300/10 before:via-fuchsia-300/5 before:to-yellow-300/10";
  if ("epic" in r)
    return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-gradient-to-r before:from-purple-400/10 before:to-pink-400/10";
  if ("rare" in r)
    return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(255,110,199,0.12),transparent_60%)]";
  return "";
}

export function pillText(r: Rarity): string {
  if ("legendary" in r) return "ULTRA RARE";
  if ("epic" in r) return "EPIC";
  if ("rare" in r) return "RARE";
  if ("uncommon" in r) return "UNCOMMON";
  return "COMMON";
}

export function pillClass(r: Rarity): string {
  if ("legendary" in r) return "bg-[#FFD700] text-[#1a0033]";
  if ("epic" in r) return "bg-[#9D4EDD] text-white";
  if ("rare" in r) return "bg-[#FF6EC7] text-[#1a0033]";
  if ("uncommon" in r) return "bg-[#F4E04D] text-[#1a0033]";
  return "bg-[#C9B5E8] text-[#1a0033]";
}

export function rarityText(r: Rarity): string {
  if ("legendary" in r) return "ULTRA RARE";
  if ("epic" in r) return "EPIC";
  if ("rare" in r) return "RARE";
  if ("uncommon" in r) return "UNCOMMON";
  return "COMMON";
}