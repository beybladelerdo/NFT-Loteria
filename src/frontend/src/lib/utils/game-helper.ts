import type { GameService } from "$lib/services/game-service";

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
