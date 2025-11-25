<script lang="ts">
  import { onMount } from "svelte";
  import QRCode from "qrcode";
  import { authStore } from "$lib/stores/auth-store";
  import { AccountIdentifier } from "@dfinity/ledger-icp";
  import type { TokenBalance } from "$lib/services/token-service";

  interface Props {
    token: TokenBalance | undefined;
    onClose: () => void;
  }

  let { token, onClose }: Props = $props();

  let qrCodeDataUrl = $state("");
  let accountId = $state("");
  let copied = $state(false);
  let qrCanvas: HTMLCanvasElement;

  onMount(async () => {
    const identity = $authStore.identity;
    if (identity && token) {
      const principal = identity.getPrincipal();
      accountId = AccountIdentifier.fromPrincipal({ principal }).toHex();

      // Generate QR code
      try {
        qrCodeDataUrl = await QRCode.toDataURL(accountId, {
          width: 300,
          margin: 2,
          color: {
            dark: "#000000",
            light: "#FFFFFF",
          },
        });
      } catch (error) {
        console.error("Error generating QR code:", error);
      }
    }
  });

  function copyToClipboard() {
    navigator.clipboard.writeText(accountId);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }

  function handleBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) {
      onClose();
    }
  }
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm"
  onclick={handleBackdropClick}
>
  <div
    class="w-full max-w-md bg-gradient-to-b from-[#522785] to-[#3d1d63] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.5)]"
  >
    <div
      class="bg-[#522785] p-2 border-b-2 border-black flex items-center justify-between"
    >
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 bg-red-500 rounded-full border border-black"></div>
        <div
          class="w-3 h-3 bg-[#FBB03B] rounded-full border border-black"
        ></div>
        <div
          class="w-3 h-3 bg-green-500 rounded-full border border-black"
        ></div>
      </div>
      <div class="text-white font-bold text-xs uppercase">
        RECEIVE_{token?.symbol}.EXE
      </div>
      <button
        onclick={onClose}
        class="w-4 h-4 bg-red-500 border border-black hover:bg-red-600 flex items-center justify-center"
      >
        <span class="text-white text-xs font-bold">×</span>
      </button>
    </div>

    <div class="bg-white p-6 border-4 border-black">
      <h2 class="text-2xl font-black text-black uppercase mb-4 text-center">
        RECEIVE {token?.symbol}
      </h2>

      {#if token}
        <div class="flex items-center justify-center gap-3 mb-6">
          <img
            src={token.icon}
            alt={token.symbol}
            class="w-8 h-8 object-contain"
          />
          <span class="text-lg font-black text-black">{token.name}</span>
        </div>
      {/if}

      {#if qrCodeDataUrl}
        <div
          class="bg-white border-4 border-black p-4 mb-4 flex justify-center"
        >
          <img src={qrCodeDataUrl} alt="QR Code" class="w-64 h-64" />
        </div>
      {:else}
        <div
          class="bg-white border-4 border-black p-8 mb-4 flex justify-center items-center"
        >
          <div
            class="animate-spin rounded-full h-12 w-12 border-4 border-black border-t-[#29ABE2]"
          ></div>
        </div>
      {/if}

      <div class="mb-4">
        <!-- svelte-ignore a11y_label_has_associated_control -->
        <label class="block text-xs font-black text-black uppercase mb-2">
          Your Account ID
        </label>
        <div class="bg-black border-2 border-[#C9B5E8] p-3">
          <code class="text-xs text-[#C9B5E8] break-all font-bold">
            {accountId || "Loading..."}
          </code>
        </div>
      </div>

      <div class="flex gap-2">
        <button
          onclick={copyToClipboard}
          class="flex-1 bg-[#C9B5E8] text-black px-4 py-3 font-black uppercase border-2 border-black hover:bg-[#1e88c7] transition-all"
          style="box-shadow: 2px 2px 0px #000;"
        >
          {copied ? "✓ COPIED!" : "COPY ADDRESS"}
        </button>
        <button
          onclick={onClose}
          class="flex-1 bg-white text-black px-4 py-3 font-black uppercase border-2 border-black hover:bg-gray-200 transition-all"
          style="box-shadow: 2px 2px 0px #000;"
        >
          CLOSE
        </button>
      </div>

      <p class="text-xs text-center mt-4 font-bold text-black">
        SCAN QR CODE OR COPY ADDRESS TO RECEIVE {token?.symbol}
      </p>
    </div>
  </div>
</div>
