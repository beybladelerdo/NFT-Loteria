<script lang="ts">
  import { isUsernameValid } from "$lib/utils/helpers";
  import { userStore } from "$lib/stores/user-store";
  import Spinner from "../shared/global/spinner.svelte";
  import Modal from "../shared/global/modal.svelte";

  interface Props {
    username: string;
    onClose: () => void;
  }
  let { username, onClose }: Props = $props();

  let isLoading = $state(false);
  let newUsername = $state(username);
  let usernameAvailable = $state(false);
  let isCheckingUsername = $state(false);
  let usernameError = $state("");
  let usernameTimeout: NodeJS.Timeout;

  async function checkUsername() {
    isCheckingUsername = true;
    try {
      if (!isUsernameValid(username)) {
        usernameError = "Username must be between 5 and 20 characters.";
      }
      const available = await userStore.isUsernameValid(username);
      usernameAvailable = available;
      usernameError = available ? "" : "Username is already taken";
    } catch (error) {
      console.error("Error checking username:", error);
      usernameError = "Error checking username availability";
    } finally {
      isCheckingUsername = false;
    }
  }

  function handleUsernameInput() {
    clearTimeout(usernameTimeout);
    usernameAvailable = false;
    if (username.length >= 5) {
      usernameTimeout = setTimeout(checkUsername, 500);
    }
  }

  async function saveUsername() {
    isLoading = true;
    try {
      await userStore.updateProfile(username);
    } catch {
      console.error("Error updating profile");
    } finally {
      isLoading = false;
    }
  }
</script>

<Modal title="Update Username" {onClose}>
  {#if isLoading}
    <Spinner />
  {:else}
    <form onsubmit={saveUsername} class="space-y-6">
      <div
        class="p-4 mb-4 border rounded-lg bg-BrandSurface border-BrandBorder"
      >
        <p class="mb-2 text-sm text-BrandSecondary">
          <span class="font-bold text-red-400">Warning:</span> Updating your
          username is a <span class="font-bold">destructive</span> action. Everything
          associated with the current username will be deleted.
        </p>
      </div>
      <div class="space-y-2">
        <label for="edit-username" class="form-label"
          >New Username <span class="text-red-500">*</span></label
        >
        <p class="text-xs text-BrandSecondary">5-20 characters</p>
        <input
          id="edit-username"
          type="text"
          bind:value={username}
          oninput={handleUsernameInput}
          class="username-input"
          placeholder="Enter new username"
        />
        {#if username.length > 0}
          <div class="mt-1 text-sm">
            {#if isCheckingUsername}
              <p class="text-BrandSecondary">Checking availability...</p>
            {:else if usernameError}
              <p class="text-red-500">{usernameError}</p>
            {:else if usernameAvailable}
              <p class="text-BrandHighlight">Username available</p>
            {/if}
          </div>
        {/if}
      </div>
      <hr class="my-4 border-BrandBorder opacity-60" />
      <div class="flex justify-end gap-2">
        <button type="button" class="cancel-button" onclick={onClose}
          >Cancel</button
        >
        <button type="submit" class="send-button">Save Username</button>
      </div>
    </form>
  {/if}
</Modal>
