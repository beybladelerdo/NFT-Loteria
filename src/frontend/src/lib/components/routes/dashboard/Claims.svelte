<script lang="ts">
  import { formatAmount, formatTokenType } from "$lib/utils/helpers";
  import { Principal } from "@dfinity/principal";
  import type { FailedClaim } from "../../../../../../declarations/backend/backend.did";

  interface Props {
    failedClaims: FailedClaim[];
    retryingClaim: string | null;
    onRetryClaim: (gameId: string) => Promise<void>;
    callerPrincipal: string;
    isLoading?: boolean;
  }

  let {
    failedClaims,
    retryingClaim,
    onRetryClaim,
    callerPrincipal,
    isLoading = false,
  }: Props = $props();

  let isExpanded = $state(false);

  const isRelevantClaim = (claim: FailedClaim): boolean => {
    const isPlayer = claim.player.toString() === callerPrincipal;
    const isHost = claim.host.toString() === callerPrincipal;

    return (
      (isPlayer && !claim.payoutStatus.winnerPaid) ||
      (isHost && !claim.payoutStatus.hostPaid)
    );
  };

  let relevantClaims = $derived(failedClaims.filter(isRelevantClaim));
  let hasFailedClaims = $derived(relevantClaims.length > 0);
</script>

<div class="arcade-panel p-4 sm:p-6">
  <button onclick={() => (isExpanded = !isExpanded)} class="w-full text-left">
    <div class="flex items-start justify-between gap-4">
      <div>
        <!-- Section label -->
        <div class="flex items-center gap-2 mb-2">
          <span class="arcade-badge">Payout Tools</span>
        </div>

        <h2
          class="text-xl sm:text-2xl font-black uppercase text-[#F4E04D] arcade-text-shadow"
        >
          Payout Recovery
        </h2>
        <p
          class="mt-1 text-[10px] sm:text-xs text-[#C9B5E8] font-bold uppercase"
        >
          Check and retry any pending payouts
        </p>
      </div>

      <div class="flex flex-col items-end gap-2 sm:gap-3">
        {#if hasFailedClaims}
          <span
            class="arcade-badge bg-[#FF6EC7] text-[#1a0033] text-xs sm:text-sm"
          >
            {relevantClaims.length} pending
          </span>
        {/if}
        <span
          class={`inline-flex items-center justify-center h-7 w-7 sm:h-8 sm:w-8 bg-[#1a0033] border-2 border-black text-[#F4E04D] text-xs sm:text-sm font-black shadow-[3px_3px_0_rgba(0,0,0,1)] transition-transform duration-200 ${
            isExpanded ? "rotate-180" : ""
          }`}
        >
          ▼
        </span>
      </div>
    </div>
  </button>

  {#if isExpanded}
    <div class="mt-4 sm:mt-6 pt-4 sm:pt-6 border-t-4 border-[#35125a]">
      {#if isLoading}
        <div class="arcade-panel-sm p-6 sm:p-8 text-center">
          <div class="text-[#C9B5E8] text-sm font-bold uppercase animate-pulse">
            Checking for pending payouts...
          </div>
        </div>
      {:else if !hasFailedClaims}
        <!-- Yellow box with purple tick -->
        <div
          class="arcade-panel-sm p-6 sm:p-8 text-center bg-[#F4E04D] border-[#1a0033]"
        >
          <span
            class="inline-flex items-center justify-center mb-3 h-12 w-12 sm:h-14 sm:w-14 mx-auto rounded-sm border-2 border-[#1a0033] bg-[#F4E04D] text-4xl sm:text-5xl font-black text-[#6D28D9] shadow-[3px_3px_0_rgba(0,0,0,1)]"
          >
            ✓
          </span>
          <div
            class="text-[#F4E04D] font-black text-base sm:text-lg uppercase mb-2 arcade-text-shadow"
          >
            All payouts complete!
          </div>
          <div class="text-[#F4E04D] text-xs sm:text-sm font-bold uppercase">
            No pending claims to recover.
          </div>
        </div>
      {:else}
        <div
          class="arcade-panel-sm p-3 sm:p-4 mb-4 sm:mb-6 bg-[#FF6EC7]/10 border-[#FF6EC7]"
        >
          <p
            class="text-xs sm:text-sm text-white font-bold uppercase leading-relaxed"
          >
            ⚠️ The following payouts need attention. This can happen due to
            network issues. Click retry to complete the transfer.
          </p>
        </div>

        <div class="space-y-3 sm:space-y-4">
          {#each relevantClaims as claim}
            <div
              class="arcade-panel-sm p-3 sm:p-4 bg-gradient-to-b from-[#2a1344] to-[#1a0033] border-[#FF6EC7]"
            >
              <!-- Header with Game ID and Amount -->
              <div class="flex items-center justify-between mb-3 sm:mb-4 gap-2">
                <div
                  class="text-xs sm:text-sm font-black text-[#C9B5E8] uppercase"
                >
                  Game:
                  <span class="text-[#F4E04D]">
                    {claim.gameId.slice(0, 8)}...
                  </span>
                </div>
                <div
                  class="text-sm sm:text-base font-black text-[#F4E04D] flex-shrink-0 arcade-text-shadow"
                >
                  {formatAmount(claim.winnerAmount, claim.tokenType)}
                  {formatTokenType(claim.tokenType)}
                </div>
              </div>

              <!-- Payout Status Grid -->
              <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-3 sm:mb-4">
                <div
                  class={`text-center p-2 sm:p-3 border-2 border-black font-black text-[10px] sm:text-xs uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
                    claim.payoutStatus.devFeePaid
                      ? "bg-[#4ade80] text-[#1a0033]"
                      : "bg-[#ef4444] text-white"
                  }`}
                >
                  Dev Fee {claim.payoutStatus.devFeePaid ? "✓" : "✗"}
                </div>
                <div
                  class={`text-center p-2 sm:p-3 border-2 border-black font-black text-[10px] sm:text-xs uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
                    claim.payoutStatus.tablaOwnerPaid
                      ? "bg-[#4ade80] text-[#1a0033]"
                      : "bg-[#ef4444] text-white"
                  }`}
                >
                  Owner {claim.payoutStatus.tablaOwnerPaid ? "✓" : "✗"}
                </div>
                <div
                  class={`text-center p-2 sm:p-3 border-2 border-black font-black text-[10px] sm:text-xs uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
                    claim.payoutStatus.winnerPaid
                      ? "bg-[#4ade80] text-[#1a0033]"
                      : "bg-[#ef4444] text-white"
                  }`}
                >
                  Winner {claim.payoutStatus.winnerPaid ? "✓" : "✗"}
                </div>
                <div
                  class={`text-center p-2 sm:p-3 border-2 border-black font-black text-[10px] sm:text-xs uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
                    claim.payoutStatus.hostPaid
                      ? "bg-[#4ade80] text-[#1a0033]"
                      : "bg-[#ef4444] text-white"
                  }`}
                >
                  Host {claim.payoutStatus.hostPaid ? "✓" : "✗"}
                </div>
              </div>

              <!-- Error Message -->
              {#if claim.lastError}
                <div
                  class="arcade-panel-sm p-2 sm:p-3 mb-3 sm:mb-4 bg-[#ef4444]/20 border-[#ef4444]"
                >
                  <p
                    class="text-[10px] sm:text-xs text-[#ef4444] font-bold uppercase break-words leading-relaxed"
                  >
                    {claim.lastError}
                  </p>
                </div>
              {/if}

              <!-- Retry Button -->
              <button
                onclick={() => onRetryClaim(claim.gameId)}
                disabled={retryingClaim === claim.gameId}
                class="arcade-button w-full py-2 sm:py-3 text-xs sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {retryingClaim === claim.gameId
                  ? "RETRYING..."
                  : "RETRY PAYOUT"}
              </button>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  {/if}
</div>
