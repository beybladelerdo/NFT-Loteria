<script lang="ts">
  import { goto } from "$app/navigation";
  import { signOut } from "$lib/services/auth-services";
  import type { MenuItem } from "$lib/types/menu";

  interface Props {
    isMenuOpen: boolean;
    toggleMenu: () => void;
    hasProfile: boolean;
  }
  let { isMenuOpen, toggleMenu, hasProfile }: Props = $props();

  let menuRef: HTMLDivElement;

  async function handleDisconnect() {
    await signOut();
    goto("/", { replaceState: true });
  }

  const menuItems: MenuItem[] = hasProfile
    ? [
        { path: "/", label: "Messages" },
        { path: "/profile", label: "Profile" },
        { path: "/", label: "Sign Out" },
      ]
    : [{ path: "/", label: "Sign Out" }];
</script>

<div
  class="{isMenuOpen
    ? 'translate-x-0'
    : 'translate-x-full'} fixed bg-BrandSidebar border-l border-BrandBorder inset-y-0 right-0 z-40 w-full sm:w-80 shadow-2xl transform transition-transform duration-300 ease-in-out"
  bind:this={menuRef}
>
  <button
    onclick={toggleMenu}
    class="absolute p-2 transition rounded-full text-BrandText top-4 right-4 hover:bg-BrandSurface"
    aria-label="Close sidebar"
  >
    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M6 18L18 6M6 6l12 12"
      />
    </svg>
  </button>

  <nav class="h-full px-8 pt-20 text-lg text-BrandText">
    <ul class="space-y-4">
      {#each menuItems as item}
        <li>
          <a
            href={item.path}
            onclick={(e) => {
              e.preventDefault();
              toggleMenu();
              if (item.label === "Sign Out") {
                handleDisconnect();
              } else {
                goto(item.path);
              }
            }}
            class="block px-3 py-2 font-medium transition rounded retro-text hover:bg-BrandSurface hover:text-BrandHighlight"
          >
            {item.label}
          </a>
        </li>
      {/each}
    </ul>
  </nav>
</div>
