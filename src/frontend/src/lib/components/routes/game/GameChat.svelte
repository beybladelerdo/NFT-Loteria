<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { gameStore } from "$lib/stores/game-store.svelte";

  type ChatMessage = { username: string; message: string; timestamp: number };

  let { gameId }: { gameId: string } = $props();

  let messages = $state<ChatMessage[]>([]);
  let newMessage = $state("");
  let isSending = $state(false);
  let chatContainer: HTMLDivElement;
  let pollInterval: ReturnType<typeof setInterval>;

  async function fetchMessages() {
    const result = await gameStore.getChatMessages(gameId);
    if (result.success && "data" in result && result.data) {
      messages = result.data.map((msg) => ({
        username: msg.username,
        message: msg.message,
        timestamp: Number(msg.timestamp) / 1_000_000,
      }));
      scrollToBottom();
    }
  }

  async function sendMessage() {
    if (!newMessage.trim() || isSending) return;
    isSending = true;
    try {
      const result = await gameStore.sendChatMessage(gameId, newMessage.trim());
      if (result.success) {
        newMessage = "";
        await fetchMessages();
      }
    } finally {
      isSending = false;
    }
  }

  function scrollToBottom() {
    if (chatContainer) {
      setTimeout(() => {
        chatContainer.scrollTop = chatContainer.scrollHeight;
      }, 50);
    }
  }

  function formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  }

  onMount(() => {
    fetchMessages();
    pollInterval = setInterval(fetchMessages, 3000);
  });

  onDestroy(() => {
    if (pollInterval) clearInterval(pollInterval);
  });
</script>

<div
  class="bg-gradient-to-b from-[#522785] to-[#3d1d63] border-2 sm:border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,0.8)] sm:shadow-[6px_6px_0px_0px_rgba(0,0,0,0.8)] flex flex-col h-[300px] sm:h-[400px]"
>
  <div class="p-2 sm:p-3 border-b-2 border-black flex-shrink-0">
    <span
      class="bg-[#F4E04D] text-[#1a0033] border-2 border-black px-2 sm:px-3 py-1 text-xs font-bold uppercase shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]"
    >
      Game Chat
    </span>
  </div>

  <div
    bind:this={chatContainer}
    class="flex-1 overflow-y-auto p-3 sm:p-4 space-y-2 sm:space-y-3 bg-[#1a0033] min-h-0"
  >
    {#if messages.length === 0}
      <div
        class="text-center text-[#C9B5E8] text-xs sm:text-sm font-bold opacity-60"
      >
        No messages yet. Say hello!
      </div>
    {:else}
      {#each messages as msg}
        <div class="flex flex-col">
          <div class="flex items-center gap-2 mb-1">
            <span class="text-xs font-black text-[#F4E04D] break-all"
              >@{msg.username}</span
            >
            <span class="text-[10px] text-[#C9B5E8] opacity-60 flex-shrink-0"
              >{formatTime(msg.timestamp)}</span
            >
          </div>
          <div
            class="bg-[#522785] text-white text-xs sm:text-sm font-bold p-2 border border-black rounded shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] break-words"
          >
            {msg.message}
          </div>
        </div>
      {/each}
    {/if}
  </div>

  <div class="p-2 sm:p-3 border-t-2 border-black bg-[#3d1d63] flex-shrink-0">
    <div class="flex gap-2">
      <input
        type="text"
        bind:value={newMessage}
        onkeydown={handleKeydown}
        placeholder="Type a message..."
        class="flex-1 bg-[#1a0033] text-white border-2 border-black p-2 text-xs sm:text-sm font-bold placeholder:text-[#C9B5E8] placeholder:opacity-50 focus:outline-none focus:border-[#F4E04D] min-w-0"
      />
      <button
        onclick={sendMessage}
        disabled={isSending || !newMessage.trim()}
        class="bg-[#F4E04D] text-[#1a0033] px-3 sm:px-4 py-2 font-black uppercase border-2 border-black hover:bg-[#fff27d] active:scale-95 transition-all text-xs shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] disabled:opacity-50 disabled:cursor-not-allowed flex-shrink-0"
      >
        {isSending ? "..." : "SEND"}
      </button>
    </div>
  </div>
</div>
