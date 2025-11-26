<script lang="ts">
  interface Props {
    drawnCards: number[];
    currentCardId: number | null;
    getCardImage: (id: number) => string;
  }

  let { drawnCards, currentCardId, getCardImage }: Props = $props();
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="mb-3 sm:mb-4">
    <span class="arcade-badge"> Draw History </span>
  </div>

  {#if drawnCards.length === 0}
    <div class="arcade-panel-sm p-4 sm:p-6 text-center">
      <p class="text-[#C9B5E8] font-bold uppercase text-xs">
        No cards have been drawn yet. Hit "Draw Next Card" to begin.
      </p>
    </div>
  {:else}
    <div
      class="max-h-[400px] sm:max-h-[500px] overflow-y-auto overflow-x-hidden arcade-panel-sm p-2 sm:p-3"
    >
      <div
        class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-2 sm:gap-3"
      >
        {#each drawnCards as id (id)}
          <div
            class={`relative arcade-panel-sm p-1 sm:p-2 ${
              id === currentCardId ? "ring-2 sm:ring-4 ring-[#F4E04D]" : ""
            }`}
          >
            <div
              class="relative w-full overflow-hidden rounded-sm border border-[#C9B5E8] bg-[#0f0220]"
              style="aspect-ratio:320/500;"
            >
              <img
                src={getCardImage(id)}
                alt={`Card ${id}`}
                class="absolute inset-0 w-full h-full object-contain"
                loading="lazy"
                decoding="async"
              />
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>
