<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { goto } from "$app/navigation";
  import Marquee from "$lib/components/landing/SlideCarousel.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import NumberTicker from "$lib/components/landing/NumberTicker.svelte";
  import { cardImages, tablaImages } from "$lib/data/gallery";
  import { gameStore } from "$lib/stores/game-store.svelte";

  const playNow = () => goto("/join-game");
  const hostGame = () => goto("/host-game");
  const dashboard = () => goto("/dashboard");
  const buyTabla = () => window.open("https://dgdg.app/nfts/collections/nft_loteria", "_blank");

  let volume24h = $state({ icp: 0n, ckbtc: 0n, gldt: 0n });
  let prevVolume24h = $state({ icp: 0n, ckbtc: 0n, gldt: 0n });
  let volumeChange = $state({ icp: 0, ckbtc: 0, gldt: 0 });
  let largestPots = $state({ icp: 0n, ckbtc: 0n, gldt: 0n });
  let isLoading = $state(true);
  let currentPotToken = $state<"icp" | "ckbtc" | "gldt">("icp");
  let pollInterval: ReturnType<typeof setInterval>;
  let potRotationInterval: ReturnType<typeof setInterval>;

  const icpValue = $derived(Number(volume24h.icp) / 1e8);
  const ckbtcValue = $derived(Number(volume24h.ckbtc) / 1e8);
  const gldtValue = $derived(Number(volume24h.gldt) / 1e8);

  const currentPotValue = $derived.by(() => {
    if (currentPotToken === "icp") return Number(largestPots.icp) / 1e8;
    if (currentPotToken === "ckbtc") return Number(largestPots.ckbtc) / 1e8;
    return Number(largestPots.gldt) / 1e8;
  });

  function calculatePercentChange(current: bigint, previous: bigint): number {
    if (previous === 0n) return 0;
    const curr = Number(current);
    const prev = Number(previous);
    return ((curr - prev) / prev) * 100;
  }

  async function fetchStats() {
    try {
      const [vol24hRes, largestPotsRes] = await Promise.all([
        gameStore.get24hVolume(),
        gameStore.getLargestPots(),
      ]);

      if (vol24hRes.success && vol24hRes.data) {
        if (prevVolume24h.icp > 0n || prevVolume24h.ckbtc > 0n || prevVolume24h.gldt > 0n) {
          volumeChange = {
            icp: calculatePercentChange(vol24hRes.data.totalICP, prevVolume24h.icp),
            ckbtc: calculatePercentChange(vol24hRes.data.totalCkBTC, prevVolume24h.ckbtc),
            gldt: calculatePercentChange(vol24hRes.data.totalGLDT, prevVolume24h.gldt),
          };
        }

        prevVolume24h = { ...volume24h };

        volume24h = {
          icp: vol24hRes.data.totalICP,
          ckbtc: vol24hRes.data.totalCkBTC,
          gldt: vol24hRes.data.totalGLDT,
        };
      }

      if (largestPotsRes.success && largestPotsRes.data) {
        largestPots = {
          icp: largestPotsRes.data.totalICP,
          ckbtc: largestPotsRes.data.totalCkBTC,
          gldt: largestPotsRes.data.totalGLDT,
        };
      }
    } catch (err) {
      console.error("Failed to load analytics:", err);
    } finally {
      isLoading = false;
    }
  }

  onMount(async () => {
    await fetchStats();
    pollInterval = setInterval(fetchStats, 30000);

    potRotationInterval = setInterval(() => {
      if (currentPotToken === "icp") currentPotToken = "ckbtc";
      else if (currentPotToken === "ckbtc") currentPotToken = "gldt";
      else currentPotToken = "icp";
    }, 3000);
  });

  onDestroy(() => {
    if (pollInterval) clearInterval(pollInterval);
    if (potRotationInterval) clearInterval(potRotationInterval);
  });
</script>

