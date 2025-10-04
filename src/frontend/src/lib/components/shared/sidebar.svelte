<script lang="ts">
  import { goto } from "$app/navigation";
  import { signOut } from "$lib/services/auth-services";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  
  interface Props {
    isMenuOpen: boolean;
    toggleMenu: () => void;
    user: Profile;
  }
  
  let { isMenuOpen, toggleMenu, user }: Props = $props();
  
  const menuItems = [
    { path: "/dashboard", label: "Dashboard" },
    { path: "/join-game", label: "Join Game" },
    { path: "/host-game", label: "Host Game" },
    { path: "/profile", label: "Profile" },
  ];
  
  async function handleSignOut() {
    await signOut();
    toggleMenu();
  }
  
  function navigate(path: string) {
    toggleMenu();
    goto(path);
  }
</script>

<div
  class="{isMenuOpen ? 'translate-x-0' : 'translate-x-full'} lg:hidden fixed inset-y-0 right-0 z-50 w-full sm:w-80 bg-black border-l border-white/10 shadow-2xl transform transition-transform duration-300 ease-in-out font-freigeist"
>
  <!-- Close Button -->
  <button
    onclick={toggleMenu}
    class="absolute top-4 right-4 p-2 text-white hover:bg-white/5 rounded-full transition"
    aria-label="Close menu"
  >
    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
    </svg>
  </button>
  
  <!-- User Info -->
  <div class="pt-16 px-6 pb-6 border-b border-white/10">
    <div class="flex items-center gap-3">
      <div class="w-12 h-12 rounded-full bg-violet-500 flex items-center justify-center text-black font-bold text-xl">
        {user.username[0].toUpperCase()}
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-white font-medium truncate">@{user.username}</p>
        <p class="text-sm text-gray-400">
          {user.games} games • {user.wins} wins
        </p>
      </div>
    </div>
  </div>
  
  <!-- Navigation -->
  <nav class="px-4 py-4">
    <ul class="space-y-1">
      {#each menuItems as item}
        <li>
          <button
            onclick={() => navigate(item.path)}
            class="w-full text-left px-4 py-3 text-white hover:bg-violet-500/20 rounded-lg transition font-medium"
          >
            {item.label}
          </button>
        </li>
      {/each}
    </ul>
  </nav>
  
  <!-- Sign Out -->
  <div class="absolute bottom-6 left-4 right-4">
    <button
      onclick={handleSignOut}
      class="w-full px-4 py-3 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-lg transition font-medium"
    >
      Sign Out
    </button>
  </div>
</div>