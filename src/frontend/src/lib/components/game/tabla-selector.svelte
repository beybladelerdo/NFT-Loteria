<script lang="ts">
  import { onMount } from "svelte";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { getTablaUrl } from "$lib/data/gallery";
  import { playSfx, playBlip } from "$lib/services/audio-services";

  interface Props {
    gameId: string;
    selectedTablaIds: number[];
    onSelect: (tablaIds: number[], totalRentalFee: bigint) => void;
  }
  let { gameId, selectedTablaIds = $bindable(), onSelect }: Props = $props();

  export type Rarity =
    | { common: null }
    | { uncommon: null }
    | { rare: null }
    | { epic: null }
    | { legendary: null };

  type TokenType =
    | { ICP: null }
    | { ckBTC: null }
    | { GLDT: null }
    | Record<string, null>;

  interface TablaInfo {
    id: number;
    name: string;
    image: string;
    rentalFee: bigint;
    rarity: Rarity;
    status: { available: null } | { rented: null } | { inGame: null };
    tokenType: TokenType;
  }

  const MAX_TABLAS = 4;

  let tablas = $state<TablaInfo[]>([]);
  let isLoading = $state(true);
  let error = $state("");

  type SortKey = "id" | "rarity" | "token";
  let sortBy = $state<SortKey>("id");
  let sortDir = $state<"asc" | "desc">("asc");
  let page = $state(1);
  let pageSize = $state(8);

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

  const tokenKey = (t: TokenType): string => {
    if ("ICP" in t) return "0-ICP";
    if ("ckBTC" in t) return "1-ckBTC";
    if ("GLDT" in t) return "2-GLDT";
    const k = Object.keys(t)[0] ?? "ZZZ";
    return `9-${k}`;
  };

  const sortedTablas = $derived(
    [...tablas].sort((a, b) => {
      let cmp = 0;
      if (sortBy === "id") cmp = a.id - b.id;
      else if (sortBy === "rarity")
        cmp = rarityRank(a.rarity) - rarityRank(b.rarity);
      else if (sortBy === "token")
        cmp = tokenKey(a.tokenType).localeCompare(tokenKey(b.tokenType));
      return sortDir === "asc" ? cmp : -cmp;
    }),
  );

  const totalPages = $derived(
    Math.max(1, Math.ceil(sortedTablas.length / pageSize)),
  );

  $effect(() => {
    if (page > totalPages) page = totalPages;
    if (page < 1) page = 1;
  });

  const visible = $derived(
    sortedTablas.slice((page - 1) * pageSize, page * pageSize),
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
            rarity: t.rarity as Rarity,
            status: t.status,
            tokenType: t.tokenType as TokenType,
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

  function handleSelect(tabla: TablaInfo) {
    const isSelected = selectedTablaIds.includes(tabla.id);
    
    if (isSelected) {
      selectedTablaIds = selectedTablaIds.filter(id => id !== tabla.id);
      playBlip();
    } else {
      if (selectedTablaIds.length >= MAX_TABLAS) {
        error = `Maximum ${MAX_TABLAS} tablas allowed`;
        setTimeout(() => error = "", 3000);
        return;
      }
      selectedTablaIds = [...selectedTablaIds, tabla.id];
      
      if ("legendary" in tabla.rarity) {
        playSfx("select_legendary");
      } else if ("epic" in tabla.rarity) {
        playSfx("select_epic");
      } else if ("rare" in tabla.rarity) {
        playSfx("select_rare");
      } else if ("uncommon" in tabla.rarity) {
        playSfx("select_uncommon");
      } else {
        playSfx("select_common");
      }
    }

    const totalFee = selectedTablaIds.reduce((sum, id) => {
      const t = tablas.find(t => t.id === id);
      return t ? sum + t.rentalFee : sum;
    }, 0n);

    onSelect(selectedTablaIds, totalFee);
  }

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
    if ("legendary" in r) return "ULTRA RARE";
    return "UNKNOWN";
  }

  function rareFlare(r: Rarity): string {
    if ("legendary" in r)
      return "before:absolute before:inset-0 before:rounded-md before:animate-pulse before:bg-gradient-to-r before:from-yellow-300/20 before:via-fuchsia-300/10 before:to-yellow-300/20";
    if ("epic" in r)
      return "before:absolute before:inset-0 before:rounded-md before:animate-pulse before:bg-gradient-to-r before:from-purple-400/15 before:to-pink-400/15";
    if ("rare" in r)
      return "before:absolute before:inset-0 before:rounded-md before:animate-pulse before:bg-[radial-gradient(circle_at_50%_0%,rgba(255,110,199,0.20),transparent_60%)]";
    return "";
  }
