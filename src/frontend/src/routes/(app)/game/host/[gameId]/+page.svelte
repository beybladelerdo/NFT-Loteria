<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/state";
  import { goto } from "$app/navigation";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import InvitePlayers from "$lib/components/game/invite-player.svelte";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import { cardImages } from "$lib/data/gallery";
  import { TokenService } from "$lib/services/token-service";
  import GameChat from "$lib/components/game/game-chat.svelte";
  import {
    type GameDetailData,
    shortPrincipal,
    formatSmart,
    modeLabel,
    statusLabel,
    tokenSymbol,
    profileName,
    playerName,
    TOTAL_CARDS,
    REFRESH_INTERVAL,
  } from "$lib/utils/game-helper";
  import AudioToggle from "$lib/components/sound/SoundToggle.svelte";
  import { startMenuMusic } from "$lib/services/audio-services";
  import CardDrawAnimation from "$lib/components/shared/DrawAnimation.svelte";

  const tokenService = new TokenService();
  const gameId = page.params.gameId ?? null;

  const cardImage = (cardId: number | null) => {
    if (!cardId) return "/cards/placeholder.png";
    return (
      cardImages[cardId - 1] ??
      (cardImages.length > 0 ? cardImages[cardImages.length - 1] : "")
    );
  };

  let gameDetail = $state<GameDetailData | null>(null);
  let isLoading = $state(true);
  let isStarting = $state(false);
  let isDrawing = $state(false);
  let isEnding = $state(false);
  let isTerminating = $state(false);
  let showTerminateModal = $state(false);
  let showInvitePanel = $state(false);
  let inviteLink = $state("");
  let errorMessage = $state("");
  let lastDrawnCardId = $state<number | null>(null);
  let showCardAnimation = $state(false);
  let potBalance = $state<bigint | null>(null);
  let pollHandle: ReturnType<typeof setInterval> | null = null;

  $effect(() => {
    if (!gameDetail?.id || !$authStore.identity) return;

    tokenService
      .getPotBalance(gameDetail.id, gameDetail.tokenType, $authStore.identity)
      .then((result) => {
        potBalance = result.amountBaseUnits;
      })
      .catch((error) => {
        console.error("Failed to load pot balance:", error);
        potBalance = null;
      });
  });

  const formattedPotBalance = $derived(
    potBalance !== null ? tokenService.formatBalance(potBalance, 8) : "—",
  );
  const isLobbyStatus = $derived(!!gameDetail && "lobby" in gameDetail.status);
  const viewerPrincipal = $derived(
    $authStore.identity ? $authStore.identity.getPrincipal().toText() : null,
  );
  const isGameActive = $derived(!!gameDetail && "active" in gameDetail.status);
  const isGameCompleted = $derived(
    !!gameDetail && "completed" in gameDetail.status,
  );

  const isHostViewer = $derived(
    !!gameDetail &&
      !!viewerPrincipal &&
      gameDetail.host.principal.toText() === viewerPrincipal,
  );

  const currentCardId = $derived(
    gameDetail?.currentCard && gameDetail.currentCard.length > 0
      ? Number(gameDetail.currentCard[0])
      : null,
  );

  const drawnCards = $derived(
    gameDetail ? gameDetail.drawnCards.map((card) => Number(card)) : [],
  );

  const remainingCards = $derived(TOTAL_CARDS - drawnCards.length);

  const marksByPlayer = $derived.by(() => {
    const map = new Map<string, number>();
    if (!gameDetail) return map;
    for (const marca of gameDetail.marks) {
      const id = marca.playerId.toText();
      map.set(id, (map.get(id) ?? 0) + 1);
    }
    return map;
  });

  const playersStats = $derived(
    (() => {
      if (!gameDetail) return [];
      return [...gameDetail.players]
        .sort((a, b) => playerName(a).localeCompare(playerName(b)))
        .map((player) => {
          const id = player.principal.toText();
          return {
            player,
            marks: marksByPlayer.get(id) ?? 0,
            tablas: player.tablas.length,
          };
        });
    })(),
  );

  const winnerPrincipal = $derived(gameDetail?.winner?.[0]?.toText() ?? null);

  const winnerLabel = $derived.by(() => {
    if (!gameDetail || !winnerPrincipal) return null;
    if (gameDetail.host.principal.toText() === winnerPrincipal) {
      return profileName(gameDetail.host);
    }
    const match = gameDetail.players.find(
      (p) => p.principal.toText() === winnerPrincipal,
    );
    return match ? playerName(match) : shortPrincipal(winnerPrincipal);
  });
  function handleCloseAnimation() {
    showCardAnimation = false;
  }

  // Enhanced polling when game completes but winner not yet set
  // This handles the race condition where status changes to completed but winner field hasn't propagated
  let fastPollHandle: ReturnType<typeof setInterval> | null = null;

  $effect(() => {
    // If game is completed but no winner yet, poll aggressively
    if (isGameCompleted && !winnerPrincipal) {
      if (!fastPollHandle) {
        console.log("Game completed but no winner yet - starting fast polling");
        let attempts = 0;
        fastPollHandle = setInterval(async () => {
          attempts++;
          await refreshGame(false);

          // Stop after 20 attempts (10 seconds) or when winner is found
          if (attempts >= 20 || winnerPrincipal) {
            if (fastPollHandle) {
              clearInterval(fastPollHandle);
              fastPollHandle = null;
              console.log(
                winnerPrincipal ? "Winner found!" : "Fast polling timeout",
              );
            }
          }
        }, 500); // Check every 500ms
      }
    } else if (fastPollHandle && (winnerPrincipal || !isGameCompleted)) {
      // Clean up fast polling if winner found or game no longer completed
      clearInterval(fastPollHandle);
      fastPollHandle = null;
    }
  });

  async function refreshGame(showSpinner = false) {
    if (!gameId) {
      errorMessage = "Missing game id.";
      return;
    }

    if (showSpinner) isLoading = true;
    try {
      const { detail } = await gameStore.fetchGameById(gameId);
      gameDetail = detail ?? null;

      if (detail && detail.drawnCards.length > 0) {
        const latest = Number(detail.drawnCards[detail.drawnCards.length - 1]);
        lastDrawnCardId = latest;
      } else {
        lastDrawnCardId = null;
      }

      errorMessage = detail ? "" : "Game not found.";
    } catch (err) {
      console.error("Failed to load game detail:", err);
      errorMessage = "Failed to load game detail.";
    } finally {
      if (showSpinner) isLoading = false;
    }
  }

  async function handleStartGame() {
    if (!isHostViewer || !gameId) return;
    isStarting = true;
    const result = await gameStore.startGame(gameId);
    if (result.success) {
      addToast({
        message: "Game started! Players can now join the action.",
        type: "success",
        duration: 2500,
      });
      await refreshGame(true);
    } else {
      addToast({
        message: result.error ?? "Failed to start game.",
        type: "error",
        duration: 3000,
      });
    }
    isStarting = false;
  }

  async function handleDrawCard() {
    if (!gameId || !isGameActive || isDrawing) return;

    isDrawing = true;
    const result = await gameStore.drawCard(gameId);

    if (result.success) {
      await refreshGame(false);
      showCardAnimation = true;

      addToast({
        message: "Card drawn!",
        type: "success",
        duration: 2000,
      });
    } else {
      addToast({
        message: result.error ?? "Failed to draw card.",
        type: "error",
        duration: 3000,
      });
    }

    isDrawing = false;
  }

  async function handleEndGame() {
    if (!isHostViewer || !gameId) return;
    isEnding = true;
    const result = await gameStore.endGame(gameId);
    if (result.success) {
      addToast({
        message: "Game ended.",
        type: "success",
        duration: 2500,
      });
      await refreshGame(true);
    } else {
      addToast({
        message: result.error ?? "Failed to end game.",
        type: "error",
        duration: 3000,
      });
    }
    isEnding = false;
  }

  async function handleTerminateGame() {
    if (!isHostViewer || !gameId) return;
    showTerminateModal = false;
    isTerminating = true;

    const result = await gameStore.terminateGame(gameId);
    if (result.success) {
      addToast({
        message: result.message || "Game terminated successfully.",
        type: "success",
        duration: 3000,
      });
      // Navigate back to dashboard after termination
      setTimeout(() => {
        goto("/dashboard");
      }, 1500);
    } else {
      addToast({
        message: result.error || "Failed to terminate game.",
        type: "error",
        duration: 3000,
      });
      isTerminating = false;
    }
  }

  onMount(() => {
    startMenuMusic("/sounds/menu_music.wav", true);
    (async () => {
      try {
        await authStore.sync();
      } catch (error) {
        console.warn("Auth sync failed:", error);
      }

      if (typeof window !== "undefined" && gameId) {
        inviteLink = `${window.location.origin}/join-game?gameId=${gameId}`;
      }

      await refreshGame(true);
      pollHandle = setInterval(() => refreshGame(false), REFRESH_INTERVAL);
    })();
  });

  onDestroy(() => {
    if (pollHandle) clearInterval(pollHandle);
    if (fastPollHandle) clearInterval(fastPollHandle);
  });
