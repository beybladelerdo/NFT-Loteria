<script lang="ts">
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { tokenStore } from "$lib/stores/token-store";
  import { TokenService } from "$lib/services/token-service";
  import { addToast } from "$lib/stores/toasts-store";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import InvitePlayers from "$lib/components/game/invite-player.svelte";
  import type { CreateGameParams } from "$lib/services/game-service";
  import { formatSmart } from "$lib/utils/game-helper";

  const tokenService = new TokenService();
  const maxPlayers = 100;

  let currentStep = $state<1 | 2 | 3>(1);
  let isLoading = $state(false);
  let isCreating = $state(false);
  let gameIdCreated = $state<string | null>(null);

  const MAX_DECIMALS = 8;

  const DECIMALS: Record<"ICP" | "ckBTC" | "GLDT", number> = {
    ICP: 8,
    ckBTC: 8,
    GLDT: 8,
  };

  const MIN_BY_TOKEN: Record<"ICP" | "ckBTC" | "GLDT", bigint> = {
    ICP: 5_000_000n,
    ckBTC: 1_000n,
    GLDT: 100_000_000n,
  };

  function POW10(n: number) {
    let x = 1n;
    for (let i = 0; i < n; i++) x *= 10n;
    return x;
  }

  function tokenDecimals() {
    return DECIMALS[tokenType];
  }

  type ParseResult = { ok: true; units: bigint } | { ok: false; error: string };

  function parseToUnits(input: string, decimals: number): ParseResult {
    const t = input.trim();
    if (!/^\d*(\.\d*)?$/.test(t) || t === "" || t === ".") {
      return { ok: false, error: "Enter a valid amount" };
    }
    let [intPart = "0", fracPart = ""] = t.split(".");
    if (fracPart.length > decimals) {
      return { ok: false, error: `Max ${decimals} decimal places` };
    }
    const fracPadded = (fracPart + "0".repeat(decimals)).slice(0, decimals);
    try {
      const whole = BigInt(intPart || "0") * POW10(decimals);
      const frac = BigInt(fracPadded || "0");
      return { ok: true, units: whole + frac };
    } catch {
      return { ok: false, error: "Number too large" };
    }
  }

  function onEntryFeeInput(e: Event) {
    const el = e.target as HTMLInputElement;
    const v = el.value;
    const m = v.match(/^(\d*)(?:\.(\d*))?$/);
    if (!m) return;
    const [, i = "", f = ""] = m;
    el.value = f.length > MAX_DECIMALS ? `${i}.${f.slice(0, MAX_DECIMALS)}` : v;
    entryFeeInput = el.value;
  }

  let gameName = $state("");
  let gameMode = $state<"Line" | "Blackout">("Line");
  let tokenType = $state<"ICP" | "ckBTC" | "GLDT">("ICP");
  let entryFeeInput = $state("");
  let hostFeePercent = $state(5);

  let balances = $derived({
    ICP: $tokenStore.balances.find((b) => b.symbol === "ICP")
      ? parseFloat(
          tokenService.formatBalance(
            $tokenStore.balances.find((b) => b.symbol === "ICP")!.balance,
            8,
          ),
        )
      : 0,
    ckBTC: $tokenStore.balances.find((b) => b.symbol === "ckBTC")
      ? parseFloat(
          tokenService.formatBalance(
            $tokenStore.balances.find((b) => b.symbol === "ckBTC")!.balance,
            8,
          ),
        )
      : 0,
    GLDT: $tokenStore.balances.find((b) => b.symbol === "GLDT")
      ? parseFloat(
          tokenService.formatBalance(
            $tokenStore.balances.find((b) => b.symbol === "GLDT")!.balance,
            8,
          ),
        )
      : 0,
  });

  let errors = $state({
    gameName: "",
    entryFee: "",
  });

  onMount(async () => {
    if (!$authStore.isAuthenticated) {
      goto("/");
      return;
    }
    isLoading = true;
    await tokenStore.fetchBalances();
    isLoading = false;
  });

  async function refreshBalances() {
    isLoading = true;
    await tokenStore.refreshBalances();
    isLoading = false;
    addToast({
      message: "Balances refreshed!",
      type: "success",
      duration: 2000,
    });
  }

  function validateStep1(): boolean {
    errors.gameName = "";
    if (!gameName.trim()) {
      errors.gameName = "Game name is required";
      return false;
    }
    if (gameName.trim().length < 3) {
      errors.gameName = "Game name must be at least 3 characters";
      return false;
    }
    if (gameName.trim().length > 50) {
      errors.gameName = "Game name must be less than 50 characters";
      return false;
    }
    return true;
  }

  function validateStep2(): boolean {
    errors.entryFee = "";
    const v = entryFeeInput.trim();
    if (v === "") {
      errors.entryFee = "Entry fee is required";
      return false;
    }
    const ok = /^\d*(?:\.\d{0,8})?$/.test(v) && v !== "." && v !== "";
    if (!ok) {
      errors.entryFee = "Use a number with up to 8 decimals";
      return false;
    }
    if (Number(v) <= 0) {
      errors.entryFee = "Amount must be greater than 0";
      return false;
    }
    const parsed = parseToUnits(v, tokenDecimals());
    if (!parsed.ok) {
      errors.entryFee = parsed.error;
      return false;
    }
    const min = MIN_BY_TOKEN[tokenType];
    if (parsed.units < min) {
      errors.entryFee =
        tokenType === "ICP"
          ? "Minimum is 0.05 ICP"
          : tokenType === "ckBTC"
            ? "Minimum is 0.00001000 ckBTC"
            : "Minimum is 1.00000000 GLDT";
      return false;
    }
    return true;
  }

  function nextStep() {
    if (currentStep === 1 && !validateStep1()) {
      addToast({
        message: errors.gameName || "Please fix validation errors",
        type: "error",
        duration: 3000,
      });
      return;
    }
    if (currentStep === 2 && !validateStep2()) {
      addToast({
        message: errors.entryFee || "Please fix validation errors",
        type: "error",
        duration: 3000,
      });
      return;
    }
    if (currentStep < 3) {
      currentStep = (currentStep + 1) as 1 | 2 | 3;
    }
  }

  function prevStep() {
    if (currentStep > 1) {
      currentStep = (currentStep - 1) as 1 | 2 | 3;
    }
  }

  function readableEntryFee(): number {
    if (entryFeeInput.trim() === "") return 0;
    return Number(entryFeeInput);
  }

  function calculatePrizePool(): number {
    const totalEntry = readableEntryFee() * maxPlayers;
    const hostFee = (totalEntry * hostFeePercent) / 100;
    return totalEntry - hostFee;
  }

  async function createGame() {
    if (!validateStep1() || !validateStep2()) {
      addToast({
        message:
          errors.gameName ||
          errors.entryFee ||
          "Please fix all validation errors",
        type: "error",
        duration: 3000,
      });
      return;
    }
    const parsed = parseToUnits(entryFeeInput, tokenDecimals());
    if (!parsed.ok) {
      addToast({
        message: parsed.error,
        type: "error",
        duration: 3000,
      });
      return;
    }
    const min = MIN_BY_TOKEN[tokenType];
    if (parsed.units < min) {
      const msg =
        tokenType === "ICP"
          ? "Minimum is 0.05 ICP"
          : tokenType === "ckBTC"
            ? "Minimum is 0.00001000 ckBTC"
            : "Minimum is 1.00000000 GLDT";
      addToast({ message: msg, type: "error", duration: 3000 });
      errors.entryFee = msg;
      return;
    }
    isCreating = true;

    const params: CreateGameParams = {
      name: gameName.trim(),
      mode: gameMode,
      tokenType,
      entryFee: Number(parsed.units as unknown as bigint),
      hostFeePercent,
    };

    try {
      const createResult = await gameStore.createGame(params);
      if (!createResult.success || !createResult.gameId) {
        throw new Error(createResult.error || "Failed to create game");
      }
      gameIdCreated = createResult.gameId;
      addToast({
        message: "Game created successfully!",
        type: "success",
        duration: 3000,
      });
      goto(`/game/host/${createResult.gameId}`);
    } catch (error: any) {
      console.error("Create game error:", error);
      addToast({
        message: error?.message || "An error occurred",
        type: "error",
        duration: 4000,
      });
    } finally {
      isCreating = false;
    }
  }

  let gameLink = $derived(
    gameIdCreated
      ? `${window.location.origin}/join-game?gameId=${gameIdCreated}`
      : "",
  );
