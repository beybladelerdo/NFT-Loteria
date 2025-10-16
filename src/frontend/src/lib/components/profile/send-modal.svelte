<script lang="ts">
  import { authStore } from "$lib/stores/auth-store";
  import { TokenService } from "$lib/services/token-service";
  import type { TokenBalance } from "$lib/services/token-service";
  import { IcrcLedgerCanister } from "@dfinity/ledger-icrc";
  import { Principal } from "@dfinity/principal";
  import { ActorFactory } from "$lib/utils/ActorFactory";

  interface Props {
    token: TokenBalance | undefined;
    onClose: () => void;
    onSuccess: () => void;
  }

  let { token, onClose, onSuccess }: Props = $props();

  const tokenService = new TokenService();

  let recipientAddress = $state("");
  let amount = $state("");
  let isSending = $state(false);
  let showConfirmation = $state(false);
  let error = $state("");
  let txFee = $state<bigint>(BigInt(10000)); // Default fee

  $effect(() => {
    if (token) {
      // Set appropriate fee based on token
      if (token.symbol === "ICP" || token.symbol === "LICP") {
        txFee = BigInt(10000);
      } else if (token.symbol === "GLDT" || token.symbol === "LGLDT") {
        txFee = BigInt(10000);
      } else if (token.symbol === "ckBTC" || token.symbol === "LCKBTC") {
        txFee = BigInt(10);
      }
    }
  });

  function handleBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) {
      onClose();
    }
  }

  function setMaxAmount() {
    if (!token) return;
    const maxAmount = token.balance - txFee;
    if (maxAmount > 0) {
      amount = tokenService.formatBalance(maxAmount, token.decimals);
    }
  }

  function parseAmount(amountStr: string, decimals: number): bigint {
    try {
      const [whole, fraction = ""] = amountStr.split(".");
      const paddedFraction = fraction.padEnd(decimals, "0").slice(0, decimals);
      return BigInt(whole + paddedFraction);
    } catch {
      return BigInt(0);
    }
  }

  function isValidAddress(address: string): boolean {
    try {
      Principal.fromText(address);
      return true;
    } catch {
      return false;
    }
  }

  function handleReviewTransfer() {
    error = "";

    // Validation
    if (!recipientAddress.trim()) {
      error = "Please enter a recipient address";
      return;
    }

    if (!isValidAddress(recipientAddress)) {
      error = "Invalid address format";
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      error = "Please enter a valid amount";
      return;
    }

    if (!token) return;

    const amountInAtomicUnits = parseAmount(amount, token.decimals);

    if (amountInAtomicUnits <= 0) {
      error = "Amount must be greater than 0";
      return;
    }

    if (amountInAtomicUnits + txFee > token.balance) {
      error = "Insufficient balance (including fees)";
      return;
    }

    // Show confirmation
    showConfirmation = true;
  }

  function handleBack() {
    showConfirmation = false;
    error = "";
  }

  async function handleConfirmSend() {
    if (!token) return;

    isSending = true;
    error = "";

    try {
      const identity = $authStore.identity;
      if (!identity) throw new Error("Not authenticated");

      const amountInAtomicUnits = parseAmount(amount, token.decimals);

      console.log("🚀 Initiating transfer:", {
        token: token.symbol,
        to: recipientAddress,
        amount: amountInAtomicUnits.toString(),
        canisterId: token.canisterId,
      });

      // Use ActorFactory to get the agent with proper root key handling
      const agent = await ActorFactory.getAgent(token.canisterId, identity);

      console.log("✅ Agent created");

      const ledger = IcrcLedgerCanister.create({
        agent,
        canisterId: Principal.fromText(token.canisterId),
      });

      console.log("✅ Ledger canister initialized");

      const recipientPrincipal = Principal.fromText(recipientAddress);

      // The transfer method returns a bigint (block index) on success
      // or throws an error on failure
      const blockIndex = await ledger.transfer({
        to: {
          owner: recipientPrincipal,
          subaccount: [],
        },
        amount: amountInAtomicUnits,
        fee: txFee, // Explicitly set the fee
        memo: undefined,
        created_at_time: undefined,
        from_subaccount: undefined,
      });

      console.log("✅ Transfer successful! Block index:", blockIndex);

      // Success!
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error("❌ Transfer error:", err);

      // Parse ICRC error codes
      if (err?.message?.includes("InsufficientFunds")) {
        error = "Insufficient funds (including fees)";
      } else if (err?.message?.includes("BadFee")) {
        error = "Incorrect fee amount";
      } else if (err?.message?.includes("TooOld")) {
        error = "Transaction expired, please try again";
      } else if (err?.message?.includes("CreatedInFuture")) {
        error = "Transaction timestamp error";
      } else if (err?.message?.includes("Duplicate")) {
        error = "Duplicate transaction detected";
      } else if (err?.message?.includes("TemporarilyUnavailable")) {
        error = "Ledger temporarily unavailable";
      } else if (err?.message?.includes("GenericError")) {
        error = `Transfer failed: ${err.message}`;
      } else if (err?.message) {
        error = err.message;
      } else if (typeof err === "string") {
        error = err;
      } else {
        error = "Transfer failed. Please try again.";
      }

      // Log the full error for debugging
      console.error("Full error:", err);
    } finally {
      isSending = false;
    }
  }
