import Enums "enums";
module Escrow {
  public type Account = { owner : Principal; subaccount : ?[Nat8] };

  public type AllowanceArgs = { account : Account; spender : Account };
  public type Allowance = { allowance : Nat; expires_at : ?Nat64 };

  public type TransferFromArgs = {
    from : Account;
    to : Account;
    amount : Nat;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
    spender_subaccount : ?[Nat8];
  };
  public type Icrc1TransferArgs = {
  from_subaccount : ?[Nat8];
  to              : Account;
  amount          : Nat;
  fee             : ?Nat;
  memo            : ?Blob;
  created_at_time : ?Nat64;
};

public type Icrc1TransferErr = {
  #BadFee : { expected_fee : Nat };
  #InsufficientFunds : { balance : Nat };
  #TxTooOld : { allowed_window_nanos : Nat64 };
  #TxCreatedInFuture : { ledger_time : Nat64 };
  #TxDuplicate : { duplicate_of : Nat };
  #TemporarilyUnavailable;
  #GenericError : { error_code : Nat; message : Text };
};

public type Icrc1TransferResult = { #Ok : Nat; #Err : Icrc1TransferErr };


  public type TransferFromError = {
    #InsufficientAllowance;
    #InsufficientFunds;
    #Expired;
    #TemporarilyUnavailable;
    #BadFee : { expected_fee : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferFromResult = { #Ok : Nat; #Err : TransferFromError };

  public type Ledger = actor {
    icrc1_symbol : shared query () -> async Text;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_transfer : shared (Icrc1TransferArgs) -> async Icrc1TransferResult;
    icrc1_balance_of : shared query (Account) -> async Nat;
    icrc2_allowance : shared query (AllowanceArgs) -> async Allowance;
    icrc2_transfer_from : shared (TransferFromArgs) -> async TransferFromResult;
  };

  public func ledgerOf(token : Enums.TokenType) : Escrow.Ledger {
    switch (token) {
      case (#ckBTC) actor ("mxzaz-hqaaa-aaaar-qaada-cai") : Escrow.Ledger;
      case (#gldt)  actor ("6c7su-kiaaa-aaaar-qaira-cai")  : Escrow.Ledger;
      case (#ICP)   actor ("ryjl3-tyaaa-aaaaa-aaaba-cai") : Escrow.Ledger;
      }
    };
  public func acct(owner : Principal, sub : ?[Nat8]) : Escrow.Account = { owner = owner; subaccount = sub };


};
