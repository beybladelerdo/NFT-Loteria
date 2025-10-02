import { ActorFactory } from "../utils/ActorFactory";
import { authStore } from "$lib/stores/auth-store";
import type {
  _SERVICE,
  Profile,
  Result,
  Result_3,
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
      const res: Result_3 = await actor.getProfile();
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
}

export const userService = new UserService();
