<div class="fixed inset-0 z-50 flex items-center justify-center bg-black">
  <!-- CRT Scanlines Effect -->
  <div class="absolute inset-0 opacity-10 pointer-events-none">
    <div class="h-full w-full scanlines"></div>
  </div>

  <div class="relative flex flex-col items-center gap-8">
    <div class="flex flex-col items-center gap-2">
      <div class="flex items-center gap-1">
        <span
          class="text-[#29ABE2] font-black text-2xl uppercase tracking-wider"
          >LOADING</span
        >
        <span class="text-[#FBB03B] font-black text-2xl animate-pulse">█</span>
        <span
          class="text-[#FBB03B] font-black text-2xl animate-pulse pulse-delay-1"
          >█</span
        >
        <span
          class="text-[#FBB03B] font-black text-2xl animate-pulse pulse-delay-2"
          >█</span
        >
      </div>

      <!-- Retro Progress Bar -->
      <div
        class="w-64 h-4 border-2 border-[#29ABE2] bg-black relative overflow-hidden"
      >
        <div
          class="absolute inset-0 bg-gradient-to-r from-[#522785] via-[#FBB03B] to-[#29ABE2] progress-bar"
        ></div>
      </div>

      <!-- System Status -->
      <div class="mt-4 border-2 border-[#FF6EC7] bg-black px-4 py-2">
        <p class="text-[#FF6EC7] font-mono text-sm">
          <span class="animate-pulse">▶</span> SYSTEM INITIALIZING...
        </p>
      </div>
    </div>
  </div>
</div>

<style>
  .scanlines {
    background: repeating-linear-gradient(
      0deg,
      rgba(0, 0, 0, 0.15),
      rgba(0, 0, 0, 0.15) 1px,
      transparent 1px,
      transparent 2px
    );
  }

  .progress-bar {
    animation: slide 2s ease-in-out infinite;
  }

  .pulse-delay-1 {
    animation-delay: 0.2s;
  }

  .pulse-delay-2 {
    animation-delay: 0.4s;
  }

  @keyframes spin {
    0% {
      transform: rotate(0deg);
    }
    100% {
      transform: rotate(360deg);
    }
  }

  @keyframes spin-reverse {
    from {
      transform: rotate(360deg);
    }
    to {
      transform: rotate(0deg);
    }
  }

  @keyframes slide {
    0%,
    100% {
      transform: translateX(-100%);
    }
    50% {
      transform: translateX(100%);
    }
  }
</style>
