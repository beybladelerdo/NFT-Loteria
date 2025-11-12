<script lang="ts">
  import { audioStore, type AudioState } from "$lib/stores/audio-store";
  import { get } from "svelte/store";
  import { onDestroy } from "svelte";

  // local reactive state mirrors the store
  let state: AudioState = get(audioStore);

  // keep in sync with the store
  const unsub = audioStore.subscribe((v) => (state = v));
  onDestroy(() => unsub());

  let open = false;
  let panel: HTMLDivElement | null = null;

  // attach/detach listeners only when open
  function onDocClick(e: MouseEvent) {
    if (!open) return;
    if (panel && !panel.contains(e.target as Node)) open = false;
  }

  function onKey(e: KeyboardEvent) {
    if (e.key === "Escape") open = false;
  }

  $: {
    if (open) {
      document.addEventListener("click", onDocClick);
      document.addEventListener("keydown", onKey);
    } else {
      document.removeEventListener("click", onDocClick);
      document.removeEventListener("keydown", onKey);
    }
  }

  // ensure listeners removed on destroy
  onDestroy(() => {
    document.removeEventListener("click", onDocClick);
    document.removeEventListener("keydown", onKey);
  });

  function setMute(cat: "music" | "sfx", val: boolean) {
    const next: AudioState = {
      ...state,
      muted: { ...state.muted, [cat]: val },
    };
    state = next;
    audioStore.set(next);
  }

  function setVol(cat: "music" | "sfx", val: number) {
    const next: AudioState = {
      ...state,
      volume: { ...state.volume, [cat]: val },
    };
    state = next;
    audioStore.set(next);
  }
</script>

<button
  class="pixel-button w-10 h-10 grid place-items-center bg-[#1a0033] text-yellow-300"
  onclick={() => (open = !open)}
  aria-haspopup="dialog"
  aria-expanded={open}
  title="Sound settings"
>
  <svg
    width="20"
    height="20"
    viewBox="0 0 24 24"
    fill="currentColor"
    aria-hidden="true"
  >
    <path
      d="M12 8a4 4 0 100 8 4 4 0 000-8zm9 4a7.9 7.9 0 00-.15-1.5l2.06-1.6-2-3.46-2.49 1a8.1 8.1 0 00-2.6-1.5L13 1h-4l-.82 3.94a8.1 8.1 0 00-2.6 1.5l-2.49-1-2 3.46 2.06 1.6A7.9 7.9 0 003 12c0 .51.05 1.01.15 1.5l-2.06 1.6 2 3.46 2.49-1a8.1 8.1 0 002.6 1.5L9 23h4l.82-3.94a8.1 8.1 0 002.6-1.5l2.49 1 2-3.46-2.06-1.6c.1-.49.15-.99.15-1.5z"
    />
  </svg>
</button>

{#if open}
  <div
    bind:this={panel}
    class="pixel-panel absolute right-0 mt-2 w-80 p-4 z-50 text-white"
    role="dialog"
    aria-label="Sound settings"
  >
    <div class="mb-3 text-sm opacity-80">Sound</div>
    {#each ["music", "sfx"] as const as cat}
      <div class="mb-4">
        <div class="flex items-center justify-between mb-2">
          <span class="capitalize">{cat}</span>
          <label class="inline-flex items-center gap-2 text-xs">
            <input
              type="checkbox"
              checked={state.muted[cat]}
              onchange={(e) =>
                setMute(cat, (e.target as HTMLInputElement).checked)}
            />
            Mute
          </label>
        </div>
        <input
          type="range"
          min="0"
          max="1"
          step="0.01"
          class="w-full"
          value={state.volume[cat]}
          oninput={(e) =>
            setVol(cat, Number((e.target as HTMLInputElement).value))}
        />
      </div>
    {/each}
    <div class="text-right">
      <button
        class="pixel-button px-3 py-1 bg-white text-black"
        onclick={() => (open = false)}
      >
        Close
      </button>
    </div>
  </div>
{/if}

<style>
  :global(.pixel-panel input[type="range"]) {
    accent-color: #ffdd33;
  }
</style>
