<script lang="ts">
  import { onMount } from "svelte";
  import { tokenStore } from "$lib/stores/token-store";
  import { TokenService } from "$lib/services/token-service";
  import QRModal from "./qr-modal.svelte";
  import SendModal from "./send-modal.svelte";

  const tokenService = new TokenService();

  let showQRModal = $state(false);
  let showSendModal = $state(false);
  let selectedToken = $state<string | null>(null);
  let isRefreshing = $state(false);

  onMount(async () => {
    await tokenStore.fetchBalances();
  });

  async function handleRefresh() {
    isRefreshing = true;
    await tokenStore.refreshBalances();
    setTimeout(() => (isRefreshing = false), 500);
  }

  function openQRCode(symbol: string) {
    selectedToken = symbol;
    showQRModal = true;
  }

  function openSend(symbol: string) {
    selectedToken = symbol;
    showSendModal = true;
  }
</script>

<div
  class="bg-gradient-to-b from-[#29ABE2] to-[#1e88c7] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
>
  <div
    class="bg-[#29ABE2] p-2 border-b-2 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <div class="w-3 h-3 bg-red-500 rounded-full border border-black"></div>
      <div class="w-3 h-3 bg-[#FBB03B] rounded-full border border-black"></div>
      <div class="w-3 h-3 bg-green-500 rounded-full border border-black"></div>
    </div>
    <div class="text-black font-bold text-sm uppercase tracking-wider">
      WALLET.EXE
    </div>
    <button
      onclick={handleRefresh}
      disabled={$tokenStore.isLoading || isRefreshing}
      class="bg-[#FBB03B] text-black px-2 py-1 font-black uppercase border-2 border-black hover:bg-[#e09a2f] transition-all text-xs disabled:opacity-50"
      style="box-shadow: 2px 2px 0px #000;"
    >
      {isRefreshing ? "..." : "⟳"}
    </button>
  </div>

  <div class="bg-white p-6 border-4 border-black">
    <h2
      class="text-2xl md:text-3xl font-black text-black uppercase mb-6 text-center"
      style="text-shadow: 3px 3px 0px #29ABE2;"
    >
      YOUR WALLET
    </h2>

    {#if $tokenStore.isLoading && $tokenStore.balances.length === 0}
      <div class="text-center py-12">
        <div
          class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-black border-t-[#29ABE2]"
        ></div>
        <p class="mt-4 font-bold text-black">LOADING BALANCES...</p>
      </div>
    {:else if $tokenStore.error}
      <div class="bg-red-500 border-4 border-black p-4 text-center">
        <p class="font-bold text-white uppercase">{$tokenStore.error}</p>
        <button
          onclick={handleRefresh}
          class="mt-4 bg-white text-black px-4 py-2 font-black uppercase border-2 border-black"
          style="box-shadow: 2px 2px 0px #000;"
        >
          RETRY
        </button>
      </div>
    {:else}
      <div class="space-y-4">
        {#each $tokenStore.balances as token}
          <div
            class="bg-white border-4 border-black p-4"
            style="box-shadow: 4px 4px 0px #000;"
          >
            <div class="flex items-center gap-4">
              <!-- Token Icon -->
              <div
                class="w-16 h-16 bg-white border-2 border-black flex items-center justify-center flex-shrink-0"
              >
                <img
                  src={token.icon}
                  alt={token.symbol}
                  class="w-12 h-12 object-contain"
                />
              </div>

              <!-- Token Info -->
              <div class="flex-1 min-w-0">
                <div class="flex items-baseline gap-2">
                  <h3 class="text-xl font-black text-black uppercase">
                    {token.name}
                  </h3>
                </div>
                <div class="mt-1">
                  <p class="text-2xl font-black text-black">
                    {tokenService.formatBalance(token.balance, token.decimals)}
                  </p>
                  <p class="text-xs font-bold text-black uppercase">
                    {token.symbol}
                  </p>
                </div>
              </div>

              <!-- Action Buttons -->
              <div class="flex flex-col gap-2">
                <button
                  onclick={() => openQRCode(token.symbol)}
                  class="bg-[#522785] text-white px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#6d3399] transition-all text-xs whitespace-nowrap"
                  style="box-shadow: 2px 2px 0px #000;"
                >
                  QR CODE
                </button>
                <button
                  onclick={() => openSend(token.symbol)}
                  class="bg-[#FBB03B] text-black px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#e09a2f] transition-all text-xs whitespace-nowrap"
                  style="box-shadow: 2px 2px 0px #000;"
                >
                  SEND
                </button>
              </div>
            </div>
          </div>
        {/each}
      </div>

      {#if $tokenStore.lastUpdated}
        <p class="text-xs text-center mt-4 font-bold text-black">
          LAST UPDATED: {new Date($tokenStore.lastUpdated).toLocaleTimeString()}
        </p>
      {/if}
    {/if}
  </div>
</div>

{#if showQRModal && selectedToken}
  <QRModal
    token={$tokenStore.balances.find((t) => t.symbol === selectedToken)}
    onClose={() => (showQRModal = false)}
  />
{/if}

{#if showSendModal && selectedToken}
  <SendModal
    token={$tokenStore.balances.find((t) => t.symbol === selectedToken)}
    onClose={() => (showSendModal = false)}
    onSuccess={handleRefresh}
  />
{/if}
