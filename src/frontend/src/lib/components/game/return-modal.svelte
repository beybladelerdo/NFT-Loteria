<script lang="ts">
  import { fade } from "svelte/transition";

  interface ActiveGame {
    gameId: string;
    role: "host" | "player";
  }

  interface Props {
    open: boolean;
    activeGame: ActiveGame | null;
    onReturn: () => void;
    onDismiss: () => void;
  }

  let { open, activeGame, onReturn, onDismiss }: Props = $props();
</script>

{#if open && activeGame}
  <div
    class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
    in:fade
  >
    <div
      class="bg-gradient-to-b from-[#522785] to-[#3d1d63] border-4 border-black p-6 max-w-md w-full shadow-[8px_8px_0px_rgba(0,0,0,0.8)]"
    >
      <div class="mb-4">
        <span
          class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)]"
        >
          🎮 Active Game
        </span>
      </div>

      <h3
        class="text-xl font-black text-[#F4E04D] uppercase mb-4"
        style="text-shadow: 3px 3px 0px #000;"
      >
        {activeGame.role === "host"
          ? "You Are Hosting a Game"
          : "You Are in a Game"}
      </h3>

      <div
        class="bg-[#1a0033] border-2 border-[#C9B5E8] p-4 mb-6 shadow-[3px_3px_0px_rgba(0,0,0,1)]"
      >
        <p class="text-white text-sm font-bold mb-2">
          It looks like you're
          {activeGame.role === "host" ? " hosting" : " playing in"} game:
        </p>
        <p class="text-[#F4E04D] text-lg font-black uppercase text-center my-3">
          {activeGame.gameId}
        </p>
        <p class="text-[#C9B5E8] text-xs">
          Would you like to return to the game?
        </p>
      </div>

      <div class="flex gap-3">
        <button
          class="flex-1 bg-[#C9B5E8] text-[#1a0033] border-4 border-black px-4 py-3 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#d9c9f0]"
          onclick={onDismiss}
        >
          Stay Here
        </button>
        <button
          class="flex-1 bg-[#F4E04D] text-[#1a0033] border-4 border-black px-4 py-3 font-black uppercase text-xs shadow-[4px_4px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d]"
          onclick={onReturn}
        >
          Return to Game
        </button>
      </div>
    </div>
  </div>
{/if}
