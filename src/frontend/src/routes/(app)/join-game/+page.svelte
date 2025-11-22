<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/state";
  import { goto } from "$app/navigation";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { tokenStore } from "$lib/stores/token-store";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import TablaSelector from "$lib/components/game/tabla-selector.svelte";
  import { TokenService, type TokenBalance } from "$lib/services/token-service";
  import type { GameService } from "$lib/services/game-service";
  import { Principal } from "@dfinity/principal";
  import { get } from "svelte/store";

  type GameView = Awaited<ReturnType<GameService["getOpenGames"]>>[number];
  type GameDetailData = NonNullable<
    Awaited<ReturnType<GameService["getGameDetail"]>>
  >;

  const tokenService = new TokenService();
  const BACKEND_CANISTER_ID = import.meta.env.VITE_BACKEND_CANISTER_ID ?? "";

  const LEDGER_FEES: Record<string, bigint> = {
    ICP: 10000n,
    ckBTC: 10000000n,
    GLDT: 10000n,
  };

  // Utility functions
  const unwrapOpt = <T,>(opt: [] | [T]): T | null =>
    opt.length ? opt[0] : null;

  const symbolFromVariant = (token: GameDetailData["tokenType"]) => {
    if ("ICP" in token) return "ICP";
    if ("ckBTC" in token) return "ckBTC";
    if ("gldt" in token) return "GLDT";
    return "ICP";
  };

  const modeLabel = (mode: GameView["mode"]) => {
    if ("line" in mode) return "Line";
    if ("blackout" in mode) return "Blackout";
    return "Unknown";
  };

  const tokenSymbol = (token: GameView["tokenType"]) =>
    symbolFromVariant(token);

  const statusLabel = (status: GameView["status"]) => {
    if ("lobby" in status) return "Lobby";
    if ("active" in status) return "Active";
    if ("completed" in status) return "Completed";
    return "Unknown";
  };

  const shortPrincipal = (text: string) =>
    text.length > 9 ? `${text.slice(0, 5)}…${text.slice(-4)}` : text;

  const ledgerFeeFor = (symbol: string) => LEDGER_FEES[symbol] ?? 0n;

  // Reactive state
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

  // Token state from store
  let tokenBalances = $state<TokenBalance[]>([]);
  let tokenLoading = $state(false);
  let tokenError = $state<string | null>(null);

  // Derived state
  const filteredGames = $derived.by(() => {
    console.log("🔍 Filtering games:", {
      modeFilter,
      totalGames: games.length,
      games: games.map((g) => ({ id: g.id, name: g.name, mode: g.mode })),
    });

    if (modeFilter === "all") {
      return games;
    }

    const filtered = games.filter((game) =>
      modeFilter === "line" ? "line" in game.mode : "blackout" in game.mode,
    );

    console.log("✅ Filtered games:", filtered.length);
    return filtered;
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

  // Store subscription
  let unsubscribeToken: (() => void) | null = null;

  // Functions
  async function loadGames() {
    try {
      console.log("📥 Starting to load games...");
      errorMessage = "";

      const result = await gameStore.fetchOpenGames(0);
      console.log("📦 Fetch result:", result);

      games = gameStore.openGames;
      console.log("🎮 Games loaded:", games.length, games);

      if (games.length === 0) {
        console.warn("⚠️ No games found in store after fetch");
      }

      if (defaultGameId) {
        console.log("🔗 Default game ID from URL:", defaultGameId);
        const initial = games.find((game) => game.id === defaultGameId);
        if (initial) {
          console.log("✅ Found matching game, selecting:", initial.name);
          await selectGame(initial);
        } else {
          console.warn("⚠️ Game ID from URL not found in games list");
        }
      }
    } catch (error) {
      console.error("❌ Failed to load games:", error);
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

  async function selectGame(game: GameView) {
    console.log("🎯 Selecting game:", game.id, game.name);
    selectedGameId = game.id;
    selectedGame = game;
    selectedDetail = null;
    selectedTablaIds = [];
    isFetchingDetail = true;

    try {
      const { detail } = await gameStore.fetchGameById(game.id);
      selectedDetail = detail ?? null;
      console.log("📋 Game detail loaded:", selectedDetail);
    } catch (error) {
      console.error("❌ Failed to load game detail:", error);
    } finally {
      isFetchingDetail = false;
    }
  }

  function handleTablaSelect(tablaIds: number[], totalFee: bigint) {
    console.log("🎴 Tablas selected:", tablaIds, "Total fee:", totalFee);
  }

  async function approveAndJoin() {
    // Validation checks
    if (!selectedGame) {
      addToast({
        message: "Select a game to join.",
        type: "error",
        duration: 2500,
      });
      return;
    }

    if (!selectedTablaIds) {
      addToast({
        message: "Select a tabla before joining.",
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

    if (!currentTokenConfig) {
      addToast({
        message: "Unable to locate a balance for this token.",
        type: "error",
        duration: 3000,
      });
      return;
    }

    const symbol = currentTokenSymbol;
    if (!symbol) {
      addToast({
        message: "Unable to determine token type.",
        type: "error",
        duration: 3000,
      });
      return;
    }

    // Check balance
    if (!hasSufficientBalance) {
      addToast({
        message: "Insufficient balance to join this game.",
        type: "error",
        duration: 3000,
      });
      return;
    }

    // Approve tokens
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
          )} ${symbol}`,
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

  // Lifecycle
  onMount(async () => {
    console.log("🚀 Join game page mounting...");

    // Subscribe to token store
    unsubscribeToken = tokenStore.subscribe((state) => {
      tokenBalances = state.balances;
      tokenLoading = state.isLoading;
      tokenError = state.error;
    });

    try {
      // Sync auth and fetch balances
      await authStore.sync();
      const auth = get(authStore);
      console.log(
        "🔐 Auth synced, identity:",
        auth.identity ? "present" : "missing",
      );

      if (auth.identity) {
        await tokenStore.fetchBalances();
        console.log("💰 Token balances fetched");
      }

      // Load games
      await loadGames();
      console.log("✅ Join game page initialized");
    } catch (error) {
      console.error("❌ Failed to initialize join page:", error);
      errorMessage = "Something went wrong while loading games.";
    } finally {
      isLoading = false;
    }
  });

  onDestroy(() => {
    console.log("👋 Join game page unmounting");
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
    <div class="relative z-10 max-w-7xl mx-auto px-4 py-8">
      <div
        class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6"
      >
        <div>
          <span
            class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
          >
            Join Game
          </span>
          <h1
            class="text-3xl md:text-4xl font-black text-white uppercase mt-3"
            style="text-shadow: 3px 3px 0px #000;"
          >
            Find A Lobby
          </h1>
        </div>

        <div class="flex flex-wrap items-center gap-3">
          <button
            class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
            onclick={refreshGames}
          >
            Refresh Games
          </button>
        </div>
      </div>

      {#if errorMessage}
        <div
          class="bg-[#FF6EC7] border-4 border-black text-[#1a0033] font-bold uppercase text-sm px-4 py-3 shadow-[4px_4px_0px_rgba(0,0,0,1)] mb-6"
        >
          {errorMessage}
        </div>
      {/if}

      <div class="grid xl:grid-cols-[360px,1fr] gap-6">
        <aside class="space-y-6">
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-5 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
          >
            <div class="mb-4">
              <span
                class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Filter
              </span>
            </div>
            <div class="flex flex-wrap gap-2">
              <button
                class={`px-3 py-2 border-2 border-black font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] ${
                  modeFilter === "all"
                    ? "bg-[#F4E04D] text-[#1a0033]"
                    : "bg-[#1a0033] text-white hover:bg-[#2f1754]"
                }`}
                onclick={() => (modeFilter = "all")}
              >
                All Modes
              </button>
              <button
                class={`px-3 py-2 border-2 border-black font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] ${
                  modeFilter === "line"
                    ? "bg-[#F4E04D] text-[#1a0033]"
                    : "bg-[#1a0033] text-white hover:bg-[#2f1754]"
                }`}
                onclick={() => (modeFilter = "line")}
              >
                Line
              </button>
              <button
                class={`px-3 py-2 border-2 border-black font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] ${
                  modeFilter === "blackout"
                    ? "bg-[#F4E04D] text-[#1a0033]"
                    : "bg-[#1a0033] text-white hover:bg-[#2f1754]"
                }`}
                onclick={() => (modeFilter = "blackout")}
              >
                Blackout
              </button>
            </div>
          </div>

          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-5 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] space-y-4"
          >
            <div class="flex items-center justify-between">
              <span
                class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Open Lobbies
              </span>
              <span class="text-xs text-white font-bold">
                {filteredGames.length}
              </span>
            </div>

            {#if filteredGames.length === 0}
              <div
                class="bg-[#1a0033] border-2 border-black text-center text-[#C9B5E8] font-bold uppercase text-xs py-6 shadow-[4px_4px_0px_rgba(0,0,0,1)]"
              >
                No games available. Try refreshing or hosting your own!
              </div>
            {:else}
              <div class="space-y-3">
                {#each filteredGames as game (game.id)}
                  <button
                    class={`w-full text-left bg-[#1a0033] border-2 border-black px-4 py-4 shadow-[4px_4px_0px_rgba(0,0,0,1)] transition ${
                      selectedGameId === game.id
                        ? "ring-4 ring-[#F4E04D]"
                        : "hover:-translate-y-1 hover:shadow-[6px_6px_0px_rgba(0,0,0,1)]"
                    }`}
                    onclick={() => selectGame(game)}
                  >
                    <div class="flex items-center justify-between gap-3">
                      <h3 class="text-lg font-black text-white uppercase">
                        {game.name}
                      </h3>
                      <span
                        class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-1 text-xs font-black uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                      >
                        {modeLabel(game.mode)}
                      </span>
                    </div>
                    <div
                      class="mt-3 grid grid-cols-2 gap-2 text-xs font-bold text-[#C9B5E8] uppercase"
                    >
                      <div>
                        Entry Fee:
                        <span class="text-white">
                          {tokenService.formatBalance(
                            game.entryFee,
                            currentTokenConfig?.decimals ?? 8,
                          )}
                          &nbsp;{tokenSymbol(game.tokenType)}
                        </span>
                      </div>
                      <div class="text-right">
                        Players:
                        <span class="text-white">
                          {Number(game.playerCount)} / {Number(game.maxPlayers)}
                        </span>
                      </div>
                    </div>
                    <p
                      class="mt-2 text-[11px] text-[#8f7fc1] font-bold uppercase"
                    >
                      Host: {shortPrincipal(game.host.toText())} · Status: {statusLabel(
                        game.status,
                      )}
                    </p>
                  </button>
                {/each}
              </div>
            {/if}
          </div>
        </aside>

        <section class="space-y-6">
          {#if !selectedGame}
            <div
              class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] text-white"
            >
              <h2
                class="text-2xl font-black text-[#F4E04D] uppercase mb-4"
                style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
              >
                Choose A Game
              </h2>
              <p class="text-sm font-bold uppercase leading-relaxed">
                Select a lobby on the to see its details, review the entry fee,
                and pick your tabla. Once you approve the tokens, you'll be
                dropped straight into the game.
              </p>
            </div>
          {:else}
            <div
              class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] space-y-4 text-white"
            >
              <div>
                <span
                  class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                >
                  Lobby Details
                </span>
                <h2
                  class="text-2xl font-black text-white uppercase mt-3"
                  style="text-shadow: 3px 3px 0px #000;"
                >
                  {selectedGame.name}
                </h2>
              </div>

              {#if isFetchingDetail}
                <div class="flex items-center justify-center py-10">
                  <Spinner />
                </div>
              {:else if selectedDetail}
                <div
                  class="grid md:grid-cols-2 gap-4 text-sm font-bold uppercase"
                >
                  <div>
                    Host:
                    <span class="text-[#F4E04D]">
                      {selectedDetail.host.username
                        ? unwrapOpt(selectedDetail.host.username)
                        : shortPrincipal(
                            selectedDetail.host.principal.toText(),
                          )}
                    </span>
                  </div>
                  <div>
                    Mode:
                    <span class="text-[#F4E04D]">
                      {modeLabel(selectedDetail.mode)}
                    </span>
                  </div>
                  <div>
                    Entry Fee:
                    <span class="text-[#F4E04D]">
                      {tokenService.formatBalance(selectedDetail.entryFee, 8)}
                      &nbsp;{symbolFromVariant(selectedDetail.tokenType)}
                    </span>
                  </div>
                  <div>
                    Players:
                    <span class="text-[#F4E04D]">
                      {selectedDetail.playerCount} / {selectedDetail.maxPlayers}
                    </span>
                  </div>
                </div>

                <div
                  class="mt-4 bg-[#1a0033] border-2 border-black p-4 shadow-[4px_4px_0px_rgba(0,0,0,1)]"
                >
                  <p class="text-xs font-bold text-[#C9B5E8] uppercase mb-2">
                    Players in Lobby:
                  </p>
                  {#if selectedDetail.players.length === 0}
                    <p class="text-[11px] text-[#8f7fc1] font-bold uppercase">
                      No one has joined yet. You can be the first!
                    </p>
                  {:else}
                    <div class="flex flex-wrap gap-2">
                      {#each selectedDetail.players as player}
                        <span
                          class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-1 text-[10px] font-black uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                        >
                          {player.username && player.username.length
                            ? unwrapOpt(player.username)
                            : shortPrincipal(player.principal.toText())}
                        </span>
                      {/each}
                    </div>
                  {/if}
                </div>

                <div class="mt-6">
                  <TablaSelector
                    gameId={selectedGame.id}
                    bind:selectedTablaIds
                    onSelect={handleTablaSelect}
                  />
                </div>

                <div
                  class="bg-[#1a0033] border-2 border-black p-4 shadow-[4px_4px_0px_rgba(0,0,0,1)] space-y-2 text-xs font-bold uppercase text-[#C9B5E8]"
                >
                  <div class="flex items-center justify-between">
                    <span>Entry Fee</span>
                    <span class="text-white">
                      {tokenService.formatBalance(currentEntryFee, 8)}
                      &nbsp;{currentTokenSymbol}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span>Ledger Fee</span>
                    <span class="text-white">
                      {tokenService.formatBalance(currentLedgerFee, 8)}
                      &nbsp;{currentTokenSymbol}
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span>Total Approval</span>
                    <span class="text-[#F4E04D]">
                      {tokenService.formatBalance(totalApprovalAmount, 8)}
                      &nbsp;{currentTokenSymbol}
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
                      &nbsp;{currentTokenSymbol}
                    </span>
                  </div>
                  {#if tokenError}
                    <p class="text-[#FF6EC7] font-bold">
                      {tokenError}
                    </p>
                  {/if}
                </div>

                <button
                  class="w-full bg-[#F4E04D] text-[#1a0033] border-4 border-black px-4 py-3 font-black uppercase text-sm shadow-[6px_6px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] disabled:bg-gray-500 disabled:text-gray-200"
                  disabled={selectedTablaIds.length === 0 ||
                    isApproving ||
                    isJoining ||
                    !hasSufficientBalance}
                  onclick={approveAndJoin}
                >
                  {isApproving
                    ? "Approving..."
                    : isJoining
                      ? "Joining..."
                      : "Approve & Join"}
                </button>
              {:else}
                <p class="text-sm text-[#C9B5E8] font-bold uppercase">
                  Unable to load detailed information for this lobby. Please try
                  again.
                </p>
              {/if}
            </div>
          {/if}
        </section>
      </div>
    </div>
  </div>
{/if}
