import { GameService } from "$lib/services/game-service";
import type {
  GameView,
  TablaInfo,
} from "../../../../declarations/backend/backend.did";
import type { CreateGameParams } from "$lib/services/game-service";

export interface GameStoreData {
  openGames: GameView[];
  activeGames: GameView[];
  currentGame: GameView | null;
  availableTablas: TablaInfo[];
  isLoading: boolean;
}

let openGames = $state<GameView[]>([]);
let activeGames = $state<GameView[]>([]);
let currentGame = $state<GameView | null>(null);
let availableTablas = $state<TablaInfo[]>([]);
let isLoading = $state(false);

export const gameStore = {
  get openGames() { return openGames; },
  get activeGames() { return activeGames; },
  get currentGame() { return currentGame; },
  get availableTablas() { return availableTablas; },
  get isLoading() { return isLoading; },

  // -------- Lists --------
  async fetchOpenGames(page = 0) {
    isLoading = true;
    try {
      const games = await new GameService().getOpenGames(page);
      openGames = games;
    } catch (error) {
      console.error("Error fetching open games:", error);
    } finally {
      isLoading = false;
    }
  },

  async fetchActiveGames(page = 0) {
    try {
      const games = await new GameService().getActiveGames(page);
      activeGames = games;
    } catch (error) {
      console.error("Error fetching active games:", error);
    }
  },

  // -------- Details --------
  async fetchGameById(gameId: string) {
    isLoading = true;
    try {
      const game = await new GameService().getGame(gameId);
      currentGame = game ?? null;
      return game;
    } catch (error) {
      console.error("Error fetching game:", error);
      return null;
    } finally {
      isLoading = false;
    }
  },

  // -------- Lifecycle --------
  async createGame(params: CreateGameParams) {
    isLoading = true;
    try {
      const result = await new GameService().createGame(params);
      if (result.success) {
        await gameStore.fetchOpenGames();
        return { success: true, gameId: result.gameId };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error creating game:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },

  async joinGame(gameId: string, rentedTablaId: number) {
    isLoading = true;
    try {
      const result = await new GameService().joinGame(gameId, rentedTablaId);
      if (result.success) return { success: true };
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error joining game:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },

  async startGame(gameId: string) {
    isLoading = true;
    try {
      const result = await new GameService().startGame(gameId);
      if (result.success) {
        await gameStore.fetchOpenGames();
        await gameStore.fetchActiveGames();
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error starting game:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },

  async drawCard(gameId: string) {
    try {
      const result = await new GameService().drawCard(gameId);
      if (result.success) {
        await gameStore.fetchGameById(gameId);
        return { success: true, cardId: result.cardId };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error drawing card:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  async endGame(gameId: string) {
    isLoading = true;
    try {
      const result = await new GameService().endGame(gameId);
      if (result.success) {
        await gameStore.fetchOpenGames();
        await gameStore.fetchActiveGames();
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error ending game:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },

  // -------- Tablas --------
  async fetchAvailableTablas() {
    try {
      const tablas = await new GameService().getAvailableTablas();
      availableTablas = tablas;
    } catch (error) {
      console.error("Error fetching available tablas:", error);
    }
  },

  async claimWin(gameId: string, tablaId: number) {
    try {
      const result = await new GameService().claimWin(gameId, tablaId);
      if (result.success) {
        await gameStore.fetchGameById(gameId);
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error claiming win:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  // -------- Utils --------
  refreshGames() {
    gameStore.fetchOpenGames();
    gameStore.fetchActiveGames();
  },
  refreshTablas() {
    gameStore.fetchAvailableTablas();
  },
};