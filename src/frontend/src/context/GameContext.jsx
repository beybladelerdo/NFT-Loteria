import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';

// Create context
const GameContext = createContext(null);

export const GameProvider = ({ children }) => {
  const { actors, isAuthenticated, userBalance, refreshBalance } = useAuth();
  
  const [openGames, setOpenGames] = useState([]);
  const [activeGames, setActiveGames] = useState([]);
  const [currentGame, setCurrentGame] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [availableTablas, setAvailableTablas] = useState([]);
  const [rentedTablas, setRentedTablas] = useState([]);
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // Fetch open games when auth state changes or explicit refresh is triggered
  useEffect(() => {
    if (isAuthenticated && actors.gameLogic) {
      fetchOpenGames();
      fetchActiveGames();
    }
  }, [isAuthenticated, actors.gameLogic, refreshTrigger]);

  // Fetch tablas when actor is available
  useEffect(() => {
    if (isAuthenticated && actors.tablaRental) {
      fetchAvailableTablas();
    }
  }, [isAuthenticated, actors.tablaRental, refreshTrigger]);

  const fetchOpenGames = async () => {
    if (!actors.gameLogic) return;
    
    try {
      setIsLoading(true);
      const games = await actors.gameLogic.getOpenGames();
      setOpenGames(games);
    } catch (error) {
      console.error("Error fetching open games:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchActiveGames = async () => {
    if (!actors.gameLogic) return;
    
    try {
      const games = await actors.gameLogic.getActiveGames();
      setActiveGames(games);
    } catch (error) {
      console.error("Error fetching active games:", error);
    }
  };

  const fetchGameById = async (gameId) => {
    if (!actors.gameLogic || !gameId) return null;
    
    try {
      setIsLoading(true);
      const game = await actors.gameLogic.getGame(Number(gameId));
      if (game.length === 0) return null;
      
      setCurrentGame(game[0]);
      return game[0];
    } catch (error) {
      console.error("Error fetching game:", error);
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  const createGame = async (gameParams) => {
    if (!actors.gameLogic) return { success: false, error: "Game Logic actor not initialized" };
    
    try {
      setIsLoading(true);
      
      // Convert entry fee to e8s (100,000,000 = 1 ICP/ckBTC)
      const entryFeeE8s = Math.floor(gameParams.entryFee * 100000000);
      
      // Prepare game parameters
      const params = {
        name: gameParams.name,
        mode: gameParams.mode === 'Line' ? { line: null } : { blackout: null },
        tokenType: gameParams.tokenType === 'ICP' ? { ICP: null } : { ckBTC: null },
        entryFee: entryFeeE8s,
        hostFeePercent: Number(gameParams.hostFeePercent)
      };
      
      const result = await actors.gameLogic.createGame(params);
      
      if ('ok' in result) {
        // Pay the entry fee
        const tokenType = gameParams.tokenType === 'ICP' ? { ICP: null } : { ckBTC: null };
        await actors.paymentSystem.payGameEntryFee(result.ok, entryFeeE8s, tokenType);
        
        // Refresh balance
        refreshBalance();
        
        // Refresh games list
        refreshGames();
        
        return { success: true, gameId: result.ok };
      } else {
        return { success: false, error: result.err };
      }
    } catch (error) {
      console.error("Error creating game:", error);
      return { success: false, error: error.message };
    } finally {
      setIsLoading(false);
    }
  };

  const joinGame = async (gameId) => {
    if (!actors.gameLogic || !actors.paymentSystem) {
      return { success: false, error: "Required actors not initialized" };
    }
    
    try {
      setIsLoading(true);
      
      // Fetch game details first
      const gameResult = await actors.gameLogic.getGame(Number(gameId));
      if (!gameResult[0]) {
        return { success: false, error: "Game not found" };
      }
      
      const game = gameResult[0];
      
      // Check user balance
      const userTokenBalance = game.tokenType === "ICP" ? userBalance.ICP : userBalance.ckBTC;
      if (userTokenBalance < (game.entryFee / 100000000)) {
        return { success: false, error: `Insufficient ${game.tokenType} balance` };
      }
      
      // Join the game
      const joinResult = await actors.gameLogic.joinGame(Number(gameId));
      
      if ('ok' in joinResult) {
        // Pay entry fee
        const tokenType = game.tokenType === "ICP" ? { ICP: null } : { ckBTC: null };
        await actors.paymentSystem.payGameEntryFee(
          Number(gameId), 
          game.entryFee, 
          tokenType
        );
        
        // Refresh balance
        refreshBalance();
        
        return { success: true };
      } else {
        return { success: false, error: joinResult.err };
      }
    } catch (error) {
      console.error("Error joining game:", error);
      return { success: false, error: error.message };
    } finally {
      setIsLoading(false);
    }
  };

  const startGame = async (gameId) => {
    if (!actors.gameLogic) {
      return { success: false, error: "Game Logic actor not initialized" };
    }
    
    try {
      setIsLoading(true);
      
      const result = await actors.gameLogic.startGame(Number(gameId));
      
      if ('ok' in result) {
        // Refresh game lists
        refreshGames();
        
        return { success: true };
      } else {
        return { success: false, error: result.err };
      }
    } catch (error) {
      console.error("Error starting game:", error);
      return { success: false, error: error.message };
    } finally {
      setIsLoading(false);
    }
  };

  const drawCard = async (gameId) => {
    if (!actors.gameLogic) {
      return { success: false, error: "Game Logic actor not initialized" };
    }
    
    try {
      const result = await actors.gameLogic.drawCard(Number(gameId));
      
      if ('ok' in result) {
        // Refresh current game
        await fetchGameById(gameId);
        
        return { success: true, cardId: result.ok };
      } else {
        return { success: false, error: result.err };
      }
    } catch (error) {
      console.error("Error drawing card:", error);
      return { success: false, error: error.message };
    }
  };

  const endGame = async (gameId) => {
    if (!actors.gameLogic) {
      return { success: false, error: "Game Logic actor not initialized" };
    }
    
    try {
      setIsLoading(true);
      
      const result = await actors.gameLogic.endGame(Number(gameId));
      
      if ('ok' in result) {
        // Refresh game lists
        refreshGames();
        
        return { success: true };
      } else {
        return { success: false, error: result.err };
      }
    } catch (error) {
      console.error("Error ending game:", error);
      return { success: false, error: error.message };
    } finally {
      setIsLoading(false);
    }
  };

  const fetchAvailableTablas = async () => {
    if (!actors.tablaRental) return;
    
    try {
      const tablas = await actors.tablaRental.getAvailableTablas();
      setAvailableTablas(tablas);
    } catch (error) {
      console.error("Error fetching available tablas:", error);
    }
  };

  const rentTabla = async (tablaId, gameId, owner) => {
    if (!actors.tablaRental || !actors.paymentSystem) {
      return { success: false, error: "Required actors not initialized" };
    }
    
    try {
      // Get tabla details
      const tablaResult = await actors.tablaRental.getTabla(Number(tablaId));
      if (!tablaResult) {
        return { success: false, error: "Tabla not found" };
      }
      
      const tabla = tablaResult;
      
      // Check user balance
      const userTokenBalance = tabla.tokenType === "ICP" ? userBalance.ICP : userBalance.ckBTC;
      if (userTokenBalance < (tabla.rentalFee / 100000000)) {
        return { success: false, error: `Insufficient ${tabla.tokenType} balance` };
      }
      
      // Pay the rental fee
      const tokenType = tabla.tokenType === "ICP" ? { ICP: null } : { ckBTC: null };
      const paymentResult = await actors.paymentSystem.payTablaRental(
        Number(tablaId),
        tabla.rentalFee,
        tokenType,
        owner
      );
      
      if ('ok' in paymentResult) {
        // Update tabla rental status
        const rentResult = await actors.tablaRental.rentTabla(
          Number(tablaId),
          gameId ? Number(gameId) : null
        );
        
        if ('ok' in rentResult) {
          // Add tabla to game
          if (gameId) {
            await actors.gameLogic.addTablaToGame(Number(gameId), Number(tablaId));
          }
          
          // Refresh balance
          refreshBalance();
          
          // Refresh tablas
          refreshTablas();
          
          return { success: true };
        } else {
          return { success: false, error: rentResult.err };
        }
      } else {
        return { success: false, error: paymentResult.err };
      }
    } catch (error) {
      console.error("Error renting tabla:", error);
      return { success: false, error: error.message };
    }
  };

  const claimWin = async (gameId, tablaId) => {
    if (!actors.gameLogic) {
      return { success: false, error: "Game Logic actor not initialized" };
    }
    
    try {
      const result = await actors.gameLogic.claimWin(Number(gameId), Number(tablaId));
      
      if ('ok' in result) {
        // Refresh current game
        await fetchGameById(gameId);
        
        return { success: true };
      } else {
        return { success: false, error: result.err };
      }
    } catch (error) {
      console.error("Error claiming win:", error);
      return { success: false, error: error.message };
    }
  };

  const refreshGames = () => {
    setRefreshTrigger(prev => prev + 1);
  };

  const refreshTablas = () => {
    setRefreshTrigger(prev => prev + 1);
  };

  const value = {
    openGames,
    activeGames,
    currentGame,
    isLoading,
    availableTablas,
    rentedTablas,
    fetchGameById,
    createGame,
    joinGame,
    startGame,
    drawCard,
    endGame,
    refreshGames,
    rentTabla,
    claimWin
  };

  return (
    <GameContext.Provider value={value}>
      {children}
    </GameContext.Provider>
  );
};

export const useGame = () => {
  const context = useContext(GameContext);
  if (!context) {
    throw new Error('useGame must be used within a GameProvider');
  }
  return context;
};