<script lang="ts">
  interface Props {
    currentStep: 1 | 2 | 3;
  }

  let { currentStep }: Props = $props();

  const stepColors: Record<number, string> = {
    1: "bg-[#F4E04D]",
    2: "bg-[#C9B5E8]",
    3: "bg-[#FF6EC7]",
  };
</script>

<div class="flex items-center justify-center gap-2 sm:gap-4 mb-6 sm:mb-8">
  {#each [1, 2, 3] as step}
    <div class="flex items-center gap-2">
      <div
        class="w-8 h-8 sm:w-10 sm:h-10 {currentStep >= step
          ? stepColors[step]
          : 'bg-gray-600'} border-2 border-black flex items-center justify-center shadow-[2px_2px_0px_rgba(0,0,0,1)]"
      >
        <span class="text-[#1a0033] font-black text-sm sm:text-base"
          >{step}</span
        >
      </div>
    </div>
    {#if step < 3}
      <div
        class="w-6 sm:w-8 md:w-16 h-1 {currentStep > step
          ? 'bg-[#F4E04D]'
          : 'bg-gray-600'} border border-black"
      ></div>
    {/if}
  {/each}
</div>
