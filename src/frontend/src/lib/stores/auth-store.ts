import {
  AUTH_MAX_TIME_TO_LIVE,
  DEV,
  INTERNET_IDENTITY_CANISTER_ID,
} from "$lib/constants/app.constants";
import type { OptionIdentity } from "$lib/types/identity";
import { createAuthClient } from "$lib/utils/auth.utils";
import type { AuthClient } from "@dfinity/auth-client";
import { writable, type Readable } from "svelte/store";
import { ActorFactory } from "../utils/ActorFactory";
import { isError } from "$lib/utils/helpers";

export interface AuthStoreData {
  identity: OptionIdentity;
}

let authClient: AuthClient | undefined | null;

const NNS_IC_ORG_ALTERNATIVE_ORIGIN = "https://btcbingo.fun";
const NNS_IC_APP_DERIVATION_ORIGIN =
  "https://zgkut-yiaaa-aaaal-qsoqa-cai.icp0.io";

const isNnsAlternativeOrigin = () => {
  return window.location.origin === NNS_IC_ORG_ALTERNATIVE_ORIGIN;
};

export interface AuthSignInParams {
  domain?: "ic0.app" | "internetcomputer.org";
}

export interface AuthStore extends Readable<AuthStoreData> {
  sync: () => Promise<void>;
  signIn: (params: AuthSignInParams) => Promise<void>;
  signOut: () => Promise<void>;
  isAdmin: () => Promise<boolean>;
}

const initAuthStore = (): AuthStore => {
  const { subscribe, set, update } = writable<AuthStoreData>({
    identity: undefined,
  });

  return {
    subscribe,

    sync: async () => {
      authClient = authClient ?? (await createAuthClient());
      const isAuthenticated: boolean = await authClient.isAuthenticated();

      set({
        identity: isAuthenticated ? authClient.getIdentity() : null,
      });
    },

    signIn: ({ domain }: AuthSignInParams) =>
      new Promise<void>(async (resolve, reject) => {
        authClient = authClient ?? (await createAuthClient());

        const loginOptions: any = {
          maxTimeToLive: AUTH_MAX_TIME_TO_LIVE,
          onSuccess: () => {
            update((state: AuthStoreData) => ({
              ...state,
              identity: authClient?.getIdentity(),
            }));
            resolve();
          },
          onError: reject,
        };

        // Only set identityProvider in production
        if (!DEV) {
          loginOptions.identityProvider = domain;
        } else {
          // In dev mode, use the local Internet Identity
          loginOptions.identityProvider = INTERNET_IDENTITY_CANISTER_ID;
        }

        await authClient?.login(loginOptions);
      }),

    signOut: async () => {
      const client: AuthClient = authClient ?? (await createAuthClient());

      await client.logout();

      authClient = null;

      update((state: AuthStoreData) => ({
        ...state,
        identity: null,
      }));
      localStorage.removeItem("user_profile_data");
    },

    isAdmin: async (): Promise<boolean> => {
      const identityActor = await ActorFactory.createIdentityActor(
        authStore,
        process.env.BACKEND_CANISTER_ID ?? "",
      );

      const result = (await identityActor.isAdmin()) as boolean;
      if (isError(result)) return false;
      return result;
    },
  };
};

export const authStore = initAuthStore();

export const authRemainingTimeStore = writable<number | undefined>(undefined);
