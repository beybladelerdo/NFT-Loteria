import { ActorFactory } from "../utils/actor.factory";
import { authStore } from "$lib/stores/auth-store";
import type {
  CreateProfile,
  IsUsernameValid,
  Profile,
  SendMessage,
  UpdateProfile,
} from "../../../../declarations/backend/backend.did";
import { isError } from "$lib/utils/helpers";

export class UserService {
  async getProfile(): Promise<Profile | undefined> {
    try {
      const identityActor: any = await ActorFactory.createIdentityActor(
        authStore,
        process.env.BACKEND_CANISTER_ID ?? "",
      );
      const result: any = await identityActor.getProfile();
      if (isError(result)) {
        return undefined;
      }
      return result.ok;
    } catch (error) {
      console.error("Error fetching profile: ", error);
      return undefined;
    }
  }

  async isUsernameValid(username: string): Promise<boolean> {
    const identityActor: any = await ActorFactory.createIdentityActor(
      authStore,
      process.env.BACKEND_CANISTER_ID ?? "",
    );
    let dto: IsUsernameValid = { username };
    return await identityActor.isUsernameValid(dto);
  }

  async createProfile(username: string): Promise<any> {
    try {
      const identityActor = await ActorFactory.createIdentityActor(
        authStore,
        process.env.BACKEND_CANISTER_ID ?? "",
      );
      let dto: CreateProfile = { username };
      const result = await identityActor.createProfile(dto);
      return result;
    } catch (error) {
      console.error("Error creating profile: ", error);
      throw error;
    }
  }

  async updateProfile(username: string): Promise<any> {
    try {
      const identityActor = await ActorFactory.createIdentityActor(
        authStore,
        process.env.BACKEND_CANISTER_ID ?? "",
      );
      let dto: UpdateProfile = { username };
      const result = await identityActor.updateProfile(dto);
      return result;
    } catch (error) {
      console.error("Error creating profile: ", error);
      throw error;
    }
  }

  async deleteProfile(): Promise<any> {
    try {
      const identityActor = await ActorFactory.createIdentityActor(
        authStore,
        process.env.BACKEND_CANISTER_ID ?? "",
      );
      const result = await identityActor.deleteProfile();
      return result;
    } catch (error) {
      console.error("Error deleting profile: ", error);
      throw error;
    }
  }
}
