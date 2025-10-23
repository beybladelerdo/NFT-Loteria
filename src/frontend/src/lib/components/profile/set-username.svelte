<script lang="ts">
  import { onMount } from "svelte";
  import { adjectives, nouns } from "$lib/constants/app.constants";
  import { isUsernameValid } from "$lib/utils/helpers";
  import { userStore } from "$lib/stores/user-store";
  import FlickeringGrid from "$lib/components/landing/FlickeringGrid.svelte";
  import Spinner from "../shared/global/spinner.svelte";
  import { goto } from "$app/navigation";

  interface Props {
    userCreated: () => void;
  }

  let { userCreated }: Props = $props();

  let isLoading = $state(false);
  let username = $state("");
  let usernameAvailable = $state(true);
  let isCheckingUsername = $state(false);
  let usernameError = $state("");
  let usernameTimeout: NodeJS.Timeout;
  let isEditing = $state(false);

  onMount(() => {
    generateUsername();
  });

  function generateUsername() {
    const numbers = Array.from({ length: 90 }, (_, i) => String(i + 10));

    const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const noun = nouns[Math.floor(Math.random() * nouns.length)];
    const number = numbers[Math.floor(Math.random() * numbers.length)];

    username = `${adjective}-${noun}-${number}`;

    if (username.length < 5 || username.length > 20) {
      generateUsername();
    }
  }

  async function checkUsername() {
    isCheckingUsername = true;
    try {
      if (!isUsernameValid(username)) {
        usernameError = "Username must be between 5 and 20 characters.";
        usernameAvailable = false;
        return;
      }
      const available = await userStore.isTagAvailable(username);
      usernameAvailable = available;
      usernameError = available ? "" : "Username is already taken";
    } catch (error) {
      console.error("Error checking username:", error);
      usernameError = "Error checking username availability";
      usernameAvailable = false;
    } finally {
      isCheckingUsername = false;
    }
  }

  function handleUsernameInput() {
    clearTimeout(usernameTimeout);
    usernameAvailable = false;
    isEditing = true;

    if (username.length >= 5) {
      usernameTimeout = setTimeout(checkUsername, 500);
    }
  }

  async function saveUsername() {
    if (isEditing && !usernameAvailable) {
      return;
    }

    isLoading = true;
    try {
      console.log("💾 Attempting to create profile with username:", username);
      await userStore.createProfile(username);
      console.log("✅ Profile created successfully");
      await userCreated();
      goto("/dashboard");
    } catch (error: any) {
      console.error("Error creating profile:", error);

      // If profile already exists, just call userCreated to refresh
      if (
        error.message?.includes("Already exists") ||
        error.message?.includes("already exists")
      ) {
        console.log("ℹ️ Profile already exists, refreshing...");
        await userCreated();
        goto("/dashboard");
      } else {
        usernameError = "Error creating profile. Please try again.";
      }
    } finally {
      isLoading = false;
    }
  }
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-[#1a0033]">
    <Spinner />
  </div>
{:else}
  <div
    class="flex flex-col items-center justify-center min-h-screen px-4 bg-[#1a0033] relative overflow-hidden"
  >
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

    <div class="w-full max-w-2xl relative z-10">
      <!-- Main Card -->
      <div
        class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-8 md:p-12 border-4 border-black shadow-[8px_8px_0px_0px_rgba(0,0,0,0.8)]"
      >
        <!-- Header -->
        <div class="text-center mb-8">
          <h1
            class="text-4xl md:text-5xl font-black uppercase mb-4"
            style="text-shadow: 4px 4px 0px #000, -2px -2px 0px #000, 2px -2px 0px #000, -2px 2px 0px #000;"
          >
            <span class="text-[#F4E04D]">CHOOSE YOUR TAG</span>
          </h1>
          <p class="text-base md:text-lg font-bold text-white max-w-xl mx-auto">
            We've generated a unique username for you. Keep it or change it—your
            choice.
          </p>
        </div>

        <!-- Username Display -->
        <div class="mb-8">
          <div
            class="bg-[#1a0033] border-4 border-[#F4E04D] p-6 text-center shadow-[6px_6px_0px_0px_rgba(0,0,0,1)]"
          >
            <p
              class="text-3xl md:text-4xl font-black text-[#F4E04D]"
              style="text-shadow: 3px 3px 0px #000;"
            >
              @{username}
            </p>
          </div>
        </div>

        <!-- Edit Section -->
        <div
          class="bg-[#1a0033] border-4 border-black p-6 mb-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
        >
          <div class="space-y-4">
            <label
              for="username"
              class="block text-sm font-black text-[#C9B5E8] uppercase tracking-wider"
            >
              EDIT USERNAME
            </label>
            <input
              id="username"
              type="text"
              bind:value={username}
              oninput={handleUsernameInput}
              class="w-full px-4 py-3 text-lg bg-white border-4 border-black text-[#1a0033] placeholder-gray-500 focus:outline-none focus:border-[#F4E04D] font-black uppercase shadow-[3px_3px_0px_0px_rgba(0,0,0,1)]"
              placeholder="YOUR-USERNAME"
            />

            {#if isEditing && username.length > 0}
              <div
                class="text-sm font-bold bg-[#1a0033] border-2 border-[#C9B5E8] p-3 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
              >
                {#if isCheckingUsername}
                  <p class="text-[#C9B5E8]">CHECKING AVAILABILITY...</p>
                {:else if usernameError}
                  <p class="text-[#FF6EC7]">{usernameError}</p>
                {:else if usernameAvailable}
                  <p class="text-[#F4E04D]">✓ USERNAME AVAILABLE</p>
                {/if}
              </div>
            {/if}

            <p
              class="text-xs font-bold text-white bg-[#522785] p-3 border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
            >
              5-20 CHARACTERS. YOU CAN CHANGE IT LATER.
            </p>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <button
            onclick={generateUsername}
            class="px-6 py-3 bg-[#C9B5E8] text-[#1a0033] font-black uppercase border-4 border-black hover:bg-[#d9c9f0] hover:scale-105 transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            GENERATE NEW
          </button>

          <button
            onclick={saveUsername}
            disabled={isEditing && (!usernameAvailable || isCheckingUsername)}
            class="px-8 py-3 bg-[#F4E04D] text-[#1a0033] font-black uppercase border-4 border-black hover:bg-[#fff27d] hover:scale-105 disabled:bg-gray-400 disabled:cursor-not-allowed transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            {isEditing ? "CONTINUE >>" : "SKIP >>"}
          </button>
        </div>
      </div>
    </div>
  </div>
{/if}
