<script lang="ts">
  import { onMount } from "svelte";
  import { userStore } from "$lib/stores/user-store";
  import { authStore } from "$lib/stores/auth-store";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Wallet from "$lib/components/profile/wallet.svelte";
  import type { Profile } from "..../../../declarations/backend/backend.did";
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
  <div class="flex items-center justify-center min-h-screen bg-[#ED1E79]">
    <Spinner />
  </div>
{:else if user}
  <div class="min-h-screen bg-[#ED1E79] relative overflow-hidden">
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

    <div class="relative max-w-4xl mx-auto px-4 py-8 md:py-12 space-y-6">
      <!-- Profile Window -->
      <div
        class="bg-gradient-to-b from-[#29ABE2] to-[#1e88c7] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
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
            PROFILE.EXE
          </div>
          <div class="w-12"></div>
        </div>

        <div class="bg-white p-6 md:p-8 border-4 border-black">
          <h1
            class="text-3xl md:text-4xl font-black text-black uppercase mb-6 text-center"
            style="text-shadow: 3px 3px 0px #29ABE2;"
          >
            YOUR PROFILE
          </h1>

          <!-- Username Section -->
          <div class="mb-6">
            <div class="bg-[#FBB03B] border-4 border-black p-1 mb-2">
              <div class="bg-black p-2 border-2 border-[#FBB03B]">
                <p class="text-xs font-black text-[#FBB03B] uppercase">
                  USERNAME
                </p>
              </div>
            </div>

            {#if isEditingUsername}
              <div class="space-y-3">
                <input
                  type="text"
                  bind:value={newUsername}
                  oninput={handleUsernameInput}
                  class="w-full px-4 py-3 text-lg bg-white border-4 border-black text-black font-black uppercase focus:outline-none focus:border-[#522785]"
                  placeholder="YOUR-USERNAME"
                />

                {#if newUsername !== user.username && newUsername.length > 0}
                  <div class="bg-black border-2 border-[#29ABE2] p-2">
                    {#if isCheckingUsername}
                      <p class="text-xs font-bold text-[#29ABE2]">
                        CHECKING...
                      </p>
                    {:else if usernameError}
                      <p class="text-xs font-bold text-red-400">
                        {usernameError.toUpperCase()}
                      </p>
                    {:else if usernameAvailable}
                      <p class="text-xs font-bold text-green-400">
                        ✓ AVAILABLE
                      </p>
                    {/if}
                  </div>
                {/if}

                <div class="flex gap-2">
                  <button
                    onclick={cancelEditingUsername}
                    class="flex-1 bg-white text-black px-4 py-2 font-black uppercase border-2 border-black hover:bg-gray-200 transition-all text-sm"
                    style="box-shadow: 2px 2px 0px #000;"
                  >
                    CANCEL
                  </button>
                  <button
                    onclick={saveUsername}
                    disabled={!usernameAvailable ||
                      isSavingUsername ||
                      newUsername === user.username}
                    class="flex-1 bg-[#522785] text-white px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#6d3399] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-sm"
                    style="box-shadow: 2px 2px 0px #000;"
                  >
                    {isSavingUsername ? "SAVING..." : "SAVE"}
                  </button>
                </div>
              </div>
            {:else}
              <div
                class="bg-white border-4 border-black p-4 flex items-center justify-between"
                style="box-shadow: 4px 4px 0px #000;"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-12 h-12 bg-[#522785] border-2 border-black flex items-center justify-center text-white font-black text-xl"
                  >
                    {user.username[0].toUpperCase()}
                  </div>
                  <span class="text-2xl font-black text-black"
                    >@{user.username}</span
                  >
                </div>
                <button
                  onclick={startEditingUsername}
                  class="bg-[#29ABE2] text-black px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#1e88c7] transition-all text-sm"
                  style="box-shadow: 2px 2px 0px #000;"
                >
                  EDIT
                </button>
              </div>
            {/if}
          </div>

          <!-- Principal ID Section -->
          <div class="mb-6">
            <div class="bg-[#29ABE2] border-4 border-black p-1 mb-2">
              <div class="bg-black p-2 border-2 border-[#29ABE2]">
                <p class="text-xs font-black text-[#29ABE2] uppercase">
                  PRINCIPAL ID
                </p>
              </div>
            </div>

            <div
              class="bg-white border-4 border-black p-4 flex items-center justify-between gap-2"
              style="box-shadow: 4px 4px 0px #000;"
            >
              <code
                class="text-xs md:text-sm font-bold text-black truncate flex-1"
              >
                {principal}
              </code>
              <button
                onclick={() => copyToClipboard(principal, "principal")}
                class="bg-[#FBB03B] text-black px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#e09a2f] transition-all text-xs flex-shrink-0"
                style="box-shadow: 2px 2px 0px #000;"
              >
                {copiedField === "principal" ? "✓" : "COPY"}
              </button>
            </div>
          </div>

          <!-- Account ID Section -->
          <div class="mb-6">
            <div class="bg-[#522785] border-4 border-black p-1 mb-2">
              <div class="bg-black p-2 border-2 border-[#522785]">
                <p class="text-xs font-black text-[#522785] uppercase">
                  ACCOUNT ID
                </p>
              </div>
            </div>

            <div
              class="bg-white border-4 border-black p-4 flex items-center justify-between gap-2"
              style="box-shadow: 4px 4px 0px #000;"
            >
              <code
                class="text-xs md:text-sm font-bold text-black truncate flex-1"
              >
                {accountId}
              </code>
              <button
                onclick={() => copyToClipboard(accountId, "account")}
                class="bg-[#FBB03B] text-black px-3 py-2 font-black uppercase border-2 border-black hover:bg-[#e09a2f] transition-all text-xs flex-shrink-0"
                style="box-shadow: 2px 2px 0px #000;"
              >
                {copiedField === "account" ? "✓" : "COPY"}
              </button>
            </div>
          </div>

          <!-- Stats Section -->
          <div class="grid grid-cols-3 gap-4">
            <div class="bg-[#FBB03B] border-2 border-black p-4 text-center">
              <div class="text-3xl font-black text-black">{user.games}</div>
              <div class="text-xs font-bold text-black uppercase mt-1">
                Games
              </div>
            </div>
            <div class="bg-[#29ABE2] border-2 border-black p-4 text-center">
              <div class="text-3xl font-black text-black">{user.wins}</div>
              <div class="text-xs font-bold text-black uppercase mt-1">
                Wins
              </div>
            </div>
            <div class="bg-[#522785] border-2 border-black p-4 text-center">
              <div class="text-3xl font-black text-white">
                {(user.winRate * 100).toFixed(1)}%
              </div>
              <div class="text-xs font-bold text-white uppercase mt-1">
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
