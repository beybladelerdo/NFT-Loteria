import { ActorFactory } from "../utils/ActorFactory";
import { authStore } from "$lib/stores/auth-store";
import type {
  _SERVICE,
  GameView,
  Profile,
  TablaInfo,
  GameMode,
  TokenType,
  Position,
  GetOpenGames,
  GetActiveGames,
  GetGame,
  JoinGame,
  Result,
  Result_1,
  Result_2,
  Result_5,
  Result_6,
  Result_7,
  Result_8,
  Result_9,
  Result_10,
  Result_11,
} from "../../../../declarations/backend/backend.did";

const BACKEND_CANISTER_ID = import.meta.env.VITE_BACKEND_CANISTER_ID ?? "";

function unwrapOpt<T>(opt: [] | [T]): T | null {
  return (opt as any)?.length ? (opt as [T])[0] : null;
}

function toMode(mode: "Line" | "Blackout"): GameMode {
  return mode === "Line" ? { line: null } : { blackout: null };
}

function toToken(tt: "ICP" | "ckBTC" | "GLDT"): TokenType {
  switch (tt) {
    case "ICP":
      return { ICP: null };
    case "ckBTC":
      return { ckBTC: null };
    case "GLDT":
      return { gldt: null };
  }
}

export interface CreateGameParams {
  name: string;
  mode: "Line" | "Blackout";
  tokenType: "ICP" | "ckBTC" | "GLDT";
  entryFee: number;
  hostFeePercent: number;
}

export interface CreateTablaParams {
  tablaId: number;
  cards: number[];
  rarity: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary";
  imageUrl: string;
}

export type Rarity =
  | { common: null }
  | { uncommon: null }
  | { rare: null }
  | { epic: null }
  | { legendary: null };

function parseRarity(rarity: string): Rarity {
  const normalized = rarity.toLowerCase().trim();
  if (normalized === "uncommon party hats") return { uncommon: null };
  if (normalized === "common") return { common: null };
  if (normalized === "uncommon") return { uncommon: null };
  if (normalized === "rare") return { rare: null };
  if (normalized === "epic") return { epic: null };
  if (normalized === "legendary") return { legendary: null };
  return { common: null }; // default
}

export class GameService {
  private async getActor(): Promise<_SERVICE> {
    return (await ActorFactory.createIdentityActor(
      authStore,
      BACKEND_CANISTER_ID,
    )) as unknown as _SERVICE;
  }

  // ---------- Games (lists & details) ----------

  async getOpenGames(page = 0): Promise<GameView[]> {
    try {
      const actor = await this.getActor();
      const dto: GetOpenGames = { page: BigInt(page) };
      const res: Result_5 = await actor.getOpenGames(dto);
      if ("err" in res) return [];
      return res.ok.openGames;
    } catch (e) {
      console.error("getOpenGames failed:", e);
      return [];
    }
  }

  async getActiveGames(page = 0): Promise<GameView[]> {
    try {
      const actor = await this.getActor();
      const dto: GetActiveGames = { page: BigInt(page) };
      const res: Result_9 = await actor.getActiveGames(dto);
      if ("err" in res) return [];
      return res.ok.activeGames;
    } catch (e) {
      console.error("getActiveGames failed:", e);
      return [];
    }
  }

  async getGame(gameId: string): Promise<GameView | null> {
    try {
      const actor = await this.getActor();
      const dto: GetGame = { gameId };
      const res: Result_6 = await actor.getGame(dto);
      if ("err" in res) return null;
      return unwrapOpt(res.ok);
    } catch (e) {
      console.error("getGame failed:", e);
      return null;
    }
  }
  async getProfileByTag(tag: string): Promise<Profile | null> {
    try {
      const actor = await this.getActor();
      const res = await actor.getPlayerProfile(tag);
      if ("err" in res) return null;
      return res.ok;
    } catch (e) {
      console.error("getProfileByTag failed:", e);
      return null;
    }
  }

  // ---------- Game lifecycle ----------

