<script lang="ts">
  interface Props {
    gameName: string;
    gameMode: "Line" | "Blackout";
    errors: { gameName: string };
    onGameNameChange: (name: string) => void;
    onGameModeChange: (mode: "Line" | "Blackout") => void;
  }

  let {
    gameName,
    gameMode,
    errors,
    onGameNameChange,
    onGameModeChange,
  }: Props = $props();
</script>

<div class="mb-4">
  <span class="arcade-badge">Step 1: Setup</span>
</div>

<h2
  class="text-2xl sm:text-3xl font-black text-[#F4E04D] uppercase mb-4 sm:mb-6 arcade-text-shadow"
>
  GAME SETUP
</h2>

<div class="mb-4 sm:mb-6">
  <label
    for="game-name"
    class="block text-sm font-black text-white uppercase mb-2"
  >
    GAME NAME:
  </label>
  <input
    id="game-name"
    type="text"
    value={gameName}
    oninput={(e) => onGameNameChange((e.target as HTMLInputElement).value)}
    placeholder="Enter game name..."
    maxlength="50"
    class="w-full px-3 sm:px-4 py-2 sm:py-3 border-4 border-black bg-white text-[#1a0033] font-bold text-base sm:text-lg focus:outline-none focus:border-[#F4E04D] shadow-[3px_3px_0px_rgba(0,0,0,1)] {errors.gameName
      ? 'border-[#FF6EC7]'
      : ''}"
  />
  {#if errors.gameName}
    <p class="mt-2 text-[#FF6EC7] font-bold text-xs">
      ⚠ {errors.gameName}
    </p>
  {/if}
  <p class="mt-1 text-[#C9B5E8] text-xs font-bold">
    {gameName.length}/50 characters
  </p>
</div>

<div class="mb-4 sm:mb-6">
  <!-- svelte-ignore a11y_label_has_associated_control -->
  <label class="block text-sm font-black text-white uppercase mb-3">
    GAME MODE:
  </label>
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
    <button
      onclick={() => onGameModeChange("Line")}
      class="p-3 sm:p-4 border-4 border-black {gameMode === 'Line'
        ? 'bg-[#F4E04D] text-[#1a0033]'
        : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <div class="text-2xl sm:text-3xl mb-2">━</div>
      <p class="font-black text-sm uppercase">LINE</p>
      <p class="text-xs mt-1 opacity-80">Complete any row/column</p>
    </button>

    <button
      onclick={() => onGameModeChange("Blackout")}
      class="p-3 sm:p-4 border-4 border-black {gameMode === 'Blackout'
        ? 'bg-[#C9B5E8] text-[#1a0033]'
        : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <div class="text-2xl sm:text-3xl mb-2">█</div>
      <p class="font-black text-sm uppercase">BLACKOUT</p>
      <p class="text-xs mt-1 opacity-80">Complete entire tabla</p>
    </button>
  </div>
</div>
