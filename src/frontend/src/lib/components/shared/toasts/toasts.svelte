<script lang="ts">
  import { toasts } from "$lib/stores/toasts-store";
  import ToastItem from "./toast-item.svelte";
  import { fly } from "svelte/transition";
</script>

<div
  class="pointer-events-none fixed top-6 right-6 z-[1000] flex flex-col gap-4 max-w-full"
>
  {#each $toasts as toast (toast.id)}
    <div class="pointer-events-auto" in:fly={{ y: 20, duration: 200 }}>
      <ToastItem {toast} />
    </div>
  {/each}
</div>
