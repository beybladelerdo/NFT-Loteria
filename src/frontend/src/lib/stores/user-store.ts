import { UserService } from "$lib/services/user-service";
import type { Profile } from "../../../../declarations/backend/backend.did";

function createUserStore() {
  const svc = new UserService();

  async function getProfile(): Promise<Profile | undefined> {
    return svc.getProfile();
  }

  async function createProfile(tag: string): Promise<void> {
    return svc.createProfile(tag);
  }

  async function updateTag(newTag: string): Promise<void> {
    return svc.updateTag(newTag);
  }

  async function isTagAvailable(tag: string): Promise<boolean> {
    return svc.isTagAvailable(tag);
  }

  async function checkIfInGame() {
    try {
      const result = await svc.isPlayerInGame();
      if (result.success && result.data) {
        return {
          success: true,
          inGame: true,
          gameId: result.data.gameId,
          role: result.data.role,
        };
      }
      return { success: true, inGame: false };
    } catch (error: any) {
      console.error("Error checking if in game:", error);
      return { success: false, error: error?.message ?? String(error) };
    }
  }

  return {
    getProfile,
    createProfile,
    updateTag,
    isTagAvailable,
    checkIfInGame,
  };
}

export const userStore = createUserStore();
