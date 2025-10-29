// $lib/utils/auth.utils.ts
import { AuthClient, LocalStorage } from "@dfinity/auth-client";
import { DEV, INTERNET_IDENTITY_CANISTER_ID } from "$lib/constants/app.constants";

export const createAuthClient = async (): Promise<AuthClient> => {
  const base = {
    idleOptions: { disableIdle: true, disableDefaultIdleCallback: true },
  } as const;

  const url = typeof window !== "undefined" ? new URL(window.location.href) : undefined;
  const override = url?.searchParams.get("ephemeral");

  const useSession =
    override === "session" || (override == null && DEV);

  const storage =
    typeof window !== "undefined" && useSession
      ? new LocalStorage("ic-", window.sessionStorage)
      : undefined; // undefined => default IndexedDB (persistent)

  const devCfg = { ...base, storage, identityProvider: INTERNET_IDENTITY_CANISTER_ID };
  const prodCfg = { ...base, storage };

  return AuthClient.create(DEV ? devCfg : prodCfg);
};
