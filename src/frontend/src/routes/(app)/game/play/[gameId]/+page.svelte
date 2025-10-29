<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/stores";
  import { goto } from "$app/navigation";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import { cardImages } from "$lib/data/gallery";
  import type { GameService } from "$lib/services/game-service";

  type GameDetailData = NonNullable<
    Awaited<ReturnType<GameService["getGameDetail"]>>
  >;
  type PlayerSummary = GameDetailData["players"][number];
  type TablaInGame = PlayerSummary["tablas"][number];

  const REFRESH_INTERVAL = 5000;
  const TOTAL_CARDS = 54;

  const gameId = $derived($page.params.gameId);

  const unwrapOpt = <T,>(opt: [] | [T]): T | null =>
    opt.length ? opt[0] : null;

  const shortPrincipal = (text: string) =>
    text.length > 9 ? `${text.slice(0, 5)}…${text.slice(-4)}` : text;

  const modeLabel = (mode?: GameDetailData["mode"]) => {
    if (!mode) return "Unknown";
    if ("line" in mode) return "Line";
    if ("blackout" in mode) return "Blackout";
    return "Unknown";
  };

  const statusLabel = (status?: GameDetailData["status"]) => {
    if (!status) return "Unknown";
    if ("lobby" in status) return "Lobby";
    if ("active" in status) return "Active";
    if ("completed" in status) return "Completed";
    return "Unknown";
  };

  const tokenSymbol = (token?: GameDetailData["tokenType"]) => {
    if (!token) return "-";
    if ("ICP" in token) return "ICP";
    if ("ckBTC" in token) return "ckBTC";
    if ("gldt" in token) return "GLDT";
    return "-";
  };

  const tokenDecimals = (token?: GameDetailData["tokenType"]) => {
    if (!token) return 8;
    if ("ICP" in token) return 8;
    if ("ckBTC" in token) return 8;
    if ("gldt" in token) return 8;
    return 8;
  };

  const formatAmount = (
    amount: bigint,
    token?: GameDetailData["tokenType"],
  ) => {
    const decimals = tokenDecimals(token);
    const divisor = 10 ** decimals;
    const value = Number(amount) / divisor;
    if (Number.isNaN(value)) return amount.toString();
    return value.toLocaleString(undefined, {
      minimumFractionDigits: 0,
      maximumFractionDigits: 4,
    });
  };

  const cardImage = (cardId: number | null) => {
    if (!cardId) return "/cards/placeholder.png";
    return (
      cardImages[cardId - 1] ??
      (cardImages.length > 0 ? cardImages[cardImages.length - 1] : "")
    );
  };

  const profileName = (profile?: GameDetailData["host"]) => {
    if (!profile) return "Unknown";
    const username = unwrapOpt(profile.username);
    return username ?? shortPrincipal(profile.principal.toText());
  };

  const playerName = (player: PlayerSummary) => {
    const username = unwrapOpt(player.username);
    return username ?? shortPrincipal(player.principal.toText());
  };

  let gameDetail = $state<GameDetailData | null>(null);
  let isLoading = $state(true);
  let isMarking = $state(false);
  let claimingTablaId = $state<number | null>(null);
  let inviteLink = $state("");
  let errorMessage = $state("");
  let pollHandle: ReturnType<typeof setInterval> | null = null;

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
    gameDetail ? gameDetail.drawnCards.map((card) => Number(card)) : [],
  );

