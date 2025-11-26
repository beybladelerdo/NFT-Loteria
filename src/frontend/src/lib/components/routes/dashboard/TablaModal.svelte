<script lang="ts">
  import type { TablaEarnings } from "../../../../../../declarations/backend/backend.did";
  import {
    toNumber,
    formatTokenEarnings,
    formatLastUsed,
  } from "$lib/utils/helpers";

  interface Props {
    tabla: TablaEarnings | null;
    isOpen: boolean;
    onClose: () => void;
  }

  let { tabla, isOpen, onClose }: Props = $props();

  function handleBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) {
      onClose();
    }
  }
  function handleModalClick(event: MouseEvent) {
    event.stopPropagation();
  }
</script>

{#if isOpen && tabla}
  <!-- svelte-ignore a11y_interactive_supports_focus -->
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 p-4"
    onclick={handleBackdropClick}
    role="dialog"
    aria-modal="true"
    aria-labelledby="tabla-modal-title"
  >
    <div
      class="relative max-w-md w-full arcade-panel p-4 sm:p-6 rounded-xl max-h-[90vh] overflow-y-auto"
    >
      <button
        type="button"
        onclick={handleModalClick}
        class="absolute top-3 right-3 bg-white text-[#1a0033] border-2 border-black rounded-full w-7 h-7 flex items-center justify-center text-xs font-black shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#F4E04D] transition-colors"
        aria-label="Close modal"
      >
        ✕
      </button>

      <h3
        id="tabla-modal-title"
        class="text-xl sm:text-2xl font-black uppercase mb-4 text-[#F4E04D] pr-8 arcade-text-shadow"
      >
        Tabla #{tabla.tablaId} Earnings
      </h3>

      <div class="grid grid-cols-2 gap-3 mb-4 text-xs sm:text-sm">
        <div
          class="bg-[#F4E04D] text-[#1a0033] border-2 border-black p-3 shadow-[3px_3px_0px_rgba(0,0,0,1)]"
        >
          <div class="font-black uppercase">Games Played</div>
          <div class="text-2xl sm:text-3xl font-black">
            {toNumber(tabla.gamesPlayed)}
          </div>
        </div>
        <div
          class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black p-3 shadow-[3px_3px_0px_rgba(0,0,0,1)]"
        >
          <div class="font-black uppercase text-[10px] sm:text-xs">
            Last Used
          </div>
          <div class="text-xs sm:text-sm font-bold mt-1">
            {formatLastUsed(tabla.lastUsed)}
          </div>
        </div>
      </div>

      <div
        class="bg-[#25004d] border-2 border-black p-3 sm:p-4 mb-4 shadow-[3px_3px_0px_rgba(0,0,0,1)] rounded-lg"
      >
        <div
          class="text-xs sm:text-sm font-black text-[#C9B5E8] uppercase mb-2"
        >
          Earnings Breakdown
        </div>
        <div class="space-y-2 text-xs sm:text-sm">
          <div class="flex items-center justify-between">
            <span class="text-[#F4E04D] font-black uppercase">ICP</span>
            <span class="text-white font-mono">
              {formatTokenEarnings(tabla.earningsICP)} ICP
            </span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-[#F4E04D] font-black uppercase">ckBTC</span>
            <span class="text-white font-mono">
              {formatTokenEarnings(tabla.earningsCkBTC)} ckBTC
            </span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-[#F4E04D] font-black uppercase">GLDT</span>
            <span class="text-white font-mono">
              {formatTokenEarnings(tabla.earningsGLDT)} GLDT
            </span>
          </div>
        </div>
      </div>

      <div class="text-[10px] sm:text-xs text-[#C9B5E8]">
        <p>
          Tip: reuse high-earning tablas when you host or join games to maximize
          your returns.
        </p>
      </div>
    </div>
  </div>
{/if}
