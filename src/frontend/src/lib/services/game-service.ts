import { ActorFactory } from "$lib/utils/actor.factory";
import { authStore } from "$lib/stores/auth-store";
import type {
  _SERVICE,
  // Records / variants
  GameView,
  TablaInfo,
  GameMode, // { line: null } | { blackout: null }
  TokenType, // { ICP: null } | { ckBTC: null }
  Position, // { row: bigint; col: bigint }
  // DTOs
  GetOpenGames, // { page: bigint }
  GetActiveGames, // { page: bigint }
  GetGame, // { gameId: string }
  JoinGame, // { gameId: string; rentedTablaId: number }
  UpdateTablaRentalFee, // { tablaId: number; newFee: bigint }
  // Results
  Result, // { ok: null } | { err: string }
  Result_1, // getTablaCards
  Result_2, // getTabla
  Result_3, // getProfile (unused here)
  Result_4, // getOpenGames
  Result_5, // getGame
  Result_6, // getDrawHistory
  Result_7, // getAvailableTablas
  Result_8, // getActiveGames
  Result_9, // drawCard
  Result_10, // createGame
} from "../../../../declarations/backend/backend.did";

const BACKEND_CANISTER_ID =
  (import.meta as any)?.env?.VITE_BACKEND_CANISTER_ID ??
  (process as any)?.env?.BACKEND_CANISTER_ID ??
  "";

function unwrapOpt<T>(opt: [] | [T]): T | null {
  return (opt as any)?.length ? (opt as [T])[0] : null;
}

function toMode(mode: "Line" | "Blackout"): GameMode {
  return mode === "Line" ? { line: null } : { blackout: null };
}

function toToken(tt: "ICP" | "ckBTC"): TokenType {
  return tt === "ICP" ? { ICP: null } : { ckBTC: null };
}

export interface CreateGameParams {
  name: string;
  mode: "Line" | "Blackout";
  tokenType: "ICP" | "ckBTC";
  /**
   * Entry fee is an INTEGER count of whole tokens (ICP or ckBTC).
   * (Backend multiplies by 1e8 internally for ICP transfers.)
   */
  entryFee: number;
  hostFeePercent: number; // 0..20 enforced by backend
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
      const res: Result_4 = await actor.getOpenGames(dto);
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
      const res: Result_8 = await actor.getActiveGames(dto);
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
      const res: Result_5 = await actor.getGame(dto);
      if ("err" in res) return null;
      return unwrapOpt(res.ok);
    } catch (e) {
      console.error("getGame failed:", e);
      return null;
    }
  }

  // ---------- Game lifecycle ----------

  async createGame(
    params: CreateGameParams,
  ): Promise<{ success: boolean; gameId?: string; error?: string }> {
    try {
      // entryFee must be an integer nat
      if (!Number.isInteger(params.entryFee) || params.entryFee < 0) {
        return {
          success: false,
          error:
            "entryFee must be a non-negative integer (whole ICP/ckBTC tokens)",
        };
      }
      const actor = await this.getActor();
      const res: Result_10 = await actor.createGame({
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
      const res: Result_9 = await actor.drawCard(gameId);
      if ("err" in res) return { success: false, error: res.err };
      // CardId is nat32 → number
      return { success: true, cardId: Number(res.ok) };
    } catch (e: any) {
      console.error("drawCard failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }

  async getDrawHistory(gameId: string): Promise<number[]> {
    try {
      const actor = await this.getActor();
      const res: Result_6 = await actor.getDrawHistory({ gameId });
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
      const res: Result_7 = await actor.getAvailableTablas();
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

  async updateRentalFee(
    tablaId: number,
    newFee: number,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      if (!Number.isInteger(newFee) || newFee < 0) {
        return {
          success: false,
          error: "newFee must be a non-negative integer",
        };
      }
      const actor = await this.getActor();
      const dto: UpdateTablaRentalFee = { tablaId, newFee: BigInt(newFee) };
      const res: Result = await actor.updateRentalFee(dto);
      if ("err" in res) return { success: false, error: res.err };
      return { success: true };
    } catch (e: any) {
      console.error("updateRentalFee failed:", e);
      return { success: false, error: e?.message ?? String(e) };
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
}
