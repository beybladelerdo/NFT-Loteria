import { IcrcLedgerCanister } from "@dfinity/ledger-icrc";
import { Principal } from "@dfinity/principal";
import { createAgent } from "@dfinity/utils";

// Canister IDs
const CANISTER_IDS = {
  ICP: "ryjl3-tyaaa-aaaaa-aaaba-cai",
  CKBTC: "mxzaz-hqaaa-aaaar-qaada-cai",
  GLDT: "6c7su-kiaaa-aaaar-qaira-cai",
};

export interface TokenBalance {
  symbol: string;
  name: string;
  balance: bigint;
  decimals: number;
  icon: string;
  canisterId: string;
}

export class TokenService {
  async getTokenBalance(
    canisterId: string,
    owner: Principal,
    identity: any,
  ): Promise<bigint> {
    try {
      const agent = await createAgent({
        identity,
        host:
          import.meta.env.VITE_DFX_NETWORK === "ic"
            ? "https://icp-api.io"
            : "http://localhost:4943",
      });

      const ledger = IcrcLedgerCanister.create({
        agent,
        canisterId: Principal.fromText(canisterId),
      });

      const balance = await ledger.balance({
        owner,
        certified: false,
      });

      return balance;
    } catch (error) {
      console.error(`Error fetching balance for ${canisterId}:`, error);
      return BigInt(0);
    }
  }

  async getAllBalances(
    owner: Principal,
    identity: any,
  ): Promise<TokenBalance[]> {
    const [icpBalance, ckbtcBalance, gldtBalance] = await Promise.all([
      this.getTokenBalance(CANISTER_IDS.ICP, owner, identity),
      this.getTokenBalance(CANISTER_IDS.CKBTC, owner, identity),
      this.getTokenBalance(CANISTER_IDS.GLDT, owner, identity),
    ]);

    return [
      {
        symbol: "ICP",
        name: "Internet Computer",
        balance: icpBalance,
        decimals: 8,
        icon: "/tokens/ICP.svg",
        canisterId: CANISTER_IDS.ICP,
      },
      {
        symbol: "ckBTC",
        name: "Chain Key Bitcoin",
        balance: ckbtcBalance,
        decimals: 8,
        icon: "/tokens/ck-BTC.svg",
        canisterId: CANISTER_IDS.CKBTC,
      },
      {
        symbol: "GLDT",
        name: "Gold Token",
        balance: gldtBalance,
        decimals: 8,
        icon: "/tokens/gldt.png",
        canisterId: CANISTER_IDS.GLDT,
      },
    ];
  }

  formatBalance(balance: bigint, decimals: number): string {
    const divisor = BigInt(10 ** decimals);
    const whole = balance / divisor;
    const fraction = balance % divisor;

    if (fraction === BigInt(0)) {
      return whole.toString();
    }

    const fractionStr = fraction.toString().padStart(decimals, "0");
    const trimmedFraction = fractionStr.replace(/0+$/, "");

    return `${whole}.${trimmedFraction}`;
  }
}