  async createGame(
    params: CreateGameParams,
  ): Promise<{ success: boolean; gameId?: string; error?: string }> {
    try {
      if (!Number.isInteger(params.entryFee) || params.entryFee < 0) {
        return {
          success: false,
          error:
            "entryFee must be a non-negative integer (whole ICP/ckBTC tokens)",
        };
      }
      const actor = await this.getActor();
      const res: Result_11 = await actor.createGame({
        name: params.name,
        mode: toMode(params.mode),
        tokenType: toToken(params.tokenType),
        entryFee: BigInt(params.entryFee),
        hostFeePercent: BigInt(params.hostFeePercent),
      });
      if ("err" in res) return { success: false, error: res.err };
      return { success: true, gameId: res.ok };
    } catch (e: any) {
      console.error("createGame failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async joinGame(
    gameId: string,
    rentedTablaId: number,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const dto: JoinGame = { gameId, rentedTablaId };
      const res: Result = await actor.joinGame(dto);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("joinGame failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async startGame(
    gameId: string,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result = await actor.startGame(gameId);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("startGame failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async endGame(gameId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result = await actor.endGame(gameId);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("endGame failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async drawCard(
    gameId: string,
  ): Promise<{ success: boolean; cardId?: number; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result_10 = await actor.drawCard(gameId);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true, cardId: Number(res.ok) };
    } catch (e: any) {
      console.error("drawCard failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async getDrawHistory(gameId: string): Promise<number[]> {
    try {
      const actor = await this.getActor();
      const res: Result_7 = await actor.getDrawHistory({ gameId });
      if ("err" in res) return [];
      return Array.from(res.ok as ArrayLike<number>, Number);
    } catch (e) {
      console.error("getDrawHistory failed:", e);
      return [];
    }
  }

  async claimWin(
    gameId: string,
    tablaId: number,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result = await actor.claimWin(gameId, tablaId);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("claimWin failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  // ---------- Tablas ----------

  async getAvailableTablas(): Promise<TablaInfo[]> {
    try {
      const actor = await this.getActor();
      const res: Result_8 = await actor.getAvailableTablas();
      if ("err" in res) return [];
      return res.ok;
    } catch (e) {
      console.error("getAvailableTablas failed:", e);
      return [];
    }
  }

  async getTabla(tablaId: number): Promise<TablaInfo | null> {
    try {
      const actor = await this.getActor();
      const res: Result_2 = await actor.getTabla(tablaId);
      if ("err" in res) return null;
      return unwrapOpt(res.ok);
    } catch (e) {
      console.error("getTabla failed:", e);
      return null;
    }
  }

  async getTablaCards(tablaId: number): Promise<number[]> {
    try {
      const actor = await this.getActor();
      const res: Result_1 = await actor.getTablaCards(tablaId);
      if ("err" in res) return [];
      return res.ok.map((n) => Number(n));
    } catch (e) {
      console.error("getTablaCards failed:", e);
      return [];
    }
  }

  async markPosition(
    gameId: string,
    tablaId: number,
    pos: { row: number; col: number },
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const dto: Position = { row: BigInt(pos.row), col: BigInt(pos.col) };
      const res: Result = await actor.markPosition(gameId, tablaId, dto);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("markPosition failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  // ---------- Admin Functions ----------

  async refreshRegistry(): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      await actor.refreshRegistry();
      return { success: true };
    } catch (e: any) {
      console.error("refreshRegistry failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async bootstrapAdmin(): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result = await actor.bootstrapAdmin();
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("bootstrapAdmin failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async adminBatchTablas(
    tablas: CreateTablaParams[],
  ): Promise<{ success: boolean; created?: number[]; error?: string }> {
    try {
      const actor = await this.getActor();
      const dtos = tablas.map((t) => ({
        tablaId: t.tablaId,
        cards: t.cards.map((c) => BigInt(c)),
        rarity: parseRarity(t.rarity),
        imageUrl: t.imageUrl,
      }));

      const res = await actor.adminBatchTablas(dtos);
      if ("err" in res) return { success: false, error: res.err };
      return {
        success: true,
        created: Array.from(res.ok).map((id) => Number(id)),
      };
    } catch (e: any) {
      console.error("adminBatchTablas failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async tablaCount(): Promise<number> {
    try {
      const actor = await this.getActor();
      const count = await actor.tablaCount();
      return Number(count);
    } catch (e) {
      console.error("tablaCount failed:", e);
      return 0;
    }
  }

  async deleteTabla(
    tablaId: number,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result = await actor.deleteTabla(tablaId);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("deleteTabla failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }
  async initRegistry(
    pairs: Array<[number, string]>,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = await this.getActor();
      const res: Result = await actor.initRegistry(pairs);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("init registry failed, Tabla failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }
}
