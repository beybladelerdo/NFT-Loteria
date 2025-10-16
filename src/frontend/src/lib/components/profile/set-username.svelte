<script lang="ts">
  import { onMount } from "svelte";
  import { adjectives, nouns } from "$lib/constants/app.constants";
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
  <div class="flex items-center justify-center min-h-screen bg-[#ED1E79]">
    <Spinner />
  </div>
{:else}
  <div
    class="flex flex-col items-center justify-center min-h-screen px-4 bg-[#ED1E79] relative overflow-hidden"
  >
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
    <div
      class="absolute bottom-32 left-1/4 w-10 h-10 border-4 border-[#522785] rotate-12 opacity-40"
    ></div>

    <div class="w-full max-w-2xl relative z-10">
      <!-- Main Window -->
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
            CHOOSE_USERNAME.EXE
          </div>
          <div class="w-12"></div>
        </div>

        <div class="bg-white p-8 md:p-12 border-4 border-black">
          <!-- Header -->
          <div class="text-center mb-8">
            <h1
              class="text-4xl md:text-5xl font-black text-black uppercase mb-4"
              style="text-shadow: 3px 3px 0px #29ABE2;"
            >
              CHOOSE YOUR TAG
            </h1>
            <p
              class="text-base md:text-lg font-bold text-black max-w-xl mx-auto"
            >
              We've generated a unique username for you. Keep it or change
              it—your choice.
            </p>
          </div>

          <!-- Username Display -->
          <div class="mb-8">
            <div
              class="bg-black border-4 border-[#29ABE2] p-6 text-center"
              style="box-shadow: 6px 6px 0px #FBB03B;"
            >
              <p class="text-3xl md:text-4xl font-black text-[#29ABE2]">
                @{username}
              </p>
            </div>
          </div>

          <!-- Edit Section -->
          <div
            class="bg-[#FBB03B] border-4 border-black p-6 mb-6"
            style="box-shadow: 4px 4px 0px #000;"
          >
            <div class="space-y-4">
              <label
                for="username"
                class="block text-sm font-black text-black uppercase tracking-wider"
              >
                EDIT USERNAME
              </label>
              <input
                id="username"
                type="text"
                bind:value={username}
                oninput={handleUsernameInput}
                class="w-full px-4 py-3 text-lg bg-white border-4 border-black text-black placeholder-gray-500 focus:outline-none focus:border-[#522785] font-black uppercase"
                placeholder="YOUR-USERNAME"
              />

              {#if isEditing && username.length > 0}
                <div
                  class="text-sm font-bold bg-white border-2 border-black p-2"
                >
                  {#if isCheckingUsername}
                    <p class="text-black">CHECKING AVAILABILITY...</p>
                  {:else if usernameError}
                    <p class="text-red-600">{usernameError}</p>
                  {:else if usernameAvailable}
                    <p class="text-green-600">✓ USERNAME AVAILABLE</p>
                  {/if}
                </div>
              {/if}

              <p
                class="text-xs font-bold text-black bg-black/10 p-2 border-2 border-black"
              >
                5-20 CHARACTERS. YOU CAN CHANGE IT LATER.
              </p>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex flex-col sm:flex-row gap-4 justify-center">
            <button
              onclick={generateUsername}
              class="px-6 py-3 bg-[#29ABE2] text-black font-black uppercase border-4 border-black hover:bg-[#1e88c7] transition-all"
              style="box-shadow: 4px 4px 0px #000;"
            >
              GENERATE NEW
            </button>

            <button
              onclick={saveUsername}
              disabled={isEditing && (!usernameAvailable || isCheckingUsername)}
              class="px-8 py-3 bg-[#522785] text-white font-black uppercase border-4 border-black hover:bg-[#6d3399] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all"
              style="box-shadow: 4px 4px 0px #000;"
            >
              {isEditing ? "CONTINUE >>" : "SKIP >>"}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}
