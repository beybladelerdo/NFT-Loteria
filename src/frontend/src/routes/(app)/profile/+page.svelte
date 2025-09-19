<script lang="ts">
  import EditUsernameModal from "$lib/components/profile/edit-username-modal.svelte";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import { userStore } from "$lib/stores/user-store";
  import { onMount } from "svelte";
  import type { Profile } from "../../../../../declarations/backend/backend.did";

  let isLoading = $state(true);
  let user: Profile | undefined = $state(undefined);
  let showEditUsernameModal = $state(false);

  onMount(async () => {
    try {
      user = await userStore.getProfile();
    } catch (error) {
      console.error("Profile fetch error:", error);
    } finally {
      isLoading = false;
    }
  });
</script>

{#if isLoading || !user}
  <Spinner />
{:else}
  <div
    class="flex items-center justify-center min-h-screen px-4 py-12 font-mono bg-BrandBackground text-BrandText"
  >
    <div
      class="flex flex-col items-center w-full max-w-md p-8 space-y-6 border rounded-lg shadow-lg bg-BrandSurface border-BrandBorder"
    >
      <h1 class="mb-2 text-3xl retro-text text-BrandHighlight">Profile</h1>
      <div class="w-full">
        <label
          for="profile-username"
          class="block mb-1 text-sm text-BrandSecondary">Username</label
        >
        <div
          class="flex items-center justify-between px-4 py-3 mb-4 border rounded-lg bg-BrandAccent border-BrandBorder"
        >
          <!--<span id="profile-username" class="text-lg font-semibold">{user.username}</span>-->
          <button
            onclick={() => (showEditUsernameModal = true)}
            class="px-3 py-1 ml-4 text-sm transition border rounded-lg border-BrandBorder bg-BrandSurface text-BrandHighlight hover:bg-BrandHighlight hover:text-BrandSurface"
          >
            Edit
          </button>
        </div>
      </div>
    </div>
    {#if showEditUsernameModal}
      <!--<EditUsernameModal username={user.username} onClose={() => { showEditUsernameModal = false; }} />-->
    {/if}
  </div>
{/if}
