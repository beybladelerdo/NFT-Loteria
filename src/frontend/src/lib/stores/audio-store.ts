import { writable } from "svelte/store";

type Category = "music" | "sfx";

export type AudioState = {
  muted: Record<Category, boolean>;
  volume: Record<Category, number>; // 0..1
};

const DEFAULT: AudioState = {
  muted: { music: false, sfx: false },
  volume: { music: 0.65, sfx: 0.9 },
};

function load(): AudioState {
  if (typeof window === "undefined") return DEFAULT;
  try {
    const raw = localStorage.getItem("audio:state");
    if (!raw) return DEFAULT;
    const s = JSON.parse(raw) as AudioState;
    return {
      muted: { ...DEFAULT.muted, ...s.muted },
      volume: { ...DEFAULT.volume, ...s.volume },
    };
  } catch {
    return DEFAULT;
  }
}

export const audioStore = writable<AudioState>(load());

audioStore.subscribe((v) => {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem("audio:state", JSON.stringify(v));
  } catch {}
});

export function vol(type: Category, s: AudioState) {
  return s.muted[type] ? 0 : s.volume[type];
}
