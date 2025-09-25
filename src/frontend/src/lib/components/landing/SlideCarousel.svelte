<script lang="ts">
  export let items: string[] = [];
  export let title: string | null = null;
  export let windowSize = 12;
  export let durationMs = 20000;
  export let reverse = false;
  export let height = 160;
  export let gap = 12;
  export let dark = false;

  let start = 0;

  function pickWindow<T>(arr: T[], s: number, n: number): T[] {
    if (!arr.length) return [];
    const out: T[] = [];
    for (let i = 0; i < Math.min(n, arr.length); i++)
      out.push(arr[(s + i) % arr.length]);
    return out;
  }

  $: current = pickWindow(
    items,
    start,
    Math.min(windowSize, items.length || 0),
  );
  $: doubled = [...current, ...current];

  function advance() {
    if (!items.length) return;
    start = (start + current.length) % items.length;
  }
</script>

{#if title}
  <div class="mb-3 flex items-center justify-between">
    <h3 class={`text-lg font-semibold ${dark ? "text-white" : "text-black"}`}>
      {title}
    </h3>
    <span class={`text-xs ${dark ? "text-white/60" : "text-black/50"}`}
      >{items.length} items</span
    >
  </div>
{/if}

<div class="relative overflow-hidden rounded-xl">
  <!-- edge fades -->
  <div
    class={`pointer-events-none absolute left-0 top-0 h-full w-12 bg-gradient-to-r ${dark ? "from-[#0b0b0b]" : "from-white"} to-transparent`}
  ></div>
  <div
    class={`pointer-events-none absolute right-0 top-0 h-full w-12 bg-gradient-to-l ${dark ? "from-[#0b0b0b]" : "from-white"} to-transparent`}
  ></div>

  <div
    class="flex will-change-transform marquee-track hover:[animation-play-state:paused]"
    style={`--marquee-duration:${durationMs}ms; --marquee-gap:${gap}px; animation-direction:${reverse ? "reverse" : "normal"};`}
    on:animationiteration={advance}
  >
    {#each doubled as src, i}
      <div class="shrink-0" style="margin-right:var(--marquee-gap)">
        <img
          {src}
          alt={`image-${i}`}
          style={`height:${height}px`}
          class={`h-[inherit] w-auto rounded-xl object-cover shadow ${dark ? "bg-white/5 ring-1 ring-white/10" : "bg-black/10 ring-1 ring-black/10"}`}
          loading="lazy"
          decoding="async"
          draggable="false"
        />
      </div>
    {/each}
  </div>
</div>

<style>
  @keyframes marquee {
    from {
      transform: translateX(0);
    }
    to {
      transform: translateX(-50%);
    }
  }
  .marquee-track {
    gap: var(--marquee-gap);
    animation-name: marquee;
    animation-duration: var(--marquee-duration);
    animation-timing-function: linear;
    animation-iteration-count: infinite;
  }
</style>
