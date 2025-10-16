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
    tabs.findIndex((tab) => $page.url.pathname.startsWith(tab.path)),
  );

  async function handleSignOut() {
    await signOut();
    showDropdown = false;
  }

  function closeDropdown(event: MouseEvent) {
    if (!(event.target as Element).closest(".dropdown-container")) {
      showDropdown = false;
    }
  }
</script>

<svelte:window onclick={closeDropdown} />

<header
  class="sticky top-0 z-50 bg-[#ED1E79] border-b-4 border-black"
  style="box-shadow: 0 4px 0 0 #29ABE2;"
>
  <div
    class="flex items-center justify-between h-16 px-4 md:px-6 max-w-7xl mx-auto"
  >
    <!-- Logo -->
    <a href="/" class="flex items-center gap-2">
      <div
        class="w-10 h-10 bg-black border-4 border-[#29ABE2] flex items-center justify-center font-black text-sm"
        style="box-shadow: 3px 3px 0 #FBB03B;"
      >
        <span class="text-[#29ABE2]">NL</span>
      </div>
      <span
        class="hidden sm:block text-xl font-black text-black uppercase tracking-tight"
        style="text-shadow: 2px 2px 0px #29ABE2;"
      >
        NFT LOTERÍA
      </span>
    </a>

    <!-- Desktop Navigation - Retro Tabs -->
    <nav class="hidden lg:block">
      <div class="relative flex items-center gap-2">
        <AnimateSharedLayout>
          {#each tabs as tab, i}
            <button
              class="group relative z-[1] px-4 py-2 font-black uppercase text-xs border-2 border-black {activeIdx ===
              i
                ? 'z-0'
                : 'bg-white'}"
              onclick={() => goto(tab.path)}
              style="box-shadow: 3px 3px 0 #000;"
            >
              {#if activeIdx === i}
                <Motion
                  layoutId="active-tab"
                  transition={{
                    duration: 0.2,
                    type: "spring",
                    stiffness: 300,
                    damping: 30,
                  }}
                  let:motion
                >
                  <div use:motion class="absolute inset-0 bg-[#FBB03B]"></div>
                </Motion>
              {/if}
              <span class="relative text-black">
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
        onclick={(e) => {
          e.stopPropagation();
          showDropdown = !showDropdown;
        }}
        class="flex items-center gap-2 px-3 py-2 bg-[#29ABE2] border-2 border-black hover:bg-[#FBB03B] transition"
        style="box-shadow: 3px 3px 0 #000;"
      >
        <div
          class="w-8 h-8 bg-[#522785] border-2 border-black flex items-center justify-center text-white font-black text-sm"
        >
          {user.username[0].toUpperCase()}
        </div>
        <span class="text-sm text-black font-black">@{user.username}</span>
        <svg
          class="w-4 h-4 text-black transition-transform {showDropdown
            ? 'rotate-180'
            : ''}"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="3"
            d="M19 9l-7 7-7-7"
          />
        </svg>
      </button>

      {#if showDropdown}
        <div
          class="absolute right-0 mt-2 w-56 bg-white border-4 border-black shadow-xl overflow-hidden"
          style="box-shadow: 6px 6px 0 #000;"
        >
          <div class="px-4 py-3 bg-[#29ABE2] border-b-2 border-black">
            <p class="text-xs text-black font-bold uppercase">Signed in as</p>
            <p class="text-sm font-black text-black truncate">
              @{user.username}
            </p>
          </div>

          <a
            href="/profile"
            class="block px-4 py-3 text-sm font-bold text-black hover:bg-[#FBB03B] transition border-b-2 border-black"
            onclick={() => (showDropdown = false)}
          >
            VIEW PROFILE &gt;&gt;
          </a>
          <button
            onclick={handleSignOut}
            class="w-full text-left px-4 py-3 text-sm font-bold bg-red-500 text-white hover:bg-red-600 transition"
          >
            SIGN OUT
          </button>
        </div>
      {/if}
    </div>

    <!-- Mobile Menu Button -->
    <button
      onclick={toggleMenu}
      class="lg:hidden p-2 bg-[#29ABE2] border-2 border-black"
      style="box-shadow: 3px 3px 0 #000;"
      aria-label="Toggle menu"
    >
      <svg
        class="w-6 h-6 stroke-black"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        stroke-width="3"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M4 6h16M4 12h16M4 18h16"
        />
      </svg>
    </button>
  </div>
</header>
