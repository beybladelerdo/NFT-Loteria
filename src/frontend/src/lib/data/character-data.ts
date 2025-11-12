// Character data mapped from the CSV
export interface CharacterData {
  id: number;
  name: string;
  color: string;
}

export const CHARACTER_COLORS = {
  Purple: "#9D4EDD",
  Yellow: "#F4E04D",
  Blue: "#29ABE2",
  Fusia: "#FF6EC7",
  Orange: "#FBB03B",
  Custom: "#C9B5E8",
} as const;

export const CHARACTERS: Record<number, CharacterData> = {
  1: { id: 1, name: "El ICP", color: "Purple" },
  2: { id: 2, name: "El Miner", color: "Yellow" },
  3: { id: 3, name: "El Windoge 98", color: "Blue" },
  4: { id: 4, name: "El Pollo", color: "Yellow" },
  5: { id: 5, name: "El VictorICP", color: "Fusia" },
  6: { id: 6, name: "El Canister", color: "Purple" },
  7: { id: 7, name: "El Wizard", color: "Purple" },
  8: { id: 8, name: "El Pepe Chad", color: "Blue" },
  9: { id: 9, name: "El Bitcoin", color: "Orange" },
  10: { id: 10, name: "El Wumbro", color: "Custom" },
  11: { id: 11, name: "La Litecoin", color: "Yellow" },
  12: { id: 12, name: "El Openchat", color: "Fusia" },
  13: { id: 13, name: "El Black Swan", color: "Purple" },
  14: { id: 14, name: "La Bag", color: "Yellow" },
  15: { id: 15, name: "Los Web 3 Vanguards", color: "Custom" },
  16: { id: 16, name: "La Network", color: "Fusia" },
  17: { id: 17, name: "El Vaultbet", color: "Fusia" },
  18: { id: 18, name: "El Airdrop", color: "Blue" },
  19: { id: 19, name: "La Plug Wallet", color: "Fusia" },
  20: { id: 20, name: "El Crab", color: "Fusia" },
  21: { id: 21, name: "El ckBTC", color: "Fusia" },
  22: { id: 22, name: "El Motoko", color: "Yellow" },
  23: { id: 23, name: "La BTC Flower", color: "Blue" },
  24: { id: 24, name: "La Quokka", color: "Orange" },
  25: { id: 25, name: "El Bull", color: "Fusia" },
  26: { id: 26, name: "EL WUMBO", color: "Custom" },
  27: { id: 27, name: "El Kongswap", color: "Custom" },
  28: { id: 28, name: "El Yuku", color: "Orange" },
  29: { id: 29, name: "La Moon", color: "Yellow" },
  30: { id: 30, name: "El Sonic Dex", color: "Orange" },
  31: { id: 31, name: "El ICPSwap", color: "Orange" },
  32: { id: 32, name: "El ckETH", color: "Orange" },
  33: { id: 33, name: "El Gold Dao", color: "Yellow" },
  34: { id: 34, name: "El King Bean", color: "Purple" },
  35: { id: 35, name: "El Ethereum", color: "Purple" },
  36: { id: 36, name: "La Stoic Wallet", color: "Yellow" },
  37: { id: 37, name: "El Hacker", color: "Purple" },
  38: { id: 38, name: "El Party Token", color: "Purple" },
  39: { id: 39, name: "La Miball", color: "Custom" },
  40: { id: 40, name: "La Pee Lady", color: "Custom" },
  41: { id: 41, name: "El Moonshift", color: "Blue" },
  42: { id: 42, name: "El USDT", color: "Orange" },
  43: { id: 43, name: "La KawaiiVHS", color: "Purple" },
  44: { id: 44, name: "El Lambo", color: "Yellow" },
  45: { id: 45, name: "El Trumpo", color: "Custom" },
  46: { id: 46, name: "El Toniq Market", color: "Blue" },
  47: { id: 47, name: "El Bear", color: "Fusia" },
  48: { id: 48, name: "El BNB", color: "Fusia" },
  49: { id: 49, name: "El Fuegozard", color: "Blue" },
  50: { id: 50, name: "Las Diamond Hands", color: "Yellow" },
  51: { id: 51, name: "El Dogecoin", color: "Blue" },
  52: { id: 52, name: "La Whale", color: "Orange" },
  53: { id: 53, name: "La Party Hat", color: "Purple" },
  54: { id: 54, name: "La Printer", color: "Blue" },
};

export function getCharacterName(cardId: number): string {
  return CHARACTERS[cardId]?.name ?? `Card #${cardId}`;
}

export function getCharacterColor(cardId: number): string {
  const colorName = CHARACTERS[cardId]?.color ?? "Custom";
  return (
    CHARACTER_COLORS[colorName as keyof typeof CHARACTER_COLORS] ??
    CHARACTER_COLORS.Custom
  );
}

export function getCharacterData(cardId: number): CharacterData | null {
  return CHARACTERS[cardId] ?? null;
}
