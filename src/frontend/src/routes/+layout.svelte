<script lang="ts">
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { goto } from '$app/navigation';
  import { fade } from 'svelte/transition';
  import { authStore, type AuthStoreData } from '$lib/stores/auth-store';
  import { gameStore } from '$lib/stores/game-store';
  import { userStore, type Profile } from '$lib/stores/user-store';
  import { initAuthWorker } from '$lib/services/worker.auth.services';
  import { displayAndCleanLogoutMsg } from '$lib/services/auth-services';
  import Navbar from '$lib/components/Navbar.svelte';
  import FullScreenSpinner from '$lib/components/shared/FullScreenSpinner.svelte';
  import Toasts from '$lib/components/shared/Toasts.svelte';
  import Connect from '$lib/components/profile/Connect.svelte';
  import SetUsername from '$lib/components/profile/SetUsername.svelte';
  import '../app.css';

  interface Props {
    children: Snippet;
  }
  let { children }: Props = $props();

  let isLoading = $state(authStore.value.isLoading);
  let hasProfile = $state(false);
  let user: Profile | undefined = $state(undefined);
  let worker: { syncAuthIdle: (auth: AuthStoreData) => void } | undefined;

  async function init() {
    if (!browser) return;
    await authStore.sync();
    displayAndCleanLogoutMsg();
    if (authStore.value.isAuthenticated) {
      await gameStore.fetchOpenGames();
      await gameStore.fetchActiveGames();
      await gameStore.fetchAvailableTablas();
    }
  }

  async function checkProfile() {
    try {
      isLoading = true;
      user = await userStore.getProfile();
      hasProfile = user !== undefined;
    } catch (err) {
      console.error('Error fetching profile:', err);
    } finally {
      isLoading = false;
    }
  }

  $effect(() => {
    if (browser && !isLoading) {
      const protectedRoutes = [
        '/dashboard',
        '/join-game',
        '/host-game',
        '/tabla-rental/',
        '/game/play/',
        '/game/host/',
        '/wallet',
        '/ckbtc-minter',
        '/profile',
      ];
      const currentPath = window.location.pathname;
      const isProtected = protectedRoutes.some((route) => currentPath.startsWith(route));

      if (isProtected && !authStore.value.isAuthenticated) {
        goto('/');
      } else if (authStore.value.isAuthenticated && !user) {
        checkProfile();
      }
    }
  });

  onMount(async () => {
    if (browser) {
      document.querySelector('#app-spinner')?.remove();
      await init();
      worker = await initAuthWorker();
      if (authStore.value.identity) {
        await checkProfile();
      }
      isLoading = false;
    }
  });

  async function userCreated() {
    await checkProfile();
  }
</script>

<svelte:window on:storage={authStore.sync} />

{#if browser && isLoading}
  <div in:fade class="min-h-screen bg-gradient-to-br from-purple-900 via-fuchsia-800 to-orange-600 flex items-center justify-center">
    <FullScreenSpinner />
  </div>
{:else}
  {#if authStore.value.isAuthenticated}
    {#if !user}
      <SetUsername {userCreated} />
    {:else}
      {@render children()}
    {/if}
    <Toasts />
  {:else}
    <Connect />
  {/if}
{/if}