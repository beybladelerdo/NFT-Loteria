<script lang="ts">
  import { goto } from "$app/navigation";
  import { authStore } from "$lib/stores/auth-store";

  let mobileMenuOpen = $state(false);

  async function handleLogin() {
    await authStore.signIn({});
    if (authStore.value.isAuthenticated) {
      goto("/dashboard");
    }
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
        class="w-10 h-10 rounded-full bg-white flex items-center justify-center text-purple-900 font-bold"
      >
        LC
      </div>
      <h1 class="text-2xl font-bold text-white ml-2">Crypto Lotería</h1>
    </a>
  </div>

  <!-- Mobile menu button -->
  <div class="md:hidden">
    <button onclick={toggleMobileMenu} class="text-white p-2">
      {#if mobileMenuOpen}
        <!--<X size={24} />-->
      {:else}
        <!--<Menu size={24} />-->
      {/if}
    </button>
  </div>

  <!-- Desktop navigation -->
  <div class="hidden md:flex items-center space-x-4">
    {#if authStore.value.isAuthenticated}
      <a href="/dashboard" class="text-white hover:text-purple-300 transition">
        Dashboard
      </a>
      <a href="/join-game" class="text-white hover:text-purple-300 transition">
        Join Game
      </a>
      <a href="/host-game" class="text-white hover:text-purple-300 transition">
        Host Game
      </a>
      <div class="flex items-center ml-2">
        <div
          class="text-white bg-white bg-opacity-20 rounded-full px-3 py-1 mr-2 flex items-center"
        >
          <!--<User size={16} class="mr-1" />-->
          {formatPrincipal(
            authStore.value.identity?.getPrincipal().toString() ?? null,
          )}
        </div>
        <a
          href="/wallet"
          class="bg-white bg-opacity-20 hover:bg-opacity-30 text-white rounded-full px-4 py-2 transition flex items-center"
        >
          <!--<Wallet size={18} class="mr-2" />-->
          My Wallet
        </a>
        <button
          onclick={handleLogout}
          class="ml-2 bg-red-500 hover:bg-red-600 text-white rounded-full px-3 py-2 transition flex items-center"
        >
          <!--<LogIn size={18} class="transform rotate-180" />-->
        </button>
      </div>
    {:else}
      <button
        onclick={handleLogin}
        class="bg-blue-600 hover:bg-blue-700 text-white rounded-full px-4 py-2 transition flex items-center"
      >
        <!--<LogIn size={18} class="mr-2" />-->
        Connect with Internet Identity
      </button>
    {/if}
  </div>

  <!-- Mobile menu -->
  {#if mobileMenuOpen}
    <div
      class="absolute top-16 left-0 right-0 bg-gradient-to-b from-purple-900 to-fuchsia-800 p-4 z-50 md:hidden"
    >
      {#if authStore.value.isAuthenticated}
        <div class="flex flex-col space-y-4">
          <a
            href="/dashboard"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition"
            onclick={() => (mobileMenuOpen = false)}
          >
            Dashboard
          </a>
          <a
            href="/join-game"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition"
            onclick={() => (mobileMenuOpen = false)}
          >
            Join Game
          </a>
          <a
            href="/host-game"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition"
            onclick={() => (mobileMenuOpen = false)}
          >
            Host Game
          </a>
          <a
            href="/wallet"
            class="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition flex items-center"
            onclick={() => (mobileMenuOpen = false)}
          >
            <!--<Wallet size={18} class="mr-2" />-->
            My Wallet
          </a>
          <button
            onclick={handleLogout}
            class="bg-red-500 hover:bg-red-600 text-white py-2 px-4 rounded transition flex items-center justify-center"
          >
            <!--<LogIn size={18} class="mr-2 transform rotate-180" />-->
            Sign Out
          </button>
        </div>
      {:else}
        <button
          onclick={handleLogin}
          class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded transition flex items-center justify-center"
        >
          <!--<LogIn size={18} class="mr-2" />-->
          Connect with Internet Identity
        </button>
      {/if}
    </div>
  {/if}
</header>