</script>

<!-- Rest of the template remains the same -->
<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  class="fixed inset-0 z-9999 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm"
  onclick={handleBackdropClick}
>
  <div
    class="w-full max-w-md bg-gradient-to-b from-[#FBB03B] to-[#e09a2f] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.5)]"
  >
    <div
      class="bg-[#FBB03B] p-2 border-b-2 border-black flex items-center justify-between"
    >
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 bg-red-500 rounded-full border border-black"></div>
        <div
          class="w-3 h-3 bg-[#29ABE2] rounded-full border border-black"
        ></div>
        <div
          class="w-3 h-3 bg-green-500 rounded-full border border-black"
        ></div>
      </div>
      <div class="text-black font-bold text-xs uppercase">
        SEND_{token?.symbol}.EXE
      </div>
      <button
        onclick={onClose}
        class="w-4 h-4 bg-red-500 border border-black hover:bg-red-600 flex items-center justify-center"
      >
        <span class="text-white text-xs font-bold">×</span>
      </button>
    </div>

    <div class="bg-white p-6 border-4 border-black">
      {#if !showConfirmation}
        <!-- STEP 1: Enter Details -->
        <h2 class="text-2xl font-black text-black uppercase mb-4 text-center">
          SEND {token?.symbol}
        </h2>

        {#if token}
          <div class="flex items-center justify-center gap-3 mb-6">
            <img
              src={token.icon}
              alt={token.symbol}
              class="w-8 h-8 object-contain"
            />
            <div class="text-center">
              <p class="text-lg font-black text-black">{token.name}</p>
              <p class="text-sm font-bold text-black">
                Balance: {tokenService.formatBalance(
                  token.balance,
                  token.decimals,
                )}
                {token.symbol}
              </p>
            </div>
          </div>

          <div class="space-y-4">
            <!-- Recipient Address -->
            <div>
              <!-- svelte-ignore a11y_label_has_associated_control -->
              <label class="block text-xs font-black text-black uppercase mb-2">
                Recipient Principal ID
              </label>
              <input
                type="text"
                bind:value={recipientAddress}
                placeholder="Enter principal ID..."
                class="w-full px-4 py-3 text-sm bg-white border-4 border-black text-black font-bold focus:outline-none focus:border-[#522785]"
              />
            </div>

            <!-- Amount -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <!-- svelte-ignore a11y_label_has_associated_control -->
                <label class="text-xs font-black text-black uppercase">
                  Amount
                </label>
                <button
                  onclick={setMaxAmount}
                  class="text-xs font-black text-[#522785] uppercase hover:text-[#6d3399]"
                >
                  MAX
                </button>
              </div>
              <input
                type="text"
                bind:value={amount}
                placeholder="0.00"
                class="w-full px-4 py-3 text-lg bg-white border-4 border-black text-black font-black focus:outline-none focus:border-[#522785]"
              />
            </div>

            <!-- Transaction Fee -->
            <div class="bg-black border-2 border-[#29ABE2] p-3">
              <div class="flex justify-between items-center">
                <span class="text-xs font-bold text-[#29ABE2] uppercase"
                  >Transaction Fee</span
                >
                <span class="text-sm font-black text-[#29ABE2]">
                  {tokenService.formatBalance(txFee, token.decimals)}
                  {token.symbol}
                </span>
              </div>
            </div>

            <!-- Error Message -->
            {#if error}
              <div class="bg-red-500 border-2 border-black p-3">
                <p class="text-xs font-bold text-white uppercase">{error}</p>
              </div>
            {/if}

            <!-- Action Buttons -->
            <div class="flex gap-2 pt-2">
              <button
                onclick={onClose}
                class="flex-1 bg-white text-black px-4 py-3 font-black uppercase border-2 border-black hover:bg-gray-200 transition-all"
                style="box-shadow: 2px 2px 0px #000;"
              >
                CANCEL
              </button>
              <button
                onclick={handleReviewTransfer}
                class="flex-1 bg-[#522785] text-white px-4 py-3 font-black uppercase border-2 border-black hover:bg-[#6d3399] transition-all"
                style="box-shadow: 2px 2px 0px #000;"
              >
                REVIEW
              </button>
            </div>
          </div>
        {/if}
      {:else}
        <!-- STEP 2: Confirmation -->
        <h2 class="text-2xl font-black text-black uppercase mb-4 text-center">
          CONFIRM TRANSFER
        </h2>

        {#if token}
          <div
            class="bg-[#FBB03B] border-4 border-black p-4 mb-4"
            style="box-shadow: 4px 4px 0px #000;"
          >
            <div class="space-y-3">
              <div>
                <p class="text-xs font-bold text-black uppercase mb-1">
                  Sending
                </p>
                <p class="text-xl font-black text-black">
                  {amount}
                  {token.symbol}
                </p>
              </div>

              <div class="border-t-2 border-black pt-3">
                <p class="text-xs font-bold text-black uppercase mb-1">To</p>
                <p class="text-xs font-bold text-black break-all">
                  {recipientAddress}
                </p>
              </div>

              <div class="border-t-2 border-black pt-3">
                <div class="flex justify-between">
                  <span class="text-xs font-bold text-black uppercase"
                    >Network Fee</span
                  >
                  <span class="text-xs font-black text-black">
                    {tokenService.formatBalance(txFee, token.decimals)}
                    {token.symbol}
                  </span>
                </div>
              </div>

              <div class="border-t-2 border-black pt-3">
                <div class="flex justify-between">
                  <span class="text-xs font-bold text-black uppercase"
                    >Total Cost</span
                  >
                  <span class="text-sm font-black text-black">
                    {tokenService.formatBalance(
                      parseAmount(amount, token.decimals) + txFee,
                      token.decimals,
                    )}
                    {token.symbol}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Error Message -->
          {#if error}
            <div class="bg-red-500 border-2 border-black p-3 mb-4">
              <p class="text-xs font-bold text-white uppercase">{error}</p>
            </div>
          {/if}

          <!-- Action Buttons -->
          <div class="flex gap-2">
            <button
              onclick={handleBack}
              disabled={isSending}
              class="flex-1 bg-white text-black px-4 py-3 font-black uppercase border-2 border-black hover:bg-gray-200 transition-all disabled:opacity-50"
              style="box-shadow: 2px 2px 0px #000;"
            >
              BACK
            </button>
            <button
              onclick={handleConfirmSend}
              disabled={isSending}
              class="flex-1 bg-[#522785] text-white px-4 py-3 font-black uppercase border-2 border-black hover:bg-[#6d3399] transition-all disabled:opacity-50"
              style="box-shadow: 2px 2px 0px #000;"
            >
              {isSending ? "SENDING..." : "CONFIRM SEND"}
            </button>
          </div>
        {/if}
      {/if}
    </div>
  </div>
</div>