</script>

<div
  class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
>
  <div class="mb-4 flex items-center justify-between">
    <span
      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
    >
      Select Tabla
    </span>
    <span
      class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
    >
      {selectedTablaIds.length}/{MAX_TABLAS} SELECTED
    </span>
  </div>

  <h3
    class="text-2xl font-black text-[#F4E04D] uppercase mb-4"
    style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
  >
    CHOOSE YOUR TABLAS
  </h3>

  <div class="flex flex-wrap items-center gap-2 mb-3">
    <label class="text-xs font-bold text-white">Sort by</label>
    <select
      bind:value={sortBy}
      class="px-2 py-1 text-xs border-2 border-black bg-white text-black"
    >
      <option value="id">ID</option>
      <option value="rarity">Rarity</option>
      <option value="token">Token</option>
    </select>
    <select
      bind:value={sortDir}
      class="px-2 py-1 text-xs border-2 border-black bg-white text-black"
    >
      <option value="asc">Asc</option>
      <option value="desc">Desc</option>
    </select>

    <label class="ml-4 text-xs font-bold text-white">Page size</label>
    <select
      bind:value={pageSize}
      class="px-2 py-1 text-xs border-2 border-black bg-white text-black"
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
        All tablas are currently being used in this game. Try refreshing!
      </p>
      <button
        onclick={loadTablas}
        class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-4 py-2 font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] hover:shadow-none hover:translate-x-0.5 hover:translate-y-0.5 transition-all"
      >
        Refresh
      </button>
    </div>
  {:else}
    <div
      class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 items-stretch"
    >
      {#each visible as tabla}
        <button
          onclick={() => handleSelect(tabla)}
          class="group relative bg-[#1a0033] border-4 border-black p-2 transition-all {selectedTablaIds.includes(tabla.id)
            ? 'ring-4 ring-[#F4E04D] shadow-[6px_6px_0px_0px_rgba(0,0,0,1)]'
            : 'shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]'}"
        >
          <div
            class={"relative rounded-md overflow-hidden border-2 border-[#C9B5E8] bg-[#0f0220] " +
              rareFlare(tabla.rarity)}
            style="aspect-ratio:569/1000;"
          >
            <img
              src={tabla.image}
              alt={tabla.name}
              loading="lazy"
              decoding="async"
              class="absolute inset-0 w-full h-full object-contain"
            />
          </div>

          {#if selectedTablaIds.includes(tabla.id)}
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
              class="text-[10px] font-bold text-center px-2 py-0.5 border border-black rounded"
              style="background-color: {getRarityColor(
                tabla.rarity,
              )}; color: #1a0033;"
            >
              {getRarityText(tabla.rarity)}
            </div>
          </div>
        </button>
      {/each}
    </div>

    <div class="mt-4 flex items-center justify-center gap-2">
      <button
        class="px-3 py-1 border-2 border-black bg-[#C9B5E8] font-bold disabled:opacity-50"
        disabled={page === 1}
        onclick={() => {
          playBlip();
          page = Math.max(1, page - 1);
        }}
      >
        Prev
      </button>
      <span class="text-white text-sm">Page {page} / {totalPages}</span>
      <button
        class="px-3 py-1 border-2 border-black bg-[#C9B5E8] font-bold disabled:opacity-50"
        disabled={page === totalPages}
        onclick={() => {
          playBlip();
          page = Math.min(totalPages, page + 1);
        }}
      >
        Next
      </button>
    </div>

    {#if selectedTablaIds.length > 0}
      <div
        class="mt-4 bg-[#1a0033] border-2 border-[#F4E04D] p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
      >
        <p class="text-[#F4E04D] font-bold text-sm text-center uppercase">
          ✓ {selectedTablaIds.length} TABLA{selectedTablaIds.length > 1 ? 'S' : ''} SELECTED: #{selectedTablaIds.join(', #')}
        </p>
      </div>
    {/if}
  {/if}
</div>