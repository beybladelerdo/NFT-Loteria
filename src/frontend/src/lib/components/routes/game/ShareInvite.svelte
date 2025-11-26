<script lang="ts">
  import { addToast } from "$lib/stores/toasts-store";

  interface Props {
    inviteLink: string;
  }

  let { inviteLink }: Props = $props();

  function copyInviteLink() {
    navigator.clipboard
      .writeText(inviteLink)
      .then(() =>
        addToast({
          message: "Invite link copied!",
          type: "success",
          duration: 2000,
        }),
      )
      .catch(() =>
        addToast({
          message: "Failed to copy link.",
          type: "error",
          duration: 2500,
        }),
      );
  }
</script>

<div class="arcade-panel p-4 sm:p-6">
  <div class="mb-3 sm:mb-4">
    <span class="arcade-badge bg-white"> Share Lobby </span>
  </div>

  <p
    class="text-xs font-bold text-white uppercase mb-3 sm:mb-4 leading-relaxed"
  >
    Share this invite link so friends can join your lobby. It copies instantly
    to your clipboard.
  </p>

  <div class="arcade-panel-sm px-2 sm:px-3 py-2 sm:py-3 space-y-2 sm:space-y-3">
    <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
      <input
        class="flex-1 bg-[#1a0033] border-2 border-black text-white text-xs font-mono px-2 py-2 min-w-0"
        readonly
        value={inviteLink}
      />
      <button
        class="arcade-button px-3 py-2 text-xs flex-shrink-0"
        onclick={copyInviteLink}
      >
        Copy
      </button>
    </div>
  </div>
</div>
