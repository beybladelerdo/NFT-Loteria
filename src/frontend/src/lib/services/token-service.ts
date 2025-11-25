import { IcrcLedgerCanister } from "@dfinity/ledger-icrc";
import { Principal } from "@dfinity/principal";
import { ActorFactory } from "$lib/utils/ActorFactory";
import type { TokenType } from "../../../../declarations/backend/backend.did";
import { BACKEND_CANISTER_ID } from "$lib/constants/app.constants";

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
  fee: bigint | null;
}
export interface PotBalance {
  amountBaseUnits: bigint;
}
export class TokenService {
  /**
   * Get the ledger canister ID for a token type.
   */
  private getTokenCanisterId(tokenType: TokenType): string {
    if ("ICP" in tokenType) return CANISTER_IDS.ICP;
    if ("ckBTC" in tokenType) return CANISTER_IDS.CKBTC;
    if ("gldt" in tokenType) return CANISTER_IDS.GLDT;
    throw new Error("Unknown token type");
  }

  /**
   * Compute the subaccount hash for a prize pool (pot).
   */
  private async computePotSubaccount(gameId: string): Promise<Uint8Array> {
    const text = `pot:${gameId}`;
    const encoded = new TextEncoder().encode(text);
    const hashBuffer = await crypto.subtle.digest("SHA-256", encoded);
    return new Uint8Array(hashBuffer);
  }
  async getPotBalance(
    gameId: string,
    tokenType: TokenType,
    identity: any,
  ): Promise<PotBalance> {
    try {
      const tokenCanisterId = this.getTokenCanisterId(tokenType);
      const agent = await ActorFactory.getAgent(tokenCanisterId, identity);

      const ledger = IcrcLedgerCanister.create({
        agent,
        canisterId: Principal.fromText(tokenCanisterId),
      });

      const subaccount = await this.computePotSubaccount(gameId);

      const balance = await ledger.balance({
        owner: Principal.fromText(BACKEND_CANISTER_ID),
        subaccount: Array.from(subaccount),
        certified: false,
      });

      return {
        amountBaseUnits: balance,
      };
    } catch (error) {
      console.error(`Error fetching pot balance for game ${gameId}:`, error);
      throw error;
    }
  }
  /**
   * Approve an allowance for a spender.
   */
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
    const agent = await ActorFactory.getAgent(canisterId, identity);

    const ledger = IcrcLedgerCanister.create({
      agent,
      canisterId: Principal.fromText(canisterId),
    });

    const nowNs = BigInt(Date.now()) * 1_000_000n;
    const expiresAtNs = nowNs + 5n * 60n * 1_000_000_000n; // 5 minutes

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

  /**
   * Get the token balance for a specific canister.
   */
  async getTokenBalance(
    canisterId: string,
    owner: Principal,
    identity: any,
  ): Promise<bigint> {
    try {
      const agent = await ActorFactory.getAgent(canisterId, identity);

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
      return 0n;
    }
  }

  /**
   * Get the transaction fee for a given ledger canister.
   */
  async getTransactionFee(canisterId: string, identity: any): Promise<bigint> {
    try {
      const agent = await ActorFactory.getAgent(canisterId, identity);

      const ledger = IcrcLedgerCanister.create({
        agent,
        canisterId: Principal.fromText(canisterId),
      });

      const fee = await ledger.transactionFee({ certified: false });
      return fee;
    } catch (error) {
      console.error(`Error fetching transaction fee for ${canisterId}:`, error);
      return 0n;
    }
  }

  /**
   * Fetch balances for all supported tokens (ICP, ckBTC, GLDT).
   */
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
        fee: await this.getTransactionFee(CANISTER_IDS.ICP, identity),
      },
      {
        symbol: "ckBTC",
        name: "Chain Key Bitcoin",
        balance: ckbtcBalance,
        decimals: 8,
        icon: "/tokens/ck-BTC.svg",
        canisterId: CANISTER_IDS.CKBTC,
        fee: await this.getTransactionFee(CANISTER_IDS.CKBTC, identity),
      },
      {
        symbol: "GLDT",
        name: "Gold Token",
        balance: gldtBalance,
        decimals: 8,
        icon: "/tokens/gldt.png",
        canisterId: CANISTER_IDS.GLDT,
        fee: await this.getTransactionFee(CANISTER_IDS.GLDT, identity),
      },
    ];
  }

  /**
   * Convert a raw balance (bigint) into a human-readable string.
   */
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
