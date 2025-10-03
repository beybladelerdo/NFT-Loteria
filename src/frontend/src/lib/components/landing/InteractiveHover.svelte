<script lang="ts">
  import { cn } from "$lib/util";
  import ArrowRight from 'lucide-svelte/icons/arrow-right';
  let _class: string = "";
  export { _class as class };
  export let text: string = "Button";
  export let onclick: ((event: MouseEvent) => void) | undefined = undefined;
</script>
<button
  class={cn(
    "group relative cursor-pointer overflow-hidden rounded-full border-2 border-[#d9ff5a] bg-black px-8 py-3 text-center font-semibold font-freigeist",
    _class
  )}
  onclick={onclick}
>
  <span
    class="inline-block transition-all duration-300 group-hover:opacity-0 text-white"
  >
    {text}
  </span>
  <div
    class="absolute inset-0 z-10 flex items-center justify-center gap-2 text-black opacity-0 transition-all duration-300 group-hover:opacity-100"
  >
    <span>{text}</span>
    <ArrowRight class="w-4 h-4" />
  </div>
  <div
    class="absolute left-1/2 top-1/2 h-2 w-2 -translate-x-1/2 -translate-y-1/2 scale-0 rounded-full bg-[#d9ff5a] transition-transform duration-300 ease-out group-hover:scale-[40]"
  ></div>
</button>