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

  function formatWinRate(rate: number): string {
    return `${(rate * 100).toFixed(1)}%`;
  }
</script>

<div
  class="{isMenuOpen
    ? 'translate-x-0'
    : 'translate-x-full'} lg:hidden fixed inset-y-0 right-0 z-50 w-full sm:w-80 bg-[#ED1E79] border-l-4 border-black shadow-2xl transform transition-transform duration-300 ease-in-out"
>
  <!-- Window Title Bar -->
  <div
    class="bg-[#29ABE2] p-3 border-b-4 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <div class="w-4 h-4 bg-red-500 border-2 border-black"></div>
      <div class="w-4 h-4 bg-[#FBB03B] border-2 border-black"></div>
      <div class="w-4 h-4 bg-green-500 border-2 border-black"></div>
      <span class="ml-2 text-black font-black text-sm uppercase">MENU.EXE</span>
    </div>
    <button
      onclick={toggleMenu}
      class="p-1 bg-red-500 border-2 border-black hover:bg-red-600"
      aria-label="Close menu"
    >
      <svg
        class="w-4 h-4 stroke-white"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        stroke-width="4"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M6 18L18 6M6 6l12 12"
        />
      </svg>
    </button>
  </div>

  <!-- User Info Panel -->
  <div class="p-6 bg-white border-b-4 border-black">
    <div class="flex items-center gap-3">
      <div
        class="w-16 h-16 bg-[#522785] border-4 border-black flex items-center justify-center text-white font-black text-2xl"
        style="box-shadow: 4px 4px 0 #FBB03B;"
      >
        {user.username[0].toUpperCase()}
      </div>
      <div class="flex-1 min-w-0">
        <p
          class="text-black font-black truncate text-lg"
          style="text-shadow: 2px 2px 0px #29ABE2;"
        >
          @{user.username}
        </p>
        <div class="flex gap-2 mt-1 flex-wrap">
          <span
            class="text-xs bg-[#FBB03B] border border-black px-2 py-0.5 font-bold text-black"
          >
            {user.games} GAMES
          </span>
          <span
            class="text-xs bg-[#29ABE2] border border-black px-2 py-0.5 font-bold text-black"
          >
            {user.wins} WINS
          </span>
        </div>
      </div>
    </div>
  </div>

  <!-- Navigation Menu -->
  <nav class="p-4">
    <ul class="space-y-2">
      {#each menuItems as item}
        <li>
          <button
            onclick={() => navigate(item.path)}
            class="w-full text-left px-4 py-3 bg-white border-2 border-black font-bold text-black text-bold uppercase text-sm hover:bg-[#FBB03B] transition flex items-center justify-between"
            style="box-shadow: 3px 3px 0 #000;"
          >
            <span>{item.label}</span>
            <span>&gt;&gt;</span>
          </button>
        </li>
      {/each}
    </ul>
  </nav>

  <!-- Sign Out Button -->
  <div class="absolute bottom-6 left-4 right-4">
    <button
      onclick={handleSignOut}
      class="w-full px-4 py-4 bg-red-500 text-white border-4 border-black font-black uppercase hover:bg-red-600 transition"
      style="box-shadow: 4px 4px 0 #000;"
    >
      SIGN OUT
    </button>
  </div>
</div>
