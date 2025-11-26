<script lang="ts">
  import { TokenService } from "$lib/services/token-service";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import type { GameDetailData } from "$lib/utils/helpers";
  import {
    modeLabel,
    shortPrincipal,
    unwrapOpt,
    symbolFromVariant,
  } from "$lib/utils/helpers";

  interface Props {
    detail: GameDetailData | null;
    isFetching: boolean;
  }

  let { detail, isFetching }: Props = $props();

  const tokenService = new TokenService();
</script>

<div class="arcade-panel p-4 sm:p-6 space-y-4">
  <div>
    <span class="arcade-badge mb-3 inline-block"> LOBBY DETAILS </span>
    {#if detail}
      <h2
        class="text-xl sm:text-2xl font-black text-white uppercase arcade-text-shadow"
      >
        {detail.name}
      </h2>
    {/if}
  </div>

  {#if isFetching}
    <div class="flex items-center justify-center py-10">
      <Spinner />
    </div>
  {:else if detail}
    <div
      class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 text-xs sm:text-sm font-bold uppercase"
    >
      <div class="text-white">
        Host:
        <span class="text-[#F4E04D] block sm:inline break-all">
          {detail.host.username
            ? unwrapOpt(detail.host.username)
            : shortPrincipal(detail.host.principal.toText())}
        </span>
      </div>
      <div class="text-white">
        Mode:
        <span class="text-[#F4E04D]">
          {modeLabel(detail.mode)}
        </span>
      </div>
      <div class="text-white">
        Entry Fee:
        <span class="text-[#F4E04D]">
          {tokenService.formatBalance(detail.entryFee, 8)}
          {symbolFromVariant(detail.tokenType)}
        </span>
      </div>
      <div class="text-white">
        Players:
        <span class="text-[#F4E04D]">
          {detail.playerCount} / {detail.maxPlayers}
        </span>
      </div>
    </div>

    <div class="arcade-panel-sm p-3 sm:p-4">
      <p class="text-xs font-bold text-[#C9B5E8] uppercase mb-2">
        Players in Lobby:
      </p>
      {#if detail.players.length === 0}
        <p
          class="text-[10px] sm:text-[11px] text-[#8f7fc1] font-bold uppercase"
        >
          No one has joined yet. You can be the first!
        </p>
      {:else}
        <div class="flex flex-wrap gap-2">
          {#each detail.players as player}
            <span class="arcade-badge text-[9px] sm:text-[10px]">
              {player.username && player.username.length
                ? unwrapOpt(player.username)
                : shortPrincipal(player.principal.toText())}
            </span>
          {/each}
        </div>
      {/if}
    </div>
  {:else}
    <p class="text-sm text-[#C9B5E8] font-bold uppercase">
      Unable to load detailed information for this lobby. Please try again.
    </p>
  {/if}
</div>
