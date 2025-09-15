<script lang="ts">
  import { goto } from "$app/navigation";
  import Marquee from "$lib/components/landing/SlideCarousel.svelte";
  import { cardImages, tablaImages } from "$lib/data/gallery";
  import BackgroundSvg from "$lib/components/landing/BackgroundSvg.svelte";

  const playNow = () => goto("/join-game");
  const hostGame = () => goto("/host-game");
</script>

<div class="relative min-h-screen bg-[#0b0b0b] overflow-x-hidden">
  <div class="fixed inset-0 z-0">
    <BackgroundSvg duration={15} />
  </div>
  <div class="relative z-10 py-8 md:py-12">
    <section
      class="relative mx-auto w-full max-w-[1200px] overflow-hidden rounded-[28px] bg-[#0f0f0f]/95 backdrop-blur-sm shadow-xl ring-1 ring-white/10"
    >
      <!-- bits -->
      <div class="pointer-events-none absolute inset-0">
        <div
          class="absolute left-12 top-16 h-3 w-3 rotate-12 rounded-sm bg-white/20"
        ></div>
        <div
          class="absolute right-24 top-24 h-6 w-6 -rotate-12 rounded-full bg-[#d9ff5a]/60"
        ></div>
        <div
          class="absolute right-36 top-64 h-4 w-4 rotate-[28deg] rounded-sm bg-white/10"
        ></div>
        <div
          class="absolute left-32 top-64 h-6 w-6 rounded-[14px] border border-white/15"
        ></div>
      </div>
      <div class="relative px-6 pb-10 pt-12 md:px-12 md:pb-14 md:pt-16">
        <!-- HERO -->
        <div class="mx-auto max-w-3xl text-center">
          <div class="relative inline-block">
            <h1 class="leading-tight text-white">
              <span
                class="font-freigeist block text-4xl font-extrabold tracking-tight md:text-6xl"
                >Own your Tabla.</span
              >
              <span
                class="font-freigeist block text-4xl font-extrabold tracking-tight md:text-6xl"
                >NFT Lotería</span
              >
            </h1>
          </div>

          <p
            class="font-freigeist mx-auto mt-4 max-w-2xl text-base text-white/70 md:mt-5 md:text-lg"
          >
            Host games, join friends, and win on-chain prizes — on the Internet
            Computer.
          </p>

          <div
            class="font-freigeist mt-7 flex items-center justify-center gap-4"
          >
            <button
              class="inline-flex items-center justify-center rounded-full bg-[#d9ff5a] px-7 py-3 text-sm font-bold text-black shadow-[0_8px_0_0_rgba(0,0,0,0.35)] ring-1 ring-black/20 transition hover:translate-y-[-1px]"
              on:click={playNow}
            >
              Join a Game!
            </button>
            <button
              class="font-freigeist inline-flex items-center justify-center rounded-full bg-white/10 px-5 py-3 text-sm font-semibold text-white shadow-sm ring-1 ring-white/15 transition hover:bg-white/15"
              on:click={hostGame}
            >
              Host a Game
            </button>
          </div>
        </div>
        <!-- /HERO -->

        <!-- TILES -->
        <div
          class="mx-auto mt-10 grid w-full max-w-5xl grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3"
        >
          <!-- CARDS (dark tile) -->
          <div
            class="w-full overflow-hidden rounded-2xl bg-[#0f0f0f] p-5 shadow-xl ring-1 ring-white/10"
          >
            <div class="mb-2 flex items-center gap-2">
              <span
                class="font-freigeist inline-flex items-center rounded-full border border-white/20 bg-white/10 px-2 py-[2px] text-[10px] font-medium text-white"
                >Cards</span
              >
              <span
                class="font-freigeist inline-flex items-center rounded-full border border-white/15 bg-[#111]/70 px-2 py-[2px] text-[10px] font-medium text-white/80"
                >1–54</span
              >
            </div>
            <h3 class="font-freigeist text-xl font-black text-white">
              Meet the Deck
            </h3>
            <p class="font-freigeist mb-3 text-sm text-white/70">
              54 iconic characters.
            </p>

            <Marquee
              items={cardImages}
              windowSize={12}
              durationMs={18000}
              height={190}
              gap={12}
              dark
            />
          </div>

          <!-- TABLAS (dark tile) -->
          <div
            class="w-full overflow-hidden rounded-2xl bg-[#0f0f0f] p-5 shadow-xl ring-1 ring-white/10"
          >
            <div class="mb-2 flex items-center gap-2">
              <span
                class="font-freigeist inline-flex items-center rounded-full border border-white/20 bg-white/10 px-2 py-[2px] text-[10px] font-medium text-white"
                >Tablas</span
              >
              <span
                class="font-freigeist inline-flex items-center rounded-full border border-white/15 bg-[#111]/70 px-2 py-[2px] text-[10px] font-medium text-white/80"
                >1–1026</span
              >
            </div>
            <h3 class="font-freigeist text-xl font-black text-white">Bingo!</h3>
            <p class="font-freigeist mb-3 text-sm text-white/70">
              It’s Free Real Estate. Your tabla. Your game. Your rules.
            </p>

            <Marquee
              items={tablaImages}
              windowSize={16}
              durationMs={24000}
              height={190}
              gap={10}
              reverse
              dark
            />
          </div>

          <!-- STATS -->
          <div
            class="w-full overflow-hidden rounded-2xl bg-[#d9ff5a] p-4 text-black shadow-lg"
          >
            <div class="mb-1 flex items-center justify-between">
              <span
                class="font-freigeist inline-flex items-center rounded-full border border-black/20 bg-white/70 px-2 py-[1px] text-[10px] font-medium"
              >
                Live Data Snapshot
              </span>
            </div>

            <h3 class="font-freigeist mb-1 text-lg font-black">
              What are you waiting for?
            </h3>
            <p class="font-freigeist mb-3 text-xs text-black/80">
              Join the fun! Join. Draw. Bingo!
            </p>

            <div class="grid grid-cols-2 gap-3 text-center">
              <div class="rounded-xl bg-white/60 p-2.5 ring-1 ring-black/10">
                <div class="font-freigeist text-xl font-extrabold leading-none">
                  12
                </div>
                <div
                  class="font-freigeist mt-1 text-[10px] uppercase tracking-wide text-black/70"
                >
                  Live Games
                </div>
              </div>
              <div class="rounded-xl bg-white/60 p-2.5 ring-1 ring-black/10">
                <div class="font-freigeist text-xl font-extrabold leading-none">
                  4,321
                </div>
                <div
                  class="font-freigeist mt-1 text-[10px] uppercase tracking-wide text-black/70"
                >
                  Total Games Hosted
                </div>
              </div>
              <div class="rounded-xl bg-white/60 p-2.5 ring-1 ring-black/10">
                <div class="font-freigeist text-xl font-extrabold leading-none">
                  363
                </div>
                <div
                  class="font-freigeist mt-1 text-[10px] uppercase tracking-wide text-black/70"
                >
                  Tablas available*
                </div>
              </div>
              <div class="rounded-xl bg-white/60 p-2.5 ring-1 ring-black/10">
                <div class="font-freigeist text-xl font-extrabold leading-none">
                  @jeff(47)
                </div>
                <div
                  class="font-freigeist mt-1 text-[10px] uppercase tracking-wide text-black/70"
                >
                  Top Tag(Most Bingos)
                </div>
              </div>
            </div>

            <div
              class="col-span-2 flex items-center justify-center gap-3 mt-3 flex flex-wrap gap-2"
            >
              <button
                class="font-freigeist inline-flex items-center justify-center rounded-full bg-black px-3 py-2 text-xs font-semibold text-white shadow-sm"
              >
                I'm in !
              </button>
              <button
                class="font-freigeist inline-flex items-center justify-center rounded-full border border-black/20 bg-white/70 px-3 py-2 text-xs font-medium text-black hover:bg-white"
              >
                Dashboard
              </button>
            </div>

            <p
              class="col-span-2 text-center justify-self-center font-freigeist mt-2 text-[10px] text-black/60"
            >
              * Tablas can be burnt and removed from circulation.
            </p>
          </div>

          <!-- /TILES -->
        </div>
      </div>
    </section>

    <footer
      class="font-freigeist mx-auto mt-6 w-[min(1200px,92vw)] text-center text-sm text-white/60"
    >
      © {new Date().getFullYear()} NFT Lotería — Built on the Internet Computer.
    </footer>
  </div>
</div>
