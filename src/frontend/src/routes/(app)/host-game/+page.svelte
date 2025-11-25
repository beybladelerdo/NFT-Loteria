<script lang="ts">
  import { onMount } from "svelte";
  import { goto } from "$app/navigation";
  import { authStore } from "$lib/stores/auth-store";
  import { gameStore } from "$lib/stores/game-store.svelte";
  import { addToast } from "$lib/stores/toasts-store";
  import {DECIMALS, MAX_DECIMALS, MIN_BY_TOKEN, maxPlayers} from "$lib/constants/app.constants";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Progress from "$lib/components/routes/host/Progress.svelte";
  import Setup from "$lib/components/routes/host/Setup.svelte";
  import Rules from "$lib/components/routes/host/Rules.svelte";
  import Review from "$lib/components/routes/host/Review.svelte";
  import type { CreateGameParams } from "$lib/services/game-service";

  let currentStep = $state<1 | 2 | 3>(1);
  let isLoading = $state(false);
  let isCreating = $state(false);
  let gameIdCreated = $state<string | null>(null);

  let gameName = $state("");
  let gameMode = $state<"Line" | "Blackout">("Line");
  let tokenType = $state<"ICP" | "ckBTC" | "GLDT">("ICP");
  let entryFeeInput = $state("");
  let hostFeePercent = $state(5);

  let errors = $state({
    gameName: "",
    entryFee: "",
  });

  let gameLink = $derived(
    gameIdCreated ? `${window.location.origin}/join-game?gameId=${gameIdCreated}` : ""
  );

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
    let v = el.value;
    
    // Remove any non-numeric characters except decimal point
    v = v.replace(/[^0-9.]/g, '');
    
    // Ensure only one decimal point
    const parts = v.split('.');
    if (parts.length > 2) {
      v = parts[0] + '.' + parts.slice(1).join('');
    }
    
    // Prevent starting with multiple zeros
    if (v.startsWith('00')) {
      v = '0';
    }
    
    // Limit to MAX_DECIMALS after decimal point
    if (parts.length === 2 && parts[1].length > MAX_DECIMALS) {
      v = parts[0] + '.' + parts[1].slice(0, MAX_DECIMALS);
    }
    
    el.value = v;
    entryFeeInput = v;
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
        message: errors.gameName || errors.entryFee || "Please fix all validation errors",
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

  onMount(async () => {
    if (!$authStore.isAuthenticated) {
      goto("/");
      return;
    }
    isLoading = false;
  });
</script>

{#if isLoading}
  <Spinner />
{:else}
  <div class="min-h-screen bg-[#1a0033] pb-8">
    <div class="max-w-4xl mx-auto px-4 py-6 sm:py-8 md:py-12">
      <div class="mb-6 sm:mb-8 text-center">
        <h1 class="text-3xl sm:text-4xl md:text-5xl font-black uppercase mb-2 px-2 arcade-text-shadow">
          <span class="text-[#F4E04D]">HOST NEW GAME</span>
        </h1>
        <Progress {currentStep} />
      </div>

      <div class="arcade-panel p-4 sm:p-6 mb-4 sm:mb-6">
        {#if currentStep === 1}
          <Setup
            {gameName}
            {gameMode}
            {errors}
            onGameNameChange={(name) => (gameName = name)}
            onGameModeChange={(mode) => (gameMode = mode)}
          />
        {/if}

        {#if currentStep === 2}
          <Rules
            {tokenType}
            {entryFeeInput}
            {hostFeePercent}
            {maxPlayers}
            {errors}
            onTokenTypeChange={(token) => (tokenType = token)}
            {onEntryFeeInput}
            onHostFeeChange={(fee) => (hostFeePercent = fee)}
          />
        {/if}

        {#if currentStep === 3}
          <Review
            {tokenType}
            readableEntryFee={readableEntryFee()}
            {hostFeePercent}
            prizePool={calculatePrizePool()}
            {gameIdCreated}
            {gameLink}
          />
        {/if}
      </div>

      <div class="flex gap-3 sm:gap-4">
        {#if currentStep > 1}
          <button
            onclick={prevStep}
            class="flex-1 bg-[#C9B5E8] text-[#1a0033] px-4 sm:px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#d9c9f0] active:scale-95 sm:hover:scale-105 transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)] text-sm sm:text-base"
          >
            ◄ BACK
          </button>
        {:else}
          <button
            onclick={() => goto("/dashboard")}
            class="flex-1 bg-[#FF6EC7] text-[#1a0033] px-4 sm:px-6 py-3 font-black uppercase border-4 border-black hover:bg-[#ff8fd4] active:scale-95 sm:hover:scale-105 transition-all shadow-[4px_4px_0px_rgba(0,0,0,1)] text-sm sm:text-base"
          >
            ✕ CANCEL
          </button>
        {/if}

        {#if currentStep < 3}
          <button
            onclick={nextStep}
            class="arcade-button flex-1 px-4 sm:px-6 py-3 text-sm sm:text-base"
          >
            NEXT ►
          </button>
        {:else}
          <button
            onclick={createGame}
            disabled={isCreating || gameIdCreated !== null}
            class="arcade-button flex-1 px-4 sm:px-6 py-3 text-sm sm:text-base disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {isCreating ? "CREATING..." : gameIdCreated ? "GAME CREATED!" : "CREATE GAME ►"}
          </button>
        {/if}
      </div>
    </div>
  </div>
{/if}