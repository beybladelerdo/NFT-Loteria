<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { tokenStore } from "$lib/stores/token-store";
  import { TokenService } from "$lib/services/token-service";
  import QRModal from "./qr-modal.svelte";
  import SendModal from "./send-modal.svelte";

  const tokenService = new TokenService();

  let showQRModal = $state(false);
  let showSendModal = $state(false);
  let selectedToken = $state<string | null>(null);
  let isRefreshing = $state(false);
  let refreshInterval: ReturnType<typeof setInterval> | null = null;

  const AUTO_REFRESH_INTERVAL = 30000;

  onMount(async () => {
    await tokenStore.fetchBalances();
    refreshInterval = setInterval(() => {
      if (!isRefreshing && !showQRModal && !showSendModal) {
        handleRefresh();
      }
    }, AUTO_REFRESH_INTERVAL);
  });

  onDestroy(() => {
    if (refreshInterval) {
      clearInterval(refreshInterval);
    }
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
  class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 md:p-8 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
>
  <div class="flex items-center justify-between mb-6">
    <span
      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
    >
      Wallet
    </span>
    <button
      onclick={handleRefresh}
      disabled={$tokenStore.isLoading || isRefreshing}
      class="bg-[#C9B5E8] text-[#1a0033] px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all text-xs disabled:opacity-50 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
    >
      {isRefreshing ? "..." : "⟳ REFRESH"}
    </button>
  </div>

  <h2
    class="text-2xl md:text-3xl font-black uppercase mb-6 text-[#F4E04D]"
    style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
  >
    YOUR BALANCES
  </h2>

  {#if $tokenStore.isLoading && $tokenStore.balances.length === 0}
    <div
      class="text-center py-12 bg-[#1a0033] border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
    >
      <div
        class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-[#C9B5E8] border-t-[#F4E04D]"
      ></div>
      <p class="mt-4 font-bold text-white uppercase">LOADING BALANCES...</p>
    </div>
  {:else if $tokenStore.error}
    <div
      class="bg-[#FF6EC7] border-4 border-black p-6 text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
    >
      <p class="font-bold text-[#1a0033] uppercase text-lg">
        {$tokenStore.error}
      </p>
      <button
        onclick={handleRefresh}
        class="mt-4 bg-white text-[#1a0033] px-6 py-3 font-black uppercase border-2 border-black hover:scale-105 transition-all shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
      >
        RETRY
      </button>
    </div>
  {:else}
    <div class="space-y-4">
      {#each $tokenStore.balances as token}
        <div
          class="bg-[#1a0033] border-4 border-black p-4 hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
        >
          <div class="flex items-center gap-4">
            <!-- Token Icon -->
            <div
              class="w-16 h-16 flex items-center justify-center flex-shrink-0"
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
                <h3
                  class="text-xl font-black text-[#F4E04D] uppercase"
                  style="text-shadow: 2px 2px 0px #000;"
                >
                  {token.name}
                </h3>
              </div>
              <div class="mt-1">
                <p
                  class="text-2xl font-black text-white"
                  style="text-shadow: 2px 2px 0px #000;"
                >
                  {tokenService.formatBalance(token.balance, token.decimals)}
                </p>
                <p class="text-xs font-bold text-[#C9B5E8] uppercase">
                  {token.symbol}
                </p>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex flex-col gap-2">
              <button
                onclick={() => openQRCode(token.symbol)}
                class="bg-[#C9B5E8] text-[#1a0033] px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all text-xs whitespace-nowrap shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              >
                QR CODE
              </button>
              <button
                onclick={() => openSend(token.symbol)}
                class="bg-[#F4E04D] text-[#1a0033] px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#fff27d] hover:scale-105 transition-all text-xs whitespace-nowrap shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              >
                SEND
              </button>
            </div>
          </div>
        </div>
      {/each}
    </div>

    {#if $tokenStore.lastUpdated}
      <p class="text-xs text-center mt-6 font-bold text-[#C9B5E8]">
        LAST UPDATED: {new Date($tokenStore.lastUpdated).toLocaleTimeString()}
      </p>
    {/if}
  {/if}
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
