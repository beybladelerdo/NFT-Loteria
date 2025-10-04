<script lang="ts">
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { userStore } from "$lib/stores/user-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Button from "$lib/components/shared/Button.svelte";
  
  let profile: Profile | undefined = $state(undefined);
  let isLoading = $state(true);
  let openGamesCount = $derived(gameStore.openGames.length);
  
  onMount(async () => {
    try {
      profile = await userStore.getProfile();
      await gameStore.fetchOpenGames(0);
    } catch (error) {
      console.error("Error loading dashboard:", error);
    } finally {
      isLoading = false;
    }
  });
  
  function formatWinRate(rate: number): string {
    return `${(rate * 100).toFixed(1)}%`;
  }
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-black">
    <Spinner />
  </div>
{:else if profile}
  <div class="min-h-screen bg-black font-freigeist">
    <div class="max-w-7xl mx-auto px-4 py-8 md:py-12">
      
      <!-- Welcome Banner -->
      <div class="mb-8 md:mb-12">
        <h1 class="text-3xl md:text-5xl font-bold text-white mb-2">
          Welcome back, <span class="text-violet-500">@{profile.username}</span>
        </h1>
        <p class="text-gray-400 text-sm md:text-base">
          {profile.games} games played • {profile.wins} wins • {formatWinRate(profile.winRate)} win rate
        </p>
      </div>

      <!-- 3-Tile Grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6 mb-8">
        
        <!-- Tile 1: Your Stats -->
        <div class="bg-violet-500 rounded-2xl p-6 text-black">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-bold uppercase tracking-wide">Your Stats</h2>
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          
          <div class="space-y-4">
            <div class="bg-black/20 rounded-xl p-4">
              <p class="text-sm opacity-80 mb-1">Games Played</p>
              <p class="text-3xl font-bold">{profile.games}</p>
            </div>
            
            <div class="grid grid-cols-2 gap-3">
              <div class="bg-black/20 rounded-xl p-4">
                <p class="text-xs opacity-80 mb-1">Wins</p>
                <p class="text-2xl font-bold">{profile.wins}</p>
              </div>
              <div class="bg-black/20 rounded-xl p-4">
                <p class="text-xs opacity-80 mb-1">Win Rate</p>
                <p class="text-2xl font-bold">{formatWinRate(profile.winRate)}</p>
              </div>
            </div>
          </div>
          
          <Button variant="secondary" fullWidth onclick={() => goto('/profile')} class="mt-4">
            View Full Profile
          </Button>
        </div>

        <!-- Tile 2: Join a Game -->
        <div class="bg-white/5 border border-white/10 rounded-2xl p-6 text-white hover:border-violet-500/50 transition-colors">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-bold uppercase tracking-wide">Join a Game</h2>
            <svg class="w-8 h-8 text-violet-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          
          <p class="text-gray-400 mb-6">
            Browse open games waiting for players. Find the perfect match and jump in!
          </p>
          
          <div class="bg-violet-500/10 rounded-lg p-4 mb-6 border border-violet-500/20">
            <p class="text-sm text-gray-400">Currently Available</p>
            <p class="text-3xl font-bold text-violet-500">{openGamesCount}</p>
            <p class="text-xs text-gray-500 mt-1">open games</p>
          </div>
          
          <Button fullWidth onclick={() => goto('/join-game')}>
            Browse Games
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </Button>
        </div>

        <!-- Tile 3: Host a Game -->
        <div class="bg-white/5 border border-white/10 rounded-2xl p-6 text-white hover:border-violet-500/50 transition-colors">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-bold uppercase tracking-wide">Host a Game</h2>
            <svg class="w-8 h-8 text-violet-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
          </div>
          
          <p class="text-gray-400 mb-6">
            Create your own game. Set the rules, entry fee, and host for others!
          </p>
          
          <div class="space-y-3 mb-6">
            <div class="flex items-center gap-2 text-sm text-gray-400">
              <svg class="w-4 h-4 text-violet-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Choose game mode
            </div>
            <div class="flex items-center gap-2 text-sm text-gray-400">
              <svg class="w-4 h-4 text-violet-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Set entry fee
            </div>
            <div class="flex items-center gap-2 text-sm text-gray-400">
              <svg class="w-4 h-4 text-violet-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Earn host fees
            </div>
          </div>
          
          <Button variant="outline" fullWidth onclick={() => goto('/host-game')}>
            Create Game
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </Button>
        </div>
      </div>

      <!-- Recent Activity Section -->
      <div class="bg-white/5 border border-white/10 rounded-2xl p-6 md:p-8">
        <h2 class="text-2xl font-bold text-white mb-6 uppercase tracking-wide">Recent Activity</h2>
        
        {#if profile.games === 0}
          <div class="text-center py-12">
            <svg class="w-16 h-16 text-gray-600 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <h3 class="text-xl font-bold text-white mb-2">No games yet</h3>
            <p class="text-gray-400 mb-6">Start playing to see your game history here</p>
            <Button onclick={() => goto('/join-game')}>
              Join Your First Game
            </Button>
          </div>
        {:else}
          <div class="space-y-3">
            <p class="text-gray-400 text-center py-8">Game history coming soon...</p>
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}