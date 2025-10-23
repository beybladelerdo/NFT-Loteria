<script lang="ts">
  import { onMount } from "svelte";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { getTablaUrl } from "$lib/data/gallery"; // your corrected path

  interface Props {
    selectedTablaId: number | null;
    onSelect: (tablaId: number, rentalFee: bigint) => void;
  }
  let { selectedTablaId = $bindable(), onSelect }: Props = $props();

  type Rarity =
    | { common: null }
    | { uncommon: null }
    | { rare: null }
    | { epic: null }
    | { legendary: null };

  interface TablaInfo {
    id: number;
    name: string;
    image: string;
    rentalFee: bigint;
    rarity: Rarity;
    status: { available: null } | { rented: null } | { inGame: null };
  }

  // state
  let tablas = $state<TablaInfo[]>([]);
  let isLoading = $state(true);
  let error = $state("");

  // sorting + pagination state
  let sortBy = $state<"id" | "rarity">("id");
  let sortDir = $state<"asc" | "desc">("asc");
  let page = $state(1);
  let pageSize = $state(8);

  // ---- derived helpers (runes mode) ----
  const rarityRank = (r: Rarity) =>
    "legendary" in r
      ? 4
      : "epic" in r
        ? 3
        : "rare" in r
          ? 2
          : "uncommon" in r
            ? 1
            : 0;

  const sortedTablas = $derived(
    [...tablas].sort((a, b) => {
      let cmp =
        sortBy === "id"
          ? a.id - b.id
          : rarityRank(a.rarity) - rarityRank(b.rarity);
      return sortDir === "asc" ? cmp : -cmp;
    }),
  );

  const totalPages = $derived(
    Math.max(1, Math.ceil(sortedTablas.length / pageSize)),
  );

  // keep page in range when data or pageSize changes
  $effect(() => {
    if (page > totalPages) page = totalPages;
    if (page < 1) page = 1;
  });

  const visible = $derived(
    sortedTablas.slice((page - 1) * pageSize, page * pageSize),
  );

  // load data
  onMount(async () => {
    try {
      const result = await gameStore.fetchAvailableTablas();
      if (result?.success && result.tablas) {
        tablas = result.tablas.map((t: any) => {
          const id = Number(t.id);
          return {
            id,
            name: t.name ?? `Tabla #${id}`,
            image: getTablaUrl(id), // <<< resolve to real Vite URL
            rentalFee: t.rentalFee as bigint,
            rarity: t.rarity as Rarity,
            status: t.status,
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
  });

  // interactions
  function handleSelect(tabla: TablaInfo) {
    selectedTablaId = tabla.id;
    onSelect(tabla.id, tabla.rentalFee);
  }

  // UI colors/text
  function getRarityColor(r: Rarity): string {
    if ("common" in r) return "#C9B5E8";
    if ("uncommon" in r) return "#F4E04D";
    if ("rare" in r) return "#FF6EC7";
    if ("epic" in r) return "#9D4EDD";
    if ("legendary" in r) return "#FFD700";
    return "#C9B5E8";
  }
  function getRarityText(r: Rarity): string {
    if ("common" in r) return "COMMON";
    if ("uncommon" in r) return "UNCOMMON";
    if ("rare" in r) return "RARE";
    if ("epic" in r) return "EPIC";
    if ("legendary" in r) return "LEGENDARY";
    return "UNKNOWN";
  }
</script>

<div
  class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
>
  <div class="mb-4">
    <span
      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
    >
      Select Tabla
    </span>
  </div>

  <h3
    class="text-2xl font-black text-[#F4E04D] uppercase mb-4"
    style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
  >
    CHOOSE YOUR TABLA
  </h3>

  <!-- Controls -->
  <div class="flex flex-wrap items-center gap-2 mb-3">
    <label class="text-xs font-bold text-white">Sort by</label>
    <select bind:value={sortBy} class="px-2 py-1 text-xs border-2 border-black">
      <option value="id" >ID</option>
      <option value="rarity">Rarity</option>
    </select>
    <select
      bind:value={sortDir}
      class="px-2 py-1 text-xs border-2 border-black"
    >
      <option value="asc">Asc</option>
      <option value="desc">Desc</option>
    </select>

    <label class="ml-4 text-xs font-bold text-white">Page size</label>
    <select
      bind:value={pageSize}
      class="px-2 py-1 text-xs border-2 border-black"
    >
      <option>4</option><option>8</option><option>12</option><option>16</option>
    </select>
  </div>

  {#if isLoading}
    <div
      class="text-center py-12 bg-[#1a0033] border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
    >
      <div
        class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-[#C9B5E8] border-t-[#F4E04D]"
      ></div>
      <p class="mt-4 font-bold text-white uppercase">LOADING TABLAS...</p>
    </div>
  {:else if error}
    <div
      class="bg-[#FF6EC7] border-4 border-black p-6 text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
    >
      <p class="font-bold text-[#1a0033] uppercase text-lg">{error}</p>
    </div>
  {:else if tablas.length === 0}
    <div
      class="bg-[#1a0033] border-4 border-black p-8 text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
    >
      <h4
        class="text-xl font-black text-[#FF6EC7] uppercase mb-3"
        style="text-shadow: 2px 2px 0px #000;"
      >
        NO TABLAS AVAILABLE!
      </h4>
      <p class="text-white font-bold mb-6">
        All tablas are currently being used. Try again later!
      </p>
    </div>
  {:else}
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      {#each visible as tabla}
        <button
          onclick={() => handleSelect(tabla)}
          class="group relative bg-[#1a0033] border-4 border-black p-2 transition-all {selectedTablaId ===
          tabla.id
            ? 'ring-4 ring-[#F4E04D] shadow-[6px_6px_0px_0px_rgba(0,0,0,1)]'
            : 'shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]'}"
        >
          <img
            src={tabla.image}
            alt={tabla.name}
            class="w-full aspect-square object-cover border-2 border-[#C9B5E8]"
          />

          {#if selectedTablaId === tabla.id}
            <div
              class="absolute inset-0 bg-[#F4E04D] bg-opacity-20 border-2 border-[#F4E04D] flex items-center justify-center"
            >
              <div
                class="bg-[#F4E04D] text-[#1a0033] w-12 h-12 rounded-full border-4 border-black flex items-center justify-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              >
                <span class="text-2xl font-black">✓</span>
              </div>
            </div>
          {/if}

          <div class="mt-2 space-y-1">
            <p class="text-xs font-bold text-white text-center uppercase">
              {tabla.name}
            </p>
            <div
              class="text-[10px] font-bold text-center px-2 py-0.5 border border-black"
              style="background-color: {getRarityColor(
                tabla.rarity,
              )}; color: #1a0033;"
            >
              {getRarityText(tabla.rarity)}
            </div>
            <p class="text-[10px] font-bold text-[#C9B5E8] text-center">
              No rental fee
            </p>
          </div>
        </button>
      {/each}
    </div>

    <div class="mt-4 flex items-center justify-center gap-2">
      <button
        class="px-3 py-1 border-2 border-black bg-[#C9B5E8] font-bold disabled:opacity-50"
        disabled={page === 1}
        onclick={() => (page = Math.max(1, page - 1))}>Prev</button
      >
      <span class="text-white text-sm">Page {page} / {totalPages}</span>
      <button
        class="px-3 py-1 border-2 border-black bg-[#C9B5E8] font-bold disabled:opacity-50"
        disabled={page === totalPages}
        onclick={() => (page = Math.min(totalPages, page + 1))}>Next</button
      >
    </div>

    {#if selectedTablaId}
      <div
        class="mt-4 bg-[#1a0033] border-2 border-[#F4E04D] p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
      >
        <p class="text-[#F4E04D] font-bold text-sm text-center uppercase">
          ✓ TABLA #{selectedTablaId} SELECTED
        </p>
        <p class="text-[#C9B5E8] font-bold text-xs text-center mt-1">
          Rental Fee: Free
        </p>
      </div>
    {/if}
  {/if}
</div>
