<script lang="ts">
  import { TokenService } from "$lib/services/token-service";
  import {
    modeLabel,
    statusLabel,
    tokenSymbol,
    profileName,
  } from "$lib/utils/game-helper";
  import type { GameDetailData } from "$lib/utils/game-helper";

  interface Props {
    gameDetail: GameDetailData;
    potBalance: bigint | null;
    winnerLabel: string | null;
  }

  let { gameDetail, potBalance, winnerLabel }: Props = $props();

  const tokenService = new TokenService();

  const formattedPotBalance = $derived(
    potBalance !== null ? tokenService.formatBalance(potBalance, 8) : "—",
  );
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="mb-3 sm:mb-4">
    <span class="arcade-badge"> Lobby Info </span>
  </div>

  <h2
    class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 sm:mb-6 break-words arcade-text-shadow"
  >
    Host Control Center
  </h2>

  <div
    class="space-y-2 sm:space-y-3 text-xs sm:text-sm font-bold text-white uppercase"
  >
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
