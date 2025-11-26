<script lang="ts">
  import { goto } from "$app/navigation";
  import { TokenService } from "$lib/services/token-service";
  import { tokenSymbol } from "$lib/utils/game-helper";

  interface Props {
    show: boolean;
    potBalance: bigint | null;
    tokenType: any;
    hostFeePercent: number;
    onClose: () => void;
  }

  let { show, potBalance, tokenType, hostFeePercent, onClose }: Props =
    $props();

  const tokenService = new TokenService();

  const OWNER_FEE_PERCENT = 10;
  const PLATFORM_FEE_PERCENT = 5;

  function pct(amt: bigint, p: number): bigint {
    return (amt * BigInt(p)) / 100n;
  }

  const estPlatformFee = $derived(
    potBalance !== null ? pct(potBalance, PLATFORM_FEE_PERCENT) : null,
  );

  const estOwnerFee = $derived(
    potBalance !== null ? pct(potBalance, OWNER_FEE_PERCENT) : null,
  );

  const estHostFee = $derived(
    potBalance !== null ? pct(potBalance, hostFeePercent) : null,
  );

  const estWinnerAmt = $derived(
    potBalance !== null &&
      estPlatformFee !== null &&
      estOwnerFee !== null &&
      estHostFee !== null
      ? potBalance - estPlatformFee - estOwnerFee - estHostFee
      : null,
  );

  const formattedPot = $derived(
    potBalance !== null ? tokenService.formatBalance(potBalance, 8) : "—",
  );
</script>

{#if show}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="fixed inset-0 z-[100] bg-black/70 flex items-center justify-center px-4"
    onclick={(e) => e.target === e.currentTarget && onClose()}
  >
    <div
      class="max-w-md w-full bg-gradient-to-b from-[#F4E04D] to-[#ffef9a] border-8 border-black shadow-[12px_12px_0_rgba(0,0,0,0.9)] p-4 sm:p-6 text-center"
    >
      <h2
        class="text-2xl sm:text-3xl font-black uppercase text-[#1a0033]"
        style="text-shadow:2px 2px 0 #fff"
      >
        🎉 Bingo!
      </h2>

      <p class="mt-3 text-sm font-bold text-[#1a0033] uppercase">
        You've won the prize pool
      </p>

      <p
        class="mt-2 text-2xl sm:text-3xl font-black text-[#1a0033]"
        style="text-shadow:1px 1px 0 #fff"
      >
        {estWinnerAmt !== null
          ? tokenService.formatBalance(estWinnerAmt, 8)
          : formattedPot}
        &nbsp;{tokenSymbol(tokenType)}
      </p>

      <div
        class="mt-5 bg-white/70 border-4 border-black text-left p-3 sm:p-4 font-black uppercase text-xs text-[#1a0033]"
      >
        <div class="flex justify-between mb-2">
          <span>Total Prize Pool</span>
          <span class="break-all">
            {formattedPot}
            {tokenSymbol(tokenType)}
          </span>
        </div>
        <div class="h-px bg-black/30 my-2"></div>
        <div class="flex justify-between mb-1">
          <span>Platform ({PLATFORM_FEE_PERCENT}%)</span>
          <span class="break-all">
            {estPlatformFee !== null
              ? tokenService.formatBalance(estPlatformFee, 8)
              : "—"}
            {tokenSymbol(tokenType)}
          </span>
        </div>
        <div class="flex justify-between mb-1">
          <span>Tabla Owner ({OWNER_FEE_PERCENT}%)</span>
          <span class="break-all">
            {estOwnerFee !== null
              ? tokenService.formatBalance(estOwnerFee, 8)
              : "—"}
            {tokenSymbol(tokenType)}
          </span>
        </div>
        <div class="flex justify-between mb-1">
          <span>Host ({hostFeePercent}%)</span>
          <span class="break-all">
            {estHostFee !== null
              ? tokenService.formatBalance(estHostFee, 8)
              : "—"}
            {tokenSymbol(tokenType)}
          </span>
        </div>
        <div class="h-px bg-black/30 my-2"></div>
        <div class="flex justify-between mb-1">
          <span>Winner (Estimated)</span>
          <span class="break-all">
            {estWinnerAmt !== null
              ? tokenService.formatBalance(estWinnerAmt, 8)
              : "—"}
            {tokenSymbol(tokenType)}
          </span>
        </div>
        <div class="mt-2 text-[10px] text-[#4b3c00]">
          Network fees not included in estimate; actual payouts may vary
          slightly.
        </div>
      </div>

      <div class="mt-4 sm:mt-6 flex items-center justify-center gap-2 sm:gap-3">
        <button
          class="flex-1 bg-white text-[#1a0033] border-4 border-black px-4 sm:px-5 py-2 font-black uppercase text-xs sm:text-sm shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#C9B5E8] active:scale-95"
          onclick={onClose}
        >
          Close
        </button>
        <button
          class="flex-1 bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 sm:px-5 py-2 font-black uppercase text-xs sm:text-sm shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-white active:scale-95"
          onclick={() => goto("/dashboard")}
        >
          Dashboard
        </button>
      </div>
    </div>
  </div>
{/if}
