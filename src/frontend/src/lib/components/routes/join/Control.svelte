<script lang="ts">
  import type { SortKey } from "$lib/utils/helpers";

  interface Props {
    sortBy: SortKey;
    sortDir: "asc" | "desc";
    pageSize: string;
    tablasAvailable: boolean;
    onSortByChange: (sort: SortKey) => void;
    onSortDirChange: (dir: "asc" | "desc") => void;
    onPageSizeChange: (size: string) => void;
    onLucky: () => void;
    onShowInfo: () => void;
  }

  let {
    sortBy,
    sortDir,
    pageSize,
    tablasAvailable,
    onSortByChange,
    onSortDirChange,
    onPageSizeChange,
    onLucky,
    onShowInfo
  }: Props = $props();
</script>

<div class="space-y-3">
  <!-- Sort and Page Size Controls -->
  <div class="flex flex-wrap items-center gap-2 text-xs">
    <label for="sort-by" class="font-bold text-white uppercase">Sort By:</label>
    <select
      id="sort-by"
      value={sortBy}
      onchange={(e) => onSortByChange(e.currentTarget.value as SortKey)}
      class="px-3 py-2 border-2 border-black bg-white text-[#1a0033] font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <option value="id">ID</option>
      <option value="rarity">Rarity</option>
    </select>

    <select
      value={sortDir}
      onchange={(e) => onSortDirChange(e.currentTarget.value as "asc" | "desc")}
      class="px-3 py-2 border-2 border-black bg-white text-[#1a0033] font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <option value="asc">↑ Asc</option>
      <option value="desc">↓ Desc</option>
    </select>

    <label for="page-size" class="font-bold text-white uppercase ml-2">Per Page:</label>
    <select
      id="page-size"
      value={pageSize}
      onchange={(e) => onPageSizeChange(e.currentTarget.value)}
      class="px-3 py-2 border-2 border-black bg-white text-[#1a0033] font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      <option value="4">4</option>
      <option value="8">8</option>
      <option value="12">12</option>
      <option value="16">16</option>
    </select>
  </div>

  <!-- Lucky Button -->
  <div class="flex items-center gap-2">
    <button
      onclick={onLucky}
      disabled={!tablasAvailable}
      class="arcade-button flex-1 px-4 py-2 text-xs disabled:bg-gray-400 disabled:cursor-not-allowed"
    >
      🍀 I'M FEELING LUCKY
    </button>
    <button
      onclick={onShowInfo}
      class="w-8 h-8 bg-[#F4E04D] text-[#1a0033] border-2 border-black font-black text-sm shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
    >
      ?
    </button>
  </div>
</div>