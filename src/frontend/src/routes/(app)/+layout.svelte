<script lang="ts">
  import { onMount, type Snippet } from "svelte";
  import { fade } from "svelte/transition";
  import { browser } from "$app/environment";
  import { goto } from "$app/navigation";
  import { page } from "$app/state";
  import { initAuthWorker } from "$lib/services/worker.auth.services";
  import { authStore, type AuthStoreData } from "$lib/stores/auth-store";
  import {
    displayAndCleanLogoutMsg,
    signIn,
  } from "$lib/services/auth-services";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { userStore } from "$lib/stores/user-store";
  import type { Profile } from "../../../../declarations/backend/backend.did";
  import SetUsername from "$lib/components/profile/set-username.svelte";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Toasts from "$lib/components/shared/toasts/toasts.svelte";
  import { get } from "svelte/store";
  import Header from "$lib/components/shared/header.svelte";
  import Sidebar from "$lib/components/shared/sidebar.svelte";
  import GameReturnModal from "$lib/components/game/return-modal.svelte";
  import "../../app.css";

  interface Props {
    children: Snippet;
  }

  let { children }: Props = $props();

  let worker: { syncAuthIdle: (auth: AuthStoreData) => void } | undefined;
  let isLoading = $state(true);
  let isMenuOpen = $state(false);
  let hasProfile = $state(false);
  let user: Profile | undefined = $state(undefined);
  let isSigningIn = $state(false);
  let hasCheckedProfile = $state(false);
  let showGameReturnPrompt = $state(false);
  let activeGame: { gameId: string; role: "host" | "player" } | null =
    $state(null);

  const init = async () => {
    if (!browser) return;
    await authStore.sync();
    displayAndCleanLogoutMsg();
  };

  async function ensureSignedIn() {
    if (!browser) return;
    if (isSigningIn) return;

    if (!get(authSignedInStore)) {
      isSigningIn = true;
      isLoading = true;
      try {
        await signIn({});
        await checkProfile();
      } catch (e) {
        console.error("signIn failed", e);
      } finally {
        isSigningIn = false;
        isLoading = false;
      }
    }
  }

  onMount(async () => {
    if (browser) document.querySelector("#app-spinner")?.remove();
    await init();
    worker = await initAuthWorker();

    const identity = get(authStore).identity;
    if (!identity) {
      await ensureSignedIn();
      return;
    }

    await checkProfile();
  });

  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
  }

  $effect(() => {
    if (browser && $authSignedInStore && !hasCheckedProfile) {
      checkProfile();
    }
  });

  $effect(() => {
    if (browser && $authSignedInStore && hasProfile) {
      const currentPath = page.url.pathname;
      checkGameStatus(currentPath);
    }
  });

  async function checkProfile() {
    if (hasCheckedProfile) return;

    try {
      isLoading = true;
      console.log("🔍 Checking for existing profile...");
      user = await userStore.getProfile();
      hasProfile = user !== undefined;
      hasCheckedProfile = true;
      console.log(
        "✅ Profile check complete:",
        hasProfile ? "Found" : "Not found",
      );
    } catch (err) {
      console.error("Error fetching profile:", err);
      hasProfile = false;
      hasCheckedProfile = true;
    } finally {
      isLoading = false;
    }
  }

  async function checkGameStatus(currentPath: string) {
    try {
      console.log("🎮 Checking if user is in a game...");
      const result = await userStore.checkIfInGame();

      if (result.success && result.inGame && result.gameId && result.role) {
        activeGame = { gameId: result.gameId, role: result.role };

        const baseHostPath = `/game/host/${result.gameId}`;
        const basePlayPath = `/game/play/${result.gameId}`;

        const isOnHostPathForThisGame =
          currentPath === baseHostPath ||
          currentPath.startsWith(baseHostPath + "/");

        const isOnPlayPathForThisGame =
          currentPath === basePlayPath ||
          currentPath.startsWith(basePlayPath + "/");

        const isInCorrectPlace =
          (result.role === "host" && isOnHostPathForThisGame) ||
          (result.role === "player" && isOnPlayPathForThisGame);

        showGameReturnPrompt = !isInCorrectPlace;

        console.log(
          "✅ User is in game:",
          result.gameId,
          "as",
          result.role,
          "currentPath:",
          currentPath,
          "isInCorrectPlace:",
          isInCorrectPlace,
        );
      } else {
        activeGame = null;
        showGameReturnPrompt = false;
        console.log("✅ User is not in any active game");
      }
    } catch (err) {
      console.error("Error checking game status:", err);
      showGameReturnPrompt = false;
    }
  }

  function returnToGame() {
    if (activeGame) {
      const route =
        activeGame.role === "host"
          ? `/game/host/${activeGame.gameId}`
          : `/game/play/${activeGame.gameId}`;
      showGameReturnPrompt = false;
      goto(route);
    }
  }

  function dismissGamePrompt() {
    showGameReturnPrompt = false;
  }

  async function userCreated() {
    console.log("🎉 User created, refreshing profile...");
    hasCheckedProfile = false;
    await checkProfile();
  }
</script>

<svelte:window on:storage={authStore.sync} />

{#if browser && isLoading}
  <div in:fade>
    <Spinner />
  </div>
{:else if $authSignedInStore}
  {#if hasProfile && user}
    <Header {toggleMenu} {user} />
    <Sidebar {toggleMenu} {isMenuOpen} {user} />
    {@render children()}
    <GameReturnModal
      open={showGameReturnPrompt}
      {activeGame}
      onReturn={returnToGame}
      onDismiss={dismissGamePrompt}
    />
  {:else}
    <SetUsername {userCreated} />
  {/if}
  <Toasts />
{:else}
  <div in:fade>
    <Spinner />
  </div>
{/if}
