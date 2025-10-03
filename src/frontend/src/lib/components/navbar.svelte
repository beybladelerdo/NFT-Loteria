<script lang="ts">
  import { goto } from "$app/navigation";
  import { authStore } from "$lib/stores/auth-store";
  import { authSignedInStore } from "$lib/derived/auth.derived";

  let mobileMenuOpen = $state(false);

  async function handleLogin() {
    await authStore.signIn({});
  }

  async function handleLogout() {
    await authStore.signOut();
    goto("/");
  }

  function toggleMobileMenu() {
    mobileMenuOpen = !mobileMenuOpen;
  }

  function formatPrincipal(principal: string | null): string {
    if (!principal) return "";
    const text = principal;
    return text.substring(0, 5) + "..." + text.substring(text.length - 5);
  }
</script>

<header class="flex justify-between items-center p-4 bg-black bg-opacity-30">
  <div class="flex items-center">
    <a href="/" class="flex items-center">
      <div
        class="w-10 h-10 rounded-full bg-white flex items-center justify-center text-purple-900 font-bold font-freigeist"
      >
        LC
      </div>
      <h1 class="text-2xl font-bold text-white ml-2 font-freigeist">Crypto Lotería</h1>
    </a>
  </div>

  <!-- Mobile menu button - only show on small screens -->
  <div class="lg:hidden">
    <button onclick={toggleMobileMenu} class="text-white p-2">
      {#if mobileMenuOpen}
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      {:else}
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      {/if}
    </button>
  </div>

  <!-- Desktop navigation - show on large screens -->
  <div class="hidden lg:flex items-center space-x-4">
    {#if $authSignedInStore}
      <a href="/dashboard" class="text-white hover:text-violet-400 transition font-freigeist">
        Dashboard
      </a>
      <a href="/join-game" class="text-white hover:text-violet-400 transition font-freigeist">
        Join Game
      </a>
      <a href="/host-game" class="text-white hover:text-violet-400 transition font-freigeist">
        Host Game
      </a>
      <div class="flex items-center ml-2">
        <div
          class="text-white bg-white bg-opacity-20 rounded-full px-3 py-1 mr-2 flex items-center font-freigeist"
        >
          {formatPrincipal(
            $authStore.identity?.getPrincipal().toString() ?? null
          )}
        </div>
        
         <a href="/wallet"
          class="bg-white bg-opacity-20 hover:bg-opacity-30 text-white rounded-full px-4 py-2 transition flex items-center font-freigeist"
        >
          My Wallet
        </a>
        <button
          onclick={handleLogout}
          class="ml-2 bg-violet-500 hover:bg-violet-600 text-black font-bold rounded-full px-4 py-2 transition font-freigeist"
        >
          Sign Out
        </button>
      </div>
    {:else}
      <button
        onclick={handleLogin}
        class="bg-violet-500 hover:bg-violet-600 text-black font-bold rounded-full px-6 py-2 transition font-freigeist uppercase tracking-wide"
      >
        Connect with Internet Identity
      </button>
    {/if}
  </div>

  <!-- Mobile menu -->
  {#if mobileMenuOpen}
    <div
      class="absolute top-16 left-0 right-0 bg-black bg-opacity-95 p-4 z-50 lg:hidden border-b border-violet-500/20"
    >
      {#if $authSignedInStore}
        <div class="flex flex-col space-y-4">
          
          <a  href="/dashboard"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition font-freigeist"
            onclick={() => (mobileMenuOpen = false)}
          >
            Dashboard
          </a>
          
           <a href="/join-game"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition font-freigeist"
            onclick={() => (mobileMenuOpen = false)}
          >
            Join Game
          </a>
          
           <a href="/host-game"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition font-freigeist"
            onclick={() => (mobileMenuOpen = false)}
          >
            Host Game
          </a>
          
          <a  href="/wallet"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition font-freigeist"
            onclick={() => (mobileMenuOpen = false)}
          >
            My Wallet
          </a>
          <button
            onclick={handleLogout}
            class="bg-violet-500 hover:bg-violet-600 text-black font-bold py-2 px-4 rounded transition font-freigeist"
          >
            Sign Out
          </button>
        </div>
      {:else}
        <button
          onclick={handleLogin}
          class="w-full bg-violet-500 hover:bg-violet-600 text-black font-bold py-2 px-4 rounded transition font-freigeist uppercase tracking-wide"
        >
          Connect with Internet Identity
        </button>
      {/if}
    </div>
  {/if}
</header>