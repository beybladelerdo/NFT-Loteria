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
  <div class="min-h-screen bg-[#1a0033] flex items-center justify-center px-6">
    <div
      class="bg-gradient-to-b from-[#522785] to-[#3d1d63] border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] p-10 text-center max-w-md"
    >
      <h1 class="text-3xl font-black text-[#F4E04D] uppercase mb-4">
        Game Not Found
      </h1>
      <p class="text-white font-bold mb-6">{errorMessage}</p>
      <button
        class="bg-[#F4E04D] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#fff27d] transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)]"
        onclick={() => goto("/dashboard")}
      >
        ◄ Back to Dashboard
      </button>
    </div>
  </div>
{:else if gameDetail}
  <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
    <FlickeringGrid
      class="absolute inset-0 opacity-20"
      squareSize={4}
      gridGap={6}
      color="rgba(196, 154, 250, 0.5)"
    />
    <div class="relative z-10 max-w-6xl mx-auto px-4 py-8 space-y-6">
      <div
        class="flex flex-col md:flex-row md:items-center md:justify-between gap-4"
      >
        <button
          onclick={() => goto("/dashboard")}
          class="inline-flex items-center justify-center gap-2 bg-[#C9B5E8] text-[#1a0033] px-5 py-3 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] transition-all text-sm shadow-[4px_4px_0px_rgba(0,0,0,1)] w-full md:w-auto"
        >
          ◄ Back to Lobby
        </button>
        <div class="text-left md:text-right">
          <p
            class="text-[#F4E04D] font-black text-xs uppercase tracking-[0.4em]"
          >
            Lobby Code
          </p>
          <p
            class="text-3xl font-black text-white mt-1"
            style="text-shadow: 3px 3px 0px #000;"
          >
            {gameDetail.id}
          </p>
        </div>
      </div>

      {#if errorMessage}
        <div
          class="bg-[#FF6EC7] border-4 border-black text-[#1a0033] font-bold uppercase text-sm px-4 py-3 shadow-[4px_4px_0px_rgba(0,0,0,1)]"
        >
          {errorMessage}
        </div>
      {/if}

      <div class="grid lg:grid-cols-[320px,1fr] gap-6">
        <div class="space-y-6">
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
          >
            <div class="mb-4">
              <span
                class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Lobby Info
              </span>
            </div>
            <h2
              class="text-2xl font-black text-[#F4E04D] uppercase mb-6"
              style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
            >
              Host Control Center
            </h2>
            <div class="space-y-3 text-sm font-bold text-white uppercase">
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Host</span>
                <span class="text-right text-[#F4E04D]">
                  {profileName(gameDetail.host)}
                </span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Mode</span>
                <span class="text-right">{modeLabel(gameDetail.mode)}</span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Status</span>
                <span class="text-right">{statusLabel(gameDetail.status)}</span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Players</span>
                <span class="text-right">
                  {gameDetail.playerCount} / {gameDetail.maxPlayers}
                </span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Entry Fee</span>
                <span class="text-right">
                  {tokenService.formatBalance(gameDetail.entryFee, 8)}
                  &nbsp;{tokenSymbol(gameDetail.tokenType)}
                </span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Host Fee</span>
                <span class="text-right">{gameDetail.hostFeePercent}%</span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Prize Pool</span>
                <span class="text-right">
                  {formattedPotBalance}
                  &nbsp;{tokenSymbol(gameDetail.tokenType)}
                </span>
              </div>
              <div class="flex justify-between gap-4">
                <span class="text-[#C9B5E8]">Winner</span>
                <span class="text-right text-[#F4E04D]">
                  {#if winnerLabel}
                    {winnerLabel}
                  {:else}
                    TBD
                  {/if}
                </span>
              </div>
            </div>
          </div>

          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
          >
            <div class="mb-4 flex items-center justify-between">
              <span
                class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Players
              </span>
              <span class="text-xs text-white font-bold">
                {playersStats.length} joined
              </span>
            </div>

            {#if playersStats.length === 0}
              <div
                class="bg-[#1a0033] border-2 border-black text-center text-[#C9B5E8] font-bold uppercase text-xs py-6 shadow-[4px_4px_0px_rgba(0,0,0,1)]"
              >
                No players have joined yet.
              </div>
            {:else}
              <div class="space-y-3">
                {#each playersStats as stat}
                  <div
                    class="bg-[#1a0033] border-2 border-black px-3 py-3 shadow-[4px_4px_0px_rgba(0,0,0,1)] flex items-center justify-between gap-4"
                  >
                    <div>
                      <p class="text-white font-black text-sm uppercase">
                        {playerName(stat.player)}
                      </p>
                      <p class="text-xs text-[#C9B5E8] font-bold">
                        Tablas: {stat.tablas} · Marks: {stat.marks}
                      </p>
                    </div>
                    <span
                      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-1 text-xs font-black uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                    >
                      #{shortPrincipal(stat.player.principal.toText())}
                    </span>
                  </div>
                {/each}
              </div>
            {/if}
          </div>

          {#if isHostViewer}
            {#if isLobbyStatus}
              <div
                class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
              >
                <div class="mb-4">
                  <span
                    class="bg-white text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                  >
                    Invite Players
                  </span>
                </div>
                <p
                  class="text-xs font-bold text-white uppercase mb-4 leading-relaxed"
                >
                  Share your invite link below or use the quick invite tool to
                  search by username. Inviting players is optional—you can
                  always come back later once the lobby is ready.
                </p>
                <div
                  class="bg-[#1a0033] border-2 border-black px-3 py-3 shadow-[3px_3px_0px_rgba(0,0,0,1)] space-y-3"
                >
                  <div class="flex items-center gap-2">
                    <input
                      class="flex-1 bg-[#1a0033] border-2 border-black text-white text-xs font-mono px-2 py-2"
                      readonly
                      value={inviteLink}
                    />
                    <button
                      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d]"
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

        <div class="space-y-6">
          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] space-y-6"
          >
            <div
              class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4"
            >
              <div>
                <span
                  class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                >
                  Game Status
                </span>
                <p
                  class="text-2xl font-black text-[#F4E04D] uppercase mt-3"
                  style="text-shadow: 3px 3px 0px #000;"
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
                      class="bg-[#F4E04D] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] disabled:bg-gray-500 disabled:text-gray-200"
                      disabled={isStarting}
                      onclick={handleStartGame}
                    >
                      {isStarting ? "Starting..." : "Start Game"}
                    </button>
                  {:else if "active" in gameDetail.status}
                    <button
                      class="bg-[#F4E04D] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] disabled:bg-gray-500 disabled:text-gray-200"
                      disabled={isDrawing}
                      onclick={handleDrawCard}
                    >
                      {isDrawing ? "Drawing..." : "Draw Next Card"}
                    </button>
                    <button
                      class="bg-white text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#C9B5E8] disabled:bg-gray-500 disabled:text-gray-200"
                      disabled={isEnding}
                      onclick={handleEndGame}
                    >
                      {isEnding ? "Ending..." : "End Game"}
                    </button>
                  {:else}
                    <div
                      class="bg-[#1a0033] border-2 border-black px-3 py-2 text-xs font-bold text-white uppercase shadow-[3px_3px_0px_rgba(0,0,0,1)]"
                    >
                      Game completed. Awaiting next lobby.
                    </div>
                  {/if}
                {/if}
                <button
                  class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
                  onclick={() => refreshGame(true)}
                >
                  Refresh
                </button>
                <AudioToggle />
              </div>
            </div>

            {#if "completed" in gameDetail.status && winnerLabel}
              <div
                class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-4 py-3 font-black uppercase text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)]"
              >
                🏆 Winner: {winnerLabel}
              </div>
            {/if}

            <div
              class="grid grid-cols-1 md:grid-cols-[180px,1fr] gap-4 items-start"
            >
              <div
                class="bg-[#1a0033] border-4 border-black p-3 shadow-[4px_4px_0_rgba(0,0,0,1)] flex flex-col items-center gap-2"
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
                    class="text-center text-[#C9B5E8] font-bold text-xs uppercase py-8"
                  >
                    Waiting for first draw...
                  </div>
                {/if}
              </div>

              <div
                class="bg-[#1a0033] border-2 border-black px-4 py-4 shadow-[4px_4px_0px_rgba(0,0,0,1)] text-white space-y-2"
              >
                <p class="text-xs font-bold uppercase">
                  Cards Drawn: {drawnCards.length} of {TOTAL_CARDS}
                </p>
                {#if lastDrawnCardId && lastDrawnCardId !== currentCardId}
                  <p class="text-xs font-bold uppercase text-[#F4E04D]">
                    Previous Card: #{lastDrawnCardId}
                  </p>
                {/if}
                <p class="text-xs font-bold uppercase">
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

          <div
            class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
          >
            <div class="mb-4">
              <span
                class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                Draw History
              </span>
            </div>
            {#if drawnCards.length === 0}
              <div
                class="bg-[#1a0033] border-2 border-black text-center text-[#C9B5E8] font-bold uppercase text-xs py-6 shadow-[4px_4px_0px_rgba(0,0,0,1)]"
              >
                No cards have been drawn yet. Hit “Draw Next Card” to begin.
              </div>
            {:else}
              <div class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-6 gap-3">
                {#each drawnCards as id}
                  <div
                    class={`relative bg-[#1a0033] border-2 border-black p-2 shadow-[4px_4px_0_rgba(0,0,0,1)] ${
                      id === currentCardId ? "ring-4 ring-[#F4E04D]" : ""
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
            {/if}
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}
