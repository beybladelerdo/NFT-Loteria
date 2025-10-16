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
  <div class="flex items-center justify-center min-h-screen bg-[#ED1E79]">
    <Spinner />
  </div>
{:else if profile}
  <div class="min-h-screen bg-[#ED1E79] relative overflow-hidden">
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
    <div
      class="absolute bottom-32 left-1/4 w-10 h-10 border-4 border-[#522785] rotate-12 opacity-40"
    ></div>

    <div class="relative max-w-7xl mx-auto px-4 py-8 md:py-12">
      <!-- Retro Window Header -->
      <div
        class="mb-8 bg-gradient-to-r from-[#29ABE2] to-[#522785] p-1 rounded-t-lg shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
      >
        <div class="bg-white p-4 rounded-t-lg border-b-2 border-black">
          <div class="flex items-center justify-between">
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
            <div class="text-black font-bold text-sm uppercase tracking-wider">
              DASHBOARD.EXE
            </div>
            <div class="w-12"></div>
          </div>
        </div>
        <div class="bg-[#FBB03B] px-6 py-8 border-b-4 border-black">
          <h1
            class="text-4xl md:text-6xl font-black text-black uppercase tracking-tight inline-block"
            style="text-shadow: 4px 4px 0px #29ABE2, 8px 8px 0px #522785;"
          >
            WELCOME BACK, <span class="text-black">@{profile.username}</span>
          </h1>
          <div class="mt-4 flex gap-4 flex-wrap text-black font-bold">
            <span
              class="bg-white px-3 py-1 border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              {profile.games} GAMES
            </span>
            <span
              class="bg-white px-3 py-1 border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              {profile.wins} WINS
            </span>
            <span
              class="bg-white px-3 py-1 border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              {formatWinRate(profile.winRate)} WIN RATE
            </span>
          </div>
        </div>
      </div>

      <!-- Main Windows Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <!-- Window 1: Your Stats -->
        <div
          class="bg-gradient-to-b from-[#29ABE2] to-[#1e88c7] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
        >
          <div
            class="bg-[#29ABE2] p-2 border-b-2 border-black flex items-center justify-between"
          >
            <div class="flex items-center gap-2">
              <div class="w-4 h-4 bg-white border-2 border-black"></div>
              <span class="text-black font-black text-xs uppercase"
                >YOUR_STATS.BMP</span
              >
            </div>
            <div class="flex gap-1">
              <div class="w-4 h-4 bg-[#FBB03B] border border-black"></div>
              <div class="w-4 h-4 bg-red-500 border border-black"></div>
            </div>
          </div>
          <div class="bg-white p-6 border-4 border-black">
            <div
              class="mb-4 bg-[#522785] text-white p-4 border-2 border-black text-center"
            >
              <div class="text-sm font-bold uppercase">Games Played</div>
              <div
                class="text-5xl font-black mt-2"
                style="text-shadow: 3px 3px 0px rgba(0,0,0,0.3);"
              >
                {profile.games}
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div class="bg-[#FBB03B] p-3 border-2 border-black text-center">
                <div class="text-xs font-bold text-black">WINS</div>
                <div class="text-3xl font-black text-black">{profile.wins}</div>
              </div>
              <div class="bg-[#29ABE2] p-3 border-2 border-black text-center">
                <div class="text-xs font-bold text-black">RATE</div>
                <div class="text-3xl font-black text-black">
                  {formatWinRate(profile.winRate)}
                </div>
              </div>
            </div>

            <button
              onclick={() => goto("/profile")}
              class="w-full mt-4 bg-black text-[#29ABE2] py-3 px-4 font-black uppercase border-4 border-[#29ABE2] hover:bg-[#29ABE2] hover:text-black transition-all"
              style="box-shadow: 4px 4px 0px #FBB03B;"
            >
              VIEW PROFILE &gt;&gt;
            </button>
          </div>
        </div>

        <!-- Window 2: Join Game -->
        <div
          class="bg-gradient-to-b from-[#FBB03B] to-[#e09a2f] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
        >
          <div
            class="bg-[#FBB03B] p-2 border-b-2 border-black flex items-center justify-between"
          >
            <div class="flex items-center gap-2">
              <div class="w-4 h-4 bg-white border-2 border-black"></div>
              <span class="text-black font-black text-xs uppercase"
                >JOIN_GAME.EXE</span
              >
            </div>
            <div class="flex gap-1">
              <div class="w-4 h-4 bg-[#29ABE2] border border-black"></div>
              <div class="w-4 h-4 bg-red-500 border border-black"></div>
            </div>
          </div>
          <div class="bg-white p-6 border-4 border-black">
            <div class="text-center mb-4">
              <h3 class="text-2xl font-black uppercase text-black">
                JOIN A GAME
              </h3>
            </div>

            <p class="text-center text-sm mb-4 font-bold text-black">
              Browse open games and jump in! Find your perfect match!
            </p>

            <div
              class="bg-black text-[#29ABE2] p-4 border-4 border-[#29ABE2] mb-4 text-center"
            >
              <div class="text-sm font-bold uppercase">Currently Available</div>
              <div
                class="text-5xl font-black mt-2"
                style="text-shadow: 3px 3px 0px #FBB03B;"
              >
                {openGamesCount}
              </div>
              <div class="text-xs mt-1 uppercase">Open Games</div>
            </div>

            <button
              onclick={() => goto("/join-game")}
              class="w-full bg-[#522785] text-white py-3 px-4 font-black uppercase border-4 border-black hover:bg-[#6d3399] transition-all"
              style="box-shadow: 4px 4px 0px #000;"
            >
              BROWSE GAMES &gt;&gt;
            </button>
          </div>
        </div>

        <!-- Window 3: Host Game -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
        >
          <div
            class="bg-[#522785] p-2 border-b-2 border-black flex items-center justify-between"
          >
            <div class="flex items-center gap-2">
              <div class="w-4 h-4 bg-white border-2 border-black"></div>
              <span class="text-white font-black text-xs uppercase"
                >HOST_GAME.EXE</span
              >
            </div>
            <div class="flex gap-1">
              <div class="w-4 h-4 bg-[#FBB03B] border border-black"></div>
              <div class="w-4 h-4 bg-red-500 border border-black"></div>
            </div>
          </div>
          <div class="bg-white p-6 border-4 border-black">
            <div class="text-center mb-4">
              <h3 class="text-2xl font-black uppercase text-black">
                HOST A GAME
              </h3>
            </div>

            <p class="text-center text-sm mb-4 font-bold text-black">
              Create your own game! Set the rules and earn host fees!
            </p>

            <div class="space-y-2 mb-4 text-sm font-bold">
              <div
                class="flex items-center gap-2 bg-[#FBB03B] p-2 border-2 border-black text-black"
              >
                <span class="text-lg">✓</span>
                <span>CHOOSE GAME MODE</span>
              </div>
              <div
                class="flex items-center gap-2 bg-[#29ABE2] p-2 border-2 border-black text-black"
              >
                <span class="text-lg">✓</span>
                <span>SET ENTRY FEE</span>
              </div>
              <div
                class="flex items-center gap-2 bg-[#522785] text-white p-2 border-2 border-black"
              >
                <span class="text-lg">✓</span>
                <span>EARN HOST FEES</span>
              </div>
            </div>

            <button
              onclick={() => goto("/host-game")}
              class="w-full bg-[#FBB03B] text-black py-3 px-4 font-black uppercase border-4 border-black hover:bg-[#e09a2f] transition-all"
              style="box-shadow: 4px 4px 0px #000;"
            >
              CREATE GAME &gt;&gt;
            </button>
          </div>
        </div>
      </div>

      <!-- Recent Activity Window -->
      <div
        class="bg-gradient-to-r from-[#29ABE2] via-[#FBB03B] to-[#522785] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
      >
        <div
          class="bg-white p-2 border-b-2 border-black flex items-center justify-between"
        >
          <div class="flex items-center gap-2">
            <div class="w-4 h-4 bg-white border-2 border-black"></div>
            <span class="text-black font-black text-xs uppercase"
              >RECENT_ACTIVITY.LOG</span
            >
          </div>
          <div class="flex gap-1">
            <div class="w-4 h-4 bg-[#29ABE2] border border-black"></div>
            <div class="w-4 h-4 bg-[#FBB03B] border border-black"></div>
            <div class="w-4 h-4 bg-red-500 border border-black"></div>
          </div>
        </div>
        <div class="bg-white p-8 border-4 border-black">
          <h2
            class="text-3xl font-black uppercase mb-6 text-center text-black"
            style="text-shadow: 3px 3px 0px #29ABE2;"
          >
            RECENT ACTIVITY
          </h2>

          {#if profile.games === BigInt(0)}
            <div class="text-center py-12 bg-[#FBB03B] border-4 border-black">
              <h3 class="text-2xl font-black uppercase mb-2 text-black">
                NO GAMES YET!
              </h3>
              <p class="text-lg font-bold mb-6 text-black">
                Start playing to see your history here!
              </p>
              <button
                onclick={() => goto("/join-game")}
                class="bg-black text-[#29ABE2] py-3 px-8 font-black uppercase border-4 border-[#29ABE2] hover:bg-[#29ABE2] hover:text-black transition-all"
                style="box-shadow: 4px 4px 0px #522785;"
              >
                JOIN FIRST GAME &gt;&gt;
              </button>
            </div>
          {:else}
            <div
              class="bg-[#522785] text-white p-8 border-4 border-black text-center font-bold"
            >
              <p class="text-xl uppercase">Game history coming soon...</p>
            </div>
          {/if}
        </div>
      </div>
    </div>
  </div>
{/if}
