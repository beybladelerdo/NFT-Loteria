<script lang="ts">
  import IcpLogo from "$lib/icons/ICPLogo.svelte";
  import { signIn } from "$lib/services/auth-services";
</script>

<div class="landing-container">
  <h1 class="landing-title">NFT Loteria</h1>

  <button class="brand-button" onclick={async () => await signIn({})}>
    <span class="flex items-center justify-center mr-2"><IcpLogo /></span>
    <span class="text-lg text-BrandText retro-text"
      >Sign in with Internet Identity</span
    >
  </button>
</div>
