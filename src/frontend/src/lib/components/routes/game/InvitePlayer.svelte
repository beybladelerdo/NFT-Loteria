<script lang="ts">
  import { UserService } from "$lib/services/user-service";
  import { addToast } from "$lib/stores/toasts-store";

  interface Props {
    gameId: string;
    gameLink: string;
  }

  let { gameId, gameLink }: Props = $props();

  let playerTag = $state("");
  let isChecking = $state(false);
  let invitedPlayers = $state<string[]>([]);

  const gameService = new UserService();

  async function checkAndInvite() {
    if (!playerTag.trim()) {
      addToast({
        message: "Please enter a player tag",
        type: "error",
        duration: 3000,
      });
      return;
    }

    isChecking = true;

    try {
      const isAvailable = await gameService.isTagAvailable(playerTag);

      if (isAvailable) {
        addToast({
          message: `Player "${playerTag}" not found`,
          type: "error",
          duration: 3000,
        });
        isChecking = false;
        return;
      }
      await navigator.clipboard.writeText(gameLink);

      invitedPlayers = [...invitedPlayers, playerTag];

      addToast({
        message: `Invite link copied! Share with ${playerTag}`,
        type: "success",
        duration: 3000,
      });

      playerTag = "";
    } catch (error) {
      console.error("Invite error:", error);
      addToast({
        message: "Error checking player",
        type: "error",
        duration: 3000,
      });
    } finally {
      isChecking = false;
    }
  }

  function removeInvited(tag: string) {
    invitedPlayers = invitedPlayers.filter((t) => t !== tag);
  }
</script>

<div class="space-y-4">
  <div
    class="bg-[#1a0033] border-4 border-black p-4 shadow-[6px_6px_0px_rgba(0,0,0,0.6)]"
  >
    <p class="text-[#C9B5E8] font-black text-xs uppercase tracking-[0.2em]">
      Share Invite Link
    </p>
    <p class="text-white font-bold text-xs uppercase mt-2 leading-relaxed">
      Copy the lobby link below to invite players directly. You can also search
      by username using the quick helper.
    </p>
    <div
      class="mt-4 flex flex-col sm:flex-row sm:items-center gap-3 bg-[#24084c] border-2 border-black p-3"
    >
      <code
        class="flex-1 bg-[#1a0033] border-2 border-black text-[#F4E04D] font-mono text-xs px-3 py-2 break-all"
      >
        {gameLink}
      </code>
      <button
        class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-4 py-2 font-black uppercase text-xs shadow-[3px_3px_0px_rgba(0,0,0,1)] hover:bg-[#fff27d]"
        onclick={async () => {
          await navigator.clipboard.writeText(gameLink);
          addToast({
            message: "Invite link copied!",
            type: "success",
            duration: 2000,
          });
        }}
      >
        Copy
      </button>
    </div>
  </div>

  <div
    class="bg-[#1a0033] border-4 border-black p-4 shadow-[6px_6px_0px_rgba(0,0,0,0.6)] space-y-3"
  >
    <p class="text-[#F4E04D] font-black text-xs uppercase tracking-[0.2em]">
      Invite By Tag
    </p>
    <div class="flex flex-col sm:flex-row gap-3">
      <input
        type="text"
        bind:value={playerTag}
        onkeydown={(e) => e.key === "Enter" && checkAndInvite()}
        placeholder="Enter username..."
        class="flex-1 px-3 py-2 border-2 border-black font-bold text-sm uppercase bg-white focus:outline-none focus:border-[#29ABE2]"
      />
      <button
        onclick={checkAndInvite}
        disabled={isChecking || !playerTag.trim()}
        class="bg-[#29ABE2] text-black px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#1e88c7] disabled:bg-gray-500 disabled:text-gray-200 transition-all text-sm shadow-[3px_3px_0px_rgba(0,0,0,1)]"
      >
        {isChecking ? "Checking..." : "Invite"}
      </button>
    </div>

    {#if invitedPlayers.length > 0}
      <div class="bg-[#24084c] border-2 border-black p-3 space-y-2">
        <p class="text-xs font-black text-white uppercase">
          Recently Invited ({invitedPlayers.length})
        </p>
        <div class="flex flex-wrap gap-2">
          {#each invitedPlayers as tag}
            <div
              class="flex items-center gap-2 bg-[#FBB03B] border border-black px-2 py-1 shadow-[2px_2px_0px_rgba(0,0,0,0.6)]"
            >
              <span class="text-black font-bold text-xs uppercase">{tag}</span>
              <button
                onclick={() => removeInvited(tag)}
                class="text-black hover:text-red-600 font-bold text-xs"
                aria-label={`Remove ${tag}`}
              >
                ✕
              </button>
            </div>
          {/each}
        </div>
      </div>
    {/if}
  </div>
</div>