<div class="relative min-h-screen bg-[#1a0033] overflow-x-hidden">
  <div class="absolute inset-0">
    <FlickeringGrid
      class="z-0 absolute inset-0 size-full"
      squareSize={4}
      gridGap={6}
      color="#C9B5E8"
      maxOpacity={0.3}
      flickerChance={0.1}
    />
  </div>

  <div class="relative z-10 py-8 md:py-12 px-4">
    <section class="relative mx-auto w-full max-w-[1200px]">
      <div class="mb-12">
        <div class="mx-auto max-w-3xl text-center">
          <h1 class="text-4xl md:text-6xl font-black uppercase mb-2 arcade-text-shadow">
            <span class="text-[#F4E04D]">OWN YOUR</span>
            <span class="text-[#C9B5E8]">TABLA</span>
          </h1>
          <h2 class="text-3xl md:text-5xl font-black text-[#F4E04D] uppercase mb-6 arcade-text-shadow">
            NFT LOTERÍA
          </h2>
          <p class="text-base md:text-lg font-bold text-white mb-10 max-w-2xl mx-auto" style="text-shadow: 2px 2px 4px #000;">
            Host games, join friends, and win on-chain prizes — on the Internet Computer.
          </p>
          <div class="flex items-center justify-center gap-4 flex-wrap">
            <button onclick={dashboard} class="arcade-button px-8 py-4 text-sm md:text-base">
              LAUNCH APP
            </button>
            <button
              onclick={playNow}
              class="bg-[#C9B5E8] text-[#1a0033] px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] active:translate-x-[2px] active:translate-y-[2px] transition-all text-sm md:text-base shadow-[4px_4px_0px_rgba(0,0,0,1)] active:shadow-[2px_2px_0px_rgba(0,0,0,1)]"
            >
              JOIN A GAME
            </button>
            <button
              onclick={hostGame}
              class="bg-white text-[#1a0033] px-6 py-4 font-black uppercase border-4 border-black hover:bg-[#f0f0f0] active:translate-x-[2px] active:translate-y-[2px] transition-all text-sm md:text-base shadow-[4px_4px_0px_rgba(0,0,0,1)] active:shadow-[2px_2px_0px_rgba(0,0,0,1)]"
            >
              HOST A GAME
            </button>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
        <div class="arcade-panel p-6 hover:shadow-[12px_12px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all">
          <div class="mb-4 flex items-center gap-2">
            <span class="arcade-badge">Cards</span>
            <span class="arcade-badge bg-white">1–54</span>
          </div>
          <h3 class="text-2xl font-black text-[#F4E04D] uppercase mb-3 arcade-text-shadow">
            MEET THE DECK
          </h3>
          <p class="mb-5 text-sm font-bold text-white">54 iconic characters.</p>
          <Marquee
            items={cardImages}
            windowSize={12}
            durationMs={18000}
            height={190}
            gap={12}
          />
        </div>

        <div class="arcade-panel p-6 hover:shadow-[12px_12px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all">
          <div class="mb-4 flex items-center gap-2">
            <span class="arcade-badge bg-[#C9B5E8]">Tablas</span>
            <span class="arcade-badge bg-white">363</span>
          </div>
          <h3 class="text-2xl font-black text-[#C9B5E8] uppercase mb-3 arcade-text-shadow">
            BINGO!
          </h3>
          <p class="mb-5 text-sm font-bold text-white">
            Your tabla. Your game. Your rules.
          </p>
          <Marquee
            items={tablaImages}
            windowSize={16}
            durationMs={24000}
            height={190}
            gap={10}
            reverse
          />
          <p class="text-center mt-3 text-[10px] text-white font-bold opacity-70">
            * Tablas can be burnt
          </p>
        </div>

        <div class="arcade-panel p-6 hover:shadow-[12px_12px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all">
          <div class="mb-4">
            <span class="arcade-badge">Live Data</span>
          </div>

          <h3 class="mb-2 text-lg font-black text-white uppercase arcade-text-shadow">
            JOIN THE FUN!
          </h3>
          <p class="mb-5 text-sm font-bold text-white">
            Select tabla. Draw cards. Bingo!
          </p>
          <p class="mb-2 text-[10px] font-bold text-[#C9B5E8] uppercase tracking-wider opacity-80 text-center">
            24H Platform Volume
          </p>

          <div class="grid grid-cols-3 gap-2 mb-4">
            <div class="arcade-panel-sm border-[#F4E04D] p-3 rounded text-center">
              <img src="/tokens/ICP.svg" alt="ICP" class="w-8 h-8 mx-auto mb-2" />
              <div class="text-base font-black text-[#F4E04D]">
                {#if isLoading}
                  ...
                {:else}
                  <NumberTicker value={icpValue} decimalPlaces={0} duration={1500} />
                {/if}
              </div>
              <div class="text-[9px] font-bold text-[#C9B5E8] uppercase mt-1">ICP</div>
              <div class="text-[8px] font-bold mt-1 {volumeChange.icp > 0 ? 'text-green-400' : volumeChange.icp < 0 ? 'text-red-400' : 'text-[#C9B5E8]'}">
                {#if volumeChange.icp > 0}
                  ↑ {volumeChange.icp.toFixed(2)}%
                {:else if volumeChange.icp < 0}
                  ↓ {Math.abs(volumeChange.icp).toFixed(2)}%
                {:else}
                  — 0.00%
                {/if}
              </div>
            </div>

            <div class="arcade-panel-sm border-[#FF9900] p-3 rounded text-center">
              <img src="/tokens/ck-BTC.svg" alt="ckBTC" class="w-8 h-8 mx-auto mb-2" />
              <div class="text-sm font-black text-[#FF9900] min-h-[24px] flex items-center justify-center">
                {#if isLoading}
                  ...
                {:else}
                  <NumberTicker value={ckbtcValue} decimalPlaces={6} duration={1500} />
                {/if}
              </div>
              <div class="text-[9px] font-bold text-[#C9B5E8] uppercase mt-1">ckBTC</div>
              <div class="text-[8px] font-bold mt-1 {volumeChange.ckbtc > 0 ? 'text-green-400' : volumeChange.ckbtc < 0 ? 'text-red-400' : 'text-[#C9B5E8]'}">
                {#if volumeChange.ckbtc > 0}
                  ↑ {volumeChange.ckbtc.toFixed(2)}%
                {:else if volumeChange.ckbtc < 0}
                  ↓ {Math.abs(volumeChange.ckbtc).toFixed(2)}%
                {:else}
                  — 0.00%
                {/if}
              </div>
            </div>

            <div class="arcade-panel-sm border-[#FFD700] p-3 rounded text-center">
              <img src="/tokens/gldt.png" alt="GLDT" class="w-8 h-8 mx-auto mb-2" />
              <div class="text-base font-black text-[#FFD700]">
                {#if isLoading}
                  ...
                {:else}
                  <NumberTicker value={gldtValue} decimalPlaces={0} duration={1500} />
                {/if}
              </div>
              <div class="text-[9px] font-bold text-[#C9B5E8] uppercase mt-1">GLDT</div>
              <div class="text-[8px] font-bold mt-1 {volumeChange.gldt > 0 ? 'text-green-400' : volumeChange.gldt < 0 ? 'text-red-400' : 'text-[#C9B5E8]'}">
                {#if volumeChange.gldt > 0}
                  ↑ {volumeChange.gldt.toFixed(2)}%
                {:else if volumeChange.gldt < 0}
                  ↓ {Math.abs(volumeChange.gldt).toFixed(2)}%
                {:else}
                  — 0.00%
                {/if}
              </div>
            </div>
          </div>

          <div class="bg-gradient-to-r from-[#F4E04D] to-[#FFD700] border-2 border-black p-3 mb-4 text-center shadow-[3px_3px_0px_rgba(0,0,0,1)]">
            <div class="text-[10px] font-bold text-[#1a0033] uppercase mb-1">
              Biggest Prize Pool
            </div>
            <div class="text-xl font-black text-[#1a0033]">
              {#if isLoading}
                ...
              {:else if currentPotToken === "icp"}
                <NumberTicker value={currentPotValue} decimalPlaces={0} duration={1000} /> ICP
              {:else if currentPotToken === "ckbtc"}
                <NumberTicker value={currentPotValue} decimalPlaces={6} duration={1000} /> ckBTC
              {:else}
                <NumberTicker value={currentPotValue} decimalPlaces={0} duration={1000} /> GLDT
              {/if}
            </div>
          </div>

          <div class="flex gap-2">
            <button
              onclick={buyTabla}
              class="flex-1 bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-2 text-xs font-bold uppercase hover:scale-105 active:scale-100 transition-all shadow-[2px_2px_0px_rgba(0,0,0,1)]"
            >
              BUY TABLA
            </button>
            <button
              onclick={dashboard}
              class="flex-1 bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-2 text-xs font-bold uppercase hover:scale-105 active:scale-100 transition-all shadow-[2px_2px_0px_rgba(0,0,0,1)]"
            >
              DASHBOARD
            </button>
          </div>
        </div>
      </div>
    </section>

    <footer class="mx-auto mt-12 max-w-[1200px] text-center">
      <div class="arcade-panel px-8 py-5 inline-block font-bold text-sm uppercase text-[#F4E04D]" style="text-shadow: 2px 2px 0px #000;">
        © {new Date().getFullYear()} NFT LOTERÍA — BUILT ON THE INTERNET COMPUTER
      </div>
    </footer>
  </div>
</div>