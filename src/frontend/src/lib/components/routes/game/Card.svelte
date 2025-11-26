<script lang="ts">
  import type { TablaInGame } from "$lib/utils/game-helper";
  import type { Rarity } from "$lib/services/game-service";
  import {
    outerBg,
    outerFX,
    panelRing,
    pillClass,
    pillText,
  } from "$lib/utils/game-helper";

  interface TablaCell {
    row: number;
    col: number;
    cardId: number;
    image: string;
    isDrawn: boolean;
    isMarked: boolean;
  }

  interface Props {
    tabla: TablaInGame;
    rarity: Rarity;
    tablaGrid: TablaCell[];
    marksOnTabla: number;
    isGameActive: boolean;
    isMarking: boolean;
    isClaiming: boolean;
    onMark: (cell: TablaCell) => void;
    onClaim: () => void;
  }

  let {
    tabla,
    rarity,
    tablaGrid,
    marksOnTabla,
    isGameActive,
    isMarking,
    isClaiming,
    onMark,
    onClaim,
  }: Props = $props();

  function canMark(cell: TablaCell): boolean {
    return isGameActive && !isMarking && cell.isDrawn && !cell.isMarked;
  }
</script>

<div
  class={`relative rounded-2xl overflow-hidden border-8 border-black shadow-[12px_12px_0_rgba(0,0,0,.9)]
    bg-gradient-to-b ${outerBg(rarity)} ${outerFX(rarity)}`}
>
  <div class="relative p-4 sm:p-5 md:p-6">
    <!-- Tabla Header -->
    <div
      class="mb-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
    >
      <div>
        <span class="arcade-badge inline-block mb-2"> Your Tabla </span>
        <p
          class="text-xl sm:text-2xl font-black text-white uppercase arcade-text-shadow"
        >
          Tabla #{tabla.tablaId}
        </p>
      </div>

      <div class="flex flex-col sm:items-end gap-2">
        <span
          class={`px-3 py-1 text-[11px] font-black uppercase border border-black rounded-md shadow-[2px_2px_0_rgba(0,0,0,1)] ${pillClass(rarity)}`}
        >
          {pillText(rarity)}
        </span>
        <div class="text-[11px] text-[#C9B5E8] font-black uppercase">
          Marks on this tabla: <span class="text-[#F4E04D]">{marksOnTabla}</span
          >
        </div>
      </div>
    </div>

    <!-- Tabla Grid -->
    <div
      class={`rounded-xl border-4 border-[#35125a] bg-[#1a0033]/85 p-2 sm:p-3 ${panelRing(rarity)}`}
    >
      <div class="grid grid-cols-4 gap-1.5 sm:gap-2">
        {#each tablaGrid as cell (cell.row * 10 + cell.col)}
          <button
            class={`relative border-2 border-black bg-[#1a0033] shadow-[3px_3px_0_rgba(0,0,0,1)] overflow-hidden transition
              ${canMark(cell) ? "hover:-translate-y-1 hover:shadow-[4px_4px_0_rgba(0,0,0,1)] active:translate-y-0 active:shadow-[3px_3px_0_rgba(0,0,0,1)] cursor-pointer" : "opacity-60 cursor-not-allowed"}
              ${cell.isDrawn ? "border-[#F4E04D]" : "border-[#35125a]"} 
              ${cell.isMarked ? "ring-2 sm:ring-4 ring-[#29ABE2]" : ""}`}
            disabled={!canMark(cell)}
            onclick={() => onMark(cell)}
          >
            <div
              class="relative w-full overflow-hidden"
              style="aspect-ratio:320/500;"
            >
              <img
                src={cell.image}
                alt={`Card ${cell.cardId}`}
                class={`absolute inset-0 w-full h-full object-contain ${cell.isMarked ? "opacity-30" : ""}`}
                loading="lazy"
                decoding="async"
              />

              {#if cell.isMarked}
                <div
                  class="absolute inset-0 bg-[#29ABE2]/70 border-2 border-[#29ABE2] flex items-center justify-center"
                >
                  <span class="text-2xl sm:text-3xl font-black text-[#1a0033]"
                    >✓</span
                  >
                </div>
              {:else if cell.isDrawn}
                <div
                  class="absolute inset-0 border-2 sm:border-4 border-[#F4E04D] pointer-events-none"
                ></div>
              {/if}

              <span
                class="absolute top-0.5 left-0.5 sm:top-1 sm:left-1 z-10 bg-[#1a0033]/90 text-white text-[9px] sm:text-[10px] font-black px-1 border border-black rounded-sm pointer-events-none"
              >
                #{cell.cardId}
              </span>
            </div>
          </button>
        {/each}
      </div>
    </div>

    <!-- Tabla Footer -->
    <div
      class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pt-3"
    >
      <p class="text-xs text-[#C9B5E8] font-bold uppercase leading-relaxed">
        Mark drawn cards to track progress. When you complete the pattern, claim
        the win!
      </p>
      <button
        class="arcade-button px-4 py-2 text-xs disabled:bg-gray-400 disabled:cursor-not-allowed whitespace-nowrap"
        disabled={isClaiming || !isGameActive}
        onclick={onClaim}
      >
        {isClaiming ? "CLAIMING..." : "CLAIM WIN"}
      </button>
    </div>
  </div>
</div>
