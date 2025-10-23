<script lang="ts">
  import { gameStore } from "$lib/stores/game-store.svelte";

  const dfxNetwork =
    (
      import.meta.env?.VITE_DFX_NETWORK as string | undefined
    )?.toLowerCase?.() ?? "local";
  const isMainnet = dfxNetwork === "ic";
  let isRefreshing = $state(false);
  let result = $state<{ success: boolean; error?: string } | null>(null);
  let manualText = $state<string>("");

  async function handleRefreshRegistry() {
    isRefreshing = true;
    result = null;

    try {
      result = await gameStore.refreshRegistry();
    } catch (error) {
      console.error("Error refreshing registry:", error);
      result = { success: false, error: String(error) };
    } finally {
      isRefreshing = false;
    }
  }
  function isLikelyJson(text: string) {
    const t = text.trim();
    return t.startsWith("[") && t.endsWith("]");
  }
  function parseJsonTuples(text: string): Array<[number, string]> {
    const parsed = JSON.parse(text);
    if (!Array.isArray(parsed))
      throw new Error("JSON must be an array of [id, owner] pairs");
    return parsed.map((row: unknown) => {
      if (!Array.isArray(row) || row.length !== 2)
        throw new Error(`Invalid row: ${JSON.stringify(row)}`);
      const id = Number(row[0]);
      const owner = String(row[1]).trim();
      if (!Number.isInteger(id) || id < 0) throw new Error(`Bad id: ${row[0]}`);
      if (!owner) throw new Error("Missing owner");
      return [id, owner] as [number, string];
    });
  }

  function parseCsvTuples(text: string): Array<[number, string]> {
    return text
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter(Boolean)
      .map((line) => {
        const [idStr, owner] = line.split(",").map((s) => s.trim());
        const id = Number(idStr);
        if (!Number.isInteger(id) || id < 0)
          throw new Error(`Bad id in line: "${line}"`);
        if (!owner) throw new Error(`Missing owner in line: "${line}"`);
        return [id, owner] as [number, string];
      });
  }

  function parseManual(text: string): Array<[number, string]> {
    return isLikelyJson(text) ? parseJsonTuples(text) : parseCsvTuples(text);
  }
  async function handleInitRegistryManual() {
    isRefreshing = true;
    result = null;
    try {
      const pairs = parseManual(manualText);

      const pairs1 = pairs.map(([id, owner]) => {
        if (!Number.isInteger(id) || id < 0) {
          throw new Error(`Invalid id: ${id}`);
        }
        if (id >= 0xffffffff) {
          throw new Error(
            `id ${id} too large to bump (+1 would overflow Nat32)`,
          );
        }
        return [id, owner] as [number, string];
      });

      result = await gameStore.initRegistry(pairs1);
    } catch (error) {
      console.error("Error initRegistry:", error);
      result = {
        success: false,
        error: (error as Error)?.message ?? String(error),
      };
    } finally {
      isRefreshing = false;
    }
  }
</script>

<div
  class="bg-gradient-to-b from-[#FBB03B] to-[#e09a2f] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
>
  <div
    class="bg-[#FBB03B] p-2 border-b-2 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <div class="w-4 h-4 bg-white border-2 border-black"></div>
      <span class="text-black font-black text-xs uppercase"
        >REGISTRY_SYNC.EXE</span
      >
    </div>
    <div class="flex gap-1">
      <div class="w-4 h-4 bg-[#29ABE2] border border-black"></div>
      <div class="w-4 h-4 bg-red-500 border border-black"></div>
    </div>
  </div>

  <div class="bg-white p-6 md:p-8 border-4 border-black">
    <h2
      class="text-2xl font-black text-black uppercase mb-4 text-center"
      style="text-shadow: 2px 2px 0px #FBB03B;"
    >
      NFT REGISTRY SYNC
    </h2>

    <div class="bg-black border-4 border-[#FBB03B] p-6 mb-6">
      <p class="text-[#FBB03B] font-bold text-sm leading-relaxed">
        &gt; {isMainnet
          ? "SYNC NFT OWNERSHIP DATA FROM EXT CANISTER"
          : "MANUAL REGISTRY INIT (LOCAL/OFFLINE)"}<br />
        &gt; CANISTER ID: psaup-3aaaa-aaaak-qsxlq-cai<br />
        &gt; RUN BEFORE LOADING TABLAS<br />
        &gt; UPDATES OWNER ACCOUNT IDS FOR ALL NFTS
      </p>
    </div>

    <!-- Controls -->
    <div class="grid gap-6 md:grid-cols-2">
      {#if isMainnet}
        <div class="text-center">
          <button
            on:click={handleRefreshRegistry}
            disabled={isRefreshing}
            class="bg-[#522785] text-white px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#6d3399] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-lg"
            style="box-shadow: 4px 4px 0px #000;"
          >
            {isRefreshing ? "SYNCING..." : "SYNC REGISTRY >>"}
          </button>
        </div>
      {/if}

      <!-- Manual admin init (always shown) -->
      <div class="md:col-start-2">
        <!-- svelte-ignore a11y_label_has_associated_control -->
        <label class="block text-xs font-black uppercase mb-2 text-black">
          Paste JSON <em>[[id, "owner"], ...]</em> or CSV <em>id, owner</em>
        </label>
        <!-- svelte-ignore element_invalid_self_closing_tag -->
        <textarea
          bind:value={manualText}
          rows="12"
          class="w-full border-4 border-black p-3 dark:text-black dark:bg-white font-mono text-xs md:text-sm"
        />
        <div class="mt-2 text-right">
          <!-- svelte-ignore event_directive_deprecated -->
          <button
            on:click={handleInitRegistryManual}
            disabled={isRefreshing}
            class="bg-[#29ABE2] text-black px-6 py-2 font-black uppercase border-4 border-black hover:brightness-110 disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-sm"
            style="box-shadow: 4px 4px 0px #000;"
          >
            {isRefreshing ? "APPLYING..." : "APPLY MANUAL >>"}
          </button>
        </div>
      </div>
    </div>

    {#if result}
      <div
        class={`mt-6 border-4 border-black p-4 ${result.success ? "bg-green-500" : "bg-red-500"}`}
      >
        <p class="text-white font-bold text-center uppercase">
          {#if result.success}
            ✓ REGISTRY INIT/SYNC SUCCESSFUL
          {:else}
            ✗ OPERATION FAILED: {result.error}
          {/if}
        </p>
      </div>
    {/if}

    <div class="mt-6 bg-[#FBB03B] border-2 border-black p-4">
      <p class="text-xs font-bold text-black uppercase text-center">
        ⚠ RUN THIS BEFORE LOADING TABLA LAYOUTS
      </p>
    </div>
  </div>
</div>
