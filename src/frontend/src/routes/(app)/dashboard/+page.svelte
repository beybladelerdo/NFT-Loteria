<script lang="ts">
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { userStore } from "$lib/stores/user-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  import Spinner from "$lib/components/shared/global/spinner.svelte";

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
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if profile}
  <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
    <!-- Flickering Grid Background -->

    <div class="relative z-10 max-w-7xl mx-auto px-4 py-8 md:py-12">
      <!-- Hero Header -->
      <div class="mb-12 text-center">
        <h1
          class="text-4xl md:text-6xl font-black uppercase tracking-tight mb-4"
          style="text-shadow: 4px 4px 0px #000, -2px -2px 0px #000, 2px -2px 0px #000, -2px 2px 0px #000;"
        >
          <span class="text-[#F4E04D]">WELCOME BACK,</span>
          <span class="text-[#C9B5E8]">@{profile.username}</span>
        </h1>
        <div class="flex justify-center gap-4 flex-wrap">
          <span
            class="bg-[#F4E04D] text-[#1a0033] px-4 py-2 border-2 border-black font-bold uppercase text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
          >
            {profile.games} GAMES
          </span>
          <span
            class="bg-[#C9B5E8] text-[#1a0033] px-4 py-2 border-2 border-black font-bold uppercase text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
          >
            {profile.wins} WINS
          </span>
        </div>
      </div>

      <!-- Main Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-8">
        <!-- Your Stats Card -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-4">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Your Stats
            </span>
          </div>

          <h3
            class="text-2xl font-black text-[#F4E04D] uppercase mb-6"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
            YOUR PROGRESS
          </h3>

          <div
            class="mb-6 bg-[#1a0033] text-[#F4E04D] p-6 border-2 border-black text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <div class="text-sm font-bold uppercase text-[#C9B5E8]">
              Games Played
            </div>
            <div
              class="text-5xl font-black mt-2"
              style="text-shadow: 3px 3px 0px #000;"
            >
              {profile.games}
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3 mb-6">
            <div
              class="bg-[#F4E04D] p-4 border-2 border-black text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-xs font-bold text-[#1a0033] uppercase">Wins</div>
              <div class="text-3xl font-black text-[#1a0033]">
                {profile.wins}
              </div>
            </div>
            <div
              class="bg-[#C9B5E8] p-4 border-2 border-black text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-xs font-bold text-[#1a0033] uppercase">Rate</div>
              <div class="text-3xl font-black text-[#1a0033]">
                {formatWinRate(profile.winRate)}
              </div>
            </div>
          </div>

          <button
            onclick={() => goto("/profile")}
            class="w-full bg-white text-[#1a0033] py-3 px-4 font-black uppercase border-4 border-black hover:bg-[#F4E04D] hover:scale-105 transition-all text-sm shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            VIEW PROFILE &gt;&gt;
          </button>
        </div>

        <!-- Join Game Card -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-4">
            <span
              class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Join Game
            </span>
          </div>

          <h3
            class="text-2xl font-black text-[#C9B5E8] uppercase mb-4"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
            JOIN A GAME
          </h3>

          <p class="text-sm mb-6 font-bold text-white">
            Browse open games and jump in! Find your perfect match!
          </p>

          <div
            class="bg-[#1a0033] text-[#C9B5E8] p-6 border-4 border-black mb-6 text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <div class="text-sm font-bold uppercase text-[#F4E04D]">
              Currently Available
            </div>
            <div
              class="text-5xl font-black mt-2"
              style="text-shadow: 3px 3px 0px #000;"
            >
              {openGamesCount}
            </div>
            <div class="text-xs mt-1 uppercase text-white">Open Games</div>
          </div>

          <button
            onclick={() => goto("/join-game")}
            class="w-full bg-[#C9B5E8] text-[#1a0033] py-3 px-4 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all text-sm shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            BROWSE GAMES &gt;&gt;
          </button>
        </div>

        <!-- Host Game Card -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-4">
            <span
              class="bg-white text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Host Game
            </span>
          </div>

          <h3
            class="text-2xl font-black text-white uppercase mb-4"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
            HOST A GAME
          </h3>

          <p class="text-sm mb-6 font-bold text-white">
            Create your own game! Set the rules and earn host fees!
          </p>

          <div class="space-y-2 mb-6 text-sm font-bold">
            <div
              class="flex items-center gap-2 bg-[#F4E04D] p-3 border-2 border-black text-[#1a0033] shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              <span class="text-lg">✓</span>
              <span>CHOOSE GAME MODE</span>
            </div>
            <div
              class="flex items-center gap-2 bg-[#C9B5E8] p-3 border-2 border-black text-[#1a0033] shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              <span class="text-lg">✓</span>
              <span>SET ENTRY FEE</span>
            </div>
            <div
              class="flex items-center gap-2 bg-white text-[#1a0033] p-3 border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              <span class="text-lg">✓</span>
              <span>EARN HOST FEES</span>
            </div>
          </div>

          <button
            onclick={() => goto("/host-game")}
            class="w-full bg-[#F4E04D] text-[#1a0033] py-3 px-4 font-black uppercase border-4 border-black hover:bg-[#fff27d] hover:scale-105 transition-all text-sm shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            CREATE GAME &gt;&gt;
          </button>
        </div>
      </div>

      <!-- Recent Activity Section -->
      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
      >
        <div class="mb-6">
          <span
            class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            Recent Activity
          </span>
        </div>

        <h2
          class="text-3xl font-black uppercase mb-8 text-[#F4E04D]"
          style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
        >
          RECENT ACTIVITY
        </h2>

        {#if profile.games === BigInt(0)}
          <div
            class="text-center py-12 bg-[#1a0033] border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <h3
              class="text-2xl font-black uppercase mb-4 text-[#F4E04D]"
              style="text-shadow: 2px 2px 0px #000;"
            >
              NO GAMES YET!
            </h3>
            <p class="text-lg font-bold mb-6 text-white">
              Start playing to see your history here!
            </p>
            <button
              onclick={() => goto("/join-game")}
              class="bg-[#F4E04D] text-[#1a0033] py-3 px-8 font-black uppercase border-4 border-black hover:bg-[#fff27d] hover:scale-105 transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
            >
              JOIN FIRST GAME &gt;&gt;
            </button>
          </div>
        {:else}
          <div
            class="bg-[#1a0033] text-white p-8 border-4 border-black text-center font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <p class="text-xl uppercase">Game history coming soon...</p>
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}
