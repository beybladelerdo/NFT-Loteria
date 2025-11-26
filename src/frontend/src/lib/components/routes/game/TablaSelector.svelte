<script lang="ts">
  import { onMount } from "svelte";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { getTablaUrl } from "$lib/data/gallery";
  import { playSfx, playBlip } from "$lib/services/audio-services";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import TablaControls from "$lib/components/routes/join/Control.svelte";
  import TablaGrid from "$lib/components/routes/join/Grid.svelte";
  import TablaPagination from "$lib/components/routes/join/Pagination.svelte";
  import InfoModal from "$lib/components/routes/join/Info.svelte";
  import type { TablaInfo, SortKey } from "$lib/utils/helpers";
  import { MAX_TABLAS, PREFERRED_TABLAS, rarityRank } from "$lib/utils/helpers";

  interface Props {
    gameId: string;
    selectedTablaIds: number[];
    onSelect: (tablaIds: number[], totalRentalFee: bigint) => void;
  }

  let { gameId, selectedTablaIds = $bindable(), onSelect }: Props = $props();

  let tablas = $state<TablaInfo[]>([]);
  let isLoading = $state(true);
  let error = $state("");
  let sortBy = $state<SortKey>("id");
  let sortDir = $state<"asc" | "desc">("asc");
  let page = $state(1);
  let pageSize = $state("8");
  let showInfo = $state(false);
  let showLuckyInfo = $state(false);

  const sortedTablas = $derived(
    [...tablas].sort((a, b) => {
      let cmp = 0;
      if (sortBy === "id") cmp = a.id - b.id;
      else if (sortBy === "rarity")
        cmp = rarityRank(a.rarity) - rarityRank(b.rarity);
      return sortDir === "asc" ? cmp : -cmp;
    }),
  );

  const totalPages = $derived(
    Math.max(1, Math.ceil(sortedTablas.length / Number(pageSize))),
  );

  $effect(() => {
    if (page > totalPages) page = totalPages;
    if (page < 1) page = 1;
  });

  const visibleTablas = $derived(
    sortedTablas.slice((page - 1) * Number(pageSize), page * Number(pageSize)),
  );

  onMount(async () => {
    await loadTablas();
  });

  async function loadTablas() {
    isLoading = true;
    error = "";
    try {
      const result = await gameStore.getAvailableTablasForGame(gameId);
      if (result?.success && result.tablas) {
        tablas = result.tablas.map((t: any) => {
          const id = Number(t.id);
          return {
            id,
            name: t.name ?? `Tabla #${id}`,
            image: getTablaUrl(id),
            rentalFee: t.rentalFee as bigint,
            rarity: t.rarity,
            status: t.status,
            tokenType: t.tokenType,
          };
        });
      } else {
        error = result?.error ?? "Failed to load tablas";
      }
    } catch (err) {
      console.error("Error loading tablas:", err);
      error = "Failed to load tablas";
    } finally {
      isLoading = false;
    }
  }

  function makeMeLucky() {
    if (tablas.length === 0) return;

    selectedTablaIds = [];

    const availableTablas = tablas.map((t) => t.id);
    const availablePreferred = PREFERRED_TABLAS.filter((id) =>
      availableTablas.includes(id),
    );
    const availableOthers = availableTablas.filter(
      (id) => !PREFERRED_TABLAS.includes(id),
    );

    const count = Math.floor(Math.random() * MAX_TABLAS) + 1;
    const selected: number[] = [];

    const shuffledPreferred = [...availablePreferred].sort(
      () => Math.random() - 0.5,
    );
    for (let i = 0; i < Math.min(count, shuffledPreferred.length); i++) {
      selected.push(shuffledPreferred[i]);
    }

    if (selected.length < count) {
      const shuffledOthers = [...availableOthers].sort(
        () => Math.random() - 0.5,
      );
      const needed = count - selected.length;
      for (let i = 0; i < Math.min(needed, shuffledOthers.length); i++) {
        selected.push(shuffledOthers[i]);
      }
    }

    selectedTablaIds = selected;
    playSfx("select_common");
    notifySelection();
  }

  function handleSelect(tabla: TablaInfo) {
    const isSelected = selectedTablaIds.includes(tabla.id);

    if (isSelected) {
      selectedTablaIds = selectedTablaIds.filter((id) => id !== tabla.id);
      playBlip();
    } else {
      if (selectedTablaIds.length >= MAX_TABLAS) {
        error = `Maximum ${MAX_TABLAS} tablas allowed`;
        setTimeout(() => (error = ""), 3000);
        return;
      }
      selectedTablaIds = [...selectedTablaIds, tabla.id];

      if ("legendary" in tabla.rarity) playSfx("select_legendary");
      else if ("epic" in tabla.rarity) playSfx("select_epic");
      else if ("rare" in tabla.rarity) playSfx("select_rare");
      else if ("uncommon" in tabla.rarity) playSfx("select_uncommon");
      else playSfx("select_common");
    }

    notifySelection();
  }

  function notifySelection() {
    const totalFee = selectedTablaIds.reduce((sum, id) => {
      const t = tablas.find((t) => t.id === id);
      return t ? sum + t.rentalFee : sum;
    }, 0n);

    onSelect(selectedTablaIds, totalFee);
  }
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="flex items-center justify-between mb-4">
    <span class="arcade-badge"> SELECT TABLA </span>
    <div class="flex items-center gap-2">
      <span class="arcade-badge bg-[#FF6EC7]">
        {selectedTablaIds.length}/{MAX_TABLAS}
      </span>
      <button
        onclick={() => (showInfo = true)}
        class="w-6 h-6 sm:w-8 sm:h-8 bg-[#F4E04D] text-[#1a0033] border-2 border-black font-black text-xs sm:text-sm shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
      >
        ?
      </button>
    </div>
  </div>

  <h3
    class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 arcade-text-shadow"
  >
    CHOOSE YOUR TABLAS
  </h3>

  <TablaControls
    {sortBy}
    {sortDir}
    {pageSize}
    tablasAvailable={tablas.length > 0}
    onSortByChange={(s) => (sortBy = s)}
    onSortDirChange={(d) => (sortDir = d)}
    onPageSizeChange={(s) => (pageSize = s)}
    onLucky={makeMeLucky}
    onShowInfo={() => (showLuckyInfo = true)}
  />

  {#if error}
    <div
      class="mt-4 bg-red-500 border-2 border-black p-3 text-white font-bold uppercase text-xs text-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      {error}
    </div>
  {/if}

  <div class="mt-4">
    {#if isLoading}
      <div
        class="arcade-panel-sm p-12 flex flex-col items-center justify-center"
      >
        <Spinner />
        <p class="mt-4 font-bold text-white uppercase text-xs">
          LOADING TABLAS...
        </p>
      </div>
    {:else if tablas.length === 0}
      <div class="arcade-panel-sm p-6 sm:p-8 text-center">
        <h4
          class="text-lg sm:text-xl font-black text-[#FF6EC7] uppercase mb-3 arcade-text-shadow"
        >
          NO TABLAS AVAILABLE!
        </h4>
        <p class="text-white font-bold text-xs sm:text-sm mb-4 sm:mb-6">
          All tablas are currently being used in this game. Try refreshing!
        </p>
        <button onclick={loadTablas} class="arcade-button px-4 py-2 text-xs">
          🔄 REFRESH
        </button>
      </div>
    {:else}
      <div class="space-y-4">
        <TablaGrid
          tablas={visibleTablas}
          selectedIds={selectedTablaIds}
          onSelect={handleSelect}
        />

        <TablaPagination
          currentPage={page}
          {totalPages}
          onPageChange={(p) => (page = p)}
        />

        {#if selectedTablaIds.length > 0}
          <div class="arcade-panel-sm p-3">
            <p
              class="text-[#F4E04D] font-bold text-xs sm:text-sm text-center uppercase"
            >
              ✓ {selectedTablaIds.length} TABLA{selectedTablaIds.length > 1
                ? "S"
                : ""} SELECTED: #{selectedTablaIds.join(", #")}
            </p>
          </div>
        {/if}
      </div>
    {/if}
  </div>
</div>

<InfoModal
  show={showInfo}
  title="How It Works"
  onClose={() => (showInfo = false)}
>
  <div class="flex gap-3">
    <span class="text-[#F4E04D] text-xl">•</span>
    <p>
      You need at least <span class="text-[#F4E04D]">1 tabla</span> to enter the
      game
    </p>
  </div>
  <div class="flex gap-3">
    <span class="text-[#F4E04D] text-xl">•</span>
    <p>
      You can select up to <span class="text-[#F4E04D]">4 tablas</span> per game
    </p>
  </div>
  <div class="flex gap-3">
    <span class="text-[#F4E04D] text-xl">•</span>
    <p>
      Each tabla requires an <span class="text-[#F4E04D]"
        >additional entry fee</span
      >
    </p>
  </div>
  <div class="flex gap-3">
    <span class="text-[#FF6EC7] text-xl">•</span>
    <p>
      More tablas = <span class="text-[#FF6EC7]">higher chance of winning!</span
      >
    </p>
  </div>
  <div class="flex gap-3">
    <span class="text-[#C9B5E8] text-xl">•</span>
    <p>
      But you'll need to <span class="text-[#C9B5E8]">pay closer attention</span
      > to match characters across multiple tablas
    </p>
  </div>
</InfoModal>

<InfoModal
  show={showLuckyInfo}
  title="Feeling Lucky?"
  onClose={() => (showLuckyInfo = false)}
>
  <p>Randomly select 1-4 tablas!</p>
</InfoModal>
