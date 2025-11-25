<script lang="ts">
  import { formatAmount, formatTokenType } from "$lib/utils/helpers";

  interface Props {
    failedClaims: any[];
    retryingClaim: string | null;
    onRetryClaim: (gameId: string) => Promise<void>;
  }

  let { failedClaims, retryingClaim, onRetryClaim }: Props = $props();
</script>

{#if failedClaims.length > 0}
  <div class="bg-gradient-to-b from-[#8B0000] to-[#5C0000] p-4 sm:p-6 border-4 border-black shadow-[8px_8px_0px_rgba(0,0,0,0.8)]">
    <div class="mb-4 sm:mb-6">
      <span class="bg-[#FF6B6B] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]">
        ⚠️ Action Required
      </span>
    </div>

    <h2 class="text-2xl sm:text-3xl font-black uppercase mb-3 sm:mb-4 text-[#FF6B6B] arcade-text-shadow">
      PENDING PAYOUTS
    </h2>
    <p class="text-xs sm:text-sm font-bold text-white mb-4 sm:mb-6">
      Some of your winnings failed to transfer. Click retry to claim your funds.
    </p>

    <div class="space-y-3 sm:space-y-4">
      {#each failedClaims as claim}
        <div class="arcade-panel-sm border-[#FF6B6B] p-3 sm:p-4">
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
            <div class="text-center p-2 border border-black {claim.payoutStatus.devFeePaid ? 'bg-green-500' : 'bg-red-500'}">
              DEV FEE
            </div>
            <div class="text-center p-2 border border-black {claim.payoutStatus.tablaOwnerPaid ? 'bg-green-500' : 'bg-red-500'}">
              OWNER
            </div>
            <div class="text-center p-2 border border-black {claim.payoutStatus.winnerPaid ? 'bg-green-500' : 'bg-red-500'}">
              WINNER
            </div>
            <div class="text-center p-2 border border-black {claim.payoutStatus.hostPaid ? 'bg-green-500' : 'bg-red-500'}">
              HOST
            </div>
          </div>

          <div class="text-[10px] font-bold text-[#FF6B6B] mb-3 break-words">
            Error: {claim.lastError}
          </div>

          <button
            onclick={() => onRetryClaim(claim.gameId)}
            disabled={retryingClaim === claim.gameId}
            class="arcade-button w-full py-2 px-3 sm:px-4 text-xs disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {retryingClaim === claim.gameId ? "RETRYING..." : "RETRY CLAIM"}
          </button>
        </div>
      {/each}
    </div>
  </div>
{/if}