<script lang="ts">
  import { formatSmart } from "$lib/utils/game-helper";

  interface Props {
    balances: {
      ICP: number;
      ckBTC: number;
      GLDT: number;
    };
    isLoading: boolean;
    onRefresh: () => void;
  }

  let { balances, isLoading, onRefresh }: Props = $props();
</script>

<div class="arcade-panel-sm p-4 mb-4 sm:mb-6">
  <div class="flex items-center justify-between mb-3">
    <p class="text-[#C9B5E8] font-black text-xs sm:text-sm uppercase">
      YOUR BALANCE:
    </p>
    <button
      onclick={onRefresh}
      disabled={isLoading}
      class="bg-[#C9B5E8] text-[#1a0033] px-3 py-1.5 font-black uppercase border-2 border-black hover:bg-[#d9c9f0] active:scale-95 disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-xs shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      {isLoading ? "..." : "⟳ REFRESH"}
    </button>
  </div>
  <div class="grid grid-cols-3 gap-2 sm:gap-3">
    <div
      class="bg-[#F4E04D] border-2 border-black p-2 sm:p-3 text-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <p
        class="text-[#1a0033] font-black text-base sm:text-lg md:text-xl truncate"
      >
        {formatSmart(balances.ICP)}
      </p>
      <p class="text-[#1a0033] font-bold text-[10px] sm:text-xs">ICP</p>
    </div>
    <div
      class="bg-[#C9B5E8] border-2 border-black p-2 sm:p-3 text-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <p
        class="text-[#1a0033] font-black text-base sm:text-lg md:text-xl truncate"
      >
        {formatSmart(balances.ckBTC)}
      </p>
      <p class="text-[#1a0033] font-bold text-[10px] sm:text-xs">ckBTC</p>
    </div>
    <div
      class="bg-white border-2 border-black p-2 sm:p-3 text-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <p
        class="text-[#1a0033] font-black text-base sm:text-lg md:text-xl truncate"
      >
        {formatSmart(balances.GLDT)}
      </p>
      <p class="text-[#1a0033] font-bold text-[10px] sm:text-xs">GLDT</p>
    </div>
  </div>
</div>
