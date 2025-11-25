<script lang="ts">
  import { onMount } from "svelte";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { goto } from "$app/navigation";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import TablaLoader from "$lib/components/routes/admin/TablaLoader.svelte";
  import AdminStats from "$lib/components/routes/admin/AdminStats.svelte";
  import RegistryManager from "$lib/components/routes/admin/RegistryManager.svelte";

  let isAdmin = $state(false);
  let isChecking = $state(true);
  let activeTab = $state<"stats" | "loader" | "registry">("stats");

  onMount(async () => {
    if (!$authStore.isAuthenticated) {
      goto("/");
      return;
    }
    try {
      const count = await gameStore.getTablaCount();
      isAdmin = true;
    } catch (error: any) {
      goto("/dashboard");
      return;
    }

    isChecking = false;

    if (!isAdmin) {
      goto("/dashboard");
    }
  });
</script>

{#if isChecking}
  <div class="flex items-center justify-center min-h-screen bg-[#100c2f]">
    <Spinner />
  </div>
{:else if isAdmin}
  <div class="min-h-screen bg-[#100c2f] relative overflow-hidden">
    <!-- Retro Grid Background -->
    <div
      class="absolute inset-0 opacity-20"
      style="background-image: repeating-linear-gradient(0deg, transparent, transparent 2px, #29ABE2 2px, #29ABE2 4px), repeating-linear-gradient(90deg, transparent, transparent 2px, #29ABE2 2px, #29ABE2 4px); background-size: 40px 40px;"
    ></div>

    <!-- Floating Decorative Elements -->
    <div
      class="absolute top-20 left-10 w-12 h-12 bg-[#FBB03B] rotate-45 opacity-50"
    ></div>
    <div
      class="absolute top-40 right-20 w-8 h-8 bg-[#29ABE2] rounded-full opacity-60"
    ></div>

    <div class="relative max-w-7xl mx-auto px-4 py-8 md:py-12">
      <!-- Admin Header Window -->
      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)] mb-6"
      >
        <div
          class="bg-[#522785] p-2 border-b-2 border-black flex items-center justify-between"
        >
          <div class="flex items-center gap-2">
            <div
              class="w-3 h-3 bg-red-500 rounded-full border border-black"
            ></div>
            <div
              class="w-3 h-3 bg-[#FBB03B] rounded-full border border-black"
            ></div>
            <div
              class="w-3 h-3 bg-green-500 rounded-full border border-black"
            ></div>
          </div>
          <div class="text-white font-bold text-sm uppercase tracking-wider">
            ADMIN_DASHBOARD.EXE
          </div>
          <button
            onclick={() => goto("/dashboard")}
            class="w-6 h-6 bg-red-500 border border-black hover:bg-red-600 flex items-center justify-center"
          >
            <span class="text-white text-xs font-bold">×</span>
          </button>
        </div>

        <div class="bg-white p-6 border-4 border-black">
          <h1
            class="text-3xl md:text-5xl font-black text-black uppercase mb-4 text-center"
            style="text-shadow: 3px 3px 0px #522785;"
          >
            ADMIN DASHBOARD
          </h1>

          <div class="text-center mb-4">
            <div
              class="inline-block bg-black border-2 border-[#00FF00] px-4 py-2"
            >
              <p class="text-[#00FF00] text-xs">
                &gt; ACCESS GRANTED: ADMINISTRATOR MODE
              </p>
            </div>
          </div>

          <!-- Tab Navigation -->
          <div class="flex gap-2 justify-center flex-wrap">
            <button
              onclick={() => (activeTab = "stats")}
              class="px-6 py-3 font-black uppercase border-2 border-black {activeTab ===
              'stats'
                ? 'bg-[#522785] text-white'
                : 'bg-white text-black hover:bg-[#FBB03B]'} transition-all"
              style="box-shadow: 3px 3px 0px #000;"
            >
              STATS
            </button>
            <button
              onclick={() => (activeTab = "registry")}
              class="px-6 py-3 font-black uppercase border-2 border-black {activeTab ===
              'registry'
                ? 'bg-[#522785] text-white'
                : 'bg-white text-black hover:bg-[#FBB03B]'} transition-all"
              style="box-shadow: 3px 3px 0px #000;"
            >
              REGISTRY
            </button>
            <button
              onclick={() => (activeTab = "loader")}
              class="px-6 py-3 font-black uppercase border-2 border-black {activeTab ===
              'loader'
                ? 'bg-[#522785] text-white'
                : 'bg-white text-black hover:bg-[#FBB03B]'} transition-all"
              style="box-shadow: 3px 3px 0px #000;"
            >
              TABLA LOADER
            </button>
          </div>
        </div>
      </div>

      {#if activeTab === "stats"}
        <AdminStats />
      {:else if activeTab === "registry"}
        <RegistryManager />
      {:else if activeTab === "loader"}
        <TablaLoader />
      {/if}
    </div>
  </div>
{/if}
