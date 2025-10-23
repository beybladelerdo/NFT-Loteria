<script lang="ts">
  import { gameStore } from "$lib/stores/game-store.svelte";
  import type { CreateTablaParams } from "$lib/services/game-service";
  import tablaMetadata from "$lib/assets/Layouts/tabla_metadata.json";

  const CHUNK_SIZE = 50; // Process 50 tablas at a time
  const FRONTEND_CANISTER_ID = import.meta.env.VITE_FRONTEND_CANISTER_ID ?? "";

  let isLoading = $state(false);
  let result = $state<{
    success: boolean;
    created?: number[];
    skipped?: number[];
    error?: string;
  } | null>(null);
  let totalTablas = $state(0);
  let processedTablas = $state(0);
  let currentChunk = $state(0);
  let totalChunks = $state(0);
  let loadingProgress = $state("");

  interface TablaJSON {
    tabla_number: number;
    characters: Record<string, string>;
    file_name: string;
    background: string;
  }

  function parseCharacterPosition(posKey: string): number {
    // "position_1" -> 1, "position_16" -> 16
    const match = posKey.match(/position_(\d+)/);
    return match ? parseInt(match[1]) : 0;
  }

  function parseCharacterId(charStr: string): number {
    // "Character_3.png" -> 3
    const match = charStr.match(/Character_(\d+)/);
    return match ? parseInt(match[1]) : 0;
  }

  function generateImageUrl(fileName: string): string {
    // Extract tabla number from filename (e.g., "0001.jpg" -> "1")
    const match = fileName.match(/(\d+)/);
    const tablaNum = match ? parseInt(match[1]) : 0;

    // Return path to asset in frontend canister
    // Format: https://{canister-id}.icp0.io/assets/tabla_{num}.png
    return `https://${FRONTEND_CANISTER_ID}.icp0.io/assets/Tablas/tabla_${tablaNum}.png`;
  }

  function parseTablaJson(jsonArray: TablaJSON[]): CreateTablaParams[] {
    const tablas: CreateTablaParams[] = [];

    for (const item of jsonArray) {
      // Sort positions 1-16 and extract card IDs
      const positions = Object.entries(item.characters)
        .map(([key, value]) => ({
          position: parseCharacterPosition(key),
          cardId: parseCharacterId(value),
        }))
        .sort((a, b) => a.position - b.position)
        .map((p) => p.cardId);

      // Validate we have exactly 16 cards
      if (positions.length !== 16) {
        console.warn(
          `Tabla ${item.tabla_number} has ${positions.length} cards, expected 16`,
        );
        continue;
      }

      // Validate all card IDs are 1-54
      if (positions.some((id) => id < 1 || id > 54)) {
        console.warn(`Tabla ${item.tabla_number} has invalid card IDs`);
        continue;
      }

      tablas.push({
        tablaId: item.tabla_number,
        cards: positions,
        rarity: item.background as any,
        imageUrl: generateImageUrl(item.file_name),
      });
    }

    return tablas;
  }

  function chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  async function handleLoadFromFile() {
    result = null;

    try {
      const parsed = tablaMetadata as TablaJSON[];
      const tablas = parseTablaJson(parsed);

      if (tablas.length === 0) {
        result = {
          success: false,
          error: "No valid tablas found in metadata file",
        };
        return;
      }

      totalTablas = tablas.length;
      processedTablas = 0;

      // Split into chunks
      const chunks = chunkArray(tablas, CHUNK_SIZE);
      totalChunks = chunks.length;

      isLoading = true;
      const allCreated: number[] = [];
      const allSkipped: number[] = [];

      // Process each chunk sequentially
      for (let i = 0; i < chunks.length; i++) {
        currentChunk = i + 1;
        loadingProgress = `Processing chunk ${currentChunk}/${totalChunks} (${chunks[i].length} tablas)...`;

        const chunkResult = await gameStore.batchLoadTablas(chunks[i]);

        // Check if the error is only about duplicates
        if (!chunkResult.success && chunkResult.error) {
          const errorMsg = chunkResult.error.toLowerCase();
          const isDuplicateOnlyError = errorMsg.includes("already exists");

          if (isDuplicateOnlyError) {
            // Extract tabla IDs from duplicate errors
            const duplicateMatches = chunkResult.error.match(/tabla (\d+):/gi);
            if (duplicateMatches) {
              const skippedIds: number[] = duplicateMatches
                .map((match: string) => {
                  const num = match.match(/\d+/);
                  return num ? parseInt(num[0]) : 0;
                })
                .filter((id: number) => id > 0);
              allSkipped.push(...skippedIds);
            }

            // Continue processing if it's only duplicates
            console.log(
              `Chunk ${currentChunk}: Skipped ${allSkipped.length} duplicates`,
            );
          } else {
            // If there's a real error (not just duplicates), stop
            result = {
              success: false,
              error: `Failed at chunk ${currentChunk}: ${chunkResult.error}`,
            };
            isLoading = false;
            return;
          }
        }

        if (chunkResult.created) {
          allCreated.push(...chunkResult.created);
        }

        processedTablas += chunks[i].length;

        // Small delay between chunks to prevent overwhelming the canister
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }

      result = {
        success: true,
        created: allCreated,
        skipped: allSkipped,
      };
      loadingProgress = "";
    } catch (error: any) {
      console.error("Error loading tablas:", error);
      result = { success: false, error: error?.message ?? String(error) };
      loadingProgress = "";
    } finally {
      isLoading = false;
      processedTablas = 0;
      currentChunk = 0;
      totalChunks = 0;
    }
  }

  async function checkLoadedCount() {
    const count = await gameStore.getTablaCount();
    totalTablas = (tablaMetadata as TablaJSON[]).length;
    return count;
  }