const drawnSet = $derived(new Set(drawnCards));

  const remainingCards = $derived(TOTAL_CARDS - drawnCards.length);

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

  const lastDrawnCardId = $derived(
    drawnCards.length > 0 ? drawnCards[drawnCards.length - 1] : null,
  );

  const tablaGrid = (tabla: TablaInGame) => {
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
        image: cardImage(cardId),
        isDrawn: drawnSet.has(cardId),
        isMarked: playerMarksSet.has(key),
      });
    }
    return tiles;
  };

  async function refreshGame(showSpinner = false) {
    if (!gameId) {
      errorMessage = "Missing game id.";
      return;
    }

    if (showSpinner) isLoading = true;
    try {
      const { detail } = await gameStore.fetchGameById(gameId);
      gameDetail = detail ?? null;
      errorMessage = detail ? "" : "Game not found.";
    } catch (err) {
      console.error("Failed to load game detail:", err);
      errorMessage = "Failed to load game detail.";
    } finally {
      if (showSpinner) isLoading = false;
    }
  }

  const canMark = (cell: { isDrawn: boolean; isMarked: boolean }) =>
    isGameActive && !isMarking && cell.isDrawn && !cell.isMarked;

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
    if (cell.isMarked || isMarking) {
      return;
    }
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
    const result = await gameStore.claimWin(gameId, tablaId);
    if (result.success) {
      addToast({
        message: "Win claim submitted!",
        type: "success",
        duration: 2500,
      });
      await refreshGame(true);
    } else {
      addToast({
        message: result.error ?? "Win claim failed.",
        type: "error",
        duration: 3000,
      });
    }
    claimingTablaId = null;
  }

  function copyInviteLink() {
    if (!inviteLink) return;
    navigator.clipboard
      .writeText(inviteLink)
      .then(() =>
        addToast({
          message: "Invite link copied!",
          type: "success",
          duration: 2000,
        }),
      )
      .catch(() =>
        addToast({
          message: "Failed to copy link.",
          type: "error",
          duration: 2500,
        }),
      );
  }

  onMount(() => {
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
  });
