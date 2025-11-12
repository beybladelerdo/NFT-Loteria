<script lang="ts">
  import { goto } from "$app/navigation";
  import { signOut } from "$lib/services/auth-services";
  import SoundSettingsPopover from "$lib/components/sound/SoundSettingsPopover.svelte";

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
    { path: "/profile", label: "Wallet" },
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
  class="{isMenuOpen
    ? 'translate-x-0'
    : 'translate-x-full'} lg:hidden fixed inset-y-0 right-0 z-50 w-full sm:w-80 bg-gradient-to-b from-[#522785] to-[#3d1d63] border-l-4 border-black shadow-2xl transform transition-transform duration-300 ease-in-out"
>
  <!-- Window Title Bar -->
  <div
    class="bg-[#F4E04D] p-3 border-b-4 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <span class="ml-2 text-[#1a0033] font-black text-sm uppercase">MENU</span>
    </div>
    <button
      onclick={toggleMenu}
      class="p-1 bg-[#1a0033] border-2 border-black hover:bg-black"
      aria-label="Close menu"
    >
      <svg
        class="w-4 h-4 stroke-[#F4E04D]"
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
  <div class="p-6 bg-[#1a0033] border-b-4 border-black">
    <div class="flex items-center gap-3">
      <div
        class="w-16 h-16 bg-gradient-to-br from-[#F4E04D] to-[#C9B5E8] border-4 border-black flex items-center justify-center text-[#1a0033] font-black text-2xl"
        style="box-shadow: 4px 4px 0 #000;"
      >
        {user.username[0].toUpperCase()}
      </div>
      <div class="flex-1 min-w-0">
        <p
          class="text-[#F4E04D] font-black truncate text-lg"
          style="text-shadow: 2px 2px 0px #000;"
        >
          @{user.username}
        </p>
        <div class="flex gap-2 mt-1 flex-wrap">
          <span
            class="text-xs bg-[#F4E04D] border-2 border-black px-2 py-0.5 font-bold text-[#1a0033] shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
          >
            {user.games} GAMES
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
            class="w-full text-left px-4 py-3 bg-white border-2 border-black font-bold text-[#1a0033] uppercase text-sm hover:bg-[#F4E04D] hover:scale-105 transition flex items-center justify-between"
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
      class="w-full px-4 py-4 bg-[#F4E04D] text-[#1a0033] border-4 border-black font-black uppercase hover:bg-[#fff27d] hover:scale-105 transition"
      style="box-shadow: 4px 4px 0 #000;"
    >
      SIGN OUT
    </button>
  </div>
</div>
