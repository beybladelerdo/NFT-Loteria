<script lang="ts">
  import { goto } from "$app/navigation";
  import Marquee from "$lib/components/landing/SlideCarousel.svelte";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import { cardImages, tablaImages } from "$lib/data/gallery";

  const playNow = () => goto("/join-game");
  const hostGame = () => goto("/host-game");
  const dashboard = () => goto("/dashboard");
</script>

<div class="relative min-h-screen bg-[#1a0033] overflow-x-hidden font-amiga">
  <!-- Flickering Grid Background -->
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
      <!-- HERO SECTION -->
      <div class="mb-12">
        <div class="mx-auto max-w-3xl text-center">
          <h1
            class="text-4xl md:text-6xl font-black uppercase mb-2"
            style="text-shadow: 4px 4px 0px #000, -2px -2px 0px #000, 2px -2px 0px #000, -2px 2px 0px #000;"
          >
            <span class="text-[#F4E04D]">OWN YOUR</span>
            <span class="text-[#C9B5E8]">TABLA</span>
          </h1>
          <h2
            class="text-3xl md:text-5xl font-black text-[#F4E04D] uppercase mb-6"
            style="text-shadow: 4px 4px 0px #000, -2px -2px 0px #000, 2px -2px 0px #000, -2px 2px 0px #000;"
          >
            NFT LOTERÍA
          </h2>
          <p
            class="text-base md:text-lg font-bold text-white mb-10 max-w-2xl mx-auto"
            style="text-shadow: 2px 2px 4px #000;"
          >
            Host games, join friends, and win on-chain prizes — on the Internet
            Computer.
          </p>
          <div class="flex items-center justify-center gap-4 flex-wrap">
            <button
              onclick={dashboard}
              class="bg-[#F4E04D] text-[#1a0033] px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#fff27d] hover:scale-105 transition-all text-sm md:text-base shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
            >
              LAUNCH APP
            </button>
            <button
              onclick={playNow}
              class="bg-[#C9B5E8] text-[#1a0033] px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all text-sm md:text-base shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
            >
              JOIN A GAME
            </button>
            <button
              onclick={hostGame}
              class="bg-white text-[#1a0033] px-6 py-4 font-black uppercase border-4 border-black hover:bg-[#f0f0f0] hover:scale-105 transition-all text-sm md:text-base shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
            >
              HOST A GAME
            </button>
          </div>
        </div>
      </div>

      <!-- CONTENT TILES -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
        <!-- CARDS -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-4 flex items-center gap-2">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Cards
            </span>
            <span
              class="bg-white text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              1–54
            </span>
          </div>
          <h3
            class="text-2xl font-black text-[#F4E04D] uppercase mb-3"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
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

        <!-- TABLAS -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-4 flex items-center gap-2">
            <span
              class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Tablas
            </span>
            <span
              class="bg-white text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              363
            </span>
          </div>
          <h3
            class="text-2xl font-black text-[#C9B5E8] uppercase mb-3"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
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
        </div>

        <!-- STATS -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] hover:shadow-[12px_12px_0px_0px_rgba(0,0,0,0.8)] hover:-translate-y-1 transition-all"
        >
          <div class="mb-4">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Live Data
            </span>
          </div>

          <h3
            class="mb-3 text-xl font-black text-white uppercase"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
            WHAT ARE YOU WAITING FOR?
          </h3>
          <p class="mb-5 text-sm font-bold text-[#C9B5E8]">
            Join the fun! Join. Draw. Bingo!
          </p>

          <div class="grid grid-cols-2 gap-3 text-center mb-4">
            <div
              class="bg-[#F4E04D] border-2 border-black p-3 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-2xl font-black leading-none text-[#1a0033]">
                12
              </div>
              <div
                class="mt-1 text-[10px] uppercase tracking-wide font-bold text-[#1a0033]"
              >
                Live Games
              </div>
            </div>
            <div
              class="bg-[#C9B5E8] border-2 border-black p-3 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-2xl font-black leading-none text-[#1a0033]">
                4,321
              </div>
              <div
                class="mt-1 text-[10px] uppercase tracking-wide font-bold text-[#1a0033]"
              >
                Total Games
              </div>
            </div>
            <div
              class="bg-white border-2 border-black p-3 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-2xl font-black leading-none text-[#1a0033]">
                363
              </div>
              <div
                class="mt-1 text-[10px] uppercase tracking-wide font-bold text-[#1a0033]"
              >
                Tablas
              </div>
            </div>
            <div
              class="bg-gradient-to-b from-[#3d1d63] to-[#522785] border-2 border-black p-3 shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-xl font-black leading-none text-[#F4E04D]">
                @jeff
              </div>
              <div
                class="mt-1 text-[10px] uppercase tracking-wide font-bold text-white"
              >
                Top Player
              </div>
            </div>
          </div>

          <div class="flex flex-wrap gap-2 mb-3">
            <button
              onclick={playNow}
              class="flex-1 bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-2 text-xs font-bold uppercase hover:scale-105 transition-all shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              I'M IN!
            </button>
            <button
              onclick={dashboard}
              class="flex-1 bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-2 text-xs font-bold uppercase hover:scale-105 transition-all shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              DASHBOARD
            </button>
          </div>

          <p class="text-center text-[10px] text-white font-bold opacity-70">
            * Tablas can be burnt
          </p>
        </div>
      </div>
    </section>

    <!-- FOOTER -->
    <footer class="mx-auto mt-12 max-w-[1200px] text-center">
      <div
        class="bg-gradient-to-r from-[#522785] to-[#3d1d63] text-[#F4E04D] border-4 border-black px-8 py-5 inline-block font-bold text-sm uppercase shadow-[6px_6px_0px_0px_rgba(0,0,0,1)]"
        style="text-shadow: 2px 2px 0px #000;"
      >
        © {new Date().getFullYear()} NFT LOTERÍA — BUILT ON THE INTERNET COMPUTER
      </div>
    </footer>
  </div>
</div>
