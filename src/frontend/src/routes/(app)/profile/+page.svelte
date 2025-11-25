<script lang="ts">
  import { onMount } from "svelte";
  import { userStore } from "$lib/stores/user-store";
  import { authStore } from "$lib/stores/auth-store";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Wallet from "$lib/components/routes/profile/Wallet.svelte";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  import { AccountIdentifier } from "@dfinity/ledger-icp";
  import { isUsernameValid } from "$lib/utils/helpers";

  let isLoading = $state(true);
  let user: Profile | undefined = $state(undefined);
  let principal = $state("");
  let accountId = $state("");
  let copiedField = $state("");

  let isEditingUsername = $state(false);
  let newUsername = $state("");
  let isCheckingUsername = $state(false);
  let usernameAvailable = $state(true);
  let usernameError = $state("");
  let isSavingUsername = $state(false);
  let checkTimeout: NodeJS.Timeout;

  onMount(async () => {
    try {
      user = await userStore.getProfile();
      const identity = $authStore.identity;
      if (identity) {
        const principalObj = identity.getPrincipal();
        principal = principalObj.toString();
        accountId = AccountIdentifier.fromPrincipal({
          principal: principalObj,
        }).toHex();
      }
    } catch (error) {
      console.error("Profile fetch error:", error);
    } finally {
      isLoading = false;
    }
  });

  function copyToClipboard(text: string, field: string) {
    navigator.clipboard.writeText(text);
    copiedField = field;
    setTimeout(() => (copiedField = ""), 2000);
  }

  function startEditingUsername() {
    if (!user) return;
    newUsername = user.username;
    isEditingUsername = true;
    usernameAvailable = true;
    usernameError = "";
  }

  function cancelEditingUsername() {
    isEditingUsername = false;
    newUsername = "";
    usernameError = "";
  }

  function handleUsernameInput() {
    if (!user) return;
    clearTimeout(checkTimeout);
    usernameAvailable = false;
    usernameError = "";

    if (newUsername === user.username) {
      usernameAvailable = true;
      return;
    }

    if (newUsername.length >= 5) {
      checkTimeout = setTimeout(checkUsernameAvailability, 500);
    }
  }

  async function checkUsernameAvailability() {
    isCheckingUsername = true;
    try {
      if (!isUsernameValid(newUsername)) {
        usernameError = "Username must be 5-20 characters";
        usernameAvailable = false;
        return;
      }

      const available = await userStore.isTagAvailable(newUsername);
      usernameAvailable = available;
      usernameError = available ? "" : "Username already taken";
    } catch (err) {
      usernameError = "Error checking availability";
      usernameAvailable = false;
    } finally {
      isCheckingUsername = false;
    }
  }

  async function saveUsername() {
    if (!user || !usernameAvailable || newUsername === user.username) return;

    isSavingUsername = true;
    try {
      await userStore.updateTag(newUsername);
      user = await userStore.getProfile();
      isEditingUsername = false;
    } catch (err) {
      usernameError = "Failed to update username";
    } finally {
      isSavingUsername = false;
    }
  }
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else if user}
  <div class="min-h-screen bg-[#1a0033] pb-8">
    <div class="max-w-4xl mx-auto px-4 py-6 sm:py-8 md:py-12 space-y-4 sm:space-y-6">
      <div class="text-center mb-6 sm:mb-8">
        <h1 class="text-3xl sm:text-4xl md:text-5xl font-black uppercase mb-2 px-2 arcade-text-shadow">
          <span class="text-[#F4E04D]">YOUR PROFILE</span>
        </h1>
      </div>

      <div class="arcade-panel p-4 sm:p-6 md:p-8">
        <div class="mb-4 sm:mb-6">
          <div class="mb-3">
            <span class="arcade-badge">Username</span>
          </div>

          {#if isEditingUsername}
            <div class="space-y-3">
              <input
                type="text"
                bind:value={newUsername}
                oninput={handleUsernameInput}
                class="w-full px-3 sm:px-4 py-2 sm:py-3 text-base sm:text-lg bg-white border-4 border-black text-[#1a0033] font-black uppercase focus:outline-none focus:border-[#F4E04D] shadow-[4px_4px_0px_rgba(0,0,0,1)]"
                placeholder="YOUR-USERNAME"
              />

              {#if newUsername !== user.username && newUsername.length > 0}
                <div class="arcade-panel-sm p-3">
                  {#if isCheckingUsername}
                    <p class="text-xs font-bold text-[#C9B5E8]">CHECKING...</p>
                  {:else if usernameError}
                    <p class="text-xs font-bold text-[#FF6EC7]">
                      {usernameError.toUpperCase()}
                    </p>
                  {:else if usernameAvailable}
                    <p class="text-xs font-bold text-[#F4E04D]">✓ AVAILABLE</p>
                  {/if}
                </div>
              {/if}

              <div class="flex gap-2">
                <button
                  onclick={cancelEditingUsername}
                  class="flex-1 bg-white text-[#1a0033] px-4 py-2 font-black uppercase border-2 border-black hover:bg-gray-200 active:scale-95 transition-all text-sm shadow-[2px_2px_0px_rgba(0,0,0,1)]"
                >
                  CANCEL
                </button>
                <button
                  onclick={saveUsername}
                  disabled={!usernameAvailable || isSavingUsername || newUsername === user.username}
                  class="arcade-button flex-1 px-4 py-2 text-sm disabled:bg-gray-400 disabled:cursor-not-allowed"
                >
                  {isSavingUsername ? "SAVING..." : "SAVE"}
                </button>
              </div>
            </div>
          {:else}
            <div class="arcade-panel-sm p-3 sm:p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-[#F4E04D] to-[#C9B5E8] border-2 border-black flex items-center justify-center text-[#1a0033] font-black text-lg sm:text-xl shadow-[2px_2px_0px_rgba(0,0,0,1)] flex-shrink-0">
                  {user.username[0].toUpperCase()}
                </div>
                <span class="text-xl sm:text-2xl font-black text-[#F4E04D] arcade-text-shadow break-all">
                  @{user.username}
                </span>
              </div>
              <button
                onclick={startEditingUsername}
                class="w-full sm:w-auto bg-[#C9B5E8] text-[#1a0033] px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#d9c9f0] active:scale-95 sm:hover:scale-105 transition-all text-sm shadow-[2px_2px_0px_rgba(0,0,0,1)]"
              >
                EDIT
              </button>
            </div>
          {/if}
        </div>

        <div class="mb-4 sm:mb-6">
          <div class="mb-3">
            <span class="arcade-badge bg-[#C9B5E8]">Principal ID</span>
          </div>

          <div class="arcade-panel-sm p-3 sm:p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 sm:gap-3">
            <code class="text-xs sm:text-sm font-bold text-[#C9B5E8] break-all flex-1 w-full">
              {principal}
            </code>
            <button
              onclick={() => copyToClipboard(principal, "principal")}
              class="arcade-button w-full sm:w-auto px-3 py-2 text-xs flex-shrink-0"
            >
              {copiedField === "principal" ? "✓ COPIED" : "COPY"}
            </button>
          </div>
        </div>

        <div class="mb-4 sm:mb-6">
          <div class="mb-3">
            <span class="arcade-badge bg-white">Account ID</span>
          </div>

          <div class="arcade-panel-sm p-3 sm:p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 sm:gap-3">
            <code class="text-xs sm:text-sm font-bold text-white break-all flex-1 w-full">
              {accountId}
            </code>
            <button
              onclick={() => copyToClipboard(accountId, "account")}
              class="arcade-button w-full sm:w-auto px-3 py-2 text-xs flex-shrink-0"
            >
              {copiedField === "account" ? "✓ COPIED" : "COPY"}
            </button>
          </div>
        </div>
      </div>

      <Wallet />
    </div>
  </div>
{/if}