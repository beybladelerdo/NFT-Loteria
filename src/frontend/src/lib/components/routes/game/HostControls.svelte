<script lang="ts">
  interface Props {
    status: any;
    isStarting: boolean;
    isDrawing: boolean;
    isEnding: boolean;
    isTerminating: boolean;
    onStart: () => void;
    onDraw: () => void;
    onEnd: () => void;
    onTerminate: () => void;
  }

  let {
    status,
    isStarting,
    isDrawing,
    isEnding,
    isTerminating,
    onStart,
    onDraw,
    onEnd,
    onTerminate,
  }: Props = $props();

  const isLobby = $derived("lobby" in status);
  const isActive = $derived("active" in status);
  const isCompleted = $derived("completed" in status);
</script>

{#if isLobby}
  <button
    class="arcade-button px-3 sm:px-4 py-2 text-xs disabled:bg-gray-400 disabled:cursor-not-allowed flex-shrink-0"
    disabled={isStarting}
    onclick={onStart}
  >
    {isStarting ? "STARTING..." : "START GAME"}
  </button>
  <button
    class="bg-[#FF6EC7] text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#ff8fd4] active:scale-95 disabled:bg-gray-400 disabled:cursor-not-allowed flex-shrink-0"
    disabled={isTerminating}
    onclick={onTerminate}
  >
    {isTerminating ? "ENDING..." : "TERMINATE"}
  </button>
{:else if isActive}
  <button
    class="arcade-button px-3 sm:px-4 py-2 text-xs disabled:bg-gray-400 disabled:cursor-not-allowed flex-shrink-0"
    disabled={isDrawing}
    onclick={onDraw}
  >
    {isDrawing ? "DRAWING..." : "DRAW CARD"}
  </button>
  <button
    class="bg-white text-[#1a0033] border-2 sm:border-4 border-black px-3 sm:px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] sm:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#C9B5E8] active:scale-95 disabled:bg-gray-400 disabled:cursor-not-allowed flex-shrink-0"
    disabled={isEnding}
    onclick={onEnd}
  >
    {isEnding ? "ENDING..." : "END GAME"}
  </button>
{:else if isCompleted}
  <div
    class="arcade-panel-sm px-2 sm:px-3 py-2 text-xs font-bold text-white uppercase flex-shrink-0"
  >
    Game Completed
  </div>
{/if}
