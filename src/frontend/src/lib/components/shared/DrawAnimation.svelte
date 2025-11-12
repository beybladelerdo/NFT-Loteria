<script lang="ts">
  import { onMount } from "svelte";
  import {
    getCharacterName,
    getCharacterColor,
  } from "$lib/data/character-data";
  import {
    playRevealHit,
    playRevealMiss,
    startShuffleLoop,
    stopShuffleLoop,
  } from "$lib/services/audio-services";

  interface Props {
    cardId: number | null;
    cardImage: string;
    show: boolean;
    isHost: boolean;
    hasCardOnTabla: boolean; // Whether this card exists on user's tabla(s)
    onClose?: () => void;
  }

  let { cardId, cardImage, show, isHost, hasCardOnTabla, onClose }: Props =
    $props();

  let flipped = $state(false);
  let mounted = $state(false);
  let shuffleStopFn: (() => void) | null = null;

  const characterName = $derived(cardId ? getCharacterName(cardId) : "");
  const characterColor = $derived(
    cardId ? getCharacterColor(cardId) : "#C9B5E8",
  );

  // Handle animation lifecycle
  $effect(() => {
    if (show && cardId && mounted) {
      // Start shuffle sound loop
      shuffleStopFn = startShuffleLoop();

      // Small delay then flip
      setTimeout(() => {
        flipped = true;

        // Stop shuffle and play hit/miss sound
        if (shuffleStopFn) {
          stopShuffleLoop(shuffleStopFn);
          shuffleStopFn = null;
        }

        // Play appropriate sound based on whether card is on user's tabla
        // Only play for non-hosts (players)
        if (!isHost) {
          if (hasCardOnTabla) {
            playRevealHit();
          } else {
            playRevealMiss();
          }
        } else {
          // Host just gets the reveal sound
          playRevealHit();
        }
      }, 300);

      // Auto-close after 3.5 seconds
      setTimeout(() => {
        if (onClose) onClose();
      }, 6500);
    } else if (!show) {
      flipped = false;
      // Clean up shuffle sound if component is hidden
      if (shuffleStopFn) {
        stopShuffleLoop(shuffleStopFn);
        shuffleStopFn = null;
      }
    }
  });

  onMount(() => {
    mounted = true;
  });
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
{#if show && cardId}
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm animate-fadeIn"
    onclick={() => onClose?.()}
  >
    <div class="flip-card-container" class:flipped>
      <div class="flip-card">
        <div class="flip-card-inner">
          <!-- Back of card (shown first) -->
          <div class="flip-card-back">
            <div class="card-back-design">
              <div class="card-back-pattern"></div>
              <div class="card-back-logo">
                <span class="text-4xl font-black">🎲</span>
                <p class="text-xs font-bold mt-2">NFT LOTERÍA</p>
              </div>
            </div>
          </div>

          <!-- Front of card (revealed) -->
          <!-- Front of card (revealed) -->
          <div class="flip-card-front">
            <!-- Card Container with colored border -->
            <div class="card-face" style="border-color: {characterColor};">
              <!-- Card Image - Now taking full card space -->
              <div class="card-image-container">
                <img src={cardImage} alt={characterName} class="card-image" />
              </div>

              <!-- Hit/Miss indicator for players only -->
              {#if !isHost && flipped}
                <div class="hit-miss-indicator">
                  {#if hasCardOnTabla}
                    <div class="hit-badge">
                      <span class="text-2xl">✓</span>
                      <span class="text-sm font-black">HIT!</span>
                    </div>
                  {:else}
                    <div class="miss-badge">
                      <span class="text-2xl">✗</span>
                      <span class="text-sm font-black">MISS</span>
                    </div>
                  {/if}
                </div>
              {/if}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  @keyframes slideUp {
    from {
      transform: translateY(20px);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  .animate-fadeIn {
    animation: fadeIn 0.3s ease-out;
  }

  /* Flip card container */
  .flip-card-container {
    perspective: 1000px;
    cursor: pointer;
    user-select: none;
  }

  .flip-card {
    background-color: transparent;
    width: 320px;
    height: 480px;
  }

  .flip-card-inner {
    position: relative;
    width: 100%;
    height: 100%;
    text-align: center;
    transition: transform 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
    transform-style: preserve-3d;
  }

  .flipped .flip-card-inner {
    transform: rotateY(180deg);
  }

  .flip-card-front,
  .flip-card-back {
    position: absolute;
    width: 100%;
    height: 100%;
    -webkit-backface-visibility: hidden;
    backface-visibility: hidden;
    border-radius: 8px;
  }

  /* Back of card */
  .flip-card-back {
    background: linear-gradient(135deg, #522785 0%, #1a0033 100%);
    border: 8px solid #f4e04d;
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);
  }

  .card-back-design {
    width: 100%;
    height: 100%;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    color: #f4e04d;
  }

  .card-back-pattern {
    position: absolute;
    inset: 0;
    background-image: repeating-linear-gradient(
      45deg,
      transparent,
      transparent 20px,
      rgba(244, 224, 77, 0.1) 20px,
      rgba(244, 224, 77, 0.1) 40px
    );
    opacity: 0.5;
  }

  .card-back-logo {
    position: relative;
    z-index: 1;
    text-align: center;
  }

  /* Front of card */
  .flip-card-front {
    transform: rotateY(180deg);
  }

  .card-face {
    width: 100%;
    height: 100%;
    background: #1a0033;
    border: 8px solid;
    box-shadow: 0 12px 24px rgba(0, 0, 0, 0.6);
    border-radius: 8px;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .card-header {
    padding: 12px 16px;
    border-bottom: 4px solid #000;
    text-align: center;
  }

  .card-image-container {
    flex: 1;
    background: #0f0220;
    border: 4px solid #000;
    margin: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }

  .card-image {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }

  .card-footer {
    padding: 12px;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .card-number {
    width: 64px;
    height: 64px;
    border-radius: 50%;
    border: 4px solid #000;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.4);
  }

  /* Hit/Miss indicator */
  .hit-miss-indicator {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 10;
    animation: slideUp 0.4s ease-out;
  }

  .hit-badge,
  .miss-badge {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    padding: 16px 24px;
    border: 4px solid #000;
    border-radius: 8px;
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.6);
    font-weight: 900;
    text-transform: uppercase;
  }

  .hit-badge {
    background: #00ff00;
    color: #000;
  }

  .miss-badge {
    background: #ff0000;
    color: #fff;
  }
</style>
