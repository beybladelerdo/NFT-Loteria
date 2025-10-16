import type { AuthStore } from "$lib/stores/auth-store";
import type { OptionIdentity } from "$lib/types/identity";
import { Actor, HttpAgent } from "@dfinity/agent";
import { get } from "svelte/store";
import { idlFactory as canister } from "../../../../declarations/backend";

export class ActorFactory {
  static async createActor(
    idlFactory: any,
    canisterId: string = "",
    identity: OptionIdentity = null,
    options: any = null,
  ) {
    const isDev =
      import.meta.env.DEV ||
      import.meta.env.MODE === "development" ||
      import.meta.env.VITE_DFX_NETWORK === "local" ||
      window.location.hostname === "localhost" ||
      window.location.hostname === "127.0.0.1";

    const hostOptions = {
      host: isDev ? `http://localhost:4943` : `https://ic0.app`,
      identity: identity,
    };

    if (!options) {
      options = {
        agentOptions: hostOptions,
      };
    } else if (!options.agentOptions) {
      options.agentOptions = hostOptions;
    } else {
      options.agentOptions.host = hostOptions.host;
    }

    const agent = new HttpAgent({ ...options.agentOptions });

    if (isDev) {
      console.log("🔑 Fetching root key for local development...");
      try {
        await agent.fetchRootKey();
        console.log("✅ Root key fetched successfully");
      } catch (err) {
        console.error("❌ Failed to fetch root key:", err);
        throw err;
      }
    }

    return Actor.createActor(idlFactory, {
      agent,
      canisterId: canisterId,
      ...options?.actorOptions,
    });
  }

  static async getAgent(
    canisterId: string = "",
    identity: OptionIdentity = null,
    options: any = null,
  ): Promise<HttpAgent> {
    const isDev =
      import.meta.env.DEV ||
      import.meta.env.MODE === "development" ||
      import.meta.env.VITE_DFX_NETWORK === "local" ||
      window.location.hostname === "localhost" ||
      window.location.hostname === "127.0.0.1";

    const hostOptions = {
      host: isDev ? `http://localhost:4943` : `https://ic0.app`,
      identity: identity,
    };

    if (!options) {
      options = {
        agentOptions: hostOptions,
      };
    } else if (!options.agentOptions) {
      options.agentOptions = hostOptions;
    } else {
      options.agentOptions.host = hostOptions.host;
    }

    const agent = new HttpAgent({ ...options.agentOptions });

    if (isDev) {
      await agent.fetchRootKey();
    }

    return agent;
  }

  static async createIdentityActor(authStore: AuthStore, canisterId: string) {
    // Use get() to read the store value directly - much simpler!
    const store = get(authStore);
    const identity = store.identity;

    if (!identity) {
      throw new Error("No identity found in auth store");
    }

    return await ActorFactory.createActor(canister, canisterId, identity);
  }
}
