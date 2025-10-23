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
  async approve(
    canisterId: string,
    identity: any,
    args: {
      amount: bigint;
      spender: { owner: Principal; subaccount?: Uint8Array | number[] | null };
      fromSubaccount?: Uint8Array | number[] | null;
      fee?: bigint;
      memo?: Uint8Array | number[];
      expectedAllowance?: bigint;
    },
  ): Promise<bigint> {
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

    const nowNs = BigInt(Date.now()) * 1_000_000n;
    const expiresAtNs = nowNs + 5n * 60n * 1_000_000_000n;

    const res = await ledger.approve({
      amount: args.amount,
      spender: {
        owner: args.spender.owner,
        subaccount:
          args.spender.subaccount != null
            ? [
                args.spender.subaccount instanceof Uint8Array
                  ? args.spender.subaccount
                  : Uint8Array.from(args.spender.subaccount),
              ]
            : [],
      },
      from_subaccount:
        args.fromSubaccount != null
          ? args.fromSubaccount instanceof Uint8Array
            ? args.fromSubaccount
            : Uint8Array.from(args.fromSubaccount)
          : undefined,
      fee: args.fee,
      memo:
        args.memo != null
          ? args.memo instanceof Uint8Array
            ? args.memo
            : Uint8Array.from(args.memo)
          : undefined,
      expected_allowance: args.expectedAllowance,
      created_at_time: nowNs,
      expires_at: expiresAtNs,
    });

    return res;
  }

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
