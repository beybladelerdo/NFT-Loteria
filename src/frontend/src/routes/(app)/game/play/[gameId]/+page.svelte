<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/state";
  import { goto } from "$app/navigation";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { type Rarity, GameService } from "$lib/services/game-service";
  import { TokenService } from "$lib/services/token-service";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import CardDrawAnimation from "$lib/components/shared/DrawAnimation.svelte";
  import GameChat from "$lib/components/routes/game/GameChat.svelte";
  import GameHeader from "$lib/components/routes/game/Header.svelte";
  import PlayerStatusPanel from "$lib/components/routes/game/PlayerStatus.svelte";
  import PlayerList from "$lib/components/routes/game/Players.svelte";
  import GameStatusInfo from "$lib/components/routes/game/Status.svelte";
  import CurrentCardDisplay from "$lib/components/routes/game/CurrentCard.svelte";
  import TablaCard from "$lib/components/routes/game/Card.svelte";
  import TablaNav from "$lib/components/routes/game/TablaNav.svelte";
  import LeaveGame from "$lib/components/routes/game/LeaveGame.svelte";
  import DrawHistoryGrid from "$lib/components/routes/game/DrawHistory.svelte";
  import WinModal from "$lib/components/routes/game/WinModal.svelte";
  import ShareInvitePanel from "$lib/components/routes/game/ShareInvite.svelte";
  import { getCardImage, TOTAL_CARDS } from "$lib/utils/helpers";
  import {
    type GameDetailData,
    type TablaInGame,
    shortPrincipal,
    profileName,
    playerName,
    REFRESH_INTERVAL,
  } from "$lib/utils/game-helper";

  const tokenService = new TokenService();
  const gameService = new GameService();
  const gameId = page.params.gameId ?? null;

  // Rarity tracking
  const rarityById = $state<Record<number, Rarity>>({});
  const rarityProm: Record<number, Promise<void>> = {};

  async function ensureRarities(ids: number[]) {
    const toFetch = ids.filter((id) => !rarityById[id] && !rarityProm[id]);
    for (const id of toFetch) {
      rarityProm[id] = (async () => {
        try {
          const info = await gameService.getTabla(Number(id));
          rarityById[id] =
            (info?.rarity as Rarity) ?? ({ common: null } as const);
        } catch {
          rarityById[id] = { common: null };
        } finally {
          delete rarityProm[id];
        }
      })();
    }
    await Promise.all(Object.values(rarityProm));
  }

  // State
  let gameDetail = $state<GameDetailData | null>(null);
  let isLoading = $state(true);
  let isMarking = $state(false);
  let claimingTablaId = $state<number | null>(null);
  let inviteLink = $state("");
  let errorMessage = $state("");
  let gameTerminated = $state(false);
  let isLeaving = $state(false);
  let showLeavingModal = $state(false);
  let potBalance = $state<bigint | null>(null);
  let pollHandle: ReturnType<typeof setInterval> | null = null;
  let showCardAnimation = $state(false);
  let currentTablaIndex = $state(0);
  let showWinModal = $state(false);
  let winAmount = $state<bigint | null>(null);
  let lastAnnouncedWinner = $state<string | null>(null);
  let locallyClaimedWin = $state(false);
  let preClaimPotBalance = $state<bigint | null>(null);

  // Derived state
  $effect(() => {
    if (!gameDetail?.id || !$authStore.identity) return;
    tokenService
      .getPotBalance(gameDetail.id, gameDetail.tokenType, $authStore.identity)
      .then((result) => {
        potBalance = result.amountBaseUnits;
      })
      .catch(() => {
        potBalance = null;
      });
  });

  $effect(() => {
    const ids = (playerSummary()?.tablas ?? []).map((t) => Number(t.tablaId));
    if (ids.length) void ensureRarities(ids);
  });

  $effect(() => {
    if (winnerPrincipal && winnerPrincipal !== lastAnnouncedWinner) {
      if (!isWinner && winnerLabel) {
        addToast({
          message: `🏆 Player ${winnerLabel} got bingo!`,
          type: "success",
          duration: 4000,
        });
      }
      lastAnnouncedWinner = winnerPrincipal;
    }
  });

  const isLobbyStatus = $derived(!!gameDetail && "lobby" in gameDetail.status);
  const viewerPrincipal = $derived(
    $authStore.identity ? $authStore.identity.getPrincipal().toText() : null,
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
    gameDetail ? Array.from(gameDetail.drawnCards, (card) => Number(card)) : [],
  );
  const drawnSet = $derived(new Set(drawnCards));
  const remainingCards = $derived(TOTAL_CARDS - drawnCards.length);
  const lastDrawnCardId = $derived(
    drawnCards.length > 0 ? drawnCards[drawnCards.length - 1] : null,
  );

  const playerSummary = $derived(() => {
    if (!gameDetail || !viewerPrincipal) return null;
    return (
      gameDetail.players.find(
        (p) => p.principal.toText() === viewerPrincipal,
      ) ?? null
    );
  });

  const playerMarksSet = $derived.by(() => {
    const set = new Set<string>();
    if (!gameDetail || !viewerPrincipal) return set;
    for (const marca of gameDetail.marks) {
      if (marca.playerId.toText() === viewerPrincipal) {
        const key = `${marca.tablaId}:${Number(marca.position.row)}:${Number(
          marca.position.col,
        )}`;
        set.add(key);
      }
    }
    return set;
  });

  const yourMarks = $derived(playerMarksSet.size);

  const marksByTabla = $derived.by(() => {
    const map = new Map<number, number>();
    if (!gameDetail || !viewerPrincipal) return map;
    for (const marca of gameDetail.marks) {
      if (marca.playerId.toText() === viewerPrincipal) {
        const id = Number(marca.tablaId);
        map.set(id, (map.get(id) ?? 0) + 1);
      }
    }
    return map;
  });

  const playersStats = $derived.by(() => {
    if (!gameDetail) return [];
    const markCounts = new Map<string, number>();
    for (const marca of gameDetail.marks) {
      const key = marca.playerId.toText();
      markCounts.set(key, (markCounts.get(key) ?? 0) + 1);
    }
    return [...gameDetail.players]
      .sort((a, b) => playerName(a).localeCompare(playerName(b)))
      .map((player) => {
        const key = player.principal.toText();
        return {
          player,
          marks: markCounts.get(key) ?? 0,
          tablas: player.tablas.length,
        };
      });
  });

  const otherPlayersStats = $derived.by(() =>
    playerSummary()
      ? playersStats.filter(
          (stat) => stat.player.principal !== playerSummary()!.principal,
        )
      : playersStats,
  );

  const winnerPrincipal = $derived(
    gameDetail && gameDetail.winner.length > 0
      ? gameDetail.winner[0]?.toText()
      : null,
  );

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

  const isWinner = $derived(
    !!winnerPrincipal &&
      !!viewerPrincipal &&
      winnerPrincipal === viewerPrincipal,
  );

  const isGameActive = $derived(!!gameDetail && "active" in gameDetail.status);
  const isGameCompleted = $derived(
    !!gameDetail && "completed" in gameDetail.status,
  );
  const hasCurrentCardOnTabla = $derived.by(() => {
    if (!currentCardId || !playerSummary()) return false;
    const summary = playerSummary();
    if (!summary) return false;
    for (const tabla of summary.tablas) {
      for (const card of tabla.cards) {
        if (Number(card) === currentCardId) return true;
      }
    }
    return false;
  });

  const currentTabla = $derived.by(() => {
    const tablas = playerSummary()?.tablas ?? [];
    return tablas[currentTablaIndex] ?? null;
  });

  const totalTablas = $derived(playerSummary()?.tablas?.length ?? 0);
  const shouldShowWinModal = $derived(
    showWinModal && (locallyClaimedWin || isWinner),
  );
  const potDisbursed = $derived(
    isGameCompleted &&
      preClaimPotBalance !== null &&
      potBalance !== null &&
      potBalance === 0n,
  );

  // Functions
  function tablaGrid(tabla: TablaInGame) {
    const tiles: Array<{
      row: number;
      col: number;
      cardId: number;
      image: string;
      isDrawn: boolean;
      isMarked: boolean;
    }> = [];
    for (let i = 0; i < tabla.cards.length; i += 1) {
      const cardId = Number(tabla.cards[i]);
      const row = Math.floor(i / 4);
      const col = i % 4;
      const key = `${tabla.tablaId}:${row}:${col}`;
      tiles.push({
        row,
        col,
        cardId,
        image: getCardImage(cardId),
        isDrawn: drawnSet.has(cardId),
        isMarked: playerMarksSet.has(key),
      });
    }
    return tiles;
  }

  async function refreshGame(showSpinner = false) {
    if (!gameId) {
      errorMessage = "Missing game id.";
      return;
    }

    if (showSpinner) isLoading = true;
    try {
      const { detail } = await gameStore.fetchGameById(gameId);

      if (!detail) {
        if (!gameTerminated) {
          gameTerminated = true;
          if (pollHandle) {
            clearInterval(pollHandle);
            pollHandle = null;
          }
          addToast({
            message:
              "This game has been terminated by the host. Your entry fee has been refunded (minus transaction fees).",
            type: "info",
            duration: 5000,
          });
          setTimeout(() => {
            goto("/dashboard");
          }, 3000);
        }
        errorMessage = "Game was terminated.";
        gameDetail = null;
        return;
      }

      gameDetail = detail;
      errorMessage = "";
    } catch (err) {
      errorMessage = "Failed to load game detail.";
    } finally {
      if (showSpinner) isLoading = false;
    }
  }
  async function handleLeaveGame() {
    if (!gameId) return;
    showLeavingModal = false;
    isLeaving = true;

    const result = await gameStore.leaveGame(gameId);
    if (result.success) {
      addToast({
        message: "Existed game successfully. Redirecting...",
        type: "success",
        duration: 3000,
      });
      setTimeout(() => {
        goto("/dashboard");
      }, 1500);
    } else {
      addToast({
        message: result.error || "Failed to leave game.",
        type: "error",
        duration: 3000,
      });
      isLeaving = false;
    }
  }

  async function handleMark(
    tablaId: number,
    cell: {
      row: number;
      col: number;
      cardId: number;
      isDrawn: boolean;
      isMarked: boolean;
    },
  ) {
    if (!gameId || !playerSummary()) return;
    if (!isGameActive) {
      addToast({
        message: "The game needs to be active to mark cards.",
        type: "error",
        duration: 2500,
      });
      return;
    }
    if (!cell.isDrawn) {
      addToast({
        message: "You can only mark cards that have been drawn.",
        type: "error",
        duration: 2500,
      });
      return;
    }
    if (cell.isMarked || isMarking) return;

    isMarking = true;
    const result = await gameStore.markPosition(gameId, tablaId, {
      row: cell.row,
      col: cell.col,
    });
    if (result.success) {
      addToast({
        message: `Marked card #${cell.cardId}!`,
        type: "success",
        duration: 2000,
      });
      await refreshGame(false);
    } else {
      addToast({
        message: result.error ?? "Failed to mark card.",
        type: "error",
        duration: 3000,
      });
    }
    isMarking = false;
  }

  async function handleClaimWin(tablaId: number) {
    if (!gameId || !playerSummary()) return;
    if (!isGameActive) {
      addToast({
        message: "You can only claim a win while the game is active.",
        type: "error",
        duration: 2500,
      });
      return;
    }
    claimingTablaId = tablaId;
    const preClaimPot = potBalance;
    const result = await gameStore.claimWin(gameId, tablaId);
    if (result.success) {
      addToast({
        message: "Win claim submitted! Verifying…",
        type: "success",
        duration: 2500,
      });
      winAmount = preClaimPot ?? null;
      preClaimPotBalance = preClaimPot;
      locallyClaimedWin = true;
      showWinModal = true;

      let pollAttempts = 0;
      const maxAttempts = 20;
      const pollForWinner = async () => {
        await refreshGame(false);
        pollAttempts++;
        if (gameDetail?.winner && gameDetail.winner.length > 0) return;
        if (pollAttempts < maxAttempts) {
          setTimeout(pollForWinner, 500);
        }
      };
      await pollForWinner();
    } else {
      addToast({
        message: result.error ?? "Win claim failed.",
        type: "error",
        duration: 3000,
      });
    }
    claimingTablaId = null;
  }

  function goToNextTabla() {
    if (currentTablaIndex < totalTablas - 1) currentTablaIndex++;
  }

  function goToPreviousTabla() {
    if (currentTablaIndex > 0) currentTablaIndex--;
  }

  onMount(() => {
    // Music disabled
    // startMenuMusic("/sounds/menu_music.wav", true);
    (async () => {
      try {
        await authStore.sync();
      } catch {}
      if (typeof window !== "undefined" && gameId) {
        inviteLink = `${window.location.origin}/join-game?gameId=${gameId}`;
      }
      await refreshGame(true);
      pollHandle = setInterval(() => refreshGame(false), REFRESH_INTERVAL);
    })();
  });

  onDestroy(() => {
    if (pollHandle) clearInterval(pollHandle);
  });
