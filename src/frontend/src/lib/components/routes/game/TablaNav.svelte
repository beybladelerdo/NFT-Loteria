<script lang="ts">
  interface Props {
    currentIndex: number;
    totalTablas: number;
    onPrevious: () => void;
    onNext: () => void;
  }

  let { currentIndex, totalTablas, onPrevious, onNext }: Props = $props();
</script>

<div class="arcade-panel p-3 sm:p-4">
  <div class="flex items-center justify-between gap-2 sm:gap-4">
    <button
      onclick={onPrevious}
      disabled={currentIndex === 0}
      class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 sm:px-6 py-3 font-black uppercase text-xl sm:text-2xl shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#d9c9f0] hover:scale-105 transition-all disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:scale-100 w-16 sm:w-24 flex items-center justify-center active:scale-95"
    >
      ◄
    </button>

    <div class="text-center flex-1">
      <p class="text-[#F4E04D] font-black uppercase text-base sm:text-xl leading-tight whitespace-nowrap arcade-text-shadow">
        Tabla {currentIndex + 1} of {totalTablas}
      </p>
      <p class="text-[#C9B5E8] text-[9px] sm:text-xs font-bold uppercase mt-1 hidden sm:block">
        Use arrows to switch between your tablas
      </p>
    </div>

    <button
      onclick={onNext}
      disabled={currentIndex === totalTablas - 1}
      class="bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 sm:px-6 py-3 font-black uppercase text-xl sm:text-2xl shadow-[4px_4px_0_rgba(0,0,0,1)] hover:bg-[#d9c9f0] hover:scale-105 transition-all disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:scale-100 w-16 sm:w-24 flex items-center justify-center active:scale-95"
    >
      ►
    </button>
  </div>
</div>