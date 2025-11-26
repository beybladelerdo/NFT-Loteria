<script lang="ts">
  import { TokenService } from "$lib/services/token-service";
  import type { GameView } from "$lib/utils/helpers";
  import { modeLabel, statusLabel, shortPrincipal } from "$lib/utils/helpers";

  interface Props {
    games: GameView[];
    selectedGameId: string | null;
    tokenDecimals: number;
    onSelectGame: (game: GameView) => void;
  }

  let { games, selectedGameId, tokenDecimals, onSelectGame }: Props = $props();

  const tokenService = new TokenService();

  function getTokenSymbol(token: GameView["tokenType"]): string {
    if ("ICP" in token) return "ICP";
    if ("ckBTC" in token) return "ckBTC";
    if ("gldt" in token) return "GLDT";
    return "ICP";
  }
</script>

<div class="arcade-panel p-4 sm:p-5 space-y-4">
  <div class="flex items-center justify-between">
    <span class="arcade-badge"> OPEN LOBBIES </span>
    <span class="text-xs text-white font-bold">
      {games.length}
    </span>
  </div>

  {#if games.length === 0}
    <div class="arcade-panel-sm p-6 text-center">
      <p class="text-white font-bold uppercase text-xs">
        No games available. Try refreshing or hosting your own!
      </p>
    </div>
  {:else}
    <div class="space-y-3">
      {#each games as game (game.id)}
        <button
          class={`w-full text-left arcade-panel-sm p-4 transition-all ${
            selectedGameId === game.id
              ? "ring-4 ring-[#F4E04D]"
              : "hover:-translate-y-1 hover:shadow-[6px_6px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-[4px_4px_0px_rgba(0,0,0,1)]"
          }`}
          onclick={() => onSelectGame(game)}
        >
          <div class="flex items-center justify-between gap-3 mb-3">
            <h3
              class="text-base sm:text-lg font-black text-white uppercase break-words"
            >
              {game.name}
            </h3>
            <span class="arcade-badge shrink-0">
              {modeLabel(game.mode)}
            </span>
          </div>

          <div
            class="grid grid-cols-2 gap-2 text-[10px] sm:text-xs font-bold text-[#C9B5E8] uppercase"
          >
            <div>
              Entry:
              <span class="text-white">
                {tokenService.formatBalance(game.entryFee, tokenDecimals)}
                {getTokenSymbol(game.tokenType)}
              </span>
            </div>
            <div class="text-right">
              Players:
              <span class="text-white">
                {Number(game.playerCount)} / {Number(game.maxPlayers)}
              </span>
            </div>
          </div>

          <p
            class="mt-2 text-[10px] sm:text-[11px] text-[#8f7fc1] font-bold uppercase break-all"
          >
            Host: {shortPrincipal(game.host.toText())} · {statusLabel(
              game.status,
            )}
          </p>
        </button>
      {/each}
    </div>
  {/if}
</div>
