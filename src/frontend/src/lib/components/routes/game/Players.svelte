<script lang="ts">
  import { addToast } from "$lib/stores/toasts-store";
  import { shortPrincipal } from "$lib/utils/game-helper";

  interface Player {
    player: any;
    marks: number;
    tablas: number;
  }

  interface Props {
    players: Player[];
    playerName: (player: any) => string;
  }

  let { players, playerName }: Props = $props();

  function copyPrincipal(principal: string) {
    navigator.clipboard.writeText(principal);
    addToast({
      message: "Principal copied!",
      type: "success",
      duration: 2000,
    });
  }
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="mb-3 sm:mb-4 flex items-center justify-between">
    <span class="arcade-badge bg-[#C9B5E8]"> Players </span>
    <span class="text-xs text-white font-bold">
      {players.length} joined
    </span>
  </div>

  {#if players.length === 0}
    <div class="arcade-panel-sm p-4 sm:p-6 text-center">
      <p class="text-[#C9B5E8] font-bold uppercase text-xs">
        No players have joined yet.
      </p>
    </div>
  {:else}
    <div class="space-y-2 sm:space-y-3">
      {#each players as stat (stat.player.principal.toText())}
        <div
          class="arcade-panel-sm p-2 sm:p-3 flex items-center justify-between gap-2 sm:gap-4"
        >
          <div class="min-w-0 flex-1">
            <p
              class="text-white font-black text-xs sm:text-sm uppercase break-all"
            >
              {playerName(stat.player)}
            </p>
            <p class="text-xs text-[#C9B5E8] font-bold">
              Tablas: {stat.tablas} · Marks: {stat.marks}
            </p>
          </div>
          <button
            class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 py-1 text-xs font-black uppercase shadow-[2px_2px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d] transition-all relative group flex-shrink-0 active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)]"
            onclick={() => copyPrincipal(stat.player.principal.toText())}
            title="Click to copy full principal"
          >
            #{shortPrincipal(stat.player.principal.toText())}
            <span
              class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-[#1a0033] border-2 border-[#F4E04D] text-[#F4E04D] text-[10px] font-mono rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none shadow-[4px_4px_0px_rgba(0,0,0,1)] z-10 hidden sm:block"
            >
              {stat.player.principal.toText()}
              <span class="block text-[8px] text-[#C9B5E8] mt-1"
                >Click to copy</span
              >
            </span>
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>