</script>

<CardDrawAnimation
  cardId={currentCardId}
  cardImage={currentCardId ? getCardImage(currentCardId) : ""}
  show={showCardAnimation}
  isHost={isHostViewer}
  hasCardOnTabla={hasCurrentCardOnTabla}
  onClose={() => (showCardAnimation = false)}
/>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if errorMessage && !gameDetail}
  <div class="min-h-screen bg-[#1a0033] flex items-center justify-center p-4">
    <div class="arcade-panel p-6 sm:p-10 text-center max-w-md w-full">
      {#if gameTerminated}
        <h1
          class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase mb-4 arcade-text-shadow"
        >
          Game Terminated
        </h1>
        <p class="text-white font-bold mb-6 text-sm sm:text-base">
          The host has terminated this game. Your entry fee has been refunded
          (minus transaction fees).
        </p>
      {:else}
        <h1
          class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase mb-4 arcade-text-shadow"
        >
          Game Not Found
        </h1>
        <p class="text-white font-bold mb-6 text-sm sm:text-base">
          {errorMessage}
        </p>
      {/if}
      <button
        class="arcade-button px-4 sm:px-6 py-2 sm:py-3 text-sm sm:text-base"
        onclick={() => goto("/dashboard")}
      >
        ◄ Back to Dashboard
      </button>
    </div>
  </div>
{:else if gameDetail}
  {#if !playerSummary()}
    <div class="min-h-screen bg-[#1a0033] flex items-center justify-center p-4">
      <div
        class="arcade-panel p-6 sm:p-10 text-center max-w-md w-full space-y-4"
      >
        {#if isHostViewer}
          <h1
            class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase arcade-text-shadow"
          >
            You're Hosting This Lobby
          </h1>
          <p class="text-white font-bold text-sm sm:text-base">
            Use the host dashboard to draw cards and manage the lobby.
          </p>
          <button
            class="arcade-button px-4 sm:px-6 py-2 sm:py-3 text-sm sm:text-base"
            onclick={() => goto(`/game/host/${gameDetail?.id}`)}
          >
            Go to Host View
          </button>
        {:else}
          <h1
            class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase arcade-text-shadow"
          >
            Join the Game
          </h1>
          <p class="text-white font-bold text-sm sm:text-base">
            You haven't joined this lobby yet. Pick a tabla and pay the entry
            fee to play.
          </p>
          <div
            class="flex flex-col sm:flex-row items-stretch sm:items-center justify-center gap-3"
          >
            <button
              class="bg-[#C9B5E8] text-[#1a0033] border-2 sm:border-4 border-black px-4 sm:px-6 py-2 sm:py-3 font-black uppercase text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0] active:scale-95"
              onclick={() => goto("/join-game")}
            >
              Browse Games
            </button>
            <button
              class="arcade-button px-4 sm:px-6 py-2 sm:py-3 text-xs sm:text-sm"
              onclick={() => goto(`/join-game?gameId=${gameDetail?.id}`)}
            >
              Join This Lobby
            </button>
          </div>
        {/if}
      </div>
    </div>
  {:else}
    <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
      <FlickeringGrid
        class="absolute inset-0 opacity-20 pointer-events-none"
        squareSize={4}
        gridGap={6}
        color="rgba(196, 154, 250, 0.5)"
      />
      <div
        class="relative z-10 w-full mx-auto px-4 py-6 sm:py-8 space-y-4 sm:space-y-6 max-w-7xl"
      >
        <GameHeader
          gameId={gameDetail.id}
          backLabel="Back to Games"
          backPath="/join-game"
        />

        {#if errorMessage}
          <div
            class="bg-[#FF6EC7] border-2 sm:border-4 border-black text-[#1a0033] font-bold uppercase text-xs sm:text-sm px-3 sm:px-4 py-2 sm:py-3 shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
          >
            {errorMessage}
          </div>
        {/if}

        {#if isWinner}
          <div
            class="bg-[#F4E04D] text-[#1a0033] border-2 sm:border-4 border-black font-bold uppercase text-xs sm:text-sm px-3 sm:px-4 py-2 sm:py-3 text-center shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
          >
            🎉 Congratulations! You are the winner of this game!
          </div>
        {:else if winnerLabel}
          <div
            class="bg-[#C9B5E8] text-[#1a0033] border-2 sm:border-4 border-black font-bold uppercase text-xs sm:text-sm px-3 sm:px-4 py-2 sm:py-3 text-center shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
          >
            🏆 Winner: {winnerLabel}
          </div>
        {/if}

        <div
          class="grid grid-cols-1 lg:grid-cols-[minmax(280px,380px),1fr] gap-4 sm:gap-6"
        >
          <aside class="space-y-4 sm:space-y-6 w-full">
            <PlayerStatusPanel
              {gameDetail}
              player={playerSummary()!}
              {yourMarks}
              {potBalance}
              {potDisbursed}
            />
            <PlayerList players={otherPlayersStats} {playerName} />
            {#if isLobbyStatus}
              <ShareInvitePanel {inviteLink} />
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
                {potDisbursed}
                onRefresh={() => refreshGame(true)}
                onLeave={() => (showLeavingModal = true)}
                {isLeaving}
              />

              <div class="flex justify-center">
                <CurrentCardDisplay
                  cardId={currentCardId}
                  cardImage={currentCardId ? getCardImage(currentCardId) : ""}
                />
              </div>
            </div>

            {#if totalTablas > 1}
              <TablaNav
                currentIndex={currentTablaIndex}
                {totalTablas}
                onPrevious={goToPreviousTabla}
                onNext={goToNextTabla}
              />
            {/if}

            {#if currentTabla}
              <TablaCard
                tabla={currentTabla}
                rarity={rarityById[currentTabla.tablaId] ??
                  ({ common: null } as const)}
                tablaGrid={tablaGrid(currentTabla)}
                marksOnTabla={marksByTabla.get(currentTabla.tablaId) ?? 0}
                {isGameActive}
                {isMarking}
                isClaiming={claimingTablaId === currentTabla.tablaId}
                onMark={(cell) => handleMark(currentTabla.tablaId, cell)}
                onClaim={() => handleClaimWin(currentTabla.tablaId)}
              />
            {/if}

            <div class="arcade-panel p-4 sm:p-6">
              <GameChat gameId={gameDetail.id} />
            </div>

            <DrawHistoryGrid {drawnCards} {currentCardId} {getCardImage} />
          </main>
        </div>
      </div>
    </div>
  {/if}
{/if}

<LeaveGame
  show={showLeavingModal}
  {isLeaving}
  onConfirm={handleLeaveGame}
  onCancel={() => (showLeavingModal = false)}
/>

<WinModal
  show={shouldShowWinModal}
  potBalance={preClaimPotBalance ?? potBalance}
  tokenType={gameDetail?.tokenType}
  hostFeePercent={Number(gameDetail?.hostFeePercent) ?? 0}
  onClose={() => {
    showWinModal = false;
    locallyClaimedWin = false;
  }}
/>
