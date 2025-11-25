<script lang="ts">
  import { TokenService } from "$lib/services/token-service";
  import { modeLabel, statusLabel, tokenSymbol, profileName, playerName } from "$lib/utils/game-helper";
  import type { GameDetailData } from "$lib/utils/game-helper";

  interface Props {
    gameDetail: GameDetailData;
    player: any;
    yourMarks: number;
    potBalance: bigint | null;
    potDisbursed?: boolean;
  }

  let { gameDetail, player, yourMarks, potBalance, potDisbursed = false }: Props = $props();

  const tokenService = new TokenService();

  const formattedPotBalance = $derived(
    potBalance !== null ? tokenService.formatBalance(potBalance, 8) : "—"
  );
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="mb-3 sm:mb-4">
    <span class="arcade-badge">
      Your Status
    </span>
  </div>
  
  <h2 class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 sm:mb-6 arcade-text-shadow">
    Ready to Play
  </h2>
  
  <div class="space-y-2 sm:space-y-3 text-xs sm:text-sm font-bold text-white uppercase">
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">You are</span>
      <span class="text-right text-[#F4E04D] break-all">
        {playerName(player)}
      </span>
    </div>
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">Host</span>
      <span class="text-right break-all">{profileName(gameDetail.host)}</span>
    </div>
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">Mode</span>
      <span class="text-right">{modeLabel(gameDetail.mode)}</span>
    </div>
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">Status</span>
      <span class="text-right">{statusLabel(gameDetail.status)}</span>
    </div>
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">Your Marks</span>
      <span class="text-right">{yourMarks}</span>
    </div>
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">Entry Fee</span>
      <span class="text-right break-all">
        {tokenService.formatBalance(gameDetail.entryFee, 8)}
        &nbsp;{tokenSymbol(gameDetail.tokenType)}
      </span>
    </div>
    <div class="flex justify-between gap-2 sm:gap-4">
      <span class="text-[#C9B5E8]">Prize Pool</span>
      <span class="text-right break-all">
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