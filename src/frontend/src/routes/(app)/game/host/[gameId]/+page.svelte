<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/state";
  import { goto } from "$app/navigation";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { TokenService } from "$lib/services/token-service";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import CardDrawAnimation from "$lib/components/shared/DrawAnimation.svelte";
  import GameChat from "$lib/components/routes/game/GameChat.svelte";
  import GameHeader from "$lib/components/routes/game/Header.svelte";
  import HostInfoPanel from "$lib/components/routes/game/HostInfo.svelte";
  import PlayerList from "$lib/components/routes/game/Players.svelte";
  import GameStatusInfo from "$lib/components/routes/game/Status.svelte";
  import CurrentCardDisplay from "$lib/components/routes/game/CurrentCard.svelte";
  import DrawHistoryGrid from "$lib/components/routes/game/DrawHistory.svelte";
  import HostControls from "$lib/components/routes/game/HostControls.svelte";
  import HostInviteSection from "$lib/components/routes/game/HostInvite.svelte";
  import TerminateModal from "$lib/components/routes/game/TerminateModal.svelte";
  import { getCardImage, TOTAL_CARDS } from "$lib/utils/helpers";
  import {
    type GameDetailData,
    shortPrincipal,
    profileName,
    playerName,
    REFRESH_INTERVAL,
  } from "$lib/utils/game-helper";

  const tokenService = new TokenService();
  const gameId = page.params.gameId ?? null;

  // State
  let gameDetail = $state<GameDetailData | null>(null);
  let isLoading = $state(true);
  let isStarting = $state(false);
  let isDrawing = $state(false);
  let isEnding = $state(false);
  let isTerminating = $state(false);
  let showTerminateModal = $state(false);
  let inviteLink = $state("");
  let errorMessage = $state("");
  let lastDrawnCardId = $state<number | null>(null);
  let showCardAnimation = $state(false);
  let potBalance = $state<bigint | null>(null);
  let pollHandle: ReturnType<typeof setInterval> | null = null;
  let fastPollHandle: ReturnType<typeof setInterval> | null = null;

  // Derived state
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

  // Enhanced polling when game completes but winner not yet set
  $effect(() => {
    if (isGameCompleted && !winnerPrincipal) {
      if (!fastPollHandle) {
        let attempts = 0;
        fastPollHandle = setInterval(async () => {
          attempts++;
          await refreshGame(false);
          if (attempts >= 20 || winnerPrincipal) {
            if (fastPollHandle) {
              clearInterval(fastPollHandle);
              fastPollHandle = null;
            }
          }
        }, 500);
      }
    } else if (fastPollHandle && (winnerPrincipal || !isGameCompleted)) {
      clearInterval(fastPollHandle);
      fastPollHandle = null;
    }
  });

  const isLobbyStatus = $derived(!!gameDetail && "lobby" in gameDetail.status);
  const viewerPrincipal = $derived(
    $authStore.identity ? $authStore.identity.getPrincipal().toText() : null,
  );
  const isGameActive = $derived(!!gameDetail && "active" in gameDetail.status);
  const isGameCompleted = $derived(!!gameDetail && "completed" in gameDetail.status);
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
    gameDetail ? Array.from(gameDetail.drawnCards, (card) => Number(card)) : [],
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

  // Functions
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
    // Music disabled
    // startMenuMusic("/sounds/menu_music.wav", true);
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
  cardImage={currentCardId ? getCardImage(currentCardId) : ""}
  show={showCardAnimation}
  isHost={isHostViewer}
  hasCardOnTabla={false}
  onClose={() => (showCardAnimation = false)}
/>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if errorMessage && !gameDetail}
  <div class="min-h-screen bg-[#1a0033] flex items-center justify-center p-4">
    <div class="arcade-panel p-6 sm:p-10 text-center max-w-md w-full">
      <h1 class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase mb-4 arcade-text-shadow">
        Game Not Found
      </h1>
      <p class="text-white font-bold mb-6 text-sm sm:text-base">{errorMessage}</p>
      <button
        class="arcade-button px-4 sm:px-6 py-2 sm:py-3 text-sm sm:text-base"
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
      <GameHeader
        gameId={gameDetail.id}
        backLabel="Back to Lobby"
        backPath="/dashboard"
      />

      {#if errorMessage}
        <div class="bg-[#FF6EC7] border-2 sm:border-4 border-black text-[#1a0033] font-bold uppercase text-xs sm:text-sm px-3 sm:px-4 py-2 sm:py-3 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]">
          {errorMessage}
        </div>
      {/if}

      <div class="grid grid-cols-1 lg:grid-cols-[minmax(280px,380px),1fr] gap-4 sm:gap-6">
        <aside class="space-y-4 sm:space-y-6 w-full">
          <HostInfoPanel {gameDetail} {potBalance} {winnerLabel} />
          <PlayerList players={playersStats} {playerName} />
          {#if isHostViewer && isLobbyStatus}
            <HostInviteSection {inviteLink} />
          {/if}
        </aside>

        <main class="space-y-4 sm:space-y-6 w-full min-w-0">
          <div class="arcade-panel p-4 sm:p-6 space-y-4 sm:space-y-6">
            <GameStatusInfo
              {gameDetail}
              {potBalance}
              {lastDrawnCardId}
              {currentCardId}
              {remainingCards}
              totalCards={TOTAL_CARDS}
              onRefresh={() => refreshGame(true)}
            >
              {#snippet children()}
                {#if isHostViewer && gameDetail}
                  <HostControls
                    status={gameDetail.status}
                    {isStarting}
                    {isDrawing}
                    {isEnding}
                    {isTerminating}
                    onStart={handleStartGame}
                    onDraw={handleDrawCard}
                    onEnd={handleEndGame}
                    onTerminate={() => (showTerminateModal = true)}
                  />
                {/if}
              {/snippet}
            </GameStatusInfo>

            {#if "completed" in gameDetail.status && winnerLabel}
              <div class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 sm:px-4 py-2 sm:py-3 font-black uppercase text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)]">
                🏆 Winner: {winnerLabel}
              </div>
            {/if}

            <CurrentCardDisplay
              cardId={currentCardId}
              cardImage={currentCardId ? getCardImage(currentCardId) : ""}
            />
          </div>

          <div class="arcade-panel p-4 sm:p-6">
            <GameChat gameId={gameDetail.id} />
          </div>

          <DrawHistoryGrid
            {drawnCards}
            currentCardId={currentCardId}
            getCardImage={getCardImage}
          />
        </main>
      </div>
    </div>
  </div>
{/if}

<TerminateModal
  show={showTerminateModal}
  {isTerminating}
  onConfirm={handleTerminateGame}
  onCancel={() => (showTerminateModal = false)}
/>