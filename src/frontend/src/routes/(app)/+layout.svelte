<script lang="ts">
  import { onMount, type Snippet } from "svelte";
  import { fade } from "svelte/transition";
  import { browser } from "$app/environment";
  import { goto } from "$app/navigation";
  import { page } from "$app/state";
  import { get } from "svelte/store";
  import { initAuthWorker } from "$lib/services/worker.auth.services";
  import { authStore, type AuthStoreData } from "$lib/stores/auth-store";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { userStore } from "$lib/stores/user-store";
  import {
    displayAndCleanLogoutMsg,
    signIn,
  } from "$lib/services/auth-services";
  import type { Profile } from "../../../../declarations/backend/backend.did";
  import Header from "$lib/components/shared/Header.svelte";
  import Sidebar from "$lib/components/shared/Sidebar.svelte";
  import Spinner from "$lib/components/shared/global/spinner.svelte";
  import Toasts from "$lib/components/shared/toasts/toasts.svelte";
  import SetUsername from "$lib/components/routes/profile/SetUsername.svelte";
  import GameReturnModal from "$lib/components/routes/game/ReturnModal.svelte";
  import { GameService } from "$lib/services/game-service";
  import { addToast } from "$lib/stores/toasts-store";
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
    if (!browser || isSigningIn) return;

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

  async function checkProfile() {
    if (hasCheckedProfile) return;

    try {
      isLoading = true;
      user = await userStore.getProfile();
      hasProfile = user !== undefined;
      hasCheckedProfile = true;
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
      } else {
        activeGame = null;
        showGameReturnPrompt = false;
      }
    } catch (err) {
      console.error("Error checking game status:", err);
      showGameReturnPrompt = false;
    }
  }

  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
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

  async function clearActiveGameOnStayHere() {
    if (!activeGame) return;

    const gameService = new GameService();
    let result:
      | {
          success: boolean;
          error?: string;
        }
      | undefined;

    if (activeGame.role === "host") {
      result = await gameService.terminateGame(activeGame.gameId);
    } else {
      result = await gameService.leaveGame(activeGame.gameId);
    }

    if (result?.success) {
      addToast({
        type: "success",
        message:
          activeGame.role === "host"
            ? "Game terminated. You’re no longer hosting a lobby."
            : "You left the game lobby.",
      });
      activeGame = null;
      showGameReturnPrompt = false;
    } else {
      addToast({
        type: "error",
        message:
          result?.error ??
          "Failed to update game. You may still be in an active lobby.",
      });
    }
  }

  async function dismissGamePrompt() {
    if (!activeGame) {
      showGameReturnPrompt = false;
      return;
    }

    if (!browser) {
      showGameReturnPrompt = false;
      return;
    }

    const actionVerb =
      activeGame.role === "host"
        ? "terminate this lobby for all players"
        : "leave this lobby";

    const confirmed = window.confirm(
      `You have an active game (${activeGame.gameId}).\n\n` +
        `If you stay here, we will ${actionVerb}.\n\n` +
        `Are you sure you want to continue?`,
    );

    if (!confirmed) {
      return;
    }

    await clearActiveGameOnStayHere();
  }

  async function userCreated() {
    hasCheckedProfile = false;
    await checkProfile();
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
