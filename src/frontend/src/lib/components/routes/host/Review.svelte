<script lang="ts">
  import { formatSmart } from "$lib/utils/game-helper";
  import InvitePlayers from "$lib/components/routes/game/InvitePlayer.svelte";

  interface Props {
    tokenType: string;
    readableEntryFee: number;
    hostFeePercent: number;
    prizePool: number;
    gameIdCreated: string | null;
    gameLink: string;
  }

  let {
    tokenType,
    readableEntryFee,
    hostFeePercent,
    prizePool,
    gameIdCreated,
    gameLink,
  }: Props = $props();
</script>

<div class="mb-4">
  <span class="arcade-badge bg-[#FF6EC7]">Step 3: Review</span>
</div>

<h2
  class="text-2xl sm:text-3xl font-black text-[#FF6EC7] uppercase mb-4 sm:mb-6 arcade-text-shadow"
>
  REVIEW & CREATE
</h2>

<div class="mb-4 sm:mb-6">
  <div class="arcade-panel-sm p-3 sm:p-4 space-y-2">
    <div class="flex justify-between items-center">
      <span class="text-white font-bold text-xs sm:text-sm uppercase"
        >Entry Fee:</span
      >
      <span class="text-[#C9B5E8] font-black text-sm sm:text-base">
        {formatSmart(readableEntryFee)}
        {tokenType}
      </span>
    </div>
    <div class="flex justify-between items-center">
      <span class="text-white font-bold text-xs sm:text-sm uppercase"
        >Host Fee:</span
      >
      <span class="text-[#F4E04D] font-black text-sm sm:text-base"
        >{hostFeePercent}%</span
      >
    </div>
    <div
      class="flex justify-between items-center pt-2 border-t border-[#C9B5E8]"
    >
      <span class="text-[#F4E04D] font-bold text-xs sm:text-sm uppercase"
        >Est. Prize Pool:</span
      >
      <span class="text-white font-black text-sm sm:text-base">
        {formatSmart(prizePool)}
        {tokenType}
      </span>
    </div>
  </div>
</div>

<div class="mb-4 sm:mb-6 arcade-panel-sm p-3">
  <p class="text-[#C9B5E8] font-bold text-xs text-center uppercase">
    Host creates the game and manages draws. Players will pay the entry fee when
    they join.
  </p>
</div>

{#if gameIdCreated}
  <div class="mb-4 sm:mb-6">
    <InvitePlayers gameId={gameIdCreated} {gameLink} />
  </div>
{/if}
