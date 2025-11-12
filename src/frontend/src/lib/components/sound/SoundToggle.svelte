<script lang="ts">
  import { audioStore, type AudioState } from "$lib/stores/audio-store";
  import { get } from "svelte/store";

  // local reactive state mirrors the store
  let state = $state<AudioState>(get(audioStore));

  // keep in sync with the store
  $effect(() => {
    const unsub = audioStore.subscribe((v) => (state = v));
    return unsub;
  });

  function toggleAll() {
    const next = {
      ...state,
      muted: {
        music: !(state.muted.music && state.muted.sfx),
        sfx: !(state.muted.music && state.muted.sfx),
      },
    };
    state = next;
    audioStore.set(next);
  }

  // computed (use $derived, not $:)
  const allMuted = $derived(state.muted.music && state.muted.sfx);
</script>

<button
  class="bg-[#F4E04D] text-[#1a0033] border-4 border-black px-3 py-2 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] transition-colors flex items-center gap-2"
  title={allMuted ? "Unmute" : "Mute"}
  onclick={toggleAll}
  aria-pressed={allMuted}
>
  <svg
    width="18"
    height="18"
    viewBox="0 0 24 24"
    fill="currentColor"
    aria-hidden="true"
    class="relative"
  >
    <path d="M3 10v4h4l5 4V6L7 10H3z"></path>
    {#if !allMuted}
      <path
        d="M16 7a5 5 0 010 10"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
      />
      <path
        d="M18 5a8 8 0 010 14"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
      />
    {:else}
      <!-- X mark for muted -->
      <line
        x1="16"
        y1="8"
        x2="22"
        y2="14"
        stroke="currentColor"
        stroke-width="3"
      />
      <line
        x1="22"
        y1="8"
        x2="16"
        y2="14"
        stroke="currentColor"
        stroke-width="3"
      />
    {/if}
  </svg>
  <span class="hidden sm:inline">SOUND</span>
</button>
