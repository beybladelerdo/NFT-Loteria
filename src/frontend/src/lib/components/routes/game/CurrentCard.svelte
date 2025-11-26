<script lang="ts">
  interface Props {
    cardId: number | null;
    cardImage: string;
  }

  let { cardId, cardImage }: Props = $props();
</script>

<div class="arcade-panel-sm p-2 sm:p-3 flex flex-col items-center gap-2">
  {#if cardId}
    <div
      class="relative w-full overflow-hidden rounded-sm border-2 border-[#F4E04D] bg-[#0f0220]"
      style="aspect-ratio:320/500;"
    >
      <img
        src={cardImage}
        alt={`Current card ${cardId}`}
        class="absolute inset-0 w-full h-full object-contain"
        loading="lazy"
        decoding="async"
      />
    </div>
    <span class="text-xs font-black text-[#F4E04D] uppercase">
      Current Card #{cardId}
    </span>
  {:else}
    <div
      class="text-center text-[#C9B5E8] font-bold text-xs uppercase py-6 sm:py-8"
    >
      Waiting for first draw...
    </div>
  {/if}
</div>
