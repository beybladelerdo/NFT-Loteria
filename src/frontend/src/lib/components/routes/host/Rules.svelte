<script lang="ts">
  interface Props {
    tokenType: "ICP" | "ckBTC" | "GLDT";
    entryFeeInput: string;
    hostFeePercent: number;
    maxPlayers: number;
    errors: { entryFee: string };
    onTokenTypeChange: (token: "ICP" | "ckBTC" | "GLDT") => void;
    onEntryFeeInput: (e: Event) => void;
    onHostFeeChange: (fee: number) => void;
  }

  let {
    tokenType,
    entryFeeInput,
    hostFeePercent,
    maxPlayers,
    errors,
    onTokenTypeChange,
    onEntryFeeInput,
    onHostFeeChange,
  }: Props = $props();
</script>

<div class="mb-4">
  <span class="arcade-badge bg-[#C9B5E8]">Step 2: Rules</span>
</div>

<h2
  class="text-2xl sm:text-3xl font-black text-[#C9B5E8] uppercase mb-4 sm:mb-6 arcade-text-shadow"
>
  GAME RULES
</h2>

<div class="mb-4 sm:mb-6">
  <!-- svelte-ignore a11y_label_has_associated_control -->
  <label class="block text-sm font-black text-white uppercase mb-3">
    TOKEN TYPE:
  </label>
  <div class="grid grid-cols-3 gap-2 sm:gap-3">
    <button
      onclick={() => onTokenTypeChange("ICP")}
      class="p-2 sm:p-3 border-4 border-black {tokenType === 'ICP'
        ? 'bg-[#F4E04D] text-[#1a0033]'
        : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all font-black uppercase text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
    >
      ICP
    </button>
    <button
      onclick={() => onTokenTypeChange("ckBTC")}
      class="p-2 sm:p-3 border-4 border-black {tokenType === 'ckBTC'
        ? 'bg-[#C9B5E8] text-[#1a0033]'
        : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all font-black uppercase text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
    >
      ckBTC
    </button>
    <button
      onclick={() => onTokenTypeChange("GLDT")}
      class="p-2 sm:p-3 border-4 border-black {tokenType === 'GLDT'
        ? 'bg-white text-[#1a0033]'
        : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all font-black uppercase text-xs sm:text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
    >
      GLDT
    </button>
  </div>
</div>

<div class="mb-4 sm:mb-6">
  <label
    for="entry-fee"
    class="block text-sm font-black text-white uppercase mb-2"
  >
    ENTRY FEE (up to 8 decimals):
  </label>
  <input
    id="entry-fee"
    type="text"
    inputmode="decimal"
    pattern="[0-9]*\.?[0-9]*"
    value={entryFeeInput}
    oninput={onEntryFeeInput}
    placeholder="0.00000000"
    class="w-full px-3 sm:px-4 py-2 sm:py-3 border-4 border-black bg-white text-[#1a0033] font-black text-xl sm:text-2xl text-center focus:outline-none focus:border-[#F4E04D] shadow-[3px_3px_0px_rgba(0,0,0,1)] {errors.entryFee
      ? 'border-[#FF6EC7]'
      : ''}"
  />
  {#if errors.entryFee}
    <p class="mt-2 text-[#FF6EC7] font-bold text-xs">
      ⚠ {errors.entryFee}
    </p>
  {/if}
</div>

<div class="mb-4 sm:mb-6">
  <label
    for="host-fee"
    class="block text-sm font-black text-white uppercase mb-2"
  >
    HOST FEE: <span class="text-[#F4E04D]">{hostFeePercent}%</span>
  </label>
  <input
    id="host-fee"
    type="range"
    value={hostFeePercent}
    oninput={(e) =>
      onHostFeeChange(Number((e.target as HTMLInputElement).value))}
    min="0"
    max="20"
    step="1"
    class="w-full h-3 sm:h-4 bg-[#1a0033] border-2 border-black appearance-none cursor-pointer rounded"
  />
  <div class="flex justify-between mt-2">
    <span class="text-xs font-bold text-[#C9B5E8]">0%</span>
    <span class="text-xs font-bold text-[#C9B5E8]">20%</span>
  </div>
</div>

<div
  class="bg-[#F4E04D] border-2 border-black p-3 shadow-[2px_2px_0px_rgba(0,0,0,1)]"
>
  <p class="text-[#1a0033] font-bold text-xs uppercase text-center">
    MAX PLAYERS: {maxPlayers}
  </p>
</div>
