<script lang="ts">
  import { Motion, AnimateSharedLayout } from "svelte-motion";
  import { page } from "$app/stores";
  import { goto } from "$app/navigation";
  import { signOut } from "$lib/services/auth-services";
  import type { Profile } from "../../../../../declarations/backend/backend.did";
  
  interface Props {
    toggleMenu: () => void;
    user: Profile;
  }
  
  let { toggleMenu, user }: Props = $props();
  let showDropdown = $state(false);
  
  const tabs = [
    { title: "Dashboard", path: "/dashboard" },
    { title: "Join Game", path: "/join-game" },
    { title: "Host Game", path: "/host-game" },
  ];
  
  let activeIdx = $derived(
    tabs.findIndex(tab => $page.url.pathname.startsWith(tab.path))
  );
  
  async function handleSignOut() {
    await signOut();
    showDropdown = false;
  }
  
  function closeDropdown(event: MouseEvent) {
    if (!(event.target as Element).closest('.dropdown-container')) {
      showDropdown = false;
    }
  }
</script>

<svelte:window onclick={closeDropdown} />

<header class="sticky top-0 z-50 bg-black border-b border-white/10 font-freigeist">
  <div class="flex items-center justify-between h-16 px-4 md:px-6 max-w-7xl mx-auto">
    <!-- Logo -->
    <a href="/" class="flex items-center gap-2">
      <div class="w-8 h-8 rounded-full bg-violet-500 flex items-center justify-center text-black font-bold text-sm">
        NL
      </div>
      <span class="hidden sm:block text-lg font-bold text-white">NFT Lotería</span>
    </a>
    
    <!-- Desktop Navigation - Animated Tabs -->
    <nav class="hidden lg:block">
      <div class="relative flex items-center gap-1 px-1 py-1 rounded-full bg-white/5">
        <AnimateSharedLayout>
          {#each tabs as tab, i}
            <button
              class="group relative z-[1] rounded-full px-4 py-2 {activeIdx === i ? 'z-0' : ''}"
              onclick={() => goto(tab.path)}
            >
              {#if activeIdx === i}
                <Motion
                  layoutId="active-tab"
                  transition={{ duration: 0.2, type: 'spring', stiffness: 300, damping: 30 }}
                  let:motion
                >
                  <div
                    use:motion
                    class="absolute inset-0 rounded-full bg-violet-500"
                  ></div>
                </Motion>
              {/if}
              <span
                class="relative text-sm font-medium duration-200 {activeIdx === i
                  ? 'text-black'
                  : 'text-white hover:text-violet-400'}"
              >
                {tab.title}
              </span>
            </button>
          {/each}
        </AnimateSharedLayout>
      </div>
    </nav>
    
    <!-- User Menu (Desktop) -->
    <div class="hidden lg:block relative dropdown-container">
      <button
        onclick={(e) => { e.stopPropagation(); showDropdown = !showDropdown; }}
        class="flex items-center gap-2 px-3 py-2 rounded-full bg-white/5 hover:bg-white/10 transition"
      >
        <div class="w-8 h-8 rounded-full bg-violet-500 flex items-center justify-center text-black font-bold text-sm">
          {user.username[0].toUpperCase()}
        </div>
        <span class="text-sm text-white">@{user.username}</span>
        <svg class="w-4 h-4 text-white transition-transform {showDropdown ? 'rotate-180' : ''}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      
      {#if showDropdown}
        <div class="absolute right-0 mt-2 w-48 rounded-lg bg-black border border-white/20 shadow-xl py-1 overflow-hidden">
          <div class="px-4 py-3 border-b border-white/10">
            <p class="text-sm text-gray-400">Signed in as</p>
            <p class="text-sm font-medium text-white truncate">@{user.username}</p>
          </div>
          
           <a href="/profile"
            class="block px-4 py-2 text-sm text-white hover:bg-white/5 transition"
            onclick={() => showDropdown = false}
          >
            View Profile
          </a>
          <button
            onclick={handleSignOut}
            class="w-full text-left px-4 py-2 text-sm text-red-400 hover:bg-white/5 transition"
          >
            Sign Out
          </button>
        </div>
      {/if}
    </div>
    
    <!-- Mobile Menu Button -->
    <button
      onclick={toggleMenu}
      class="lg:hidden p-2 text-white hover:bg-white/5 rounded-lg transition"
      aria-label="Toggle menu"
    >
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
      </svg>
    </button>
  </div>
</header>