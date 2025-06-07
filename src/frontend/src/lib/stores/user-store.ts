import { UserService } from "$lib/services/user-service";
import type { Profile } from "../../../../declarations/backend/backend.did";

function createUserStore() {
  async function getProfile(): Promise<Profile | undefined> {
    return new UserService().getProfile();
  }

  async function isUsernameValid(username: string): Promise<boolean> {
    return new UserService().isUsernameValid(username);
  }

  async function createProfile(username: string): Promise<any> {
    return new UserService().createProfile(username);
  }

  async function updateProfile(username: string): Promise<any> {
    return new UserService().updateProfile(username);
  }

  async function deleteProfile(): Promise<any> {
    return new UserService().deleteProfile();
  }

  return {
    getProfile,
    createProfile,
    updateProfile,
    isUsernameValid,
    deleteProfile,
  };
}

export const userStore = createUserStore();
