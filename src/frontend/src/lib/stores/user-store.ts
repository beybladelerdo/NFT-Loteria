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

  return {
    getProfile,
    createProfile,
    updateTag,
    isTagAvailable,
  };
}

export const userStore = createUserStore();
