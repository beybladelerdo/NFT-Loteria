<!-- src/routes/+layout.svelte -->
<script lang="ts">
  import { onMount, type Snippet } from "svelte";
  import "../app.css";
  import Toasts from "$lib/components/shared/toasts/toasts.svelte";

  interface Props { children: Snippet }
  let { children }: Props = $props();

  onMount(() => {
    document.querySelector('#app-spinner')?.remove();
  });
</script>

{@render children()}
<Toasts />
