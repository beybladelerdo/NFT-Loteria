<script lang="ts">
  interface Props {
    modeFilter: "all" | "line" | "blackout";
    onFilterChange: (filter: "all" | "line" | "blackout") => void;
  }

  let { modeFilter, onFilterChange }: Props = $props();
</script>

<div class="arcade-panel p-4 sm:p-5">
  <div class="mb-3 sm:mb-4">
    <span class="arcade-badge">
      FILTER
    </span>
  </div>
  <div class="flex flex-wrap gap-2">
    <button
      class={`px-3 py-2 border-2 border-black font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] transition-all active:translate-x-[1px] active:translate-y-[1px] active:shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
        modeFilter === "all"
          ? "bg-[#F4E04D] text-[#1a0033]"
          : "bg-[#1a0033] text-white hover:bg-[#2f1754]"
      }`}
      onclick={() => onFilterChange("all")}
    >
      ALL MODES
    </button>
    <button
      class={`px-3 py-2 border-2 border-black font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] transition-all active:translate-x-[1px] active:translate-y-[1px] active:shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
        modeFilter === "line"
          ? "bg-[#F4E04D] text-[#1a0033]"
          : "bg-[#1a0033] text-white hover:bg-[#2f1754]"
      }`}
      onclick={() => onFilterChange("line")}
    >
      LINE
    </button>
    <button
      class={`px-3 py-2 border-2 border-black font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] transition-all active:translate-x-[1px] active:translate-y-[1px] active:shadow-[2px_2px_0px_rgba(0,0,0,1)] ${
        modeFilter === "blackout"
          ? "bg-[#F4E04D] text-[#1a0033]"
          : "bg-[#1a0033] text-white hover:bg-[#2f1754]"
      }`}
      onclick={() => onFilterChange("blackout")}
    >
      BLACKOUT
    </button>
  </div>
</div>