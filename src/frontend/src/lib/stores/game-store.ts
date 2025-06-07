import { writable } from "svelte/store";
import {
  GameService,
  type Game,
  type Tabla,
  type CreateGameParams,
  type JoinGameParams,
  type RentTablaParams,
} from "$lib/services/game-service";

export interface GameStoreData {
  openGames: Game[];
  activeGames: Game[];
  currentGame: Game | null;
  availableTablas: Tabla[];
  rentedTablas: Tabla[];
  isLoading: boolean;
}

let data = $state<GameStoreData>({
  openGames: [],
  activeGames: [],
  currentGame: null,
  availableTablas: [],
  rentedTablas: [],
  isLoading: false,
});

export const gameStore = {
  get value() {
    return $derived(data);
  },
  async fetchOpenGames() {
    data.isLoading = true;
    try {
      const games = await new GameService().getOpenGames();
      data.openGames = games;
    } catch (error) {
      console.error("Error fetching open games:", error);
    } finally {
      data.isLoading = false;
    }
  },
  async fetchActiveGames() {
    try {
      const games = await new GameService().getActiveGames();
      data.activeGames = games;
    } catch (error) {
      console.error("Error fetching active games:", error);
    }
  },
  async fetchGameById(gameId: number) {
    data.isLoading = true;
    try {
      const game = await new GameService().getGame(gameId);
      data.currentGame = game ?? null;
      return game;
    } catch (error) {
      console.error("Error fetching game:", error);
      return null;
    } finally {
      data.isLoading = false;
    }
  },
  async createGame(params: CreateGameParams) {
    data.isLoading = true;
    try {
      const result = await new GameService().createGame(params);
      if (result.success) {
        await gameStore.fetchOpenGames();
        return { success: true, gameId: result.gameId };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error creating game:", error);
      return { success: false, error: error.message };
    } finally {
      data.isLoading = false;
    }
  },
  async joinGame(params: JoinGameParams) {
    data.isLoading = true;
    try {
      const result = await new GameService().joinGame(params);
      if (result.success) {
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error joining game:", error);
      return { success: false, error: error.message };
    } finally {
      data.isLoading = false;
    }
  },
  async startGame(gameId: number) {
    data.isLoading = true;
    try {
      const result = await new GameService().startGame(gameId);
      if (result.success) {
        await gameStore.fetchOpenGames();
        await gameStore.fetchActiveGames();
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error starting game:", error);
      return { success: false, error: error.message };
    } finally {
      data.isLoading = false;
    }
  },
  async drawCard(gameId: number) {
    try {
      const result = await new GameService().drawCard(gameId);
      if (result.success) {
        await gameStore.fetchGameById(gameId);
        return { success: true, cardId: result.cardId };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error drawing card:", error);
      return { success: false, error: error.message };
    }
  },
  async endGame(gameId: number) {
    data.isLoading = true;
    try {
      const result = await new GameService().endGame(gameId);
      if (result.success) {
        await gameStore.fetchOpenGames();
        await gameStore.fetchActiveGames();
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error ending game:", error);
      return { success: false, error: error.message };
    } finally {
      data.isLoading = false;
    }
  },
  async fetchAvailableTablas() {
    try {
      const tablas = await new GameService().getAvailableTablas();
      data.availableTablas = tablas;
    } catch (error) {
      console.error("Error fetching available tablas:", error);
    }
  },
  async rentTabla(params: RentTablaParams) {
    try {
      const result = await new GameService().rentTabla(params);
      if (result.success) {
        await gameStore.fetchAvailableTablas();
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error renting tabla:", error);
      return { success: false, error: error.message };
    }
  },
  async claimWin(gameId: number, tablaId: number) {
    try {
      const result = await new GameService().claimWin(gameId, tablaId);
      if (result.success) {
        await gameStore.fetchGameById(gameId);
        return { success: true };
      }
      return { success: false, error: result.error };
    } catch (error) {
      console.error("Error claiming win:", error);
      return { success: false, error: error.message };
    }
  },
  refreshGames() {
    gameStore.fetchOpenGames();
    gameStore.fetchActiveGames();
  },
  refreshTablas() {
    gameStore.fetchAvailableTablas();
  },
};
