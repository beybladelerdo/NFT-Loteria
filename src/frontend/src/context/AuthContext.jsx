import React, { createContext, useContext, useState, useEffect } from 'react';
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';
import { idlFactory as gameLogicIDL } from '../declarations/game_logic';
import { idlFactory as tablaRentalIDL } from '../declarations/tabla_rental';
import { idlFactory as paymentSystemIDL } from '../declarations/payment_system';

// Create context
const AuthContext = createContext(null);

// Constants
const CANISTER_IDS = {
  game_logic: process.env.GAME_LOGIC_CANISTER_ID,
  tabla_rental: process.env.TABLA_RENTAL_CANISTER_ID,
  payment_system: process.env.PAYMENT_SYSTEM_CANISTER_ID
};

export const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [authClient, setAuthClient] = useState(null);
  const [principal, setPrincipal] = useState(null);
  const [actors, setActors] = useState({
    gameLogic: null,
    tablaRental: null,
    paymentSystem: null
  });
  const [userBalance, setUserBalance] = useState({
    ICP: 0,
    ckBTC: 0
  });

  useEffect(() => {
    initAuth();
  }, []);

  useEffect(() => {
    if (principal && actors.paymentSystem) {
      fetchUserBalance();
    }
  }, [principal, actors.paymentSystem]);

  const initAuth = async () => {
    try {
      setIsLoading(true);
      
      // Initialize auth client
      const client = await AuthClient.create();
      setAuthClient(client);
      
      const isAuthenticated = await client.isAuthenticated();
      setIsAuthenticated(isAuthenticated);
      
      if (isAuthenticated) {
        const identity = client.getIdentity();
        const principal = identity.getPrincipal();
        setPrincipal(principal);
        
        // Initialize actors
        await initActors(identity);
      }
    } catch (error) {
      console.error("Auth initialization error:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const initActors = async (identity) => {
    try {
      const agent = new HttpAgent({ identity });
      
      // In development, fetch root key
      if (process.env.NODE_ENV !== "production") {
        await agent.fetchRootKey();
      }
      
      // Create actors
      const gameLogic = Actor.createActor(gameLogicIDL, {
        agent,
        canisterId: CANISTER_IDS.game_logic
      });
      
      const tablaRental = Actor.createActor(tablaRentalIDL, {
        agent,
        canisterId: CANISTER_IDS.tabla_rental
      });
      
      const paymentSystem = Actor.createActor(paymentSystemIDL, {
        agent,
        canisterId: CANISTER_IDS.payment_system
      });
      
      setActors({
        gameLogic,
        tablaRental,
        paymentSystem
      });
    } catch (error) {
      console.error("Actor initialization error:", error);
    }
  };

  const fetchUserBalance = async () => {
    try {
      if (!actors.paymentSystem || !principal) return;
      
      const balance = await actors.paymentSystem.getBalance(principal);
      
      // Divide by 10^8 for proper decimal representation (100,000,000 = 1 ICP/ckBTC)
      setUserBalance({
        ICP: Number(balance.ICP) / 100000000,
        ckBTC: Number(balance.ckBTC) / 100000000
      });
    } catch (error) {
      console.error("Error fetching user balance:", error);
    }
  };

  const login = async () => {
    try {
      if (!authClient) return;
      
      await authClient.login({
        identityProvider: process.env.II_URL || "https://identity.ic0.app",
        onSuccess: async () => {
          setIsAuthenticated(true);
          
          const identity = authClient.getIdentity();
          const principal = identity.getPrincipal();
          setPrincipal(principal);
          
          await initActors(identity);
        }
      });
    } catch (error) {
      console.error("Login error:", error);
    }
  };

  const logout = async () => {
    if (!authClient) return;
    
    await authClient.logout();
    setIsAuthenticated(false);
    setPrincipal(null);
    setActors({
      gameLogic: null,
      tablaRental: null,
      paymentSystem: null
    });
    setUserBalance({
      ICP: 0,
      ckBTC: 0
    });
  };

  const refreshBalance = () => {
    fetchUserBalance();
  };

  const addFundsForTesting = async (token, amount) => {
    if (!actors.paymentSystem || !principal) return;
    
    // For demo purposes only - would be removed in production
    try {
      // Convert to e8s (100,000,000 = 1 ICP/ckBTC)
      const amountE8s = Math.floor(amount * 100000000);
      
      const tokenType = token === 'ICP' ? { ICP: null } : { ckBTC: null };
      
      const result = await actors.paymentSystem.deposit(tokenType, amountE8s);
      
      if ('ok' in result) {
        await fetchUserBalance();
        return { success: true, txId: result.ok };
      } else {
        return { success: false, error: result.err };
      }
    } catch (error) {
      console.error("Error adding funds:", error);
      return { success: false, error: error.message };
    }
  };

  const value = {
    isAuthenticated,
    isLoading,
    principal,
    actors,
    userBalance,
    login,
    logout,
    refreshBalance,
    addFundsForTesting
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};