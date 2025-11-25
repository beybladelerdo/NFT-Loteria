<script lang="ts">
  import type { TablaEarnings } from "../../../../../../declarations/backend/backend.did";
  import { toNumber, formatTokenEarnings, formatLastUsed } from "$lib/utils/helpers";
  import { getTablaUrl } from "$lib/data/gallery";

  interface Props {
    tablaStats: TablaEarnings[];
    isLoading: boolean;
    onTablaClick: (tabla: TablaEarnings) => void;
  }

  let { tablaStats, isLoading, onTablaClick }: Props = $props();

  let tablaSearch = $state("");
  let tablaSortKey = $state<"gamesPlayed" | "earningsICP" | "earningsCkBTC" | "earningsGLDT">("earningsICP");
  let tablaSortDir = $state<"asc" | "desc">("desc");

  const filteredTablaStats = $derived.by(() => {
    return tablaStats
      .filter((t) => {
        if (!tablaSearch.trim()) return true;
        const idStr = String(t.tablaId);
        return idStr.includes(tablaSearch.trim());
      })
      .sort((a, b) => {
        const aVal = toNumber(a[tablaSortKey]);
        const bVal = toNumber(b[tablaSortKey]);
        if (tablaSortDir === "desc") return bVal - aVal;
        return aVal - bVal;
      });
  });

  function handleInput(e: Event) {
    const target = e.target as HTMLInputElement;
    target.value = target.value.replace(/[^0-9]/g, "");
    tablaSearch = target.value;
  }

  function toggleSort() {
    tablaSortDir = tablaSortDir === "desc" ? "asc" : "desc";
  }

  const sortLabels: Record<typeof tablaSortKey, string> = {
    gamesPlayed: "Games Played",
    earningsICP: "ICP Earnings",
    earningsCkBTC: "ckBTC Earnings",
    earningsGLDT: "GLDT Earnings"
  };
</script>

<section class="arcade-panel p-4 sm:p-6">
  <div class="mb-4 sm:mb-6">
    <span class="arcade-badge bg-[#C9B5E8]">Tabla Earnings</span>
    <h2 class="mt-3 text-2xl sm:text-3xl font-black uppercase text-[#F4E04D] arcade-text-shadow">
      TOP EARNING TABLAS
    </h2>
    <p class="text-xs sm:text-sm font-bold text-white mt-1">
      See which tablas are used and earning the most. Tap a card for details.
    </p>
  </div>

  <div class="mb-4 sm:mb-6 arcade-panel-sm p-4">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="md:col-span-1">
        <label for="tabla-search" class="block text-xs sm:text-sm font-black text-[#F4E04D] uppercase mb-2">
          Search by Tabla ID
        </label>
        <input
          id="tabla-search"
          type="text"
          inputmode="numeric"
          pattern="[0-9]*"
          placeholder="Enter tabla number..."
          value={tablaSearch}
          oninput={handleInput}
          class="w-full px-4 py-3 text-base font-bold text-[#1a0033] rounded border-4 border-black bg-white shadow-[3px_3px_0px_rgba(0,0,0,1)] focus:outline-none focus:ring-2 focus:ring-[#F4E04D]"
        />
      </div>

      <div class="md:col-span-1">
        <label for="tabla-sort" class="block text-xs sm:text-sm font-black text-[#F4E04D] uppercase mb-2">
          Sort By
        </label>
        <select
          id="tabla-sort"
          bind:value={tablaSortKey}
          class="w-full px-4 py-3 text-base font-bold text-[#1a0033] rounded border-4 border-black bg-white shadow-[3px_3px_0px_rgba(0,0,0,1)] focus:outline-none focus:ring-2 focus:ring-[#F4E04D]"
        >
          <option value="gamesPlayed">Games Played</option>
          <option value="earningsICP">ICP Earnings</option>
          <option value="earningsCkBTC">ckBTC Earnings</option>
          <option value="earningsGLDT">GLDT Earnings</option>
        </select>
      </div>

      <div class="md:col-span-1">
        <!-- svelte-ignore a11y_label_has_associated_control -->
        <label class="block text-xs sm:text-sm font-black text-[#F4E04D] uppercase mb-2">
         Sort Order
        </label>
        <button
          type="button"
          onclick={toggleSort}
          class="arcade-button w-full px-4 py-3 text-base flex items-center justify-center gap-2"
          title={tablaSortDir === "desc" ? "Highest first" : "Lowest first"}
        >
          <span>{sortLabels[tablaSortKey]}</span>
          <span class="text-xl">{tablaSortDir === "desc" ? "↓" : "↑"}</span>
        </button>
      </div>
    </div>
  </div>

  {#if isLoading}
    <div class="arcade-panel-sm py-6 text-center text-[#C9B5E8] text-sm">
      Loading tabla stats...
    </div>
  {:else if filteredTablaStats.length === 0}
    <div class="arcade-panel-sm py-6 text-center text-[#C9B5E8] text-sm">
      {tablaSearch ? "No tablas found matching that ID." : "No tabla stats yet. Play some games to see earnings!"}
    </div>
  {:else}
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3 sm:gap-4">
      {#each filteredTablaStats as t}
        <button
          type="button"
          onclick={() => onTablaClick(t)}
          class="text-left arcade-panel-sm p-2 sm:p-3 hover:shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:-translate-y-1 transition-all rounded-lg group"
        >
          <div class="relative mb-2 overflow-hidden rounded border-2 border-black aspect-[3/4]">
            <img
              src={getTablaUrl(Number(t.tablaId))}
              alt="Tabla {t.tablaId}"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform"
            />
            <div class="absolute top-1 right-1 bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-0.5 text-[10px] font-black shadow-[2px_2px_0px_rgba(0,0,0,1)]">
              #{t.tablaId}
            </div>
          </div>

          <div class="mb-2">
            <p class="text-[10px] sm:text-xs text-[#C9B5E8] uppercase font-black text-center">
              {toNumber(t.gamesPlayed)} GAMES PLAYED
            </p>
          </div>

          <div class="grid grid-cols-3 gap-1 text-[9px] sm:text-[10px]">
            <div class="bg-[#25004d] border border-black px-1 py-1 rounded text-center">
              <p class="text-[#F4E04D] font-black">ICP</p>
              <p class="text-white font-mono truncate">
                {formatTokenEarnings(t.earningsICP)}
              </p>
            </div>
            <div class="bg-[#25004d] border border-black px-1 py-1 rounded text-center">
              <p class="text-[#FF9900] font-black">BTC</p>
              <p class="text-white font-mono truncate">
                {formatTokenEarnings(t.earningsCkBTC)}
              </p>
            </div>
            <div class="bg-[#25004d] border border-black px-1 py-1 rounded text-center">
              <p class="text-[#FFD700] font-black">GLD</p>
              <p class="text-white font-mono truncate">
                {formatTokenEarnings(t.earningsGLDT)}
              </p>
            </div>
          </div>
        </button>
      {/each}
    </div>
  {/if}
</section>