<script lang="ts">
  import { formatDate, formatAmount, formatTokenType, formatStatus } from "$lib/utils/helpers";

  interface Props {
    recentGames: any[];
    onNavigate: (path: string) => void;
  }

  let { recentGames, onNavigate }: Props = $props();
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="mb-4 sm:mb-6">
    <span class="arcade-badge">Recent Activity</span>
  </div>

  <h2 class="text-2xl sm:text-3xl font-black uppercase mb-6 sm:mb-8 text-[#F4E04D] arcade-text-shadow">
    LATEST GAMES
  </h2>

  {#if recentGames.length === 0}
    <div class="text-center py-8 sm:py-12 arcade-panel-sm">
      <h3 class="text-xl sm:text-2xl font-black uppercase mb-3 sm:mb-4 text-[#F4E04D] px-4 arcade-text-shadow">
        NO GAMES YET!
      </h3>
      <p class="text-sm sm:text-lg font-bold mb-4 sm:mb-6 text-white px-4">
        Start playing to see your history here!
      </p>
      <button
        onclick={() => onNavigate("/join-game")}
        class="arcade-button py-2 sm:py-3 px-6 sm:px-8 text-xs sm:text-base"
      >
        JOIN FIRST GAME &gt;&gt;
      </button>
    </div>
  {:else}
    <div class="space-y-2 sm:space-y-3">
      {#each recentGames as game}
        <div class="arcade-panel-sm p-3 sm:p-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
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
              <span class="arcade-badge bg-white text-[10px]">HOST</span>
            {/if}
            {#if game.isWinner}
              <span class="arcade-badge text-[10px]">🏆 WON</span>
            {:else}
              <span class="arcade-badge bg-[#C9B5E8] text-[10px]">
                {formatStatus(game.status)}
              </span>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>