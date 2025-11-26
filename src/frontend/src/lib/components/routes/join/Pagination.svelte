<script lang="ts">
  import { playBlip } from "$lib/services/audio-services";

  interface Props {
    currentPage: number;
    totalPages: number;
    onPageChange: (page: number) => void;
  }

  let { currentPage, totalPages, onPageChange }: Props = $props();

  function handlePrev() {
    if (currentPage > 1) {
      playBlip();
      onPageChange(currentPage - 1);
    }
  }

  function handleNext() {
    if (currentPage < totalPages) {
      playBlip();
      onPageChange(currentPage + 1);
    }
  }
</script>

<div class="flex items-center justify-center gap-3">
  <button
    class="px-4 py-2 border-2 border-black bg-[#C9B5E8] text-[#1a0033] font-bold uppercase text-xs shadow-[2px_2px_0px_rgba(0,0,0,1)] disabled:opacity-50 disabled:cursor-not-allowed hover:bg-[#d9c9f0] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
    disabled={currentPage === 1}
    onclick={handlePrev}
  >
    ◄ PREV
  </button>

  <span class="text-white text-xs sm:text-sm font-bold uppercase">
    Page {currentPage} / {totalPages}
  </span>

  <button
    class="px-4 py-2 border-2 border-black bg-[#C9B5E8] text-[#1a0033] font-bold uppercase text-xs shadow-[2px_2px_0px_rgba(0,0,0,1)] disabled:opacity-50 disabled:cursor-not-allowed hover:bg-[#d9c9f0] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
    disabled={currentPage === totalPages}
    onclick={handleNext}
  >
    NEXT ►
  </button>
</div>
