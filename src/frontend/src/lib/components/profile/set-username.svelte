<script lang="ts">
  import { onMount } from "svelte";
  import {adjectives, nouns} from  "$lib/constants/app.constants";
  import { isUsernameValid } from "$lib/utils/helpers";
  import { userStore } from "$lib/stores/user-store";
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
      await userStore.createProfile(username);
      await userCreated();
      goto("/");
    } catch (error) {
      console.error("Error creating profile:", error);
      usernameError = "Error creating profile. Please try again.";
    } finally {
      isLoading = false;
    }
  }
</script>

{#if isLoading}
  <div class="flex items-center justify-center min-h-screen bg-black">
    <Spinner />
  </div>
{:else}
  <div class="flex flex-col items-center justify-center min-h-screen px-4 bg-black">
    <div class="w-full max-w-2xl space-y-12">
      <!-- Header -->
      <div class="text-center space-y-6">
        <h1 class="text-5xl md:text-7xl font-bold text-white font-freigeist uppercase tracking-tight">
          Choose Your Tag.
        </h1>
        <p class="text-lg md:text-xl text-gray-400 font-freigeist max-w-xl mx-auto">
          We've generated a unique username for you. Keep it or change it—your choice.
        </p>
      </div>

      <!-- Username Display - Prominent but not oversized -->
<div class="text-center">
  <div class="inline-block bg-gradient-to-r from-violet-500 to-purple-500 p-1 rounded-xl">
    <div class="bg-black px-6 py-4 rounded-xl">
      <p class="text-3xl md:text-4xl font-bold text-white font-freigeist">
        @{username}
      </p>
    </div>
  </div>
</div>

      <!-- Edit Section -->
      <div class="bg-white/5 border border-white/10 rounded-2xl p-8 backdrop-blur-sm">
        <div class="space-y-6">
          <div class="space-y-3">
            <label
              for="username"
              class="block text-sm font-medium text-white font-freigeist uppercase tracking-wider"
            >
              Edit Username
            </label>
            <input
              id="username"
              type="text"
              bind:value={username}
              oninput={handleUsernameInput}
              class="w-full px-6 py-4 text-xl bg-black border-2 border-violet-500/50 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-violet-500 transition-colors font-freigeist"
              placeholder="your-username"
            />
            
            {#if isEditing && username.length > 0}
              <div class="text-sm font-freigeist">
                {#if isCheckingUsername}
                  <p class="text-gray-400">Checking availability...</p>
                {:else if usernameError}
                  <p class="text-red-400">{usernameError}</p>
                {:else if usernameAvailable}
                  <p class="text-violet-400">✓ Username available</p>
                {/if}
              </div>
            {/if}
            
            <p class="text-xs text-gray-500 font-freigeist">
              5-20 characters. You can change it later in settings.
            </p>
          </div>

          <button
            onclick={saveUsername}
            disabled={isEditing && (!usernameAvailable || isCheckingUsername)}
            class="w-full max-w-xs mx-auto block px-8 py-4 bg-violet-500 hover:bg-violet-400 disabled:bg-gray-700 disabled:cursor-not-allowed text-black disabled:text-gray-500 font-bold text-lg rounded-xl transition-all duration-200 font-freigeist uppercase tracking-wide"
          >
            {isEditing ? 'Continue' : 'Skip'}
          </button>
        </div>
      </div>
    </div>
  </div>
{/if}