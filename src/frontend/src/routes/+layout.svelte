<script lang="ts">
  import { onMount, type Snippet } from "svelte"; 
  import { fade } from "svelte/transition";
  import { browser } from "$app/environment";
  import { initAuthWorker } from "$lib/services/worker.auth.services";
  import { authStore, type AuthStoreData } from "$lib/stores/auth-store";
  import { displayAndCleanLogoutMsg } from "$lib/services/auth-services";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { userStore } from "$lib/stores/user-store";
  import type { Profile } from "../../../declarations/backend/backend.did";
  import SetUsername from "$lib/components/profile/set-username.svelte";
  
  import Connect from "$lib/components/profile/connect.svelte";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Toasts from "$lib/components/shared/toasts/toasts.svelte";
  import { get } from "svelte/store";
  import Header from "$lib/shared/header.svelte";
  import Sidebar from "$lib/shared/sidebar.svelte";

  import "../app.css";
  
  interface Props { children: Snippet }
  let { children }: Props = $props();
    
  let worker: { syncAuthIdle: (auth: AuthStoreData) => void } | undefined;
  let isLoading = $state(true);
  let isMenuOpen = $state(false);
  let hasProfile = $state(false);
  let user: Profile | undefined = $state(undefined);

  const init = async () => {
    if (!browser) return;
    await authStore.sync();
    displayAndCleanLogoutMsg();
  };

  onMount(async () => {
    if (browser) {
      document.querySelector('#app-spinner')?.remove();
    }
    await init();
    worker = await initAuthWorker();
    const identity = get(authStore).identity;
    if (identity) {
      await checkProfile();
    }
    isLoading = false;
  });
  
  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
  }

  
	$effect(() => {
    if($authSignedInStore){
      checkProfile();
    }
	});

  async function checkProfile(){
    try {
      isLoading = true;
      user = await userStore.getProfile();
      hasProfile = user != undefined;
    } catch (err) {
      console.error('Error fetching profile:', err);
    } finally {
      isLoading = false;
    }
  }

  async function userCreated(){
    checkProfile();
  }

</script>

<svelte:window on:storage={authStore.sync} />

{#if browser && isLoading}
  <div in:fade>
    <Spinner />
  </div>
{:else}
  {#if $authSignedInStore}
    <Header {toggleMenu} />
    <Sidebar {toggleMenu} {isMenuOpen} {hasProfile} />
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