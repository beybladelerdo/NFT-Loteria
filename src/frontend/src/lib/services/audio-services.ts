import { get } from "svelte/store";
import { audioStore, type AudioState } from "$lib/stores/audio-store";

export type SfxKey =
  | "blip"
  | "shuffle"
  | "reveal_miss"
  | "reveal_hit"
  | "victory"
  | "menu_music"
  | "select_common"
  | "select_uncommon"
  | "select_rare"
  | "select_epic"
  | "select_legendary";

const SFX_SRC: Record<SfxKey, string> = {
  blip: "/sounds/blip.wav",
  shuffle: "/sounds/shuffle.wav",
  reveal_miss: "/sounds/reveal_miss.wav",
  reveal_hit: "/sounds/reveal_hit.wav",
  victory: "/sounds/victory.wav",
  menu_music: "/sounds/menu_music.wav",
  select_common: "/sounds/select_common.wav",
  select_uncommon: "/sounds/select_uncommon.wav",
  select_rare: "/sounds/select_rare.wav",
  select_epic: "/sounds/select_epic.wav",
  select_legendary: "/sounds/select_legendary.wav",
};

type Loaded = {
  base: HTMLAudioElement;
  loop?: boolean;
};

const sfxBank: Partial<Record<SfxKey, Loaded>> = {};
let unlocked = false;

function currentVol(kind: "music" | "sfx") {
  const s = get(audioStore);
  return s.muted[kind] ? 0 : s.volume[kind];
}

function applySfxVolume() {
  const v = currentVol("sfx");
  Object.values(sfxBank).forEach((o) => {
    if (o?.base) o.base.volume = v;
  });
}

audioStore.subscribe(applySfxVolume);

export function preloadSfx(key: SfxKey, loop = false) {
  if (sfxBank[key]) return;
  const a = new Audio(SFX_SRC[key]);
  a.preload = "auto";
  a.loop = loop;
  a.volume = currentVol("sfx");
  sfxBank[key] = { base: a, loop };
}

export function preloadAll() {
  (Object.keys(SFX_SRC) as SfxKey[]).forEach((k) => preloadSfx(k));
}

export function unlockAudio() {
  if (unlocked) return;
  unlocked = true;
  // Pre-create short silent play attempt to satisfy iOS
  try {
    const a = new Audio();
    a.muted = true;
    // Some browsers need a play attempt in a user gesture; this is a no-op
    a.play?.().catch(() => {});
    // Warm-up SFX elements
    preloadAll();
  } catch {}
}

type PlayOpts = {
  volume?: number;
  allowOverlap?: boolean;
  rate?: number;
  loop?: boolean;
};

function makeInstance(key: SfxKey, loop?: boolean) {
  const reg = sfxBank[key] ?? { base: new Audio(SFX_SRC[key]) };
  if (!sfxBank[key]) {
    reg.base.preload = "auto";
    sfxBank[key] = { base: reg.base };
  }
  const clone = reg.base.cloneNode(true) as HTMLAudioElement;
  clone.loop = !!loop;
  clone.volume = currentVol("sfx");
  return clone;
}

export function playSfx(key: SfxKey, opts: PlayOpts = {}): () => void {
  const { allowOverlap = true, rate = 1, loop = false } = opts;
  let inst: HTMLAudioElement;

  // allowOverlap: always make a fresh instance
  // no-overlap: reuse base (interrupts prior)
  if (allowOverlap) {
    inst = makeInstance(key, loop);
  } else {
    preloadSfx(key, loop);
    inst = sfxBank[key]!.base;
    inst.pause();
    inst.currentTime = 0;
    inst.loop = loop;
  }

  const baseVol = currentVol("sfx");
  const vol = Math.max(0, Math.min(1, (opts.volume ?? 1) * baseVol));
  inst.volume = vol;
  inst.playbackRate = rate;

  // Some browsers throw if not yet unlocked
  try {
    inst.play();
  } catch {
    /* ignore */
  }

  if (loop) {
    return () => {
      try {
        inst.pause();
        inst.currentTime = 0;
      } catch {}
    };
  }
  return () => {};
}

export function playBlip() {
  playSfx("blip", { allowOverlap: true, rate: 1 });
}

export function startShuffleLoop() {
  return playSfx("shuffle", { loop: true, allowOverlap: false });
}
export function stopShuffleLoop(stopFn?: () => void) {
  if (stopFn) stopFn();
}

export function playRevealHit() {
  playSfx("reveal_hit", { allowOverlap: true });
}
export function playRevealMiss() {
  playSfx("reveal_miss", { allowOverlap: true });
}
export function playVictory() {
  playSfx("victory", { allowOverlap: false });
}

/** Hover tick rate-limit (e.g., on grid hover) */
let lastHover = 0;
export function hoverTick(minGapMs = 60) {
  const now = performance.now();
  if (now - lastHover < minGapMs) return;
  lastHover = now;
  playBlip();
}

let music: HTMLAudioElement | null = null;

export function startMenuMusic(url: string, loop = true) {
  if (!music) {
    music = new Audio(url);
  } else {
    music.pause();
    music.src = url;
  }
  music.loop = loop;
  music.volume = currentVol("music");
  try {
    music.play();
  } catch {}
}

export async function crossfadeTo(url: string, ms = 600) {
  if (!music) {
    startMenuMusic(url, true);
    return;
  }
  const from = music;
  const to = new Audio(url);
  to.loop = true;
  to.volume = 0;
  try {
    await to.play();
  } catch {}

  const steps = 30;
  const stepDur = ms / steps;
  const targetVol = currentVol("music");

  await new Promise<void>((resolve) => {
    let i = 0;
    const id = setInterval(() => {
      i++;
      const t = i / steps;
      to.volume = targetVol * t;
      from.volume = targetVol * (1 - t);
      if (i >= steps) {
        clearInterval(id);
        from.pause();
        music = to;
        resolve();
      }
    }, stepDur);
  });
}

audioStore.subscribe((s: AudioState) => {
  if (music) music.volume = currentVol("music");
});
