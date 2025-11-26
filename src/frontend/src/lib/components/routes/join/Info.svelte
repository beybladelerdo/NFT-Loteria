<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    show: boolean;
    title: string;
    onClose: () => void;
    children: Snippet;
  }

  let { show, title, onClose, children }: Props = $props();
</script>

{#if show}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
    onclick={onClose}
  >
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="arcade-panel p-4 sm:p-6 max-w-lg w-full"
      onclick={(e) => e.stopPropagation()}
    >
      <div class="flex items-start justify-between mb-4">
        <h3
          class="text-lg sm:text-xl font-black text-[#F4E04D] uppercase arcade-text-shadow"
        >
          {title}
        </h3>
        <button
          onclick={onClose}
          class="w-8 h-8 bg-[#FF6EC7] text-white border-2 border-black font-black text-lg shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#ff8fd4] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
        >
          ✕
        </button>
      </div>

      <div
        class="space-y-3 text-white text-xs sm:text-sm font-bold leading-relaxed"
      >
        {@render children()}
      </div>
    </div>
  </div>
{/if}
