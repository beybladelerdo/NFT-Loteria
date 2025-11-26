<script lang="ts">
  interface Props {
    gameId: string;
    backLabel?: string;
    backPath?: string;
    onBack?: () => void;
  }

  let {
    gameId,
    backLabel = "Back to Games",
    backPath = "/join-game",
    onBack,
  }: Props = $props();

  function handleBack() {
    if (onBack) {
      onBack();
    } else if (backPath) {
      window.location.href = backPath;
    }
  }
</script>

<div
  class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4"
>
  <button
    onclick={handleBack}
    class="inline-flex items-center justify-center gap-2 arcade-button px-4 sm:px-5 py-2 sm:py-3 text-xs sm:text-sm w-full sm:w-auto"
  >
    ◄ {backLabel}
  </button>
  <div class="text-center sm:text-right">
    <p
      class="text-[#F4E04D] font-black text-xs uppercase tracking-[0.2em] sm:tracking-[0.4em]"
    >
      Lobby Code
    </p>
    <p
      class="text-2xl sm:text-3xl font-black text-white mt-1 arcade-text-shadow"
    >
      {gameId}
    </p>
  </div>
</div>
