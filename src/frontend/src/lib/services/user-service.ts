import { ActorFactory } from "../utils/ActorFactory";
import { authStore } from "$lib/stores/auth-store";
import type {
  _SERVICE,
  Profile,
  Result,
  Result_4,
} from "../../../../declarations/backend/backend.did";

const BACKEND_CANISTER_ID = import.meta.env.VITE_BACKEND_CANISTER_ID ?? "";

export class UserService {
  private async getActor(): Promise<_SERVICE> {
    const actor = (await ActorFactory.createIdentityActor(
      authStore,
      BACKEND_CANISTER_ID,
    )) as unknown as _SERVICE;
    return actor;
  }

  async getProfile(): Promise<Profile | undefined> {
    try {
      const actor = await this.getActor();
      const res: Result_4 = await actor.getProfile();
      if ("ok" in res) return res.ok;
      return undefined;
    } catch (error) {
      console.error("Error fetching profile:", error);
      return undefined;
    }
  }

  /**
   * Creates a profile with the given tag.
   * Throws Error(message) if backend returns { err }.
   */
  async createProfile(tag: string): Promise<void> {
    const actor = await this.getActor();
    const res: Result = await actor.createProfile(tag);
    if ("err" in res) throw new Error(res.err);
  }

  /**
   * Updates the username/tag.
   * Throws Error(message) if backend returns { err } (e.g. "username taken").
   */
  async updateTag(newTag: string): Promise<void> {
    const actor = await this.getActor();
    const res: Result = await actor.updateTag(newTag);
    if ("err" in res) throw new Error(res.err);
  }
  async isTagAvailable(tag: string): Promise<boolean> {
    try {
      const actor = await this.getActor();
      return await actor.isTagAvailable(tag);
    } catch (error) {
      console.error("Error checking tag availability:", error);
      return false;
    }
  }
  async isPlayerInGame(): Promise<{
    success: boolean;
    data?: { gameId: string; role: "host" | "player" };
    error?: string;
  }> {
    try {
      const actor = await this.getActor();
      const result = await actor.isPlayerInGame();

      if (result.length > 0 && result[0]) {
        const gameInfo = result[0];
        return {
          success: true,
          data: {
            gameId: gameInfo.gameId,
            role: "host" in gameInfo.role ? "host" : "player",
          },
        };
      }
      return { success: true, data: undefined };
    } catch (e: any) {
      console.error("isPlayerInGame failed:", e);
      return { success: false, error: e?.message ?? String(e) };
    }
  }
}

export const userService = new UserService();
