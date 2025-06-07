import { writable } from "svelte/store";
import type { Identity, Actor } from "@dfinity/agent";
import { createAuthClient } from "$lib/utils/auth.utils";
import { popupCenter } from "$lib/utils/window.utils";
import { ActorFactory } from "$lib/utils/actor.factory";

export interface AuthStoreData {
  identity: Identity | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  principal: string | null;
  userBalance: { ICP: number; ckBTC: number };
  actors: {
    gameLogic: Actor | null;
    tablaRental: Actor | null;
    paymentSystem: Actor | null;
  };
}

const AUTH_MAX_TIME_TO_LIVE = BigInt(7 * 24 * 60 * 60 * 1000_000_000);
const AUTH_POPUP_WIDTH = 600;
const AUTH_POPUP_HEIGHT = 700;
const NNS_IC_ORG_ALTERNATIVE_ORIGIN = "https://ic1.xyz";
const NNS_IC_APP_DERIVATION_ORIGIN =
  "https://zgkut-yiaaa-aaaal-qsoqa-cai.icp0.io";

const isNnsAlternativeOrigin = () =>
  window.location.origin === NNS_IC_ORG_ALTERNATIVE_ORIGIN;

export interface AuthSignInParams {
  domain?: "ic0.app" | "internetcomputer.org";
}

let authClient: AuthClient | null | undefined;
let data = $state<AuthStoreData>({
  identity: null,
  isAuthenticated: false,
  isLoading: true,
  principal: null,
  userBalance: { ICP: 0, ckBTC: 0 },
  actors: {
    gameLogic: null,
    tablaRental: null,
    paymentSystem: null,
  },
});

export const authStore = {
  get value() {
    return $derived(data);
  },
  sync: async () => {
    data.isLoading = true;
    authClient = authClient ?? (await createAuthClient());
    const isAuthenticated = await authClient.isAuthenticated();
    const identity = isAuthenticated ? authClient.getIdentity() : null;
    data = {
      ...data,
      identity,
      isAuthenticated,
      principal: identity?.getPrincipal().toString() ?? null,
      actors: await createActors(identity),
      isLoading: false,
    };
    if (isAuthenticated) {
      await authStore.refreshBalance();
    }
  },
  signIn: async ({ domain }: AuthSignInParams) => {
    authClient = authClient ?? (await createAuthClient());
    const identityProvider =
      domain === "ic0.app"
        ? "https://identity.ic0.app"
        : "https://identity.internetcomputer.org";

    await authClient?.login({
      maxTimeToLive: AUTH_MAX_TIME_TO_LIVE,
      onSuccess: async () => {
        const identity = authClient?.getIdentity() ?? null;
        data = {
          ...data,
          identity,
          isAuthenticated: true,
          principal: identity?.getPrincipal().toString() ?? null,
          actors: await createActors(identity),
          isLoading: false,
        };
        await authStore.refreshBalance();
      },
      onError: (err) => {
        console.error("Login failed:", err);
        data.isLoading = false;
      },
      identityProvider,
      ...(isNnsAlternativeOrigin() && {
        derivationOrigin: NNS_IC_APP_DERIVATION_ORIGIN,
      }),
      windowOpenerFeatures: popupCenter({
        width: AUTH_POPUP_WIDTH,
        height: AUTH_POPUP_HEIGHT,
      }),
    });
  },
  signOut: async () => {
    const client = authClient ?? (await createAuthClient());
    await client.logout();
    authClient = null;
    data = {
      identity: null,
      isAuthenticated: false,
      isLoading: false,
      principal: null,
      userBalance: { ICP: 0, ckBTC: 0 },
      actors: { gameLogic: null, tablaRental: null, paymentSystem: null },
    };
  },
  async refreshBalance() {
    try {
      const actor: any = await ActorFactory.createIdentityActor(
        authStore,
        process.env.PAYMENT_SYSTEM_CANISTER_ID ?? "",
      );
      const balances: any = await actor.getUserBalance();
      data.userBalance = {
        ICP: balances?.ICP / 100000000 || 0,
        ckBTC: balances?.ckBTC / 100000000 || 0,
      };
    } catch (error) {
      console.error("Error refreshing balance:", error);
    }
  },
};

async function createActors(identity: Identity | null) {
  if (!identity) {
    return { gameLogic: null, tablaRental: null, paymentSystem: null };
  }
  try {
    const gameLogic = await ActorFactory.createIdentityActor(
      authStore,
      process.env.GAME_LOGIC_CANISTER_ID ?? "",
    );
    const tablaRental = await ActorFactory.createIdentityActor(
      authStore,
      process.env.TABLA_RENTAL_CANISTER_ID ?? "",
    );
    const paymentSystem = await ActorFactory.createIdentityActor(
      authStore,
      process.env.PAYMENT_SYSTEM_CANISTER_ID ?? "",
    );
    return { gameLogic, tablaRental, paymentSystem };
  } catch (error) {
    console.error("Error creating actors:", error);
    return { gameLogic: null, tablaRental: null, paymentSystem: null };
  }
}
