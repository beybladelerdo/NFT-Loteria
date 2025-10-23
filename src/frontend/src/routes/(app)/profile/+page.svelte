<script lang="ts">
  import { onMount } from "svelte";
  import { userStore } from "$lib/stores/user-store";
  import { authStore } from "$lib/stores/auth-store";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Wallet from "$lib/components/profile/wallet.svelte";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  import { AccountIdentifier } from "@dfinity/ledger-icp";
  import { isUsernameValid } from "$lib/utils/helpers";

  let isLoading = $state(true);
  let user: Profile | undefined = $state(undefined);
  let principal = $state("");
  let accountId = $state("");
  let copiedField = $state("");

  // Username editing
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
  <div class="min-h-screen bg-[#1a0033] relative overflow-hidden">
    <div class="relative z-10 max-w-4xl mx-auto px-4 py-8 md:py-12 space-y-6">
      <!-- Profile Header -->
      <div class="text-center mb-8">
        <h1
          class="text-4xl md:text-5xl font-black uppercase mb-2"
          style="text-shadow: 4px 4px 0px #000, -2px -2px 0px #000, 2px -2px 0px #000, -2px 2px 0px #000;"
        >
          <span class="text-[#F4E04D]">YOUR PROFILE</span>
        </h1>
      </div>

      <!-- Profile Card -->
      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-6 md:p-8 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
      >
        <!-- Username Section -->
        <div class="mb-6">
          <div class="mb-3">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Username
            </span>
          </div>

          {#if isEditingUsername}
            <div class="space-y-3">
              <input
                type="text"
                bind:value={newUsername}
                oninput={handleUsernameInput}
                class="w-full px-4 py-3 text-lg bg-white border-4 border-black text-[#1a0033] font-black uppercase focus:outline-none focus:border-[#F4E04D] shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
                placeholder="YOUR-USERNAME"
              />

              {#if newUsername !== user.username && newUsername.length > 0}
                <div
                  class="bg-[#1a0033] border-2 border-[#C9B5E8] p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
                >
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
                  class="flex-1 bg-white text-[#1a0033] px-4 py-2 font-black uppercase border-2 border-black hover:bg-gray-200 transition-all text-sm shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
                >
                  CANCEL
                </button>
                <button
                  onclick={saveUsername}
                  disabled={!usernameAvailable ||
                    isSavingUsername ||
                    newUsername === user.username}
                  class="flex-1 bg-[#F4E04D] text-[#1a0033] px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#fff27d] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-sm shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
                >
                  {isSavingUsername ? "SAVING..." : "SAVE"}
                </button>
              </div>
            </div>
          {:else}
            <div
              class="bg-[#1a0033] border-4 border-black p-4 flex items-center justify-between shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="flex items-center gap-3">
                <div
                  class="w-12 h-12 bg-gradient-to-br from-[#F4E04D] to-[#C9B5E8] border-2 border-black flex items-center justify-center text-[#1a0033] font-black text-xl shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
                >
                  {user.username[0].toUpperCase()}
                </div>
                <span
                  class="text-2xl font-black text-[#F4E04D]"
                  style="text-shadow: 2px 2px 0px #000;">@{user.username}</span
                >
              </div>
              <button
                onclick={startEditingUsername}
                class="bg-[#C9B5E8] text-[#1a0033] px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all text-sm shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              >
                EDIT
              </button>
            </div>
          {/if}
        </div>

        <!-- Principal ID Section -->
        <div class="mb-6">
          <div class="mb-3">
            <span
              class="bg-[#C9B5E8] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Principal ID
            </span>
          </div>

          <div
            class="bg-[#1a0033] border-4 border-black p-4 flex items-center justify-between gap-2 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <code
              class="text-xs md:text-sm font-bold text-[#C9B5E8] truncate flex-1"
            >
              {principal}
            </code>
            <button
              onclick={() => copyToClipboard(principal, "principal")}
              class="bg-[#F4E04D] text-[#1a0033] px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#fff27d] hover:scale-105 transition-all text-xs flex-shrink-0 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              {copiedField === "principal" ? "✓" : "COPY"}
            </button>
          </div>
        </div>

        <!-- Account ID Section -->
        <div class="mb-6">
          <div class="mb-3">
            <span
              class="bg-white text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Account ID
            </span>
          </div>

          <div
            class="bg-[#1a0033] border-4 border-black p-4 flex items-center justify-between gap-2 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            <code
              class="text-xs md:text-sm font-bold text-white truncate flex-1"
            >
              {accountId}
            </code>
            <button
              onclick={() => copyToClipboard(accountId, "account")}
              class="bg-[#F4E04D] text-[#1a0033] px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#fff27d] hover:scale-105 transition-all text-xs flex-shrink-0 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              {copiedField === "account" ? "✓" : "COPY"}
            </button>
          </div>
        </div>

        <!-- Stats Section -->
        <div>
          <div class="mb-3">
            <span
              class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              Your Stats
            </span>
          </div>

          <div class="grid grid-cols-3 gap-4">
            <div
              class="bg-[#F4E04D] border-2 border-black p-4 text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-3xl font-black text-[#1a0033]">{user.games}</div>
              <div class="text-xs font-bold text-[#1a0033] uppercase mt-1">
                Games
              </div>
            </div>
            <div
              class="bg-[#C9B5E8] border-2 border-black p-4 text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-3xl font-black text-[#1a0033]">{user.wins}</div>
              <div class="text-xs font-bold text-[#1a0033] uppercase mt-1">
                Wins
              </div>
            </div>
            <div
              class="bg-white border-2 border-black p-4 text-center shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
            >
              <div class="text-3xl font-black text-[#1a0033]">
                {(user.winRate * 100).toFixed(1)}%
              </div>
              <div class="text-xs font-bold text-[#1a0033] uppercase mt-1">
                Win Rate
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Wallet Component -->
      <Wallet />
    </div>
  </div>
{/if}
