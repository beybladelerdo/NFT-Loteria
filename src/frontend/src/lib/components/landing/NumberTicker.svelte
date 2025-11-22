<script lang="ts">
  import { cubicOut } from "svelte/easing";
  import { onMount } from "svelte";
  import { tweened } from "svelte/motion";
  import { cn } from "$lib/util";

  export let value = 0;
  export let initial = 0;
  export let duration = 2000;
  export let decimalPlaces = 0;
  let className: any = "";
  export { className as class };

  let num = tweened(initial, {
    duration: duration,
    easing: cubicOut,
  });

  onMount(() => {
    num.set(value);
  });

  $: num.set(value);
</script>

<span class={cn("inline-block tracking-normal", className)} {...$$restProps}>
  {decimalPlaces > 0
    ? $num.toFixed(decimalPlaces)
    : Math.floor($num).toLocaleString()}
</span>
