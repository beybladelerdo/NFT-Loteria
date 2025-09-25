<script lang="ts">
  import MenuIcon from "$lib/icons/MenuIcon.svelte";

  interface Props {
    toggleMenu: () => void;
  }

  let { toggleMenu }: Props = $props();

  function handleMenuClick(event: MouseEvent) {
    event.stopPropagation();
    toggleMenu();
  }
</script>

<header
  class="z-30 flex items-center justify-between h-16 px-6 text-white shadow-md bg-BrandBlack/90"
>
  <div class="flex items-center gap-4">
    <button
      onclick={handleMenuClick}
      class="p-2 text-white transition-colors rounded-md bg-BrandBlack hover:bg-BrandBlack"
      aria-label="Toggle menu"
    >
      <MenuIcon className="w-6 h-6" fill="white" />
    </button>
  </div>
</header>
