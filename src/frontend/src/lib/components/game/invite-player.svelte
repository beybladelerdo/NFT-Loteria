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

<div
  class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-1 shadow-[4px_4px_0px_0px_rgba(0,0,0,0.3)]"
>
  <div class="bg-[#522785] p-2 border-b-2 border-black">
    <p class="text-white font-black text-xs uppercase">👥 INVITE PLAYERS</p>
  </div>

  <div class="bg-white p-4 border-2 border-black">
    <div class="mb-4">
      <!-- svelte-ignore a11y_label_has_associated_control -->
      <label class="block text-xs font-bold text-black uppercase mb-2">
        PLAYER TAG:
      </label>
      <div class="flex gap-2">
        <input
          type="text"
          bind:value={playerTag}
          onkeydown={(e) => e.key === "Enter" && checkAndInvite()}
          placeholder="Enter username..."
          class="flex-1 px-3 py-2 border-2 border-black font-bold text-sm focus:outline-none focus:border-[#29ABE2]"
        />
        <button
          onclick={checkAndInvite}
          disabled={isChecking || !playerTag.trim()}
          class="bg-[#29ABE2] text-black px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#1e88c7] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-sm whitespace-nowrap"
          style="box-shadow: 2px 2px 0px #000;"
        >
          {isChecking ? "..." : "INVITE"}
        </button>
      </div>
    </div>

    <!-- Invited Players List -->
    {#if invitedPlayers.length > 0}
      <div class="border-2 border-[#FBB03B] p-3">
        <p class="text-xs font-black text-black uppercase mb-2">
          INVITED ({invitedPlayers.length}):
        </p>
        <div class="flex flex-wrap gap-2">
          {#each invitedPlayers as tag}
            <div
              class="flex items-center gap-2 bg-[#FBB03B] border border-black px-2 py-1"
            >
              <span class="text-black font-bold text-xs">{tag}</span>
              <button
                onclick={() => removeInvited(tag)}
                class="text-black hover:text-red-600 font-bold text-xs"
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
