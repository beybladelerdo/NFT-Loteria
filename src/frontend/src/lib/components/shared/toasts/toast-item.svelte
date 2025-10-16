<script lang="ts">
  import { onMount } from "svelte";
  import { toasts } from "$lib/stores/toasts-store";
  import type { Toast } from "$lib/stores/toasts-store";
  import CloseIcon from "$lib/components/shared/toasts/close-toast.svelte";
  
  interface Props {
    toast: Toast;
  }
  
  let { toast }: Props = $props();
  let timer: ReturnType<typeof setTimeout> | null = null;
  let progress = $state(100);
  let progressInterval: ReturnType<typeof setInterval> | null = null;

  const duration = toast.duration ?? 3000;
  const type = toast.type ?? "info";

  const themeConfig = {
    success: {
      bg: "bg-[#00FF00]",
      border: "border-[#00FF00]",
      text: "text-black",
      icon: "✓",
      glow: "shadow-[0_0_20px_rgba(0,255,0,0.5)]"
    },
    error: {
      bg: "bg-[#ED1E79]",
      border: "border-[#ED1E79]",
      text: "text-white",
      icon: "✕",
      glow: "shadow-[0_0_20px_rgba(237,30,121,0.5)]"
    },
    info: {
      bg: "bg-[#29ABE2]",
      border: "border-[#29ABE2]",
      text: "text-white",
      icon: "ℹ",
      glow: "shadow-[0_0_20px_rgba(41,171,226,0.5)]"
    }
  };
  
  const theme = themeConfig[type];
  
  onMount(() => {
    if (duration > 0) {
      timer = setTimeout(closeToast, duration);

      const interval = 50;
      const decrement = (100 / duration) * interval;
      progressInterval = setInterval(() => {
        progress -= decrement;
        if (progress <= 0) {
          progress = 0;
          if (progressInterval) clearInterval(progressInterval);
        }
      }, interval);
    }
    
    return () => {
      if (timer) clearTimeout(timer);
      if (progressInterval) clearInterval(progressInterval);
    };
  });
  
  function closeToast() {
    toasts.removeToast(toast.id);
  }
</script>

<div class="w-full max-w-sm">
  <div class="bg-black border-4 border-black p-1 {theme.glow}">
    <div class="{theme.bg} border-b-2 border-black p-2 flex items-center justify-between">
      <div class="flex items-center gap-2">
        <div class="w-3 h-3 bg-white border border-black"></div>
        <span class="{theme.text} font-black text-xs uppercase tracking-wider">
          SYSTEM_{type.toUpperCase()}
        </span>
      </div>
      <button
        onclick={closeToast}
        class="w-5 h-5 bg-black border border-white hover:bg-white hover:text-black transition-colors flex items-center justify-center"
        aria-label="Close"
      >
        <CloseIcon className="w-3 h-3" />
      </button>
    </div>
    <div class="bg-white border-2 border-black p-4">
      <div class="flex items-start gap-3">
        <div class="{theme.bg} border-2 border-black w-10 h-10 flex items-center justify-center flex-shrink-0">
          <span class="{theme.text} font-black text-2xl">{theme.icon}</span>
        </div>
        <div class="flex-1 pt-1">
          <p class="text-black font-bold text-sm leading-tight">
            {toast.message}
          </p>
        </div>
      </div>
      {#if duration > 0}
        <div class="mt-3 h-2 bg-black border border-black relative overflow-hidden">
          <div 
            class="{theme.bg} h-full transition-all duration-50 ease-linear"
            style="width: {progress}%"
          ></div>
        </div>
      {/if}
    </div>
  </div>
</div>