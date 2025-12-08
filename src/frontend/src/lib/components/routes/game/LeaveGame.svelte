<script lang="ts">
  interface Props {
    show: boolean;
    isLeaving: boolean;
    onConfirm: () => void;
    onCancel: () => void;
  }

  let { show, isLeaving, onConfirm, onCancel }: Props = $props();
</script>

{#if show}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
    onclick={(e) => e.target === e.currentTarget && onCancel()}
  >
    <div class="arcade-panel p-4 sm:p-6 max-w-md w-full">
      <div class="mb-3 sm:mb-4">
        <span class="arcade-badge bg-[#FF6EC7]"> Leave Game </span>
      </div>

      <h3
        class="text-lg sm:text-xl font-black text-[#F4E04D] uppercase mb-3 sm:mb-4 arcade-text-shadow"
      >
        Leave this game?
      </h3>

      <div
        class="arcade-panel-sm p-3 sm:p-4 mb-4 sm:mb-6 border-2 border-[#FF6EC7]"
      >
        <p class="text-white text-xs sm:text-sm font-bold mb-2 sm:mb-3">
          If you leave now:
        </p>
        <ul
          class="text-[#C9B5E8] text-xs space-y-1 sm:space-y-2 list-disc list-inside"
        >
          <li>You will be removed from this game lobby</li>
          <li>Your tablas will be released back to the pool</li>
          <li>
            If you have already paid, the system will attempt to refund your
            entry fee (minus network fees)
          </li>
          <li>This action cannot be undone</li>
        </ul>
      </div>

      <p class="text-white text-xs font-bold mb-4 sm:mb-6 text-center">
        Are you sure you want to leave this game?
      </p>

      <div class="flex gap-2 sm:gap-3">
        <button
          class="flex-1 bg-[#C9B5E8] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 sm:py-3 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0] active:scale-95 disabled:bg-gray-400 disabled:cursor-not-allowed"
          onclick={onCancel}
          disabled={isLeaving}
        >
          Stay
        </button>
        <button
          class="flex-1 bg-[#FF6EC7] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 sm:py-3 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#ff8fd4] active:scale-95 disabled:bg-gray-400 disabled:cursor-not-allowed"
          onclick={onConfirm}
          disabled={isLeaving}
        >
          {isLeaving ? "LEAVING..." : "YES, LEAVE GAME"}
        </button>
      </div>
    </div>
  </div>
{/if}
