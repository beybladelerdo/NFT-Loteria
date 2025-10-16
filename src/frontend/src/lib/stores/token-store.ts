import { writable, derived, get } from "svelte/store";
import { authStore } from "./auth-store";
import { TokenService, type TokenBalance } from "$lib/services/token-service";

interface TokenStoreState {
  balances: TokenBalance[];
  isLoading: boolean;
  error: string | null;
  lastUpdated: number | null;
}

function createTokenStore() {
  const tokenService = new TokenService();

  const { subscribe, set, update } = writable<TokenStoreState>({
    balances: [],
    isLoading: false,
    error: null,
    lastUpdated: null,
  });

  async function fetchBalances() {
    const auth = get(authStore);
    if (!auth.identity) {
      update((state) => ({ ...state, error: "Not authenticated" }));
      return;
    }

    update((state) => ({ ...state, isLoading: true, error: null }));

    try {
      const principal = auth.identity.getPrincipal();
      const balances = await tokenService.getAllBalances(
        principal,
        auth.identity,
      );

      update((state) => ({
        ...state,
        balances,
        isLoading: false,
        lastUpdated: Date.now(),
      }));
    } catch (error) {
      console.error("Error fetching token balances:", error);
      update((state) => ({
        ...state,
        isLoading: false,
        error:
          error instanceof Error ? error.message : "Failed to fetch balances",
      }));
    }
  }

  async function refreshBalances() {
    await fetchBalances();
  }

  function reset() {
    set({
      balances: [],
      isLoading: false,
      error: null,
      lastUpdated: null,
    });
  }

  return {
    subscribe,
    fetchBalances,
    refreshBalances,
    reset,
  };
}

export const tokenStore = createTokenStore();