</script>

{#if isLoading}
  <Spinner />
{:else}
  <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
    <div class="relative z-10 max-w-4xl mx-auto px-4 py-8 md:py-12">
      <div class="mb-8 text-center">
        <h1
          class="text-4xl md:text-5xl font-black uppercase mb-2"
          style="text-shadow: 4px 4px 0px #000, -2px -2px 0px #000, 2px -2px 0px #000, -2px 2px 0px #000;"
        >
          <span class="text-[#F4E04D]">HOST NEW GAME</span>
        </h1>
        <div class="flex items-center justify-center gap-2 md:gap-4 mt-6">
          {#each [1, 2, 3] as step}
            <div class="flex items-center gap-2">
              <div
                class="w-10 h-10 {currentStep >= step
                  ? step === 1
                    ? 'bg-[#F4E04D]'
                    : step === 2
                      ? 'bg-[#C9B5E8]'
                      : 'bg-[#FF6EC7]'
                  : 'bg-gray-600'} border-2 border-black flex items-center justify-center shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              >
                <span class="text-[#1a0033] font-black">{step}</span>
              </div>
            </div>
            {#if step < 3}
              <div
                class="w-8 md:w-16 h-1 {currentStep > step
                  ? 'bg-[#F4E04D]'
                  : 'bg-gray-600'} border border-black"
              ></div>
            {/if}
          {/each}
        </div>
      </div>

      <div
        class="bg-[#1a0033] border-4 border-[#C9B5E8] p-4 mb-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
      >
        <div class="flex items-center justify-between mb-3">
          <p class="text-[#C9B5E8] font-black text-xs uppercase">
            YOUR BALANCE:
          </p>
          <button
            onclick={refreshBalances}
            disabled={$tokenStore.isLoading}
            class="bg-[#C9B5E8] text-[#1a0033] px-3 py-1 font-black uppercase border border-black hover:bg-[#d9c9f0] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-xs shadow-[1px_1px_0px_0px_rgba(0,0,0,1)]"
          >
            {$tokenStore.isLoading ? "..." : "⟳ REFRESH"}
          </button>
        </div>
        <div class="grid grid-cols-3 gap-3">
          <div
            class="bg-[#F4E04D] border-2 border-black p-2 text-center shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            <p class="text-[#1a0033] font-black text-lg md:text-xl">
              {formatSmart(balances.ICP)}
            </p>
            <p class="text-[#1a0033] font-bold text-xs">ICP</p>
          </div>
          <div
            class="bg-[#C9B5E8] border-2 border-black p-2 text-center shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            <p class="text-[#1a0033] font-black text-lg md:text-xl">
              {formatSmart(balances.ckBTC)}
            </p>
            <p class="text-[#1a0033] font-bold text-xs">ckBTC</p>
          </div>
          <div
            class="bg-white border-2 border-black p-2 text-center shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            <p class="text-[#1a0033] font-black text-lg md:text-xl">
              {formatSmart(balances.GLDT)}
            </p>
            <p class="text-[#1a0033] font-bold text-xs">GLDT</p>
          </div>
        </div>
      </div>

      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)] mb-6"
      >
        {#if currentStep === 1}
          <div class="mb-4">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Step 1: Setup
            </span>
          </div>

          <h2
            class="text-2xl font-black text-[#F4E04D] uppercase mb-6"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
            GAME SETUP
          </h2>

          <div class="mb-6">
            <!-- svelte-ignore a11y_label_has_associated_control -->
            <label class="block text-sm font-black text-white uppercase mb-2">
              GAME NAME:
            </label>
            <input
              type="text"
              bind:value={gameName}
              placeholder="Enter game name..."
              maxlength="50"
              class="w-full px-4 py-3 border-4 border-black bg-white text-[#1a0033] font-bold text-lg focus:outline-none focus:border-[#F4E04D] shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] {errors.gameName
                ? 'border-[#FF6EC7]'
                : ''}"
            />
            {#if errors.gameName}
              <p class="mt-2 text-[#FF6EC7] font-bold text-xs">
                ⚠ {errors.gameName}
              </p>
            {/if}
            <p class="mt-1 text-[#C9B5E8] text-xs font-bold">
              {gameName.length}/50 characters
            </p>
          </div>

          <div class="mb-6">
            <!-- svelte-ignore a11y_label_has_associated_control -->
            <label class="block text-sm font-black text-white uppercase mb-3">
              GAME MODE:
            </label>
            <div class="grid grid-cols-2 gap-4">
              <button
                onclick={() => (gameMode = "Line")}
                class="p-4 border-4 border-black {gameMode === 'Line'
                  ? 'bg-[#F4E04D] text-[#1a0033]'
                  : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
              >
                <div class="text-3xl mb-2">━</div>
                <p class="font-black text-sm uppercase">LINE</p>
                <p class="text-xs mt-1 opacity-80">Complete any row/column</p>
              </button>

              <button
                onclick={() => (gameMode = "Blackout")}
                class="p-4 border-4 border-black {gameMode === 'Blackout'
                  ? 'bg-[#C9B5E8] text-[#1a0033]'
                  : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
              >
                <div class="text-3xl mb-2">█</div>
                <p class="font-black text-sm uppercase">BLACKOUT</p>
                <p class="text-xs mt-1 opacity-80">Complete entire tabla</p>
              </button>
            </div>
          </div>
        {/if}

        {#if currentStep === 2}
          <div class="mb-4">
            <span
              class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Step 2: Rules
            </span>
          </div>

          <h2
            class="text-2xl font-black text-[#C9B5E8] uppercase mb-6"
            style="text-shadow: 3px 3px 0px #000, -1px -1px 0px #000;"
          >
            GAME RULES
          </h2>

          <div class="mb-6">
            <!-- svelte-ignore a11y_label_has_associated_control -->
            <label class="block text-sm font-black text-white uppercase mb-3">
              TOKEN TYPE:
            </label>
            <div class="grid grid-cols-3 gap-3">
              <button
                onclick={() => (tokenType = "ICP")}
                class="p-3 border-4 border-black {tokenType === 'ICP'
                  ? 'bg-[#F4E04D] text-[#1a0033]'
                  : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all font-black uppercase text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              >
                ICP
              </button>
              <button
                onclick={() => (tokenType = "ckBTC")}
                class="p-3 border-4 border-black {tokenType === 'ckBTC'
                  ? 'bg-[#C9B5E8] text-[#1a0033]'
                  : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all font-black uppercase text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              >
                ckBTC
              </button>
              <button
                onclick={() => (tokenType = "GLDT")}
                class="p-3 border-4 border-black {tokenType === 'GLDT'
                  ? 'bg-white text-[#1a0033]'
                  : 'bg-[#1a0033] text-white hover:bg-[#2a1a4d]'} transition-all font-black uppercase text-sm shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              >
                GLDT
              </button>
            </div>
          </div>

          <div class="mb-6">
            <!-- svelte-ignore a11y_label_has_associated_control -->
            <label class="block text-sm font-black text-white uppercase mb-2">
              ENTRY FEE (up to 8 decimals):
            </label>
            <input
              type="text"
              bind:value={entryFeeInput}
              inputmode="decimal"
              placeholder="0.00000000"
              oninput={onEntryFeeInput}
              class="w-full px-4 py-3 border-4 border-black bg-white text-[#1a0033] font-black text-2xl text-center focus:outline-none focus:border-[#F4E04D] shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] {errors.entryFee
                ? 'border-[#FF6EC7]'
                : ''}"
            />
            {#if errors.entryFee}
              <p class="mt-2 text-[#FF6EC7] font-bold text-xs">
                ⚠ {errors.entryFee}
              </p>
            {/if}
            <p class="mt-2 text-[#C9B5E8] text-xs font-bold text-center">
              Your balance: {formatSmart(balances[tokenType])}
              {tokenType}
            </p>
          </div>

          <div class="mb-6">
            <!-- svelte-ignore a11y_label_has_associated_control -->
            <label class="block text-sm font-black text-white uppercase mb-2">
              HOST FEE: {hostFeePercent}%
            </label>
            <input
              type="range"
              bind:value={hostFeePercent}
              min="0"
              max="20"
              step="1"
              class="w-full h-4 bg-[#1a0033] border-2 border-black appearance-none cursor-pointer"
            />
            <div class="flex justify-between mt-2">
              <span class="text-xs font-bold text-[#C9B5E8]">0%</span>
              <span class="text-xs font-bold text-[#C9B5E8]">20%</span>
            </div>
          </div>

          <div
            class="bg-[#F4E04D] border-2 border-black p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            <p class="text-[#1a0033] font-bold text-xs uppercase text-center">
              MAX PLAYERS: {maxPlayers}
            </p>
          </div>
        {/if}

        {#if currentStep === 3}
          <div class="mb-4">
            <span
              class="bg-[#FF6EC7] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Step 3: Review
            </span>
          </div>

          <div class="mb-6">
            <div
              class="bg-[#522785] border-2 border-white p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] space-y-2"
            >
              <div class="flex justify-between items-center">
                <span class="text-white font-bold text-xs uppercase"
                  >Entry Fee:</span
                >
                <span class="text-[#C9B5E8] font-black text-sm">
                  {formatSmart(readableEntryFee())}
                  {tokenType}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-white font-bold text-xs uppercase"
                  >Host Fee Percent:</span
                >
                <span class="text-[#F4E04D] font-black text-sm"
                  >{hostFeePercent}%</span
                >
              </div>
              <div
                class="flex justify-between items-center pt-2 border-t border-white"
              >
                <span class="text-[#F4E04D] font-bold text-xs uppercase"
                  >Estimated Prize Pool (Max Players):</span
                >
                <span class="text-white font-black text-sm">
                  {formatSmart(calculatePrizePool())}
                  {tokenType}
                </span>
              </div>
            </div>
          </div>

          <div
            class="mb-6 bg-[#1a0033] border-2 border-[#C9B5E8] p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            <p class="text-[#C9B5E8] font-bold text-xs text-center uppercase">
              Host creates the game and manages draws. Players will pay the
              entry fee when they join.
            </p>
          </div>

          {#if gameIdCreated}
            <div class="mb-6">
              <InvitePlayers gameId={gameIdCreated} {gameLink} />
            </div>
          {/if}
        {/if}
      </div>

      <div class="flex justify-between gap-4">
        {#if currentStep > 1}
          <button
            onclick={prevStep}
            class="flex-1 bg-[#C9B5E8] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            ◄ BACK
          </button>
        {:else}
          <button
            onclick={() => goto("/dashboard")}
            class="flex-1 bg-[#FF6EC7] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#ff8fd4] hover:scale-105 transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            ✕ CANCEL
          </button>
        {/if}

        {#if currentStep < 3}
          <button
            onclick={nextStep}
            class="flex-1 bg-[#F4E04D] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#fff27d] hover:scale-105 transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            NEXT ►
          </button>
        {:else}
          <button
            onclick={createGame}
            disabled={isCreating || gameIdCreated !== null}
            class="flex-1 bg-[#F4E04D] text-[#1a0033] px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#fff27d] hover:scale-105 disabled:bg-gray-400 disabled:cursor-not-allowed transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            {isCreating
              ? "CREATING..."
              : gameIdCreated
                ? "GAME CREATED!"
                : "CREATE GAME ►"}
          </button>
        {/if}
      </div>
    </div>
  </div>
{/if}