</script>

<CardDrawAnimation
  cardId={currentCardId}
  cardImage={currentCardId ? cardImage(currentCardId) : ""}
  show={showCardAnimation}
  isHost={isHostViewer}
  hasCardOnTabla={false}
  onClose={handleCloseAnimation}
/>
{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if errorMessage && !gameDetail}
  <div class="min-h-screen bg-[#1a0033] flex items-center justify-center p-4">
    <div
      class="bg-gradient-to-b from-[#522785] to-[#3d1d63] border-2 sm:border-4 border-black shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)] p-6 sm:p-10 text-center max-w-md w-full"
    >
      <h1 class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase mb-4">
        Game Not Found
      </h1>
      <p class="text-white font-bold mb-6 text-sm sm:text-base">{errorMessage}</p>
      <button
        class="bg-[#F4E04D] text-[#1a0033] px-4 sm:px-6 py-2 sm:py-3 font-black uppercase border-2 sm:border-4 border-black hover:bg-[#fff27d] transition-all shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] text-sm sm:text-base"
        onclick={() => goto("/dashboard")}
      >
        ◄ Back to Dashboard
      </button>
    </div>
  </div>
{:else if gameDetail}
  <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
    <FlickeringGrid
      class="absolute inset-0 opacity-20 pointer-events-none"
      squareSize={4}
      gridGap={6}
      color="rgba(196, 154, 250, 0.5)"
    />
    <div class="relative z-10 w-full mx-auto px-4 py-6 sm:py-8 space-y-4 sm:space-y-6 max-w-7xl">
      <div
        class="flex flex-col gap-3 sm:gap-4"
      >
        <button
          onclick={() => goto("/dashboard")}
          class="inline-flex items-center justify-center gap-2 bg-[#C9B5E8] text-[#1a0033] px-4 sm:px-5 py-2 sm:py-3 font-black uppercase border-2 sm:border-4 border-black hover:bg-[#d9c9f0] transition-all text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] w-full sm:w-auto"
        >
          ◄ Back to Lobby
        </button>
        <div class="text-center sm:text-left">
          <p
            class="text-[#F4E04D] font-black text-xs uppercase tracking-[0.2em] sm:tracking-[0.4em]"
          >
            Lobby Code
          </p>
          <p
            class="text-2xl sm:text-3xl font-black text-white mt-1"
            style="text-shadow: 2px 2px 0px #000;"
          >
            {gameDetail.id}
          </p>
        </div>
      </div>
      {#if errorMessage}
        <div
          class="bg-[#FF6EC7] border-2 sm:border-4 border-black text-[#1a0033] font-bold uppercase text-xs sm:text-sm px-3 sm:px-4 py-2 sm:py-3 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
        >
          {errorMessage}
        </div>
      {/if}
      
      <!-- Main Content Grid - Mobile First -->
      <div class="grid grid-cols-1 lg:grid-cols-[minmax(280px,380px),1fr] gap-4 sm:gap-6">
        <!-- Sidebar -->
        <div class="space-y-4 sm:space-y-6 w-full">
          <!-- Host Control Center -->
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)] w-full"
          >
            <div class="mb-3 sm:mb-4">
              <span
                class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Lobby Info
              </span>
            </div>
            <h2
              class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 sm:mb-6 break-words"
              style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;"
            >
              Host Control Center
            </h2>
            <div class="space-y-2 sm:space-y-3 text-xs sm:text-sm font-bold text-white uppercase">
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Host</span>
                <span class="text-right text-[#F4E04D] break-all">
                  {profileName(gameDetail.host)}
                </span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Mode</span>
                <span class="text-right">{modeLabel(gameDetail.mode)}</span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Status</span>
                <span class="text-right">{statusLabel(gameDetail.status)}</span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Players</span>
                <span class="text-right">
                  {gameDetail.playerCount} / {gameDetail.maxPlayers}
                </span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Entry Fee</span>
                <span class="text-right break-all">
                  {tokenService.formatBalance(gameDetail.entryFee, 8)}
                  &nbsp;{tokenSymbol(gameDetail.tokenType)}
                </span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Host Fee</span>
                <span class="text-right">{gameDetail.hostFeePercent}%</span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Prize Pool</span>
                <span class="text-right break-all">
                  {formattedPotBalance}
                  &nbsp;{tokenSymbol(gameDetail.tokenType)}
                </span>
              </div>
              <div class="flex justify-between gap-2 sm:gap-4">
                <span class="text-[#C9B5E8] flex-shrink-0">Winner</span>
                <span class="text-right text-[#F4E04D] break-all">
                  {#if winnerLabel}
                    {winnerLabel}
                  {:else}
                    TBD
                  {/if}
                </span>
              </div>
            </div>
          </div>
          
          <!-- Players List -->
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)] w-full"
          >
            <div class="mb-3 sm:mb-4 flex items-center justify-between">
              <span
                class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Players
              </span>
              <span class="text-xs text-white font-bold">
                {playersStats.length} joined
              </span>
            </div>
            {#if playersStats.length === 0}
              <div
                class="bg-[#1a0033] border-2 border-black text-center text-[#C9B5E8] font-bold uppercase text-xs py-4 sm:py-6 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
              >
                No players have joined yet.
              </div>
            {:else}
              <div class="space-y-2 sm:space-y-3">
                {#each playersStats as stat}
                  <div
                    class="bg-[#1a0033] border-2 border-black px-2 sm:px-3 py-2 sm:py-3 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] flex items-center justify-between gap-2 sm:gap-4"
                  >
                    <div class="min-w-0 flex-1">
                      <p class="text-white font-black text-xs sm:text-sm uppercase break-all">
                        {playerName(stat.player)}
                      </p>
                      <p class="text-xs text-[#C9B5E8] font-bold">
                        Tablas: {stat.tablas} · Marks: {stat.marks}
                      </p>
                    </div>
                    <button
                      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-1 text-xs font-black uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] transition-all relative group flex-shrink-0"
                      onclick={() => {
                        navigator.clipboard.writeText(
                          stat.player.principal.toText(),
                        );
                        addToast({
                          message: "Principal copied!",
                          type: "success",
                          duration: 2000,
                        });
                      }}
                      title="Click to copy full principal"
                    >
                      #{shortPrincipal(stat.player.principal.toText())}
                      <span
                        class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-[#1a0033] border-2 border-[#F4E04D] text-[#F4E04D] text-[10px] font-mono rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none shadow-[4px_4px_0px_rgba(0,0,0,1)] z-10 hidden sm:block"
                      >
                        {stat.player.principal.toText()}
                        <span class="block text-[8px] text-[#C9B5E8] mt-1"
                          >Click to copy</span
                        >
                      </span>
                    </button>
                  </div>
                {/each}
              </div>
            {/if}
          </div>
          
          <!-- Invite Players -->
          {#if isHostViewer}
            {#if isLobbyStatus}
              <div
                class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)] w-full"
              >
                <div class="mb-3 sm:mb-4">
                  <span
                    class="bg-white text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                  >
                    Invite Players
                  </span>
                </div>
                <p
                  class="text-xs font-bold text-white uppercase mb-3 sm:mb-4 leading-relaxed"
                >
                  Share your invite link below or use the quick invite tool to
                  search by username. Inviting players is optional—you can
                  always come back later once the lobby is ready.
                </p>
                <div
                  class="bg-[#1a0033] border-2 border-black px-2 sm:px-3 py-2 sm:py-3 shadow-[3px_3px_0px_rgba(0,0,0,1)] space-y-2 sm:space-y-3"
                >
                  <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
                    <input
                      class="flex-1 bg-[#1a0033] border-2 border-black text-white text-xs font-mono px-2 py-2 min-w-0"
                      readonly
                      value={inviteLink}
                    />
                    <button
                      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] flex-shrink-0"
                      onclick={() => {
                        navigator.clipboard.writeText(inviteLink);
                        addToast({
                          message: "Invite link copied!",
                          type: "success",
                          duration: 2000,
                        });
                      }}
                    >
                      Copy
                    </button>
                  </div>
                  <button
                    class="w-full bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
                    onclick={() => (showInvitePanel = !showInvitePanel)}
                  >
                    {showInvitePanel
                      ? "Hide Invite Helper"
                      : "Open Invite Helper"}
                  </button>
                  {#if showInvitePanel}
                    <div class="pt-3 border-t border-[#C9B5E8]">
                      <InvitePlayers
                        gameId={gameDetail.id}
                        gameLink={inviteLink}
                      />
                    </div>
                  {/if}
                </div>
              </div>
            {/if}
          {/if}
        </div>
        
        <!-- Main Game Area -->
        <div class="space-y-4 sm:space-y-6 w-full min-w-0">
          <!-- Game Status Card -->
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)] space-y-4 sm:space-y-6 w-full"
          >
            <div
              class="flex flex-col gap-3 sm:gap-4"
            >
              <div class="flex-1 min-w-0">
                <span
                  class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                >
                  Game Status
                </span>
                <p
                  class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mt-2 sm:mt-3 break-words"
                  style="text-shadow: 2px 2px 0px #000;"
                >
                  {statusLabel(gameDetail.status)}
                </p>
                <p class="text-xs font-bold text-white uppercase mt-2">
                  Mode: {modeLabel(gameDetail.mode)} · Remaining Cards: {remainingCards}
                </p>
              </div>
              <div class="flex flex-wrap gap-2">
  {#if isHostViewer}
    {#if "lobby" in gameDetail.status}
      <button
        class="bg-[#F4E04D] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] active:scale-95 disabled:bg-gray-500 disabled:text-gray-200 flex-shrink-0"
        disabled={isStarting}
        onclick={handleStartGame}
      >
        {isStarting ? "Starting..." : "Start Game"}
      </button>
      <button
        class="bg-[#FF6EC7] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#ff8fd4] active:scale-95 disabled:bg-gray-500 disabled:text-gray-200 flex-shrink-0"
        disabled={isTerminating}
        onclick={() => (showTerminateModal = true)}
      >
        {isTerminating ? "End" : "Terminate"}
      </button>
    {:else if "active" in gameDetail.status}
      <button
        class="bg-[#F4E04D] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] active:scale-95 disabled:bg-gray-500 disabled:text-gray-200 flex-shrink-0"
        disabled={isDrawing}
        onclick={handleDrawCard}
      >
        {isDrawing ? "Drawing..." : "Draw Card"}
      </button>
      <button
        class="bg-white text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#C9B5E8] active:scale-95 disabled:bg-gray-500 disabled:text-gray-200 flex-shrink-0"
        disabled={isEnding}
        onclick={handleEndGame}
      >
        {isEnding ? "Ending..." : "End Game"}
      </button>
    {:else}
      <div
        class="bg-[#1a0033] border-2 border-black px-2 sm:px-3 py-2 text-xs font-bold text-white uppercase shadow-[3px_3px_0px_rgba(0,0,0,1)]"
      >
        Game completed
      </div>
    {/if}
  {/if}
  <button
    class="bg-[#C9B5E8] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0] active:scale-95 flex-shrink-0"
    onclick={() => refreshGame(true)}
  >
    Refresh
  </button>
  <div class="flex-shrink-0">
    <AudioToggle />
  </div>
</div>
            </div>
            {#if "completed" in gameDetail.status && winnerLabel}
              <div
                class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 sm:px-4 py-2 sm:py-3 font-black uppercase text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)]"
              >
                🏆 Winner: {winnerLabel}
              </div>
            {/if}
            
            <!-- Current Card and Info -->
            <div
              class="grid grid-cols-1 sm:grid-cols-[minmax(140px,180px),1fr] gap-3 sm:gap-4 items-start"
            >
              <div
                class="bg-[#1a0033] border-2 sm:border-4 border-black p-2 sm:p-3 shadow-[3px_3px_0_rgba(0,0,0,1)] sm:shadow-[4px_4px_0_rgba(0,0,0,1)] flex flex-col items-center gap-2"
              >
                {#if currentCardId}
                  <div
                    class="relative w-full overflow-hidden rounded-sm border-2 border-[#F4E04D] bg-[#0f0220]"
                    style="aspect-ratio:320/500;"
                  >
                    <img
                      src={cardImage(currentCardId)}
                      alt={`Current card ${currentCardId}`}
                      class="absolute inset-0 w-full h-full object-contain"
                      loading="lazy"
                      decoding="async"
                    />
                  </div>
                  <span class="text-xs font-black text-[#F4E04D] uppercase">
                    Current Card #{currentCardId}
                  </span>
                {:else}
                  <div
                    class="text-center text-[#C9B5E8] font-bold text-xs uppercase py-6 sm:py-8"
                  >
                    Waiting for first draw...
                  </div>
                {/if}
              </div>
              <div
                class="bg-[#1a0033] border-2 border-black px-3 sm:px-4 py-3 sm:py-4 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] text-white space-y-2"
              >
                <p class="text-xs font-bold uppercase">
                  Cards Drawn: {drawnCards.length} of {TOTAL_CARDS}
                </p>
                {#if lastDrawnCardId && lastDrawnCardId !== currentCardId}
                  <p class="text-xs font-bold uppercase text-[#F4E04D]">
                    Previous Card: #{lastDrawnCardId}
                  </p>
                {/if}
                <p class="text-xs font-bold uppercase break-all">
                  Prize Pool:{" "}
                  {formattedPotBalance}
                  &nbsp;{tokenSymbol(gameDetail.tokenType)}
                </p>
                <p class="text-xs font-bold uppercase">
                  Players currently playing: {gameDetail.playerCount}
                </p>
                <p class="text-xs font-bold uppercase text-[#C9B5E8]">
                  Share invite link anytime to bring more players in.
                </p>
              </div>
            </div>
          </div>
          
          <!-- Chat and Draw History -->
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)] w-full"
          >
            <GameChat gameId={gameDetail.id} />
            
            <div class="mt-4 sm:mt-6 mb-3 sm:mb-4">
              <span
                class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Draw History
              </span>
            </div>
              {#if drawnCards.length === 0}
    <div
      class="bg-[#1a0033] border-2 border-black text-center text-[#C9B5E8] font-bold uppercase text-xs py-4 sm:py-6 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
    >
      No cards have been drawn yet. Hit "Draw Next Card" to begin.
    </div>
  {:else}
    <!-- Add max-height and overflow for proper scrolling -->
    <div class="max-h-[400px] sm:max-h-[500px] overflow-y-auto overflow-x-hidden bg-[#1a0033] border-2 border-black p-2 sm:p-3 shadow-[3px_3px_0px_rgba(0,0,0,1)]">
      <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-2 sm:gap-3">
        {#each drawnCards as id}
          <div
            class={`relative bg-[#1a0033] border-2 border-black p-1 sm:p-2 shadow-[2px_2px_0_rgba(0,0,0,1)] sm:shadow-[3px_3px_0_rgba(0,0,0,1)] ${
              id === currentCardId ? "ring-2 sm:ring-4 ring-[#F4E04D]" : ""
            }`}
          >
            <div
              class="relative w-full overflow-hidden rounded-sm border border-[#C9B5E8] bg-[#0f0220]"
              style="aspect-ratio:320/500;"
            >
              <img
                        src={cardImage(id)}
                        alt={`Card ${id}`}
                        class="absolute inset-0 w-full h-full object-contain"
                        loading="lazy"
                        decoding="async"
                      />
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>
        </div>
      </div>
    </div>
  </div>
{/if}

<!-- Terminate Game Confirmation Modal -->
{#if showTerminateModal}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
    onclick={(e) => {
      if (e.target === e.currentTarget) showTerminateModal = false;
    }}
  >
    <div
      class="bg-gradient-to-b from-[#522785] to-[#3d1d63] border-2 sm:border-4 border-black p-4 sm:p-6 max-w-md w-full shadow-[4px_4px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
    >
      <div class="mb-3 sm:mb-4">
        <span
          class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
        >
          ⚠️ Warning
        </span>
      </div>
      <h3
        class="text-lg sm:text-xl font-black text-[#F4E04D] uppercase mb-3 sm:mb-4"
        style="text-shadow: 2px 2px 0px #000;"
      >
        Terminate Game?
      </h3>
      <div
        class="bg-[#1a0033] border-2 border-[#FF6EC7] p-3 sm:p-4 mb-4 sm:mb-6 shadow-[3px_3px_0px_rgba(0,0,0,1)]"
      >
        <p class="text-white text-xs sm:text-sm font-bold mb-2 sm:mb-3">This action will:</p>
        <ul class="text-[#C9B5E8] text-xs space-y-1 sm:space-y-2 list-disc list-inside">
          <li>Permanently delete this game</li>
          <li>Refund all players their entry fees (minus transaction fees)</li>
          <li>Cannot be undone</li>
        </ul>
      </div>
      <p class="text-white text-xs font-bold mb-4 sm:mb-6 text-center">
        Are you sure you want to terminate this game?
      </p>
      <div class="flex gap-2 sm:gap-3">
        <button
          class="flex-1 bg-[#C9B5E8] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 sm:py-3 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
          onclick={() => (showTerminateModal = false)}
        >
          Cancel
        </button>
        <button
          class="flex-1 bg-[#FF6EC7] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 sm:py-3 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#ff8fd4]"
          onclick={handleTerminateGame}
        >
          Yes, Terminate
        </button>
      </div>
    </div>
  </div>
{/if}
