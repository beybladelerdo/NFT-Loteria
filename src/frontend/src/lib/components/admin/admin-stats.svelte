<script lang="ts">
  import { onMount } from "svelte";
  import { gameStore } from "$lib/stores/game-store.svelte";

  let tablaCount = $state(0);
  let openGamesCount = $state(0);
  let activeGamesCount = $state(0);
  let isLoading = $state(true);

  onMount(async () => {
    await loadStats();
  });

  async function loadStats() {
    isLoading = true;
    try {
      tablaCount = await gameStore.getTablaCount();
      await gameStore.fetchOpenGames(0);
      await gameStore.fetchActiveGames(0);
      openGamesCount = gameStore.openGames.length;
      activeGamesCount = gameStore.activeGames.length;
    } catch (error) {
      console.error("Error loading stats:", error);
    } finally {
      isLoading = false;
    }
  }
</script>

<div
  class="bg-gradient-to-b from-[#29ABE2] to-[#1e88c7] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
>
  <div
    class="bg-[#29ABE2] p-2 border-b-2 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <div class="w-4 h-4 bg-white border-2 border-black"></div>
      <span class="text-black font-black text-xs uppercase"
        >SYSTEM_STATS.DAT</span
      >
    </div>
    <button
      onclick={loadStats}
      class="bg-[#FBB03B] text-black px-2 py-1 font-black uppercase border-2 border-black hover:bg-[#e09a2f] transition-all text-xs"
      style="box-shadow: 2px 2px 0px #000;"
    >
      ⟳ REFRESH
    </button>
  </div>

  <div class="bg-white p-6 md:p-8 border-4 border-black">
    <h2
      class="text-2xl font-black text-black uppercase mb-6 text-center"
      style="text-shadow: 2px 2px 0px #29ABE2;"
    >
      SYSTEM STATISTICS
    </h2>

    {#if isLoading}
      <div class="text-center py-12">
        <div
          class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-black border-t-[#29ABE2]"
        ></div>
        <p class="mt-4 font-bold text-black">LOADING STATS...</p>
      </div>
    {:else}
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Tablas Loaded -->
        <div class="bg-[#522785] border-4 border-black p-6 text-center">
          <div class="text-5xl font-black text-white mb-2">{tablaCount}</div>
          <div class="text-sm font-bold text-white uppercase">
            Tablas Loaded
          </div>
          <div class="mt-4 bg-white border-2 border-black p-2">
            <p class="text-xs font-bold text-black">
              {tablaCount > 0 ? "SYSTEM READY" : "NO TABLAS LOADED"}
            </p>
          </div>
        </div>

        <!-- Open Games -->
        <div class="bg-[#FBB03B] border-4 border-black p-6 text-center">
          <div class="text-5xl font-black text-black mb-2">
            {openGamesCount}
          </div>
          <div class="text-sm font-bold text-black uppercase">Open Games</div>
          <div class="mt-4 bg-white border-2 border-black p-2">
            <p class="text-xs font-bold text-black">IN LOBBY</p>
          </div>
        </div>

        <!-- Active Games -->
        <div class="bg-[#29ABE2] border-4 border-black p-6 text-center">
          <div class="text-5xl font-black text-black mb-2">
            {activeGamesCount}
          </div>
          <div class="text-sm font-bold text-black uppercase">Active Games</div>
          <div class="mt-4 bg-white border-2 border-black p-2">
            <p class="text-xs font-bold text-black">IN PROGRESS</p>
          </div>
        </div>
      </div>

      <!-- System Status -->
      <div class="mt-6 bg-black border-4 border-[#29ABE2] p-4">
        <div class="flex items-center justify-between">
          <span class="text-[#29ABE2] font-bold uppercase text-sm"
            >SYSTEM STATUS:</span
          >
          <span class="text-[#00FF00] font-black text-lg">
            {tablaCount > 0 ? "● OPERATIONAL" : "● SETUP REQUIRED"}
          </span>
        </div>
      </div>
    {/if}
  </div>
</div>
