<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { page } from "$app/state";
  import { goto } from "$app/navigation";
  import { addToast } from "$lib/stores/toasts-store";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { type Rarity, GameService } from "$lib/services/game-service";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import { cardImages } from "$lib/data/gallery";
  import { TokenService } from "$lib/services/token-service";
  import GameChat from "$lib/components/game/game-chat.svelte";
  import {
    type GameDetailData,
    type TablaInGame,
    shortPrincipal,
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
  function outerBg(r: Rarity) {
    if ("legendary" in r)
      return "from-yellow-200/35 via-fuchsia-300/20 to-yellow-200/35";
    if ("epic" in r)
      return "from-purple-700/35 via-fuchsia-500/15 to-purple-700/35";
    if ("rare" in r)
      return "from-[#ff6ec7]/30 via-[#ff6ec7]/10 to-[#ff6ec7]/30";
    if ("uncommon" in r)
      return "from-[#F4E04D]/30 via-[#F4E04D]/10 to-[#F4E04D]/30";
    return "from-[#C9B5E8]/25 via-transparent to-[#C9B5E8]/25";
  }

  function outerFX(r: Rarity) {
    if ("legendary" in r)
      return "before:absolute before:inset-0 before:rounded-2xl before:pointer-events-none before:bg-[conic-gradient(from_0deg,rgba(255,215,0,.25),rgba(255,105,180,.15),rgba(255,215,0,.25))] before:animate-[spin_9s_linear_infinite] after:absolute after:inset-0 after:rounded-2xl after:pointer-events-none after:bg-[radial-gradient(circle_at_20%_15%,rgba(255,255,255,.18),transparent_35%),radial-gradient(circle_at_80%_85%,rgba(255,255,255,.10),transparent_40%)]";
    if ("epic" in r)
      return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(157,78,221,.22),transparent_60%)]";
    if ("rare" in r)
      return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(255,110,199,.25),transparent_60%)]";
    return "";
  }

  function panelRing(r: Rarity) {
    if ("legendary" in r)
      return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-yellow-300";
    if ("epic" in r)
      return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-purple-400";
    if ("rare" in r)
      return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-pink-300";
    if ("uncommon" in r)
      return "ring-4 ring-offset-4 ring-offset-[#1a0033] ring-amber-300";
    return "";
  }

  function pillText(r: Rarity) {
    if ("legendary" in r) return "ULTRA RARE";
    if ("epic" in r) return "EPIC";
    if ("rare" in r) return "RARE";
    if ("uncommon" in r) return "UNCOMMON";
    return "COMMON";
  }
  function pillClass(r: Rarity) {
    if ("legendary" in r) return "bg-[#FFD700] text-[#1a0033]";
    if ("epic" in r) return "bg-[#9D4EDD] text-white";
    if ("rare" in r) return "bg-[#FF6EC7] text-[#1a0033]";
    if ("uncommon" in r) return "bg-[#F4E04D] text-[#1a0033]";
    return "bg-[#C9B5E8] text-[#1a0033]";
  }
  function rarityText(r: Rarity): string {
    if ("legendary" in r) return "ULTRA RARE";
    if ("epic" in r) return "EPIC";
    if ("rare" in r) return "RARE";
    if ("uncommon" in r) return "UNCOMMON";
    return "COMMON";
  }
  $effect(() => {
    const ids = (playerSummary()?.tablas ?? []).map((t) => Number(t.tablaId));
    if (ids.length) void ensureRarities(ids);
  });
  const gameService = new GameService();
  export function tablaBg(r: Rarity): string {
    if ("legendary" in r)
      return "from-yellow-300/25 via-fuchsia-300/15 to-yellow-300/25";
    if ("epic" in r)
      return "from-purple-500/25 via-pink-400/10 to-purple-500/25";
    if ("rare" in r) return "from-[#FF6EC7]/20 via-transparent to-[#FF6EC7]/20";
    if ("uncommon" in r)
      return "from-[#F4E04D]/20 via-transparent to-[#F4E04D]/20";
    return "from-[#C9B5E8]/15 via-transparent to-[#C9B5E8]/15";
  }
  export function tablaPulse(r: Rarity): string {
    if ("legendary" in r)
      return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-gradient-to-r before:from-yellow-300/10 before:via-fuchsia-300/5 before:to-yellow-300/10";
    if ("epic" in r)
      return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-gradient-to-r before:from-purple-400/10 before:to-pink-400/10";
    if ("rare" in r)
      return "before:absolute before:inset-0 before:rounded-2xl before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(255,110,199,0.12),transparent_60%)]";
    return "";
  }
  let gameDetail = $state<GameDetailData | null>(null);
  let isLoading = $state(true);
  let isMarking = $state(false);
  let claimingTablaId = $state<number | null>(null);
  let inviteLink = $state("");
  let errorMessage = $state("");
  let gameTerminated = $state(false);
  let potBalance = $state<bigint | null>(null);
  let pollHandle: ReturnType<typeof setInterval> | null = null;
  let showCardAnimation = $state(false);
  let isDrawing = $state(false);
  let currentTablaIndex = $state(0);
  const hasCurrentCardOnTabla = $derived.by(() => {
    if (!currentCardId || !playerSummary()) return false;
    const summary = playerSummary();
    if (!summary) return false;
    for (const tabla of summary.tablas) {
      for (const card of tabla.cards) {
        if (Number(card) === currentCardId) {
          return true;
        }
      }
    }
    return false;
  });

  function handleCloseAnimation() {
    showCardAnimation = false;
  }

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

  const formattedPotBalance = $derived(
    potBalance !== null ? tokenService.formatBalance(potBalance, 8) : "—",
  );
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

  const isGameCompleted = $derived(
    !!gameDetail && "completed" in gameDetail.status,
  );

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

      if (!detail) {
        // Game not found - it was likely terminated by the host
        if (!gameTerminated) {
          gameTerminated = true;

          // Stop polling
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

          // Redirect to dashboard after a delay
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

  const canMark = (cell: { isDrawn: boolean; isMarked: boolean }) =>
    isGameActive && !isMarking && cell.isDrawn && !cell.isMarked;

  let showWinModal = $state(false);
  let winAmount = $state<bigint | null>(null);
  let lastAnnouncedWinner = $state<string | null>(null);

  let locallyClaimedWin = $state(false);
  let preClaimPotBalance = $state<bigint | null>(null); // Store pot balance before disbursement

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

  const shouldShowWinModal = $derived(
    showWinModal && (locallyClaimedWin || isWinner),
  );

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
    const preClaimPot = potBalance;
    const result = await gameStore.claimWin(gameId, tablaId);
    if (result.success) {
      addToast({
        message: "Win claim submitted! Verifying…",
        type: "success",
        duration: 2500,
      });
      winAmount = preClaimPot ?? null;
      preClaimPotBalance = preClaimPot; // Store for display calculations
      locallyClaimedWin = true;
      showWinModal = true;

      // Poll for winner to be populated (backend sets winner but payouts take time)
      let pollAttempts = 0;
      const maxAttempts = 20; // Try for up to 10 seconds (20 * 500ms)
      const pollForWinner = async () => {
        await refreshGame(false);
        pollAttempts++;

        // Check if winner is now set
        if (gameDetail?.winner && gameDetail.winner.length > 0) {
          // Winner found! Stop polling
          return;
        }

        // Continue polling if we haven't hit max attempts
        if (pollAttempts < maxAttempts) {
          setTimeout(pollForWinner, 500); // Check every 500ms
        }
      };

      // Start polling
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
  const OWNER_FEE_PERCENT = 10;
  const PLATFORM_FEE_PERCENT = 5;

  const hostFeePct = $derived(
    gameDetail ? Number(gameDetail.hostFeePercent ?? 0) : 0,
  );
  const currentTabla = $derived.by(() => {
    const tablas = playerSummary()?.tablas ?? [];
    return tablas[currentTablaIndex] ?? null;
  });

  const totalTablas = $derived(playerSummary()?.tablas?.length ?? 0);

  function goToNextTabla() {
    if (currentTablaIndex < totalTablas - 1) {
      currentTablaIndex++;
    }
  }

  function goToPreviousTabla() {
    if (currentTablaIndex > 0) {
      currentTablaIndex--;
    }
  }

  // Use pre-claim balance if available (after win), otherwise current balance
  const estPot = $derived(preClaimPotBalance ?? potBalance ?? null);

  function pct(amt: bigint, p: number): bigint {
    return (amt * BigInt(p)) / 100n;
  }

  const estPlatformFee = $derived(
    estPot !== null ? pct(estPot, PLATFORM_FEE_PERCENT) : null,
  );
  const estOwnerFee = $derived(
    estPot !== null ? pct(estPot, OWNER_FEE_PERCENT) : null,
  );
  const estHostFee = $derived(estPot !== null ? pct(estPot, hostFeePct) : null);
  const estWinnerAmt = $derived(
    estPot !== null &&
      estPlatformFee !== null &&
      estOwnerFee !== null &&
      estHostFee !== null
      ? estPot - estPlatformFee - estOwnerFee - estHostFee
      : null,
  );

  // Check if pot has been disbursed (pot is 0 but we have pre-claim balance)
  const potDisbursed = $derived(
    isGameCompleted &&
      preClaimPotBalance !== null &&
      potBalance !== null &&
      potBalance === 0n,
  );

  onMount(() => {
    startMenuMusic("/sounds/menu_music.wav", true);
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
  cardImage={currentCardId ? cardImage(currentCardId) : ""}
  show={showCardAnimation}
  isHost={isHostViewer}
  hasCardOnTabla={hasCurrentCardOnTabla}
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
      {#if gameTerminated}
        <div class="mb-6">
          <span
            class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
          >
            Game Terminated
          </span>
        </div>
        <h1 class="text-3xl font-black text-[#F4E04D] uppercase mb-4">
          Game Was Terminated
        </h1>
        <div
          class="bg-[#1a0033] border-2 border-[#C9B5E8] p-4 mb-6 shadow-[3px_3px_0px_rgba(0,0,0,1)]"
        >
          <p class="text-white text-sm font-bold mb-2">
            The host has terminated this game.
          </p>
          <p class="text-[#C9B5E8] text-xs">
            Your entry fee has been refunded (minus transaction fees).
            Redirecting you to the dashboard...
          </p>
        </div>
      {:else}
        <h1 class="text-3xl font-black text-[#F4E04D] uppercase mb-4">
          Game Not Found
        </h1>
        <p class="text-white font-bold mb-6">{errorMessage}</p>
      {/if}
      <button
        class="bg-[#F4E04D] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#fff27d] transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)]"
        onclick={() => goto("/dashboard")}
      >
        Go to Dashboard
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
                    {playerSummary() ? playerName(playerSummary()!) : ""}
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
                    {tokenService.formatBalance(gameDetail.entryFee, 8)}
                    &nbsp;{tokenSymbol(gameDetail.tokenType)}
                  </span>
                </div>
                <div class="flex justify-between gap-4">
                  <span class="text-[#C9B5E8]">Prize Pool</span>
                  <span class="text-right">
                    {#if potDisbursed}
                      <span class="text-[#4ade80]">DISBURSED</span>
                    {:else}
                      {formattedPotBalance}
                      &nbsp;{tokenSymbol(gameDetail.tokenType)}
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
                      <button
                        class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-1 text-xs font-black uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] transition-all relative group"
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

                        <!-- Tooltip on hover -->
                        <span
                          class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-[#1a0033] border-2 border-[#F4E04D] text-[#F4E04D] text-[10px] font-mono rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none shadow-[4px_4px_0px_rgba(0,0,0,1)] z-10"
                        >
                          {stat.player.principal.toText()}
                          <span class="block text-[8px] text-[#C9B5E8] mt-1"
                            >Click to copy</span
                          >
                        </span>
                      </button>
                    </div>
                  {/each}
                  <GameChat gameId={gameDetail.id} />
                </div>
              {/if}
            </div>
            {#if isLobbyStatus}
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
                  Share this invite link so friends can join your lobby. It
                  copies instantly to your clipboard.
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
                  <button
                    class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
                    onclick={() => refreshGame(true)}
                  >
                    Refresh
                  </button>
                  <AudioToggle />
                </div>
              </div>

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
                    {#if potDisbursed}
                      <span class="text-[#4ade80]">DISBURSED</span>
                    {:else}
                      {formattedPotBalance}
                      &nbsp;{tokenSymbol(gameDetail.tokenType)}
                    {/if}
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
            {#if totalTablas > 1}
              <div
                class="mb-4 flex items-center justify-between bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 border-4 border-black shadow-[4px_4px_0_rgba(0,0,0,1)]"
              >
                <div
                  class="w-full flex items-center justify-between gap-2 sm:gap-4"
                >
                  <button
                    onclick={goToPreviousTabla}
                    disabled={currentTablaIndex === 0}
                    class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 sm:px-6 py-3 font-black uppercase text-xl sm:text-2xl shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#d9c9f0] hover:scale-105 transition-all disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:scale-100 w-16 sm:w-24 flex items-center justify-center"
                  >
                    ◄
                  </button>

                  <div class="text-center flex-1">
                    <p
                      class="text-[#F4E04D] font-black uppercase text-xs sm:text-xl leading-tight whitespace-nowrap"
                      style="text-shadow: 2px 2px 0px #000;"
                    >
                      Tabla {currentTablaIndex + 1} of {totalTablas}
                    </p>
                    <p
                      class="text-[#C9B5E8] text-[9px] sm:text-xs font-bold uppercase mt-1 hidden sm:block"
                    >
                      Use arrows to switch between your tablas
                    </p>
                  </div>

                  <button
                    onclick={goToNextTabla}
                    disabled={currentTablaIndex === totalTablas - 1}
                    class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 sm:px-6 py-3 font-black uppercase text-xl sm:text-2xl shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#d9c9f0] hover:scale-105 transition-all disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:scale-100 w-16 sm:w-24 flex items-center justify-center"
                  >
                    ►
                  </button>
                </div>
              </div>
            {/if}
            {#if currentTabla}
              {@const r =
                rarityById[currentTabla.tablaId] ?? ({ common: null } as const)}

              <div
                class={`relative rounded-2xl overflow-hidden border-8 border-black shadow-[12px_12px_0_rgba(0,0,0,.9)]
               bg-gradient-to-b ${outerBg(r)} ${outerFX(r)}`}
              >
                <div class="relative p-5 md:p-6">
                  <div class="mb-3 flex items-center justify-between gap-3">
                    <div>
                      <span
                        class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-[11px] font-black uppercase shadow-[2px_2px_0_rgba(0,0,0,1)]"
                        >Your Tabla</span
                      >
                      <p
                        class="text-2xl font-black text-white uppercase mt-2"
                        style="text-shadow:2px 2px 0 #000"
                      >
                        Tabla #{currentTabla.tablaId}
                      </p>
                    </div>

                    <div class="flex flex-col items-end gap-2 shrink-0">
                      <span
                        class={`px-3 py-1 text-[11px] font-black uppercase border border-black rounded-md shadow-[2px_2px_0_rgba(0,0,0,1)] ${pillClass(r)}`}
                      >
                        {pillText(r)}
                      </span>
                      <div
                        class="text-[11px] text-[#C9B5E8] font-black uppercase"
                      >
                        Marks on this tabla: <span class="text-[#F4E04D]"
                          >{marksByTabla.get(currentTabla.tablaId) ?? 0}</span
                        >
                      </div>
                    </div>
                  </div>

                  <div
                    class={`rounded-xl border-4 border-[#35125a] bg-[#1a0033]/85 p-3 ${panelRing(r)}`}
                  >
                    <div class="grid grid-cols-4 gap-2">
                      {#each tablaGrid(currentTabla) as cell (cell.row * 10 + cell.col)}
                        <button
                          class={`relative border-2 border-black bg-[#1a0033] shadow-[3px_3px_0_rgba(0,0,0,1)] overflow-hidden transition
                      ${canMark(cell) ? "hover:-translate-y-1 hover:shadow-[4px_4px_0_rgba(0,0,0,1)]" : "opacity-60 cursor-not-allowed"}
                      ${cell.isDrawn ? "border-[#F4E04D]" : "border-[#35125a]"} ${cell.isMarked ? "ring-4 ring-[#29ABE2]" : ""}`}
                          disabled={!canMark(cell)}
                          onclick={() => handleMark(currentTabla.tablaId, cell)}
                        >
                          <div
                            class="relative w-full overflow-hidden"
                            style="aspect-ratio:320/500;"
                          >
                            <img
                              src={cell.image}
                              alt={`Card ${cell.cardId}`}
                              class={`absolute inset-0 w-full h-full object-contain ${cell.isMarked ? "opacity-30" : ""}`}
                              loading="lazy"
                              decoding="async"
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
                              class="absolute top-1 left-1 z-10 bg-[#1a0033]/90 text-white text-[10px] font-black px-1 border border-black rounded-sm pointer-events-none"
                              >#{cell.cardId}</span
                            >
                          </div>
                        </button>
                      {/each}
                    </div>
                  </div>

                  <div
                    class="flex flex-wrap items-center justify-between gap-3 pt-3"
                  >
                    <p class="text-xs text-[#C9B5E8] font-bold uppercase">
                      Mark drawn cards to track progress. When you complete the
                      pattern, claim the win!
                    </p>
                    <button
                      class="bg-[#F4E04D] text-[#1a0033] border-4 border-black px-4 py-2 font-black uppercase text-xs shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#fff27d] disabled:bg-gray-500 disabled:text-gray-200"
                      disabled={claimingTablaId === currentTabla.tablaId ||
                        !isGameActive}
                      onclick={() => handleClaimWin(currentTabla.tablaId)}
                    >
                      {claimingTablaId === currentTabla.tablaId
                        ? "Claiming..."
                        : "Claim Win"}
                    </button>
                  </div>
                </div>
              </div>
            {:else}
              <div
                class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black text-center"
              >
                <p class="text-white font-bold uppercase">No tablas found</p>
              </div>
            {/if}

            <div
              class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
            >
              <GameChat gameId={gameDetail.id} />

              <div class="mt-6 mb-4">
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
                <div
                  class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-6 gap-3"
                >
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
      <FlickeringGrid
        class="absolute inset-0 opacity-20"
        squareSize={4}
        gridGap={6}
        color="rgba(196, 154, 250, 0.5)"
      />
    </div>
  {/if}
{/if}

{#if shouldShowWinModal}
  <div
    class="fixed inset-0 z-[100] bg-black/70 flex items-center justify-center px-4"
  >
    <div
      class="max-w-md w-full bg-gradient-to-b from-[#F4E04D] to-[#ffef9a] border-8 border-black shadow-[12px_12px_0_rgba(0,0,0,0.9)] p-6 text-center"
    >
      <h2
        class="text-3xl font-black uppercase text-[#1a0033]"
        style="text-shadow:2px 2px 0 #fff"
      >
        🎉 Bingo!
      </h2>
      <p class="mt-3 text-sm font-bold text-[#1a0033] uppercase">
        You’ve won the prize pool
      </p>
      <p
        class="mt-2 text-3xl font-black text-[#1a0033]"
        style="text-shadow:1px 1px 0 #fff"
      >
        {estWinnerAmt !== null
          ? tokenService.formatBalance(estWinnerAmt, 8)
          : formattedPotBalance}
        &nbsp;{tokenSymbol(gameDetail?.tokenType)}
      </p>

      <div
        class="mt-5 bg-white/70 border-4 border-black text-left p-4 font-black uppercase text-xs text-[#1a0033]"
      >
        <div class="flex justify-between mb-2">
          <span>Total Prize Pool</span>
          <span
            >{estPot !== null ? tokenService.formatBalance(estPot, 8) : "—"}
            {tokenSymbol(gameDetail?.tokenType)}</span
          >
        </div>
        <div class="h-px bg-black/30 my-2"></div>
        <div class="flex justify-between mb-1">
          <span>Platform ({PLATFORM_FEE_PERCENT}%)</span>
          <span
            >{estPlatformFee !== null
              ? tokenService.formatBalance(estPlatformFee, 8)
              : "—"}
            {tokenSymbol(gameDetail?.tokenType)}</span
          >
        </div>
        <div class="flex justify-between mb-1">
          <span>Tabla Owner ({OWNER_FEE_PERCENT}%)</span>
          <span
            >{estOwnerFee !== null
              ? tokenService.formatBalance(estOwnerFee, 8)
              : "—"}
            {tokenSymbol(gameDetail?.tokenType)}</span
          >
        </div>
        <div class="flex justify-between mb-1">
          <span>Host ({hostFeePct}%)</span>
          <span
            >{estHostFee !== null
              ? tokenService.formatBalance(estHostFee, 8)
              : "—"}
            {tokenSymbol(gameDetail?.tokenType)}</span
          >
        </div>
        <div class="h-px bg-black/30 my-2"></div>
        <div class="flex justify-between mb-1">
          <span>Winner (Estimated)</span>
          <span
            >{estWinnerAmt !== null
              ? tokenService.formatBalance(estWinnerAmt, 8)
              : "—"}
            {tokenSymbol(gameDetail?.tokenType)}</span
          >
        </div>
        <div class="mt-2 text-[10px] text-[#4b3c00]">
          Network fees not included in estimate; actual payouts may vary
          slightly.
        </div>
      </div>

      <div class="mt-6 flex items-center justify-center gap-3">
        <button
          class="bg-white text-[#1a0033] border-4 border-black px-5 py-2 font-black uppercase text-sm shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#C9B5E8]"
          onclick={() => {
            showWinModal = false;
            locallyClaimedWin = false;
          }}>Close</button
        >
        <button
          class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-5 py-2 font-black uppercase text-sm shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-white"
          onclick={() => goto("/dashboard")}>Go to Dashboard</button
        >
      </div>
    </div>
  </div>
{/if}
