<script lang="ts">
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { userStore } from "$lib/stores/user-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import type { Profile, TablaEarnings } from "../../../../../declarations/backend/backend.did";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import StatsCard from "$lib/components/routes/dashboard/Stats.svelte";
  import TablaEarningsSection from "$lib/components/routes/dashboard/Earnings.svelte";
  import RecentActivitySection from "$lib/components/routes/dashboard/Activity.svelte";
  import FailedClaimsSection from "$lib/components/routes/dashboard/Claims.svelte";
  import TablaModal from "$lib/components/routes/dashboard/TablaModal.svelte";

  let profile: Profile | undefined = $state(undefined);
  let isLoading = $state(true);
  let openGamesCount = $derived(gameStore.openGames.length);

  let failedClaims = $state<any[]>([]);
  let recentGames = $state<any[]>([]);
  let retryingClaim = $state<string | null>(null);

  let tablaStats = $state<TablaEarnings[]>([]);
  let tablaStatsLoading = $state(true);

  let selectedTabla = $state<TablaEarnings | null>(null);
  let isTablaModalOpen = $state(false);

  function openTablaModal(tabla: TablaEarnings) {
    selectedTabla = tabla;
    isTablaModalOpen = true;
  }

  function closeTablaModal() {
    isTablaModalOpen = false;
    selectedTabla = null;
  }

  function handleNavigate(path: string) {
    goto(path);
  }

  async function handleRetryClaim(gameId: string) {
    retryingClaim = gameId;
    try {
      const result = await gameStore.retryFailedClaim(gameId);
      if (result.success) {
        failedClaims = failedClaims.filter((c) => c.gameId !== gameId);
      } else {
        alert("Retry failed: " + result.error);
      }
    } catch (error) {
      console.error("Retry error:", error);
    } finally {
      retryingClaim = null;
    }
  }

  onMount(async () => {
    try {
      profile = await userStore.getProfile();
      await gameStore.fetchOpenGames(0);

      const claimsResult = await gameStore.getFailedClaims();
      if (claimsResult.success && "data" in claimsResult && claimsResult.data) {
        failedClaims = claimsResult.data;
      }

      const gamesResult = await gameStore.getRecentGamesForPlayer(10);
      if (gamesResult.success && "data" in gamesResult && gamesResult.data) {
        recentGames = gamesResult.data;
      }

      const tablaResult = await gameStore.fetchAllTablaStats();
      if (tablaResult.success && "data" in tablaResult && tablaResult.data) {
        tablaStats = tablaResult.data;
      }
    } catch (error) {
      console.error("Error loading dashboard:", error);
    } finally {
      isLoading = false;
      tablaStatsLoading = false;
    }
  });
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if profile}
  <div class="min-h-screen bg-[#1a0033] pb-8">
    <div class="w-full mx-auto px-4 py-6 sm:py-8 md:py-12 max-w-7xl">
      <div class="mb-8 sm:mb-12 text-center">
        <h1 class="text-2xl sm:text-4xl md:text-6xl font-black uppercase tracking-tight mb-3 sm:mb-4 leading-tight px-2 arcade-text-shadow">
          <span class="text-[#F4E04D] block sm:inline">WELCOME BACK,</span>
          <span class="text-[#C9B5E8] block sm:inline break-all">@{profile.username}</span>
        </h1>
      </div>

      <div class="space-y-6 sm:space-y-8">
        <StatsCard {profile} {openGamesCount} onNavigate={handleNavigate} />

        <TablaEarningsSection
          {tablaStats}
          isLoading={tablaStatsLoading}
          onTablaClick={openTablaModal}
        />

        <RecentActivitySection {recentGames} onNavigate={handleNavigate} />

        <FailedClaimsSection
          {failedClaims}
          {retryingClaim}
          onRetryClaim={handleRetryClaim}
        />
      </div>
    </div>
  </div>

  <TablaModal
    tabla={selectedTabla}
    isOpen={isTablaModalOpen}
    onClose={closeTablaModal}
  />
{/if}