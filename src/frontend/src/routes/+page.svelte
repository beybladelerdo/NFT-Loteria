<script lang="ts">
  import { goto } from "$app/navigation";
  import Marquee from "$lib/components/landing/SlideCarousel.svelte";
  import { cardImages, tablaImages } from "$lib/data/gallery";

  const playNow = () => goto("/join-game");
  const hostGame = () => goto("/host-game");
  const dashboard = () => goto("/dashboard");
</script>

<div class="relative min-h-screen bg-[#ED1E79] overflow-x-hidden font-amiga">
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
  <div
    class="absolute top-1/2 right-1/3 w-6 h-6 bg-white border-2 border-black opacity-30"
  ></div>

  <div class="relative z-10 py-8 md:py-12 px-4">
    <section class="relative mx-auto w-full max-w-[1200px]">
      <!-- Main Hero Window -->
      <div
        class="bg-gradient-to-b from-[#29ABE2] to-[#1e88c7] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)] mb-6"
      >
        <div
          class="bg-[#29ABE2] p-2 border-b-2 border-black flex items-center justify-between"
        >
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
            NFT_LOTERIA.EXE
          </div>
          <div class="w-12"></div>
        </div>

        <div class="bg-white p-8 md:p-12 border-4 border-black">
          <!-- HERO -->
          <div class="mx-auto max-w-3xl text-center">
            <h1
              class="text-4xl md:text-6xl font-black text-black uppercase mb-2"
              style="text-shadow: 4px 4px 0px #29ABE2, 8px 8px 0px #522785;"
            >
              OWN YOUR TABLA
            </h1>
            <h2
              class="text-3xl md:text-5xl font-black text-black uppercase mb-4"
              style="text-shadow: 3px 3px 0px #FBB03B;"
            >
              NFT LOTERÍA
            </h2>

            <p
              class="text-base md:text-lg font-bold text-black mb-8 max-w-2xl mx-auto"
            >
              Host games, join friends, and win on-chain prizes — on the
              Internet Computer.
            </p>

            <div class="flex items-center justify-center gap-4 flex-wrap">
              <button
                onclick={dashboard}
                class="bg-[#522785] text-white px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#6d3399] transition-all text-sm md:text-base"
                style="box-shadow: 4px 4px 0px #000;"
              >
                LAUNCH APP &gt;&gt;
              </button>
              <button
                onclick={playNow}
                class="bg-[#FBB03B] text-black px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#e09a2f] transition-all text-sm md:text-base"
                style="box-shadow: 4px 4px 0px #000;"
              >
                JOIN A GAME!
              </button>
              <button
                onclick={hostGame}
                class="bg-white text-black px-6 py-4 font-black uppercase border-4 border-black hover:bg-[#29ABE2] transition-all text-sm md:text-base"
                style="box-shadow: 4px 4px 0px #000;"
              >
                HOST A GAME
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- TILES -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <!-- CARDS Window -->
        <div
          class="bg-gradient-to-b from-[#FBB03B] to-[#e09a2f] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
        >
          <div
            class="bg-[#FBB03B] p-2 border-b-2 border-black flex items-center justify-between"
          >
            <div class="flex items-center gap-2">
              <div class="w-4 h-4 bg-white border-2 border-black"></div>
              <span class="text-black font-black text-xs uppercase"
                >CARDS.BMP</span
              >
            </div>
            <div class="flex gap-1">
              <div class="w-4 h-4 bg-[#29ABE2] border border-black"></div>
              <div class="w-4 h-4 bg-red-500 border border-black"></div>
            </div>
          </div>
          <div class="bg-white p-5 border-4 border-black">
            <div class="mb-2 flex items-center gap-2">
              <span
                class="bg-black text-[#29ABE2] border-2 border-[#29ABE2] px-2 py-1 text-[10px] font-bold uppercase"
              >
                Cards
              </span>
              <span
                class="bg-[#FBB03B] text-black border-2 border-black px-2 py-1 text-[10px] font-bold"
              >
                1–54
              </span>
            </div>
            <h3 class="text-xl font-black text-black uppercase mb-2">
              MEET THE DECK
            </h3>
            <p class="mb-3 text-sm font-bold text-black">
              54 iconic characters.
            </p>

            <Marquee
              items={cardImages}
              windowSize={12}
              durationMs={18000}
              height={190}
              gap={12}
            />
          </div>
        </div>

        <!-- TABLAS Window -->
        <div
          class="bg-gradient-to-b from-[#29ABE2] to-[#1e88c7] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
        >
          <div
            class="bg-[#29ABE2] p-2 border-b-2 border-black flex items-center justify-between"
          >
            <div class="flex items-center gap-2">
              <div class="w-4 h-4 bg-white border-2 border-black"></div>
              <span class="text-black font-black text-xs uppercase"
                >TABLAS.BMP</span
              >
            </div>
            <div class="flex gap-1">
              <div class="w-4 h-4 bg-[#FBB03B] border border-black"></div>
              <div class="w-4 h-4 bg-red-500 border border-black"></div>
            </div>
          </div>
          <div class="bg-white p-5 border-4 border-black">
            <div class="mb-2 flex items-center gap-2">
              <span
                class="bg-black text-[#FBB03B] border-2 border-[#FBB03B] px-2 py-1 text-[10px] font-bold uppercase"
              >
                Tablas
              </span>
              <span
                class="bg-[#29ABE2] text-black border-2 border-black px-2 py-1 text-[10px] font-bold"
              >
                1–1026
              </span>
            </div>
            <h3 class="text-xl font-black text-black uppercase mb-2">BINGO!</h3>
            <p class="mb-3 text-sm font-bold text-black">
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
        </div>

        <!-- STATS Window -->
        <div
          class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
        >
          <div
            class="bg-[#522785] p-2 border-b-2 border-black flex items-center justify-between"
          >
            <div class="flex items-center gap-2">
              <div class="w-4 h-4 bg-white border-2 border-black"></div>
              <span class="text-white font-black text-xs uppercase"
                >STATS.DAT</span
              >
            </div>
            <div class="flex gap-1">
              <div class="w-4 h-4 bg-[#FBB03B] border border-black"></div>
              <div class="w-4 h-4 bg-red-500 border border-black"></div>
            </div>
          </div>
          <div class="bg-white p-4 border-4 border-black">
            <div class="mb-2">
              <span
                class="bg-black text-[#29ABE2] border-2 border-[#29ABE2] px-2 py-1 text-[10px] font-bold uppercase"
              >
                Live Data Snapshot
              </span>
            </div>

            <h3 class="mb-1 text-lg font-black text-black uppercase">
              WHAT ARE YOU WAITING FOR?
            </h3>
            <p class="mb-3 text-xs font-bold text-black">
              Join the fun! Join. Draw. Bingo!
            </p>

            <div class="grid grid-cols-2 gap-3 text-center">
              <div class="bg-[#FBB03B] border-2 border-black p-2.5">
                <div class="text-xl font-black leading-none text-black">12</div>
                <div
                  class="mt-1 text-[10px] uppercase tracking-wide font-bold text-black"
                >
                  Live Games
                </div>
              </div>
              <div class="bg-[#29ABE2] border-2 border-black p-2.5">
                <div class="text-xl font-black leading-none text-black">
                  4,321
                </div>
                <div
                  class="mt-1 text-[10px] uppercase tracking-wide font-bold text-black"
                >
                  Total Games
                </div>
              </div>
              <div class="bg-[#522785] border-2 border-black p-2.5">
                <div class="text-xl font-black leading-none text-white">
                  363
                </div>
                <div
                  class="mt-1 text-[10px] uppercase tracking-wide font-bold text-white"
                >
                  Tablas
                </div>
              </div>
              <div class="bg-white border-2 border-black p-2.5">
                <div class="text-lg font-black leading-none text-black">
                  @jeff
                </div>
                <div
                  class="mt-1 text-[10px] uppercase tracking-wide font-bold text-black"
                >
                  Top Player
                </div>
              </div>
            </div>

            <div class="mt-3 flex flex-wrap gap-2">
              <button
                onclick={playNow}
                class="flex-1 bg-black text-[#29ABE2] border-2 border-[#29ABE2] px-3 py-2 text-xs font-bold uppercase"
                style="box-shadow: 2px 2px 0px #000;"
              >
                I'M IN!
              </button>
              <button
                onclick={dashboard}
                class="flex-1 bg-[#FBB03B] text-black border-2 border-black px-3 py-2 text-xs font-bold uppercase"
                style="box-shadow: 2px 2px 0px #000;"
              >
                DASHBOARD
              </button>
            </div>

            <p class="text-center mt-2 text-[10px] text-black font-bold">
              * Tablas can be burnt
            </p>
          </div>
        </div>
      </div>
    </section>

    <footer class="mx-auto mt-8 max-w-[1200px] text-center">
      <div
        class="bg-black text-[#29ABE2] border-4 border-[#29ABE2] px-6 py-4 inline-block font-bold text-sm"
        style="box-shadow: 4px 4px 0px #FBB03B;"
      >
        © {new Date().getFullYear()} NFT LOTERÍA — BUILT ON THE INTERNET COMPUTER
      </div>
    </footer>
  </div>
</div>
