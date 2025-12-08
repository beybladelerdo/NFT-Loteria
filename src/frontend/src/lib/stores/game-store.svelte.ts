import { GameService } from "$lib/services/game-service";
import type {
  GameView,
  GameDetail,
  TablaInfo,
  TablaEarnings,
} from "../../../../declarations/backend/backend.did";
import type {
  CreateGameParams,
  CreateTablaParams,
  PrincipalEntry,
} from "$lib/services/game-service";
import type LeaveGame from "$lib/components/routes/game/LeaveGame.svelte";

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
let currentGameDetail = $state<GameDetail | null>(null);
let availableTablas = $state<TablaInfo[]>([]);
let isLoading = $state(false);
let tablaStats = $state<TablaEarnings[]>([]);

export const gameStore = {
  get openGames() {
    return openGames;
  },
  get activeGames() {
    return activeGames;
  },
  get currentGame() {
    return currentGame;
  },
  get currentGameDetail() {
    return currentGameDetail;
  },
  get availableTablas() {
    return availableTablas;
  },
  get isLoading() {
    return isLoading;
  },
  get tablaStats() {
    return tablaStats;
  },

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
      const service = new GameService();
      const [game, detail] = await Promise.all([
        service.getGame(gameId),
        service.getGameDetail(gameId),
      ]);
      currentGame = game ?? null;
      currentGameDetail = detail ?? null;
      return { game, detail };
    } catch (error) {
      console.error("Error fetching game:", error);
      currentGame = null;
      currentGameDetail = null;
      return { game: null, detail: null };
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

  async joinGame(gameId: string, rentedTablaId: number[]) {
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
  async leaveGame(gameId: string) {
    isLoading = true;
    try {
      const result = await new GameService().leaveGame(gameId);
      if (result.success) {
        await gameStore.fetchOpenGames();
        await gameStore.fetchActiveGames();
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error leaving game:", error);
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
    isLoading = true;
    try {
      const tablas = await new GameService().getAvailableTablas();
      availableTablas = tablas;
      return { success: true, tablas };
    } catch (error: any) {
      console.error("Error fetching available tablas:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
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
  async markPosition(
    gameId: string,
    tablaId: number,
    pos: { row: number; col: number },
  ) {
    try {
      const result = await new GameService().markPosition(gameId, tablaId, pos);
      if (result.success) {
        await gameStore.fetchGameById(gameId);
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error marking position:", error);
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
  async refreshRegistry() {
    try {
      const result = await new GameService().refreshRegistry();
      return result;
    } catch (error: any) {
      console.error("Error refreshing registry:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  async bootstrapAdmin() {
    try {
      const result = await new GameService().bootstrapAdmin();
      return result;
    } catch (error: any) {
      console.error("Error bootstrapping admin:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  async batchLoadTablas(tablas: CreateTablaParams[]) {
    isLoading = true;
    try {
      const result = await new GameService().adminBatchTablas(tablas);
      if (result.success) {
        await gameStore.refreshTablas();
        return { success: true, created: result.created };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error batch loading tablas:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },

  async getTablaCount() {
    try {
      return await new GameService().tablaCount();
    } catch (error) {
      console.error("Error getting tabla count:", error);
      return 0;
    }
  },

  async deleteTabla(tablaId: number) {
    try {
      const result = await new GameService().deleteTabla(tablaId);
      if (result.success) {
        await gameStore.refreshTablas();
      }
      return result;
    } catch (error: any) {
      console.error("Error deleting tabla:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async initRegistry(pairs: Array<[number, string]>) {
    try {
      const result = await new GameService().initRegistry(pairs);
      return result;
    } catch (error: any) {
      console.error("Error initializing registry:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async upsertOwners(pairs: PrincipalEntry) {
    try {
      const result = await new GameService().upsertOwners(pairs);
      return result;
    } catch (error: any) {
      console.error("Error upserting principal registry:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async getAvailableTablasForGame(gameId: string) {
    isLoading = true;
    try {
      const result = await new GameService().getAvailableTablasForGame(gameId);
      if (result.success) {
        return { success: true, tablas: result.tablas };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error fetching available tablas for game:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },
  async terminateGame(gameId: string) {
    isLoading = true;
    try {
      const result = await new GameService().terminateGame(gameId);
      if (result.success) {
        return { success: true, message: result.message };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error terminating game:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },
  async getPlatformVolume() {
    try {
      const result = await new GameService().getPlatformVolume();
      if (result.success && result.data) {
        return {
          success: true,
          data: result.data,
        };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error fetching platform volume:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  async get24hVolume() {
    try {
      const result = await new GameService().get24hVolume();
      if (result.success && result.data) {
        return {
          success: true,
          data: result.data,
        };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error fetching 24h volume:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  async getLargestPots() {
    try {
      const result = await new GameService().getLargestPots();
      if (result.success && result.data) {
        return {
          success: true,
          data: result.data,
        };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error fetching largest pots:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async retryFailedClaim(gameId: string) {
    try {
      const result = await new GameService().retryFailedClaim(gameId);
      return result;
    } catch (error: any) {
      console.error("Error retrying failed claim:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async getFailedClaims() {
    try {
      const result = await new GameService().getFailedClaims();
      if (result.success && result.data) {
        return {
          success: true,
          data: result.data,
        };
      }
      return { success: false, error: result.error };
    } catch (error: any) {
      console.error("Error fetching failed claims:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async getRecentGamesForPlayer(limit: number = 10) {
    try {
      const result = await new GameService().getRecentGamesForPlayer(limit);
      return result;
    } catch (error: any) {
      console.error("Error fetching recent games:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async sendChatMessage(gameId: string, message: string) {
    try {
      const result = await new GameService().sendChatMessage(gameId, message);
      return result;
    } catch (error: any) {
      console.error("Error sending chat message:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },

  async getChatMessages(gameId: string) {
    try {
      const result = await new GameService().getChatMessages(gameId);
      return result;
    } catch (error: any) {
      console.error("Error fetching chat messages:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
  async fetchAllTablaStats() {
    isLoading = true;
    try {
      const result = await new GameService().getAllTablaStats();
      if (result.success && result.data) {
        tablaStats = result.data;
      }
      return result;
    } catch (error: any) {
      console.error("Error fetching tabla stats:", error);
      return { success: false, error: error?.message ?? String(error) };
    } finally {
      isLoading = false;
    }
  },

  async getTablaStats(tablaId: number) {
    try {
      const result = await new GameService().getTablaStats(tablaId);
      return result;
    } catch (error: any) {
      console.error("Error fetching single tabla stats:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  },
};
