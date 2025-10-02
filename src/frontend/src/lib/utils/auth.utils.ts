import { AuthClient } from "@dfinity/auth-client";
import {
  DEV,
  INTERNET_IDENTITY_CANISTER_ID,
} from "$lib/constants/app.constants";

export const createAuthClient = async (): Promise<AuthClient> => {
  const devConfig = {
    idleOptions: {
      disableIdle: true,
      disableDefaultIdleCallback: true,
    },
    identityProvider: INTERNET_IDENTITY_CANISTER_ID,
  };

  const prodConfig = {
    idleOptions: {
      disableIdle: true,
      disableDefaultIdleCallback: true,
    },
  };

  return AuthClient.create(DEV ? devConfig : prodConfig);
};
