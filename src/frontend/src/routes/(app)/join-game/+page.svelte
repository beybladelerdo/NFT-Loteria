<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/state";
  import { goto } from "$app/navigation";
  import { get } from "svelte/store";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { tokenStore } from "$lib/stores/token-store";
  import { TokenService, type TokenBalance } from "$lib/services/token-service";
  import { BACKEND_CANISTER_ID } from "$lib/constants/app.constants";
  import { Principal } from "@dfinity/principal";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import GameFilters from "$lib/components/routes/join/Filter.svelte";
  import GameList from "$lib/components/routes/join/List.svelte";
  import GameDetails from "$lib/components/routes/join/Details.svelte";
  import BalanceDisplay from "$lib/components/routes/join/Balance.svelte";
  import TablaSelector from "$lib/components/routes/game/TablaSelector.svelte";
  import type { GameView, GameDetailData } from "$lib/utils/helpers";
  import { symbolFromVariant, ledgerFeeFor } from "$lib/utils/helpers";

  const tokenService = new TokenService();

  let isLoading = $state(true);
  let games = $state<GameView[]>([]);
  let modeFilter = $state<"all" | "line" | "blackout">("all");
  let selectedGameId = $state<string | null>(null);
  let selectedGame = $state<GameView | null>(null);
  let selectedDetail = $state<GameDetailData | null>(null);
  let selectedTablaIds = $state<number[]>([]);
  let isFetchingDetail = $state(false);
  let isApproving = $state(false);
  let isJoining = $state(false);
  let errorMessage = $state("");

  let tokenBalances = $state<TokenBalance[]>([]);
  let tokenLoading = $state(false);
  let tokenError = $state<string | null>(null);

  const filteredGames = $derived.by(() => {
    if (modeFilter === "all") return games;
    return games.filter((game) =>
      modeFilter === "line" ? "line" in game.mode : "blackout" in game.mode,
    );
  });

  const balances = $derived({
    ICP: tokenBalances.find((b) => b.symbol === "ICP")
      ? parseFloat(
          tokenService.formatBalance(
            tokenBalances.find((b) => b.symbol === "ICP")!.balance,
            8,
          ),
        )
      : 0,
    ckBTC: tokenBalances.find((b) => b.symbol === "ckBTC")
      ? parseFloat(
          tokenService.formatBalance(
            tokenBalances.find((b) => b.symbol === "ckBTC")!.balance,
            8,
          ),
        )
      : 0,
    GLDT: tokenBalances.find((b) => b.symbol === "GLDT")
      ? parseFloat(
          tokenService.formatBalance(
            tokenBalances.find((b) => b.symbol === "GLDT")!.balance,
            8,
          ),
        )
      : 0,
  });

  const currentTokenConfig = $derived.by(() => {
    const tokenType = selectedDetail?.tokenType ?? selectedGame?.tokenType;
    if (!tokenType) return null;
    const symbol = symbolFromVariant(tokenType);
    return tokenBalances.find((b) => b.symbol === symbol) ?? null;
  });

  const currentTokenSymbol = $derived(currentTokenConfig?.symbol ?? null);

  const currentEntryFee = $derived.by(() => {
    const baseFee = selectedDetail
      ? BigInt(selectedDetail.entryFee)
      : selectedGame
        ? BigInt(selectedGame.entryFee)
        : 0n;
    return baseFee * BigInt(selectedTablaIds.length || 1);
  });

  const currentLedgerFee = $derived.by(() => {
    const symbol = currentTokenSymbol;
    return symbol ? ledgerFeeFor(symbol) : 0n;
  });

  const totalApprovalAmount = $derived(currentEntryFee + currentLedgerFee);

  const hasSufficientBalance = $derived.by(() => {
    if (!currentTokenConfig) return false;
    return currentTokenConfig.balance >= totalApprovalAmount;
  });

  const defaultGameId = $derived(page.url.searchParams.get("gameId"));

  let unsubscribeToken: (() => void) | null = null;

  async function loadGames() {
    try {
      errorMessage = "";
      await gameStore.fetchOpenGames(0);
      games = gameStore.openGames;

      if (defaultGameId) {
        const initial = games.find((game) => game.id === defaultGameId);
        if (initial) {
          await selectGame(initial);
        }
      }
    } catch (error) {
      console.error("Failed to load games:", error);
      errorMessage = "Failed to load games. Please try refreshing.";
    }
  }

  async function refreshGames() {
    isLoading = true;
    await loadGames();
    isLoading = false;

    addToast({
      message: `Games refreshed. Found ${games.length} open game${games.length !== 1 ? "s" : ""}.`,
      type: "success",
      duration: 2000,
    });
  }

  async function refreshBalances() {
    tokenLoading = true;
    await tokenStore.refreshBalances();
    tokenLoading = false;
    addToast({
      message: "Balances refreshed!",
      type: "success",
      duration: 2000,
    });
  }

  async function selectGame(game: GameView) {
    selectedGameId = game.id;
    selectedGame = game;
    selectedDetail = null;
    selectedTablaIds = [];
    isFetchingDetail = true;

    try {
      const { detail } = await gameStore.fetchGameById(game.id);
      selectedDetail = detail ?? null;
    } catch (error) {
      console.error("Failed to load game detail:", error);
    } finally {
      isFetchingDetail = false;
    }
  }

  function handleTablaSelect(tablaIds: number[], totalFee: bigint) {
    // Just update state, fee calculation handled by derived values
  }

  async function approveAndJoin() {
    if (!selectedGame || selectedTablaIds.length === 0) {
      addToast({
        message: "Select at least one tabla before joining.",
        type: "error",
        duration: 2500,
      });
      return;
    }

    const detail = selectedDetail;
    if (!detail) {
      addToast({
        message: "Unable to load game details. Try again.",
        type: "error",
        duration: 2500,
      });
      return;
    }

    const auth = get(authStore);
    if (!auth.identity) {
      addToast({
        message: "Sign in to join a game.",
        type: "error",
        duration: 2500,
      });
      return;
    }

    if (!currentTokenConfig || !currentTokenSymbol) {
      addToast({
        message: "Unable to determine token type.",
        type: "error",
        duration: 3000,
      });
      return;
    }

    if (!hasSufficientBalance) {
      addToast({
        message: "Insufficient balance to join this game.",
        type: "error",
        duration: 3000,
      });
      return;
    }

    try {
      if (totalApprovalAmount > 0n) {
        isApproving = true;
        const backendPrincipal = Principal.fromText(BACKEND_CANISTER_ID);
        await tokenService.approve(
          currentTokenConfig.canisterId,
          auth.identity,
          {
            amount: totalApprovalAmount,
            spender: { owner: backendPrincipal, subaccount: null },
          },
        );
        addToast({
          message: `Approved ${tokenService.formatBalance(
            totalApprovalAmount,
            currentTokenConfig?.decimals ?? 8,
          )} ${currentTokenSymbol}`,
          type: "success",
          duration: 2500,
        });
      }
    } catch (error) {
      console.error("Approve failed:", error);
      addToast({
        message: "Approval failed. Please try again.",
        type: "error",
        duration: 3000,
      });
      isApproving = false;
      return;
    } finally {
      isApproving = false;
    }

    await joinSelectedGame(detail);
  }

  async function joinSelectedGame(detail: GameDetailData) {
    if (selectedTablaIds.length === 0) return;

    isJoining = true;
    const result = await gameStore.joinGame(detail.id, selectedTablaIds);

    if (result.success) {
      addToast({
        message: "You're in! Redirecting to the lobby...",
        type: "success",
        duration: 2500,
      });
      await tokenStore.refreshBalances();
      goto(`/game/play/${detail.id}`);
    } else {
      addToast({
        message: result.error ?? "Failed to join game.",
        type: "error",
        duration: 3000,
      });
    }

    isJoining = false;
  }

  onMount(async () => {
    unsubscribeToken = tokenStore.subscribe((state) => {
      tokenBalances = state.balances;
      tokenLoading = state.isLoading;
      tokenError = state.error;
    });

    try {
      await authStore.sync();
      const auth = get(authStore);

      if (auth.identity) {
        await tokenStore.fetchBalances();
      }

      await loadGames();
    } catch (error) {
      console.error("Failed to initialize join page:", error);
      errorMessage = "Something went wrong while loading games.";
    } finally {
      isLoading = false;
    }
  });

  onDestroy(() => {
    if (unsubscribeToken) unsubscribeToken();
  });
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else}
  <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
    <FlickeringGrid
      class="absolute inset-0 opacity-20"
      squareSize={4}
      gridGap={6}
      color="rgba(196, 154, 250, 0.5)"
    />

    <div class="relative z-10 max-w-7xl mx-auto px-4 py-6 sm:py-8">
      <div
        class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6"
      >
        <div>
          <span class="arcade-badge inline-block mb-2 sm:mb-3">
            Join Game
          </span>
          <h1
            class="text-2xl sm:text-3xl md:text-4xl font-black text-white uppercase arcade-text-shadow"
          >
            Find A Lobby
          </h1>
        </div>

        <button
          class="arcade-button px-4 py-2 text-xs sm:self-start"
          onclick={refreshGames}
        >
          🔄 REFRESH
        </button>
      </div>

      {#if errorMessage}
        <div
          class="bg-red-500 border-4 border-black text-white font-bold uppercase text-xs sm:text-sm px-4 py-3 shadow-[4px_4px_0px_rgba(0,0,0,1)] mb-6"
        >
          {errorMessage}
        </div>
      {/if}

      <div
        class="grid lg:grid-cols-[340px,1fr] xl:grid-cols-[360px,1fr] gap-4 sm:gap-6"
      >
        <aside class="space-y-4 sm:space-y-6">
          <GameFilters {modeFilter} onFilterChange={(f) => (modeFilter = f)} />

          <GameList
            games={filteredGames}
            {selectedGameId}
            tokenDecimals={currentTokenConfig?.decimals ?? 8}
            onSelectGame={selectGame}
          />
        </aside>

        <section class="space-y-4 sm:space-y-6">
          {#if !selectedGame}
            <div class="arcade-panel p-6">
              <h2
                class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 arcade-text-shadow"
              >
                Choose A Game
              </h2>
              <p
                class="text-xs sm:text-sm font-bold uppercase leading-relaxed text-white"
              >
                Select a lobby to see its details, review the entry fee, and
                pick your tabla. Once you approve the tokens, you'll be dropped
                straight into the game.
              </p>
            </div>
          {:else}
            <GameDetails
              detail={selectedDetail}
              isFetching={isFetchingDetail}
            />

            {#if selectedDetail}
              <BalanceDisplay
                {balances}
                isLoading={tokenLoading}
                onRefresh={refreshBalances}
              />

              <TablaSelector
                gameId={selectedGame.id}
                bind:selectedTablaIds
                onSelect={handleTablaSelect}
              />

              <div
                class="arcade-panel-sm p-4 space-y-2 text-xs font-bold uppercase text-[#C9B5E8]"
              >
                <div class="flex items-center justify-between">
                  <span>Entry Fee</span>
                  <span class="text-white">
                    {tokenService.formatBalance(currentEntryFee, 8)}
                    {currentTokenSymbol}
                  </span>
                </div>
                <div class="flex items-center justify-between">
                  <span>Ledger Fee</span>
                  <span class="text-white">
                    {tokenService.formatBalance(currentLedgerFee, 8)}
                    {currentTokenSymbol}
                  </span>
                </div>
                <div class="flex items-center justify-between">
                  <span>Total Approval</span>
                  <span class="text-[#F4E04D]">
                    {tokenService.formatBalance(totalApprovalAmount, 8)}
                    {currentTokenSymbol}
                  </span>
                </div>
                <div class="flex items-center justify-between">
                  <span>Your Balance</span>
                  <span class="text-white">
                    {tokenLoading
                      ? "..."
                      : currentTokenConfig
                        ? tokenService.formatBalance(
                            currentTokenConfig.balance,
                            currentTokenConfig.decimals,
                          )
                        : "0"}
                    {currentTokenSymbol}
                  </span>
                </div>
                {#if tokenError}
                  <p class="text-red-500 font-bold break-words">
                    {tokenError}
                  </p>
                {/if}
              </div>

              <button
                class="arcade-button w-full px-4 py-3 text-sm disabled:bg-gray-400 disabled:cursor-not-allowed"
                disabled={selectedTablaIds.length === 0 ||
                  isApproving ||
                  isJoining ||
                  !hasSufficientBalance}
                onclick={approveAndJoin}
              >
                {isApproving
                  ? "APPROVING..."
                  : isJoining
                    ? "JOINING..."
                    : "APPROVE & JOIN"}
              </button>
            {/if}
          {/if}
        </section>
      </div>
    </div>
  </div>
{/if}