</script>

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
        onclick={() => goto("/join-game")}
      >
        Browse Games
      </button>
    </div>
  </div>
{:else if gameDetail}
  {#if !playerSummary()}
    <div
      class="min-h-screen bg-[#1a0033] flex items-center justify-center px-6"
    >
      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] p-10 text-center max-w-md space-y-4"
      >
        {#if isHostViewer}
          <h1 class="text-3xl font-black text-[#F4E04D] uppercase">
            You're Hosting This Lobby
          </h1>
          <p class="text-white font-bold">
            Use the host dashboard to draw cards and manage the lobby.
          </p>
          <button
            class="bg-[#F4E04D] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#fff27d] transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)]"
            onclick={() => goto(`/game/host/${gameDetail?.id}`)}
          >
            Go to Host View
          </button>
        {:else}
          <h1 class="text-3xl font-black text-[#F4E04D] uppercase">
            Join the Game
          </h1>
          <p class="text-white font-bold">
            You haven't joined this lobby yet. Pick a tabla and pay the entry
            fee to play.
          </p>
          <div class="flex flex-wrap items-center justify-center gap-3">
            <button
              class="bg-[#C9B5E8] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)]"
              onclick={() => goto("/join-game")}
            >
              Browse Games
            </button>
            <button
              class="bg-[#F4E04D] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#fff27d] transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)]"
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
      <div class="relative z-10 max-w-6xl mx-auto px-4 py-8 space-y-6">
        <div
          class="flex flex-col md:flex-row md:items-center md:justify-between gap-4"
        >
          <button
            onclick={() => goto("/join-game")}
            class="inline-flex items-center justify-center gap-2 bg-[#C9B5E8] text-[#1a0033] px-5 py-3 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] transition-all text-sm shadow-[4px_4px_0px_rgba(0,0,0,1)] w-full md:w-auto"
          >
            ◄ Back to Games
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

        {#if isWinner}
          <div
            class="bg-[#F4E04D] text-[#1a0033] border-4 border-black font-black uppercase px-4 py-3 text-center shadow-[6px_6px_0px_rgba(0,0,0,0.8)]"
          >
            🎉 Congratulations! You are the winner of this game!
          </div>
        {:else if winnerLabel}
          <div
            class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black font-black uppercase px-4 py-3 text-center shadow-[6px_6px_0px_rgba(0,0,0,0.8)]"
          >
            🏆 Winner: {winnerLabel}
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
                  Your Status
                </span>
              </div>
              <h2
                class="text-2xl font-black text-[#F4E04D] uppercase mb-6"
                style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
              >
                Ready to Play
              </h2>
              <div class="space-y-3 text-sm font-bold text-white uppercase">
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">You are</span>
                  <span class="text-right text-[#F4E04D]">
  {playerSummary() ? playerName(playerSummary()!) : ''}
</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Host</span>
                  <span class="text-right">{profileName(gameDetail.host)}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Mode</span>
                  <span class="text-right">{modeLabel(gameDetail.mode)}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Status</span>
                  <span class="text-right"
                    >{statusLabel(gameDetail.status)}</span
                  >
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Your Marks</span>
                  <span class="text-right">{yourMarks}</span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Entry Fee</span>
                  <span class="text-right">
                    {formatAmount(gameDetail.entryFee, gameDetail.tokenType)}
                    &nbsp;{tokenSymbol(gameDetail.tokenType)}
                  </span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Prize Pool</span>
                  <span class="text-right">
                    {formatAmount(gameDetail.prizePool, gameDetail.tokenType)}
                    &nbsp;{tokenSymbol(gameDetail.tokenType)}
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
                  Other Players
                </span>
                <span class="text-xs text-white font-bold">
                  {otherPlayersStats.length}
                  {otherPlayersStats.length === 1 ? " player" : " players"}
                </span>
              </div>

              {#if otherPlayersStats.length === 0}
                <div
                  class="bg-[#1a0033] border-2 border-black text-center text-[#C9B5E8] font-bold uppercase text-xs py-6 shadow-[4px_4px_0px_rgba(0,0,0,1)]"
                >
                  You're the first player in this lobby. Invite your friends!
                </div>
              {:else}
                <div class="space-y-3">
                  {#each otherPlayersStats as stat}
                    <div
                      class="bg-[#1a0033] border-2 border-black px-3 py-3 shadow-[4px_4px_0px_rgba(0,0,0,1)] flex items-center justify-between gap-4"
                    >
                      <div>
                        <p class="text-white font-black text-sm uppercase">
                          {playerName(stat.player)}
                        </p>
                        <p class="text-xs text-[#C9B5E8] font-bold">
                          Marks: {stat.marks} · Tablas: {stat.tablas}
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

            <div
              class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
            >
              <div class="mb-4">
                <span
                  class="bg-white text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                >
                  Share Lobby
                </span>
              </div>
              <p
                class="text-xs font-bold text-white uppercase mb-4 leading-relaxed"
              >
                Share this invite link so friends can join your lobby. It copies
                instantly to your clipboard.
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
                    onclick={copyInviteLink}
                  >
                    Copy
                  </button>
                </div>
              </div>
            </div>
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
                  <button
                    class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
                    onclick={() => refreshGame(true)}
                  >
                    Refresh
                  </button>
                  <button
                    class="bg-white text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#C9B5E8]"
                    onclick={() => goto(`/game/host/${gameDetail?.id}`)}
                  >
                    View Host Screen
                  </button>
                </div>
              </div>

              <div
                class="grid grid-cols-1 md:grid-cols-[180px,1fr] gap-4 items-start"
              >
                <div
                  class="bg-[#1a0033] border-4 border-black p-2 shadow-[4px_4px_0px_rgba(0,0,0,1)] flex flex-col items-center justify-center aspect-square"
                >
                  {#if currentCardId}
                    <img
                      src={cardImage(currentCardId)}
                      alt={`Current card ${currentCardId}`}
                      class="w-full h-full object-cover border-2 border-[#F4E04D]"
                    />
                    <span
                      class="mt-2 text-xs font-black text-[#F4E04D] uppercase"
                    >
                      Current Card #{currentCardId}
                    </span>
                  {:else}
                    <div
                      class="text-center text-[#C9B5E8] font-bold text-xs uppercase"
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
                    {formatAmount(gameDetail.prizePool, gameDetail.tokenType)}
                    &nbsp;{tokenSymbol(gameDetail.tokenType)}
                  </p>
                  <p class="text-xs font-bold uppercase">
                    Players currently playing: {gameDetail.playerCount}
                  </p>
                  <p class="text-xs font-bold uppercase text-[#C9B5E8]">
                    Mark the drawn cards on your tabla. Once you complete the
                    winning pattern, submit your win!
                  </p>
                </div>
              </div>
            </div>

            {#each playerSummary()?.tablas ?? [] as tabla (tabla.tablaId)}
              <div
                class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)] space-y-4"
              >
                <div class="flex items-center justify-between">
                  <div>
                    <span
                      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                    >
                      Your Tabla
                    </span>
                    <p
                      class="text-xl font-black text-white uppercase mt-2"
                      style="text-shadow: 2px 2px 0px #000;"
                    >
                      Tabla #{tabla.tablaId}
                    </p>
                  </div>
                  <div
                    class="text-right text-xs text-[#C9B5E8] font-bold uppercase"
                  >
                    Marks on this tabla:
                    <span class="text-[#F4E04D]">
                      {marksByTabla.get(tabla.tablaId) ?? 0}
                    </span>
                  </div>
                </div>

                <div class="grid grid-cols-4 gap-2">
                  {#each tablaGrid(tabla) as cell (cell.row * 10 + cell.col)}
                    <button
                      class={`relative aspect-square border-2 border-black bg-[#1a0033] shadow-[3px_3px_0px_rgba(0,0,0,1)] overflow-hidden transition ${
                        canMark(cell)
                          ? "hover:-translate-y-1 hover:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
                          : "opacity-60 cursor-not-allowed"
                      } ${cell.isDrawn ? "border-[#F4E04D]" : "border-[#35125a]"} ${
                        cell.isMarked ? "ring-4 ring-[#29ABE2]" : ""
                      }`}
                      disabled={!canMark(cell)}
                      onclick={() => handleMark(tabla.tablaId, cell)}
                    >
                      <img
                        src={cell.image}
                        alt={`Card ${cell.cardId}`}
                        class={`w-full h-full object-cover ${
                          cell.isMarked ? "opacity-30" : ""
                        }`}
                      />
                      {#if cell.isMarked}
                        <div
                          class="absolute inset-0 bg-[#29ABE2]/70 border-2 border-[#29ABE2] flex items-center justify-center"
                        >
                          <span class="text-3xl font-black text-[#1a0033]"
                            >✓</span
                          >
                        </div>
                      {:else if cell.isDrawn}
                        <div
                          class="absolute inset-0 border-4 border-[#F4E04D] pointer-events-none"
                        ></div>
                      {/if}
                      <span
                        class="absolute bottom-1 left-1 bg-[#1a0033]/80 text-white text-[10px] font-black px-1 border border-black"
                      >
                        #{cell.cardId}
                      </span>
                    </button>
                  {/each}
                </div>

                <div
                  class="flex flex-wrap items-center justify-between gap-3 pt-2"
                >
                  <p class="text-xs text-[#C9B5E8] font-bold uppercase">
                    Mark drawn cards to track progress. When you complete the
                    pattern, claim the win!
                  </p>
                  <button
                    class="bg-[#F4E04D] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] disabled:bg-gray-500 disabled:text-gray-200"
                    disabled={claimingTablaId === tabla.tablaId ||
                      !isGameActive}
                    onclick={() => handleClaimWin(tabla.tablaId)}
                  >
                    {claimingTablaId === tabla.tablaId
                      ? "Claiming..."
                      : "Claim Win"}
                  </button>
                </div>
              </div>
            {/each}

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
                  No cards have been drawn yet. Watch for the host to begin!
                </div>
              {:else}
                <div
                  class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-6 gap-3"
                >
                  {#each drawnCards as cardId}
                    <div
                      class="relative bg-[#1a0033] border-2 border-black p-2 shadow-[4px_4px_0px_rgba(0,0,0,1)] {cardId ===
                      currentCardId
                        ? 'ring-4 ring-[#F4E04D]'
                        : ''}"
                    >
                      <img
                        src={cardImage(cardId)}
                        alt={`Card ${cardId}`}
                        class="w-full aspect-square object-cover border border-[#C9B5E8]"
                      />
                      <span
                        class="absolute top-1 right-1 bg-[#F4E04D] text-[#1a0033] border border-black text-[10px] font-black px-1"
                      >
                        #{cardId}
                      </span>
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
{/if}
