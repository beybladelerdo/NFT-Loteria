import type { GameService } from "$lib/services/game-service";
import { cardImages } from "$lib/data/gallery";

export type GameView = Awaited<ReturnType<GameService["getOpenGames"]>>[number];
export type GameDetailData = NonNullable<
  Awaited<ReturnType<GameService["getGameDetail"]>>
>;
export type Rarity =
  | { common: null }
  | { uncommon: null }
  | { rare: null }
  | { epic: null }
  | { legendary: null };

export type TokenType =
  | { ICP: null }
  | { ckBTC: null }
  | { GLDT: null }
  | Record<string, null>;

export interface TablaInfo {
  id: number;
  name: string;
  image: string;
  rentalFee: bigint;
  rarity: Rarity;
  status: { available: null } | { rented: null } | { inGame: null };
  tokenType: TokenType;
}

export type SortKey = "id" | "rarity";

export const MAX_TABLAS = 4;
export const TOTAL_CARDS = 54;

export function getCardImage(cardId: number | null): string {
  if (!cardId) return "/cards/placeholder.png";
  return (
    cardImages[cardId - 1] ??
    (cardImages.length > 0 ? cardImages[cardImages.length - 1] : "")
  );
}
export const PREFERRED_TABLAS = [78, 83, 132, 20, 68, 65, 72, 117, 87, 61];

export const rarityRank = (r: Rarity) =>
  "legendary" in r
    ? 4
    : "epic" in r
      ? 3
      : "rare" in r
        ? 2
        : "uncommon" in r
          ? 1
          : 0;

export function getRarityColor(r: Rarity): string {
  if ("common" in r) return "#C9B5E8";
  if ("uncommon" in r) return "#F4E04D";
  if ("rare" in r) return "#FF6EC7";
  if ("epic" in r) return "#9D4EDD";
  if ("legendary" in r) return "#FFD700";
  return "#C9B5E8";
}

export function getRarityText(r: Rarity): string {
  if ("common" in r) return "COMMON";
  if ("uncommon" in r) return "UNCOMMON";
  if ("rare" in r) return "RARE";
  if ("epic" in r) return "EPIC";
  if ("legendary" in r) return "ULTRA RARE";
  return "UNKNOWN";
}

export function getRarityGlow(r: Rarity): string {
  if ("legendary" in r)
    return "before:absolute before:inset-0 before:rounded-md before:animate-pulse before:bg-gradient-to-r before:from-yellow-300/20 before:via-fuchsia-300/10 before:to-yellow-300/20";
  if ("epic" in r)
    return "before:absolute before:inset-0 before:rounded-md before:animate-pulse before:bg-gradient-to-r before:from-purple-400/15 before:to-pink-400/15";
  if ("rare" in r)
    return "before:absolute before:inset-0 before:rounded-md before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(255,110,199,0.20),transparent_60%)]";
  return "";
}
export const LEDGER_FEES: Record<string, bigint> = {
  ICP: 10000n,
  ckBTC: 10000n,
  GLDT: 10000n,
};

export const unwrapOpt = <T>(opt: [] | [T]): T | null =>
  opt.length ? opt[0] : null;

export const symbolFromVariant = (token: GameDetailData["tokenType"]) => {
  if ("ICP" in token) return "ICP";
  if ("ckBTC" in token) return "ckBTC";
  if ("gldt" in token) return "GLDT";
  return "ICP";
};

export const modeLabel = (mode: GameView["mode"]) => {
  if ("line" in mode) return "Line";
  if ("blackout" in mode) return "Blackout";
  return "Unknown";
};

export const statusLabel = (status: GameView["status"]) => {
  if ("lobby" in status) return "Lobby";
  if ("active" in status) return "Active";
  if ("completed" in status) return "Completed";
  return "Unknown";
};

export const shortPrincipal = (text: string) =>
  text.length > 9 ? `${text.slice(0, 5)}…${text.slice(-4)}` : text;

export const ledgerFeeFor = (symbol: string) => LEDGER_FEES[symbol] ?? 0n;
export function isUsernameValid(username: string): boolean {
  if (!username) {
    return false;
  }
  if (username.length < 5 || username.length > 20) {
    return false;
  }
  // Allow letters, numbers, and hyphens
  return /^[a-zA-Z0-9-]+$/.test(username);
}

interface ErrorResponse {
  err: {
    NotFound?: null;
  };
}

export function isError(response: any): response is ErrorResponse {
  return response && response.err !== undefined;
}

export function formatTime(nanoseconds: bigint): string {
  const totalMilliseconds = Number(nanoseconds / 1_000_000n);
  const totalSeconds = Math.floor(totalMilliseconds / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
}

export function toNumber(val: bigint | number): number {
  return typeof val === "bigint" ? Number(val) : val;
}

export function formatTokenEarnings(amount: bigint | number): string {
  const num = toNumber(amount) / 1e8;
  return num.toFixed(4);
}

export function formatLastUsed(timestamp: bigint | number): string {
  const ts = toNumber(timestamp);
  if (ts === 0) return "Never";

  const date = new Date(ts / 1_000_000);
  const now = Date.now();
  const diff = now - date.getTime();

  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days < 7) return `${days}d ago`;

  return date.toLocaleDateString();
}

export function formatTokenType(tokenType: any): string {
  if ("ICP" in tokenType) return "ICP";
  if ("ckBTC" in tokenType) return "ckBTC";
  if ("gldt" in tokenType) return "GLDT";
  return "Unknown";
}

export function formatAmount(amount: bigint, tokenType: any): string {
  const num = Number(amount) / 1e8;
  if ("ckBTC" in tokenType) return num.toFixed(6);
  return Math.floor(num).toLocaleString();
}

export function formatStatus(status: any): string {
  if ("open" in status) return "OPEN";
  if ("active" in status) return "ACTIVE";
  if ("completed" in status) return "COMPLETED";
  if ("cancelled" in status) return "CANCELLED";
  if ("lobby" in status) return "LOBBY";
  return "UNKNOWN";
}

export function formatDate(timestamp: bigint): string {
  const date = new Date(Number(timestamp) / 1_000_000);
  return date.toLocaleDateString();
}
