import { ActorFactory } from "$lib/utils/actor.factory";
import { authStore } from "$lib/stores/auth-store";
import { isError } from "$lib/utils/helpers";

// Placeholder types (refine with .did file)
export interface Game {
  id: number;
  name: string;
  mode: "Line" | "Blackout";
  tokenType: "ICP" | "ckBTC";
  entryFee: number; // e8s
  hostFeePercent: number;
  players: string[];
  // Add other fields
}

export interface Tabla {
  id: number;
  tokenType: "ICP" | "ckBTC";
  rentalFee: number; // e8s
  owner: string;
  // Add other fields
}

export interface CreateGameParams {
  name: string;
  mode: "Line" | "Blackout";
  tokenType: "ICP" | "ckBTC";
  entryFee: number; // Decimal (e.g., 0.1 ICP)
  hostFeePercent: number;
}

export interface JoinGameParams {
  gameId: number;
}

export interface RentTablaParams {
  tablaId: number;
  gameId: number | null;
  owner: string;
}

export class GameService {
  private async getGameLogicActor() {
    return ActorFactory.createIdentityActor(
      authStore,
      process.env.GAME_LOGIC_CANISTER_ID ?? "",
    );
  }

  private async getTablaRentalActor() {
    return ActorFactory.createIdentityActor(
      authStore,
      process.env.TABLA_RENTAL_CANISTER_ID ?? "",
    );
  }

  private async getPaymentSystemActor() {
    return ActorFactory.createIdentityActor(
      authStore,
      process.env.PAYMENT_SYSTEM_CANISTER_ID ?? "",
    );
  }

  async getOpenGames(): Promise<Game[]> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.getOpenGames();
      if (isError(result)) return [];
      return result.ok || [];
    } catch (error) {
      console.error("Error getting open games:", error);
      return [];
    }
  }

  async getActiveGames(): Promise<Game[]> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.getActiveGames();
      if (isError(result)) return [];
      return result.ok || [];
    } catch (error) {
      console.error("Error getting active games:", error);
      return [];
    }
  }

  async getGame(gameId: number): Promise<Game | null> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.getGame(gameId);
      if (isError(result) || result.length === 0) return null;
      return result[0];
    } catch (error) {
      console.error("Error getting game:", error);
      return null;
    }
  }

  async createGame(
    params: CreateGameParams,
  ): Promise<{ success: boolean; gameId?: number; error?: string }> {
    try {
      const actor: any = await this.getGameLogicActor();
      const paymentActor: any = await this.getPaymentSystemActor();
      const entryFeeE8s = Math.floor(params.entryFee * 100000000);
      const gameParams = {
        name: params.name,
        mode: params.mode === "Line" ? { line: null } : { blackout: null },
        tokenType: params.tokenType === "ICP" ? { ICP: null } : { ckBTC: null },
        entryFee: entryFeeE8s,
        hostFeePercent: params.hostFeePercent,
      };
      const result: any = await actor.createGame(gameParams);
      if (isError(result)) {
        return { success: false, error: result.err };
      }
      await paymentActor.payGameEntryFee(
        result.ok,
        entryFeeE8s,
        gameParams.tokenType,
      );
      return { success: true, gameId: result.ok };
    } catch (error) {
      console.error("Error creating game:", error);
      return { success: false, error: error.message };
    }
  }

  async joinGame(
    params: JoinGameParams,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor: any = await this.getGameLogicActor();
      const paymentActor: any = await this.getPaymentSystemActor();
      const gameResult: any = await actor.getGame(params.gameId);
      if (isError(gameResult) || !gameResult[0]) {
        return { success: false, error: "Game not found" };
      }
      const game = gameResult[0];
      // Assume authStore provides userBalance (to be implemented)
      const userBalance = { ICP: 0, ckBTC: 0 }; // Placeholder
      const userTokenBalance =
        game.tokenType === "ICP" ? userBalance.ICP : userBalance.ckBTC;
      if (userTokenBalance < game.entryFee / 100000000) {
        return {
          success: false,
          error: `Insufficient ${game.tokenType} balance`,
        };
      }
      const joinResult: any = await actor.joinGame(params.gameId);
      if (isError(joinResult)) {
        return { success: false, error: joinResult.err };
      }
      await paymentActor.payGameEntryFee(
        params.gameId,
        game.entryFee,
        game.tokenType,
      );
      return { success: true };
    } catch (error) {
      console.error("Error joining game:", error);
      return { success: false, error: error.message };
    }
  }

  async startGame(
    gameId: number,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.startGame(gameId);
      if (isError(result)) {
        return { success: false, error: result.err };
      }
      return { success: true };
    } catch (error) {
      console.error("Error starting game:", error);
      return { success: false, error: error.message };
    }
  }

  async drawCard(
    gameId: number,
  ): Promise<{ success: boolean; cardId?: number; error?: string }> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.drawCard(gameId);
      if (isError(result)) {
        return { success: false, error: result.err };
      }
      return { success: true, cardId: result.ok };
    } catch (error) {
      console.error("Error drawing card:", error);
      return { success: false, error: error.message };
    }
  }

  async endGame(gameId: number): Promise<{ success: boolean; error?: string }> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.endGame(gameId);
      if (isError(result)) {
        return { success: false, error: result.err };
      }
      return { success: true };
    } catch (error) {
      console.error("Error ending game:", error);
      return { success: false, error: error.message };
    }
  }

  async getAvailableTablas(): Promise<Tabla[]> {
    try {
      const actor: any = await this.getTablaRentalActor();
      const result: any = await actor.getAvailableTablas();
      if (isError(result)) return [];
      return result.ok || [];
    } catch (error) {
      console.error("Error getting available tablas:", error);
      return [];
    }
  }

  async rentTabla(
    params: RentTablaParams,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const tablaActor: any = await this.getTablaRentalActor();
      const paymentActor: any = await this.getPaymentSystemActor();
      const tablaResult: any = await tablaActor.getTabla(params.tablaId);
      if (isError(tablaResult) || !tablaResult) {
        return { success: false, error: "Tabla not found" };
      }
      const tabla = tablaResult;
      // Placeholder userBalance
      const userBalance = { ICP: 0, ckBTC: 0 };
      const userTokenBalance =
        tabla.tokenType === "ICP" ? userBalance.ICP : userBalance.ckBTC;
      if (userTokenBalance < tabla.rentalFee / 100000000) {
        return {
          success: false,
          error: `Insufficient ${tabla.tokenType} balance`,
        };
      }
      const paymentResult: any = await paymentActor.payTablaRental(
        params.tablaId,
        tabla.rentalFee,
        tabla.tokenType,
        params.owner,
      );
      if (isError(paymentResult)) {
        return { success: false, error: paymentResult.err };
      }
      const rentResult: any = await tablaActor.rentTabla(
        params.tablaId,
        params.gameId,
      );
      if (isError(rentResult)) {
        return { success: false, error: rentResult.err };
      }
      if (params.gameId) {
        const gameActor: any = await this.getGameLogicActor();
        await gameActor.addTablaToGame(params.gameId, params.tablaId);
      }
      return { success: true };
    } catch (error) {
      console.error("Error renting tabla:", error);
      return { success: false, error: error.message };
    }
  }

  async claimWin(
    gameId: number,
    tablaId: number,
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor: any = await this.getGameLogicActor();
      const result: any = await actor.claimWin(gameId, tablaId);
      if (isError(result)) {
        return { success: false, error: result.err };
      }
      return { success: true };
    } catch (error) {
      console.error("Error claiming win:", error);
      return { success: false, error: error.message };
    }
  }
}
