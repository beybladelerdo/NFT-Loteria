<script lang="ts">
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { userStore } from "$lib/stores/user-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  import Spinner from "$lib/components/shared/global/spinner.svelte";

  let profile: Profile | undefined = $state(undefined);
  let isLoading = $state(true);
  let openGamesCount = $derived(gameStore.openGames.length);

  let failedClaims = $state<any[]>([]);
  let recentGames = $state<any[]>([]);
  let retryingClaim = $state<string | null>(null);

  onMount(async () => {
    try {
      profile = await userStore.getProfile();
      await gameStore.fetchOpenGames(0);

      const claimsResult = await gameStore.getFailedClaims();
      if (claimsResult.success && "data" in claimsResult && claimsResult.data) {
        failedClaims = claimsResult.data;
      }

      const gamesResult = await gameStore.getRecentGamesForPlayer(10);
      if (gamesResult.success && "data" in gamesResult && gamesResult.data) {
        recentGames = gamesResult.data;
      }
    } catch (error) {
      console.error("Error loading dashboard:", error);
    } finally {
      isLoading = false;
    }
  });

  async function handleRetryClaim(gameId: string) {
    retryingClaim = gameId;
    try {
      const result = await gameStore.retryFailedClaim(gameId);
      if (result.success) {
        failedClaims = failedClaims.filter((c) => c.gameId !== gameId);
      } else {
        alert("Retry failed: " + result.error);
      }
    } catch (error) {
      console.error("Retry error:", error);
    } finally {
      retryingClaim = null;
    }
  }

  function formatTokenType(tokenType: any): string {
    if ("ICP" in tokenType) return "ICP";
    if ("ckBTC" in tokenType) return "ckBTC";
    if ("gldt" in tokenType) return "GLDT";
    return "Unknown";
  }

  function formatAmount(amount: bigint, tokenType: any): string {
    const num = Number(amount) / 1e8;
    if ("ckBTC" in tokenType) return num.toFixed(6);
    return Math.floor(num).toLocaleString();
  }

  function formatStatus(status: any): string {
    if ("open" in status) return "OPEN";
    if ("active" in status) return "ACTIVE";
    if ("completed" in status) return "COMPLETED";
    if ("cancelled" in status) return "CANCELLED";
    if ("lobby" in status) return "LOBBY";
    return "UNKNOWN";
  }

  function formatDate(timestamp: bigint): string {
    const date = new Date(Number(timestamp) / 1_000_000);
    return date.toLocaleDateString();
  }
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if profile}
  <div class="min-h-screen bg-[#1a0033] pb-8">
    <div class="w-full mx-auto px-4 py-6 sm:py-8 md:py-12 max-w-7xl">
      <!-- Hero Header -->
      <div class="mb-8 sm:mb-12 text-center">
        <h1
          class="text-2xl sm:text-4xl md:text-6xl font-black uppercase tracking-tight mb-3 sm:mb-4 leading-tight px-2"
          style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000, 1px -1px 0px #000, -1px 1px 0px #000;"
        >
          <span class="text-[#F4E04D] block sm:inline">WELCOME BACK,</span>
          <span class="text-[#C9B5E8] block sm:inline break-all">@{profile.username}</span>
        </h1>
        <div class="flex justify-center gap-2 sm:gap-4 flex-wrap">
          <span
            class="bg-[#F4E04D] text-[#1a0033] px-3 sm:px-4 py-1 sm:py-2 border-2 border-black font-bold uppercase text-xs sm:text-sm shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] sm:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
          >
            {profile.games} GAMES
          </span>
          <span
            class="bg-[#C9B5E8] text-[#1a0033] px-3 sm:px-4 py-1 sm:py-2 border-2 border-black font-bold uppercase text-xs sm:text-sm shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] sm:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
          >
            {profile.wins} WINS
          </span>
        </div>
      </div>

      <!-- Main Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 md:gap-8 mb-6 sm:mb-8">
        <!-- Your Stats Card -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,0.8)] sm:hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-3 sm:mb-4">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Your Stats
            </span>
          </div>

          <h3
            class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 sm:mb-6"
            style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;"
          >
            YOUR PROGRESS
          </h3>

          <div
            class="mb-4 sm:mb-6 bg-[#1a0033] text-[#F4E04D] p-4 sm:p-6 border-2 border-black text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <div class="text-xs sm:text-sm font-bold uppercase text-[#C9B5E8]">
              Games Played
            </div>
            <div
              class="text-4xl sm:text-5xl font-black mt-2"
              style="text-shadow: 2px 2px 0px #000;"
            >
              {profile.games}
            </div>
          </div>

          <div class="grid grid-cols-2 gap-2 sm:gap-3 mb-4 sm:mb-6">
            <div
              class="bg-[#F4E04D] p-3 sm:p-4 border-2 border-black text-center shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] sm:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-xs font-bold text-[#1a0033] uppercase">Wins</div>
              <div class="text-2xl sm:text-3xl font-black text-[#1a0033]">
                {profile.wins}
              </div>
            </div>
            <div
              class="bg-[#C9B5E8] p-3 sm:p-4 border-2 border-black text-center shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] sm:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-xs font-bold text-[#1a0033] uppercase">
                Win Streak
              </div>
              <div class="text-2xl sm:text-3xl font-black text-[#1a0033]">0</div>
            </div>
          </div>

          <button
            onclick={() => goto("/profile")}
            class="w-full bg-white text-[#1a0033] py-2 sm:py-3 px-3 sm:px-4 font-black uppercase border-2 sm:border-4 border-black hover:bg-[#F4E04D] active:scale-95 sm:hover:scale-105 transition-all text-xs sm:text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            WALLET &gt;&gt;
          </button>
        </div>

        <!-- Join Game Card -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,0.8)] sm:hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-3 sm:mb-4">
            <span
              class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Join Game
            </span>
          </div>

          <h3
            class="text-xl sm:text-2xl font-black text-[#C9B5E8] uppercase mb-3 sm:mb-4"
            style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;"
          >
            JOIN A GAME
          </h3>

          <p class="text-xs sm:text-sm mb-4 sm:mb-6 font-bold text-white">
            Browse open games and jump in! Find your perfect match!
          </p>

          <div
            class="bg-[#1a0033] text-[#C9B5E8] p-4 sm:p-6 border-2 sm:border-4 border-black mb-4 sm:mb-6 text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <div class="text-xs sm:text-sm font-bold uppercase text-[#F4E04D]">
              Currently Available
            </div>
            <div
              class="text-4xl sm:text-5xl font-black mt-2"
              style="text-shadow: 2px 2px 0px #000;"
            >
              {openGamesCount}
            </div>
            <div class="text-xs mt-1 uppercase text-white">Open Games</div>
          </div>

          <button
            onclick={() => goto("/join-game")}
            class="w-full bg-[#C9B5E8] text-[#1a0033] py-2 sm:py-3 px-3 sm:px-4 font-black uppercase border-2 sm:border-4 border-black hover:bg-[#d9c9f0] active:scale-95 sm:hover:scale-105 transition-all text-xs sm:text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            BROWSE GAMES &gt;&gt;
          </button>
        </div>

        <!-- Host Game Card -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,0.8)] sm:hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-3 sm:mb-4">
            <span
              class="bg-white text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Host Game
            </span>
          </div>

          <h3
            class="text-xl sm:text-2xl font-black text-white uppercase mb-3 sm:mb-4"
            style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;"
          >
            HOST A GAME
          </h3>

          <p class="text-xs sm:text-sm mb-4 sm:mb-6 font-bold text-white">
            Create your own game! Set the rules and earn host fees!
          </p>

          <div class="space-y-2 mb-4 sm:mb-6 text-xs sm:text-sm font-bold">
            <div
              class="flex items-center gap-2 bg-[#F4E04D] p-2 sm:p-3 border-2 border-black text-[#1a0033] shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              <span class="text-base sm:text-lg">✓</span>
              <span>CHOOSE GAME MODE</span>
            </div>
            <div
              class="flex items-center gap-2 bg-[#C9B5E8] p-2 sm:p-3 border-2 border-black text-[#1a0033] shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              <span class="text-base sm:text-lg">✓</span>
              <span>SET ENTRY FEE</span>
            </div>
            <div
              class="flex items-center gap-2 bg-white text-[#1a0033] p-2 sm:p-3 border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              <span class="text-base sm:text-lg">✓</span>
              <span>EARN HOST FEES</span>
            </div>
          </div>

          <button
            onclick={() => goto("/host-game")}
            class="w-full bg-[#F4E04D] text-[#1a0033] py-2 sm:py-3 px-3 sm:px-4 font-black uppercase border-2 sm:border-4 border-black hover:bg-[#fff27d] active:scale-95 sm:hover:scale-105 transition-all text-xs sm:text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            CREATE GAME &gt;&gt;
          </button>
        </div>
      </div>

      <!-- Recent Activity Section -->
      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] mb-6 sm:mb-8"
      >
        <div class="mb-4 sm:mb-6">
          <span
            class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            Recent Activity
          </span>
        </div>

        <h2
          class="text-2xl sm:text-3xl font-black uppercase mb-6 sm:mb-8 text-[#F4E04D]"
          style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;"
        >
          LATEST GAMES
        </h2>

        {#if recentGames.length === 0}
          <div
            class="text-center py-8 sm:py-12 bg-[#1a0033] border-2 sm:border-4 border-black shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <h3
              class="text-xl sm:text-2xl font-black uppercase mb-3 sm:mb-4 text-[#F4E04D] px-4"
              style="text-shadow: 2px 2px 0px #000;"
            >
              NO GAMES YET!
            </h3>
            <p class="text-sm sm:text-lg font-bold mb-4 sm:mb-6 text-white px-4">
              Start playing to see your history here!
            </p>
            <button
              onclick={() => goto("/join-game")}
              class="bg-[#F4E04D] text-[#1a0033] py-2 sm:py-3 px-6 sm:px-8 font-black uppercase border-2 sm:border-4 border-black hover:bg-[#fff27d] active:scale-95 sm:hover:scale-105 transition-all shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] text-xs sm:text-base"
            >
              JOIN FIRST GAME &gt;&gt;
            </button>
          </div>
        {:else}
          <div class="space-y-2 sm:space-y-3">
            {#each recentGames as game}
              <div
                class="bg-[#1a0033] border-2 border-black p-3 sm:p-4 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] sm:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
              >
                <div class="flex flex-wrap items-center gap-2 sm:gap-4">
                  <div class="text-xs font-bold text-[#C9B5E8] uppercase">
                    {formatDate(game.createdAt)}
                  </div>
                  <div class="text-xs sm:text-sm font-black text-white">
                    {game.mode.line ? "LINE" : "BLACKOUT"}
                  </div>
                  <div class="text-xs sm:text-sm font-bold text-[#F4E04D] break-all">
                    {formatAmount(game.entryFee, game.tokenType)}
                    {formatTokenType(game.tokenType)}
                  </div>
                </div>
                <div class="flex items-center gap-2 sm:gap-3 flex-wrap">
                  {#if game.isHost}
                    <span
                      class="bg-white text-[#1a0033] px-2 py-1 text-[10px] font-bold uppercase border border-black"
                      >HOST</span
                    >
                  {/if}
                  {#if game.isWinner}
                    <span
                      class="bg-[#F4E04D] text-[#1a0033] px-2 py-1 text-[10px] font-bold uppercase border border-black"
                      >🏆 WON</span
                    >
                  {:else}
                    <span
                      class="bg-[#C9B5E8] text-[#1a0033] px-2 py-1 text-[10px] font-bold uppercase border border-black"
                    >
                      {formatStatus(game.status)}
                    </span>
                  {/if}
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </div>

      <!-- Failed Claims Recovery Section -->
      {#if failedClaims.length > 0}
        <div
          class="bg-gradient-to-b from-[#8B0000] to-[#5C0000] p-4 sm:p-6 border-2 sm:border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,0.8)] sm:shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
        >
          <div class="mb-4 sm:mb-6">
            <span
              class="bg-[#FF6B6B] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              ⚠️ Action Required
            </span>
          </div>

          <h2
            class="text-2xl sm:text-3xl font-black uppercase mb-3 sm:mb-4 text-[#FF6B6B]"
            style="text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;"
          >
            PENDING PAYOUTS
          </h2>
          <p class="text-xs sm:text-sm font-bold text-white mb-4 sm:mb-6">
            Some of your winnings failed to transfer. Click retry to claim your
            funds.
          </p>

          <div class="space-y-3 sm:space-y-4">
            {#each failedClaims as claim}
              <div
                class="bg-[#1a0033] border-2 border-[#FF6B6B] p-3 sm:p-4 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] sm:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              >
                <div class="flex items-center justify-between mb-3 gap-2">
                  <div class="text-xs sm:text-sm font-black text-white break-all">
                    Game: {claim.gameId.slice(0, 8)}...
                  </div>
                  <div class="text-xs sm:text-sm font-bold text-[#F4E04D] flex-shrink-0">
                    {formatAmount(claim.winnerAmount, claim.tokenType)}
                    {formatTokenType(claim.tokenType)}
                  </div>
                </div>

                <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-3 text-[10px] font-bold">
                  <div
                    class="text-center p-2 border border-black {claim
                      .payoutStatus.devFeePaid
                      ? 'bg-green-500'
                      : 'bg-red-500'}"
                  >
                    DEV FEE
                  </div>
                  <div
                    class="text-center p-2 border border-black {claim
                      .payoutStatus.tablaOwnerPaid
                      ? 'bg-green-500'
                      : 'bg-red-500'}"
                  >
                    OWNER
                  </div>
                  <div
                    class="text-center p-2 border border-black {claim
                      .payoutStatus.winnerPaid
                      ? 'bg-green-500'
                      : 'bg-red-500'}"
                  >
                    WINNER
                  </div>
                  <div
                    class="text-center p-2 border border-black {claim
                      .payoutStatus.hostPaid
                      ? 'bg-green-500'
                      : 'bg-red-500'}"
                  >
                    HOST
                  </div>
                </div>

                <div class="text-[10px] font-bold text-[#FF6B6B] mb-3 break-words">
                  Error: {claim.lastError}
                </div>

                <button
                  onclick={() => handleRetryClaim(claim.gameId)}
                  disabled={retryingClaim === claim.gameId}
                  class="w-full bg-[#F4E04D] text-[#1a0033] py-2 px-3 sm:px-4 font-black uppercase border-2 border-black hover:bg-[#fff27d] active:scale-95 sm:hover:scale-105 transition-all text-xs shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {retryingClaim === claim.gameId
                    ? "RETRYING..."
                    : "RETRY CLAIM"}
                </button>
              </div>
            {/each}
          </div>
        </div>
      {/if}
    </div>
  </div>
{/if}