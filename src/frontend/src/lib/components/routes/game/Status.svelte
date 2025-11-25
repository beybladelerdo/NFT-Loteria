<script lang="ts">
  import { TokenService } from "$lib/services/token-service";
  import { modeLabel, statusLabel, tokenSymbol } from "$lib/utils/game-helper";
  import AudioToggle from "$lib/components/sound/SoundToggle.svelte";
  import type { GameDetailData } from "$lib/utils/game-helper";

  interface Props {
    gameDetail: GameDetailData;
    potBalance: bigint | null;
    lastDrawnCardId: number | null;
    currentCardId: number | null;
    remainingCards: number;
    totalCards: number;
    potDisbursed?: boolean;
    onRefresh: () => void;
    children?: any;
  }

  let { 
    gameDetail, 
    potBalance, 
    lastDrawnCardId, 
    currentCardId, 
    remainingCards,
    totalCards,
    potDisbursed = false,
    onRefresh,
    children
  }: Props = $props();

  const tokenService = new TokenService();

  const formattedPotBalance = $derived(
    potBalance !== null ? tokenService.formatBalance(potBalance, 8) : "—"
  );
</script>

<div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 sm:gap-4">
  <div class="flex-1 min-w-0">
    <span class="arcade-badge bg-[#FF6EC7] inline-block mb-2 sm:mb-3">
      Game Status
    </span>
    <p class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase arcade-text-shadow break-words">
      {statusLabel(gameDetail.status)}
    </p>
    <p class="text-xs font-bold text-white uppercase mt-2">
      Mode: {modeLabel(gameDetail.mode)} · Remaining Cards: {remainingCards}
    </p>
  </div>
  
  <div class="flex flex-wrap gap-2">
    {#if children}
      {@render children()}
    {/if}
    <button
      class="bg-[#C9B5E8] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0] active:scale-95 flex-shrink-0"
      onclick={onRefresh}
    >
      Refresh
    </button>
    <div class="flex-shrink-0">
      <AudioToggle />
    </div>
  </div>
</div>

<div class="mt-4 arcade-panel-sm px-3 sm:px-4 py-3 sm:py-4 space-y-2 text-white">
  <p class="text-xs font-bold uppercase">
    Cards Drawn: {totalCards - remainingCards} of {totalCards}
  </p>
  {#if lastDrawnCardId && lastDrawnCardId !== currentCardId}
    <p class="text-xs font-bold uppercase text-[#F4E04D]">
      Previous Card: #{lastDrawnCardId}
    </p>
  {/if}
  <p class="text-xs font-bold uppercase break-all">
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
</div>