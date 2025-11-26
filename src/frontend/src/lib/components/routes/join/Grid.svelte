<script lang="ts">
  import type { TablaInfo } from "$lib/utils/helpers";
  import {
    getRarityColor,
    getRarityText,
    getRarityGlow,
  } from "$lib/utils/helpers";

  interface Props {
    tablas: TablaInfo[];
    selectedIds: number[];
    onSelect: (tabla: TablaInfo) => void;
  }

  let { tablas, selectedIds, onSelect }: Props = $props();
</script>

<div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
  {#each tablas as tabla (tabla.id)}
    <button
      onclick={() => onSelect(tabla)}
      class="group relative arcade-panel-sm p-2 transition-all {selectedIds.includes(
        tabla.id,
      )
        ? 'ring-4 ring-[#F4E04D] shadow-[6px_6px_0px_rgba(0,0,0,1)]'
        : 'hover:-translate-y-1 hover:shadow-[6px_6px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-[4px_4px_0px_rgba(0,0,0,1)]'}"
    >
      <div
        class="relative rounded-md overflow-hidden border-2 border-[#C9B5E8] bg-[#0f0220] {getRarityGlow(
          tabla.rarity,
        )}"
        style="aspect-ratio: 569/1000;"
      >
        <img
          src={tabla.image}
          alt={tabla.name}
          loading="lazy"
          decoding="async"
          class="absolute inset-0 w-full h-full object-contain"
        />
      </div>

      {#if selectedIds.includes(tabla.id)}
        <div
          class="absolute inset-0 bg-[#F4E04D] bg-opacity-20 border-2 border-[#F4E04D] flex items-center justify-center pointer-events-none"
        >
          <div
            class="bg-[#F4E04D] text-[#1a0033] w-10 h-10 sm:w-12 sm:h-12 rounded-full border-4 border-black flex items-center justify-center shadow-[3px_3px_0px_rgba(0,0,0,1)]"
          >
            <span class="text-xl sm:text-2xl font-black">✓</span>
          </div>
        </div>
      {/if}

      <div class="mt-2 space-y-1">
        <p
          class="text-[10px] sm:text-xs font-bold text-white text-center uppercase break-words"
        >
          {tabla.name}
        </p>

        <div
          class="text-[9px] sm:text-[10px] font-bold text-center px-2 py-0.5 border border-black"
          style="background-color: {getRarityColor(
            tabla.rarity,
          )}; color: #1a0033;"
        >
          {getRarityText(tabla.rarity)}
        </div>
      </div>
    </button>
  {/each}
</div>
