<script lang="ts">
  import type { Profile } from "../../../../../../declarations/backend/backend.did";

  interface Props {
    profile: Profile;
    openGamesCount: number;
    onNavigate: (path: string) => void;
  }

  let { profile, openGamesCount, onNavigate }: Props = $props();
</script>

<div
  class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 md:gap-8"
>
  <div
    class="arcade-panel p-4 sm:p-6 hover:shadow-[12px_12px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
  >
    <div class="mb-3 sm:mb-4">
      <span class="arcade-badge">Your Stats</span>
    </div>

    <h3
      class="text-xl sm:text-2xl font-black text-[#F4E04D] uppercase mb-4 sm:mb-6 arcade-text-shadow"
    >
      YOUR PROGRESS
    </h3>

    <div
      class="mb-4 sm:mb-6 arcade-panel-sm text-[#F4E04D] p-4 sm:p-6 text-center"
    >
      <div class="text-xs sm:text-sm font-bold uppercase text-[#C9B5E8]">
        Games Played
      </div>
      <div class="text-4xl sm:text-5xl font-black mt-2 arcade-text-shadow">
        {profile.games}
      </div>
    </div>

    <div class="grid grid-cols-2 gap-2 sm:gap-3 mb-4 sm:mb-6">
      <div
        class="bg-[#F4E04D] p-3 sm:p-4 border-2 border-black text-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <div class="text-xs font-bold text-[#1a0033] uppercase">Wins</div>
        <div class="text-2xl sm:text-3xl font-black text-[#1a0033]">
          {profile.wins}
        </div>
      </div>
      <div
        class="bg-[#C9B5E8] p-3 sm:p-4 border-2 border-black text-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <div class="text-xs font-bold text-[#1a0033] uppercase">Win Streak</div>
        <div class="text-2xl sm:text-3xl font-black text-[#1a0033]">0</div>
      </div>
    </div>

    <button
      onclick={() => onNavigate("/profile")}
      class="w-full arcade-button py-2 sm:py-3 px-3 sm:px-4 text-xs sm:text-sm bg-white hover:bg-[#F4E04D]"
    >
      WALLET &gt;&gt;
    </button>
  </div>

  <div
    class="arcade-panel p-4 sm:p-6 hover:shadow-[12px_12px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
  >
    <div class="mb-3 sm:mb-4">
      <span class="arcade-badge bg-[#C9B5E8]">Join Game</span>
    </div>

    <h3
      class="text-xl sm:text-2xl font-black text-[#C9B5E8] uppercase mb-3 sm:mb-4 arcade-text-shadow"
    >
      JOIN A GAME
    </h3>

    <p class="text-xs sm:text-sm mb-4 sm:mb-6 font-bold text-white">
      Browse open games and jump in! Find your perfect match!
    </p>

    <div
      class="arcade-panel-sm text-[#C9B5E8] p-4 sm:p-6 mb-4 sm:mb-6 text-center"
    >
      <div class="text-xs sm:text-sm font-bold uppercase text-[#F4E04D]">
        Currently Available
      </div>
      <div class="text-4xl sm:text-5xl font-black mt-2 arcade-text-shadow">
        {openGamesCount}
      </div>
      <div class="text-xs mt-1 uppercase text-white">Open Games</div>
    </div>

    <button
      onclick={() => onNavigate("/join-game")}
      class="w-full bg-[#C9B5E8] text-[#1a0033] py-2 sm:py-3 px-3 sm:px-4 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] active:translate-x-[2px] active:translate-y-[2px] transition-all text-xs sm:text-sm shadow-[4px_4px_0px_rgba(0,0,0,1)] active:shadow-[2px_2px_0px_rgba(0,0,0,1)]"
    >
      BROWSE GAMES &gt;&gt;
    </button>
  </div>

  <div
    class="arcade-panel p-4 sm:p-6 hover:shadow-[12px_12px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
  >
    <div class="mb-3 sm:mb-4">
      <span class="arcade-badge bg-white">Host Game</span>
    </div>

    <h3
      class="text-xl sm:text-2xl font-black text-white uppercase mb-3 sm:mb-4 arcade-text-shadow"
    >
      HOST A GAME
    </h3>

    <p class="text-xs sm:text-sm mb-4 sm:mb-6 font-bold text-white">
      Create your own game! Set the rules and earn host fees!
    </p>

    <div class="space-y-2 mb-4 sm:mb-6 text-xs sm:text-sm font-bold">
      <div
        class="flex items-center gap-2 bg-[#F4E04D] p-2 sm:p-3 border-2 border-black text-[#1a0033] shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <span class="text-base sm:text-lg">✓</span>
        <span>CHOOSE GAME MODE</span>
      </div>
      <div
        class="flex items-center gap-2 bg-[#C9B5E8] p-2 sm:p-3 border-2 border-black text-[#1a0033] shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <span class="text-base sm:text-lg">✓</span>
        <span>SET ENTRY FEE</span>
      </div>
      <div
        class="flex items-center gap-2 bg-white text-[#1a0033] p-2 sm:p-3 border-2 border-black shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <span class="text-base sm:text-lg">✓</span>
        <span>EARN HOST FEES</span>
      </div>
    </div>

    <button
      onclick={() => onNavigate("/host-game")}
      class="arcade-button w-full py-2 sm:py-3 px-3 sm:px-4 text-xs sm:text-sm"
    >
      CREATE GAME &gt;&gt;
    </button>
  </div>
</div>