</script>

<div
  class="bg-gradient-to-b from-[#522785] to-[#3d1d63] p-1 shadow-[8px_8px_0px_0px_rgba(0,0,0,0.3)]"
>
  <div
    class="bg-[#522785] p-2 border-b-2 border-black flex items-center justify-between"
  >
    <div class="flex items-center gap-2">
      <div class="w-4 h-4 bg-white border-2 border-black"></div>
      <span class="text-white font-black text-xs uppercase"
        >TABLA_LOADER.EXE</span
      >
    </div>
    <div class="flex gap-1">
      <div class="w-4 h-4 bg-[#FBB03B] border border-black"></div>
      <div class="w-4 h-4 bg-red-500 border border-black"></div>
    </div>
  </div>

  <div class="bg-white p-6 md:p-8 border-4 border-black">
    <h2
      class="text-2xl font-black text-black uppercase mb-4 text-center"
      style="text-shadow: 2px 2px 0px #522785;"
    >
      BULK TABLA LOADER
    </h2>

    <!-- Instructions -->
    <div class="bg-[#FBB03B] border-4 border-black p-4 mb-6">
      <p class="text-xs font-bold text-black uppercase mb-2">
        📋 LOADING PROCESS:
      </p>
      <ul class="text-xs font-bold text-black space-y-1">
        <li>1. SYNC REGISTRY FIRST (REQUIRED)</li>
        <li>
          2. METADATA FILE: {(tablaMetadata as TablaJSON[]).length} TABLAS READY
        </li>
        <li>3. CHUNKED UPLOAD: {CHUNK_SIZE} TABLAS PER BATCH</li>
        <li>4. DUPLICATES WILL BE AUTOMATICALLY SKIPPED</li>
        <li>5. WAIT FOR COMPLETION (MAY TAKE SEVERAL MINUTES)</li>
      </ul>
    </div>

    <!-- Status Display -->
    <div class="bg-black border-4 border-[#29ABE2] p-4 mb-6">
      <div class="flex items-center justify-between mb-2">
        <span class="text-[#29ABE2] font-bold uppercase text-sm"
          >METADATA FILE:</span
        >
        <span class="text-[#00FF00] font-black text-sm">
          {(tablaMetadata as TablaJSON[]).length} TABLAS LOADED
        </span>
      </div>
      <div class="flex items-center justify-between">
        <span class="text-[#29ABE2] font-bold uppercase text-sm"
          >CHUNK SIZE:</span
        >
        <span class="text-[#FBB03B] font-black text-sm"
          >{CHUNK_SIZE} PER BATCH</span
        >
      </div>
    </div>

    <!-- Loading Progress -->
    {#if isLoading}
      <div class="bg-[#522785] border-4 border-black p-6 mb-6">
        <div class="text-center mb-4">
          <div
            class="inline-block animate-spin rounded-full h-16 w-16 border-4 border-white border-t-[#FBB03B]"
          ></div>
        </div>
        <p class="text-white font-black text-center text-lg mb-2">
          LOADING TABLAS...
        </p>
        <p class="text-[#FBB03B] font-bold text-center text-sm">
          {loadingProgress}
        </p>
        <div
          class="mt-4 bg-white border-2 border-black h-8 relative overflow-hidden"
        >
          <div
            class="absolute top-0 left-0 h-full bg-[#FBB03B] transition-all duration-300"
            style="width: {totalTablas > 0
              ? (processedTablas / totalTablas) * 100
              : 0}%"
          ></div>
          <div class="absolute inset-0 flex items-center justify-center">
            <span class="text-black font-black text-xs">
              {processedTablas} / {totalTablas}
            </span>
          </div>
        </div>
      </div>
    {:else}
      <!-- Load Button -->
      <div class="text-center mb-6">
        <button
          onclick={handleLoadFromFile}
          disabled={isLoading}
          class="bg-[#522785] text-white px-8 py-4 font-black uppercase border-4 border-black hover:bg-[#6d3399] disabled:bg-gray-400 disabled:cursor-not-allowed transition-all text-lg"
          style="box-shadow: 4px 4px 0px #000;"
        >
          LOAD ALL {(tablaMetadata as TablaJSON[]).length} TABLAS >>
        </button>
      </div>
    {/if}

    <!-- Result -->
    {#if result}
      <div
        class="bg-{result.success
          ? 'green'
          : 'red'}-500 border-4 border-black p-4"
      >
        <p class="text-white font-bold uppercase text-center mb-2">
          {#if result.success}
            ✓ SUCCESS: {result.created?.length ?? 0} TABLAS CREATED
          {:else}
            ✗ ERROR: {result.error}
          {/if}
        </p>
        {#if result.success && result.skipped && result.skipped.length > 0}
          <p class="text-white font-bold text-center text-sm">
            ⊘ {result.skipped.length} DUPLICATES SKIPPED
          </p>
        {/if}
      </div>
    {/if}

    <!-- Verification -->
    {#if !isLoading}
      <div class="mt-6 text-center">
        <button
          onclick={async () => {
            const count = await checkLoadedCount();
            alert(`Currently loaded: ${count} / ${totalTablas} tablas`);
          }}
          class="bg-[#29ABE2] text-black px-6 py-2 font-black uppercase border-2 border-black hover:bg-[#1e88c7] transition-all text-sm"
          style="box-shadow: 2px 2px 0px #000;"
        >
          CHECK LOADED COUNT
        </button>
      </div>
    {/if}
  </div>
</div>
