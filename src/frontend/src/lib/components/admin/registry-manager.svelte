<script lang="ts">
  import { gameStore } from "$lib/stores/game-store.svelte";

  let isRefreshing = $state(false);
  let result = $state<{ success: boolean; error?: string } | null>(null);

  async function handleRefreshRegistry() {
    isRefreshing = true;
    result = null;

    try {
      result = await gameStore.refreshRegistry();
    } catch (error) {
      console.error("Error refreshing registry:", error);
      result = { success: false, error: String(error) };
    } finally {
      isRefreshing = false;
    }
  }
</script>

<div
  class="bg-gradient-to-b from-[#FBB03B] to-[#e09a2f] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
>
  <div
    class="bg-[#FBB03B] p-2 border-b-2 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <div class="w-4 h-4 bg-white border-2 border-black"></div>
      <span class="text-black font-black text-xs uppercase"
        >REGISTRY_SYNC.EXE</span
      >
    </div>
    <div class="flex gap-1">
      <div class="w-4 h-4 bg-[#29ABE2] border border-black"></div>
      <div class="w-4 h-4 bg-red-500 border border-black"></div>
    </div>
  </div>

  <div class="bg-white p-6 md:p-8 border-4 border-black">
    <h2
      class="text-2xl font-black text-black uppercase mb-4 text-center"
      style="text-shadow: 2px 2px 0px #FBB03B;"
    >
      NFT REGISTRY SYNC
    </h2>

    <div class="bg-black border-4 border-[#FBB03B] p-6 mb-6">
      <p class="text-[#FBB03B] font-bold text-sm leading-relaxed">
        &gt; SYNC NFT OWNERSHIP DATA FROM EXT CANISTER<br />
        &gt; CANISTER ID: psaup-3aaaa-aaaak-qsxlq-cai<br />
        &gt; THIS MUST BE RUN BEFORE LOADING TABLAS<br />
        &gt; UPDATES OWNER ACCOUNT IDS FOR ALL NFTS
      </p>
    </div>

    <div class="text-center mb-6">
      <button
        onclick={handleRefreshRegistry}
        disabled={isRefreshing}
        class="bg-[#522785] text-white px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#6d3399] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-lg"
        style="box-shadow: 4px 4px 0px #000;"
      >
        {isRefreshing ? "SYNCING..." : "SYNC REGISTRY >>"}
      </button>
    </div>

    {#if result}
      <div
        class="bg-{result.success
          ? 'green'
          : 'red'}-500 border-4 border-black p-4"
      >
        <p class="text-white font-bold text-center uppercase">
          {#if result.success}
            ✓ REGISTRY SYNC SUCCESSFUL
          {:else}
            ✗ SYNC FAILED: {result.error}
          {/if}
        </p>
      </div>
    {/if}

    <div class="mt-6 bg-[#FBB03B] border-2 border-black p-4">
      <p class="text-xs font-bold text-black uppercase text-center">
        ⚠ RUN THIS BEFORE LOADING TABLA LAYOUTS
      </p>
    </div>
  </div>
</div>
