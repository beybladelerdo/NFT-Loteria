<script lang="ts">
  import { onMount } from "svelte";
  import { toasts } from "$lib/stores/toasts-store";
  import type { Toast } from "$lib/stores/toasts-store";

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
      bg: "bg-green-500",
      border: "border-green-500",
      text: "text-white",
      icon: "✓",
      progressBg: "bg-green-500",
    },
    error: {
      bg: "bg-red-500",
      border: "border-red-500",
      text: "text-white",
      icon: "✕",
      progressBg: "bg-red-500",
    },
    info: {
      bg: "bg-[#C9B5E8]",
      border: "border-[#C9B5E8]",
      text: "text-[#1a0033]",
      icon: "ℹ",
      progressBg: "bg-[#C9B5E8]",
    },
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
  <div class="arcade-panel-sm p-3">
    <div class="flex items-center justify-between mb-2">
      <div class="flex items-center gap-2">
        <div
          class="{theme.bg} border-2 border-black w-6 h-6 flex items-center justify-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
        >
          <span class="{theme.text} font-black text-lg leading-none"
            >{theme.icon}</span
          >
        </div>
        <span
          class="{theme.bg} {theme.text} px-2 py-1 font-black text-[10px] uppercase border-2 border-black shadow-[2px_2px_0px_rgba(0,0,0,1)]"
        >
          {type}
        </span>
      </div>
      <button
        onclick={closeToast}
        class="w-6 h-6 bg-white text-[#1a0033] border-2 border-black hover:bg-[#F4E04D] transition-colors flex items-center justify-center shadow-[2px_2px_0px_rgba(0,0,0,1)] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_rgba(0,0,0,1)] font-black text-sm"
        aria-label="Close"
      >
        ✕
      </button>
    </div>

    <p class="text-white font-bold text-sm leading-snug mb-3 break-words">
      {toast.message}
    </p>

    {#if duration > 0}
      <div
        class="h-2 bg-[#1a0033] border-2 border-black relative overflow-hidden shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <div
          class="{theme.progressBg} h-full transition-all duration-50 ease-linear"
          style="width: {progress}%"
        ></div>
      </div>
    {/if}
  </div>
</div>
