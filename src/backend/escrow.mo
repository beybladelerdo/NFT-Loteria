/**
 * NFT Lotería - Escrow
 * Payment processing and ledger interactions
 * 
 * @author Demali Gregg
 * @company Canister Software Inc.
 */

import T "Types";
import Map "mo:core/Map";
import Text "mo:core/Text";
import Blob "mo:core/Blob";
import Principal "mo:core/Principal";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Error "mo:base/Error";
import Utils "Utilities";
import Nat "mo:core/Nat";
import Analytics "Analytics";
import List "mo:core/List";
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

  public func ledgerOf(token : T.TokenType) : Escrow.Ledger {
    switch (token) {
      case (#ckBTC) actor ("mxzaz-hqaaa-aaaar-qaada-cai") : Escrow.Ledger;
      case (#gldt)  actor ("6c7su-kiaaa-aaaar-qaira-cai")  : Escrow.Ledger;
      case (#ICP)   actor ("ryjl3-tyaaa-aaaaa-aaaba-cai") : Escrow.Ledger;
      }
    };
  public func acct(owner : Principal, sub : ?[Nat8]) : Escrow.Account = { owner = owner; subaccount = sub };

  public func processPayouts(
    selfPrincipal : Principal,
    devWallet : ?Principal,
    analytics : Analytics.AnalyticsState,
    failedClaims : Map.Map<Text, T.FailedClaim>,
    gameId : Text,
    claim : T.FailedClaim
  ) : async Result.Result<(), Text> {
    let l = ledgerOf(claim.tokenType);
    let potAcct = acct(selfPrincipal, ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
    let now_ns = Nat64.fromNat(Int.abs(Time.now()));
    
    var status = claim.payoutStatus;
    var lastError = "";

    // Dev fee
    if (not status.devFeePaid and claim.devFee > 0) {
      let devAcct = acct(selfPrincipal, ?Blob.toArray(Utils.devFeeSubAcc()));
      let res = await l.icrc1_transfer({
        from_subaccount = potAcct.subaccount;
        to = devAcct;
        amount = claim.devFee;
        fee = null;
        memo = ?Text.encodeUtf8(gameId);
        created_at_time = ?now_ns
      });
      switch (res) {
        case (#Ok _) {
          status := { status with devFeePaid = true };
          switch (devWallet) {
            case (?wallet) { 
              ignore await l.icrc1_transfer({
                from_subaccount = ?Blob.toArray(Utils.devFeeSubAcc());
                to = acct(wallet, null);
                amount = claim.devFee;
                fee = null;
                memo = ?Text.encodeUtf8(gameId);
                created_at_time = ?now_ns
              }) 
            };
            case null {} 
          };
        };
        case (#Err e) { lastError := "Dev fee: " # debug_show e };
      };
    };

    // Tabla owner
    if (not status.tablaOwnerPaid) {
      switch (claim.tablaOwnerPayment) {
        case (?#icrc1(principal)) {
          if (claim.tablaOwnerFee > 0) {
            let res = await l.icrc1_transfer({
              from_subaccount = potAcct.subaccount;
              to = acct(principal, null);
              amount = claim.tablaOwnerFee;
              fee = null;
              memo = ?Text.encodeUtf8(gameId);
              created_at_time = ?now_ns
            });
            switch (res) {
              case (#Ok _) { 
                status := { status with tablaOwnerPaid = true };
                Analytics.recordTablaEarning(analytics, claim.tablaId, claim.tokenType, claim.tablaOwnerFee);
              };
              case (#Err e) { lastError := "Tabla owner ICRC1: " # debug_show e };
            };
          } else {
            status := { status with tablaOwnerPaid = true };
          };
        };
        case (?#icpAccount(accountBlob)) {
          if (claim.tablaOwnerFee > 0) {
            try {
              let icpLedger : actor {
                transfer : ({
                  to : Blob;
                  fee : { e8s : Nat64 };
                  memo : Nat64;
                  from_subaccount : ?Blob;
                  created_at_time : ?{ timestamp_nanos : Nat64 };
                  amount : { e8s : Nat64 };
                }) -> async { #Ok : Nat64; #Err : {
                  #TxTooOld : { allowed_window_nanos : Nat64 };
                  #BadFee : { expected_fee : { e8s : Nat64 } };
                  #TxDuplicate : { duplicate_of : Nat64 };
                  #TxCreatedInFuture;
                  #InsufficientFunds : { balance : { e8s : Nat64 } };
                }};
              } = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
              
              let res = await icpLedger.transfer({
                to = accountBlob;
                fee = { e8s = 10_000 };
                memo = 0;
                from_subaccount = ?Utils.prizePoolSubAcc(gameId);
                created_at_time = ?{ timestamp_nanos = now_ns };
                amount = { e8s = Nat64.fromNat(claim.tablaOwnerFee) };
              });
              switch (res) {
                case (#Ok _) { 
                  status := { status with tablaOwnerPaid = true };
                  Analytics.recordTablaEarning(analytics, claim.tablaId, claim.tokenType, claim.tablaOwnerFee);
                };
                case (#Err e) { lastError := "Tabla owner ICP legacy: " # debug_show e };
              };
            } catch (e) {
              lastError := "Tabla owner ICP legacy unavailable: " # Error.message(e);
            };
          } else {
            status := { status with tablaOwnerPaid = true };
          };
        };
        case null { status := { status with tablaOwnerPaid = true } };
      };
    };

    // Winner
    if (not status.winnerPaid) {
      let res = await l.icrc1_transfer({
        from_subaccount = potAcct.subaccount;
        to = acct(claim.player, null);
        amount = claim.winnerAmount;
        fee = null;
        memo = null;
        created_at_time = ?now_ns
      });
      switch (res) {
        case (#Ok _) { status := { status with winnerPaid = true } };
        case (#Err e) { lastError := "Winner: " # debug_show e };
      };
    };

    // Host
    if (not status.hostPaid) {
      let res = await l.icrc1_transfer({
        from_subaccount = potAcct.subaccount;
        to = acct(claim.host, null);
        amount = claim.hostFee;
        fee = null;
        memo = null;
        created_at_time = ?now_ns
      });
      switch (res) {
        case (#Ok _) { status := { status with hostPaid = true } };
        case (#Err e) { lastError := "Host: " # debug_show e };
      };
    };

    let criticalPayoutsComplete = status.devFeePaid and status.winnerPaid and status.hostPaid;
    
    if (criticalPayoutsComplete and status.tablaOwnerPaid) {
      Map.remove(failedClaims, Text.compare, gameId);
      #ok(())
    } else if (criticalPayoutsComplete and not status.tablaOwnerPaid) {
      Map.add(failedClaims, Text.compare, gameId, { claim with payoutStatus = status; lastError = lastError; failedAt = Time.now() });
      #ok(())
    } else {
      Map.add(failedClaims, Text.compare, gameId, { claim with payoutStatus = status; lastError = lastError; failedAt = Time.now() });
      #err("Partial payout. Retry needed: " # lastError)
    }
  };
  public func getPot(
  game : T.Game,
  selfPrincipal : Principal,
  gameId : Text
) : async { amountBaseUnits : Nat; symbol : Text; decimals : Nat8 } {
  let l = ledgerOf(game.tokenType);
  let potAcct = acct(selfPrincipal, ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
  let bal = await l.icrc1_balance_of(potAcct);
  let symbol = await l.icrc1_symbol();
  let decimals = await l.icrc1_decimals();
  { amountBaseUnits = bal; symbol; decimals };
};
public func disburseStuckPrize(
  selfPrincipal : Principal,
  game : T.Game,
  gameId : Text,
  winner : Principal
) : async Result.Result<Nat, Text> {
  let ledger = ledgerOf(game.tokenType);
  let fee = await ledger.icrc1_fee();
  
  let potAcct = acct(selfPrincipal, ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
  let balance = await ledger.icrc1_balance_of(potAcct);
  
  if (balance <= fee) {
    return #err("Balance too low to cover fee. Balance: " # Nat.toText(balance) # ", Fee: " # Nat.toText(fee));
  };
  
  let payoutAmount = balance - fee;
  
  let transferArgs : Icrc1TransferArgs = {
    from_subaccount = ?Blob.toArray(Utils.prizePoolSubAcc(gameId));
    to = { owner = winner; subaccount = null };
    amount = payoutAmount;
    fee = ?fee;
    memo = null;
    created_at_time = null;
  };
  
  switch (await ledger.icrc1_transfer(transferArgs)) {
    case (#Ok(blockIndex)) { #ok(blockIndex) };
    case (#Err(e)) { #err("Transfer failed: " # debug_show(e)) };
  };
};
public func disburseFromSubaccount(
  selfPrincipal : Principal,
  gameId : Text,
  token : T.TokenType,
  recipient : Principal,
  amount : Nat
) : async Result.Result<Nat, Text> {
  if (amount == 0) {
    return #err("Amount must be greater than 0");
  };
  
  let ledger = ledgerOf(token);
  let fee = await ledger.icrc1_fee();
  
  let potAcct = acct(selfPrincipal, ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
  let balance = await ledger.icrc1_balance_of(potAcct);
  
  if (balance < amount + fee) {
    return #err("Balance too low to cover fee. Balance: " # Nat.toText(balance) # ", Fee: " # Nat.toText(fee));
  };
  
  let transferArgs : Icrc1TransferArgs = {
    from_subaccount = potAcct.subaccount;
    to = { owner = recipient; subaccount = null };
    amount = amount;
    fee = ?fee;
    memo = null;
    created_at_time = null;
  };
  
  switch (await ledger.icrc1_transfer(transferArgs)) {
    case (#Ok(blockIndex)) { #ok(blockIndex) };
    case (#Err(e)) { #err("Transfer failed: " # debug_show(e)) };
  };
};
public func terminateGameRefunds(
  selfPrincipal : Principal,
  game : T.Game,
  gameId : Text,
  playerTablaCounts : Map.Map<Principal, Nat>
) : async { successfulRefunds : Nat; refundErrors : Text } {
  let ledger = ledgerOf(game.tokenType);
  let ledgerFee = await ledger.icrc1_fee();
  let prizePoolAcct = acct(selfPrincipal, ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
  
  var refundErrors = "";
  var successfulRefunds = 0;
  let now_ns = Nat64.fromNat(Int.abs(Time.now()));
  
  for ((playerId, tablaCount) in Map.entries(playerTablaCounts)) {
    let totalPaid = game.entryFee * tablaCount;
    
    if (totalPaid <= ledgerFee) {
      refundErrors := refundErrors # "Player " # Principal.toText(playerId) # ": refund amount too small; ";
    } else {
      let refundAmount = totalPaid - ledgerFee;
      
      let transferResult = await ledger.icrc1_transfer({
        from_subaccount = prizePoolAcct.subaccount;
        to = acct(playerId, null);
        amount = refundAmount;
        fee = ?ledgerFee;
        memo = null;
        created_at_time = ?now_ns;
      });
      
      switch (transferResult) {
        case (#Ok _) { successfulRefunds += 1 };
        case (#Err e) {
          refundErrors := refundErrors # "Player " # Principal.toText(playerId) # ": " # debug_show(e) # "; ";
        };
      };
    };
  };
  
  { successfulRefunds; refundErrors };
};
public func disburseDevFees(
  selfPrincipal : Principal,
  tokenType : T.TokenType,
  recipient : Principal,
  amount : Nat
) : async Result.Result<(), Text> {
  let l = ledgerOf(tokenType);
  let devAcct = acct(selfPrincipal, ?Blob.toArray(Utils.devFeeSubAcc()));
  let balance = await l.icrc1_balance_of(devAcct);
  
  if (balance < amount) return #err("Insufficient dev fee balance");
  
  let now_ns = Nat64.fromNat(Int.abs(Time.now()));
  let res = await l.icrc1_transfer({
    from_subaccount = devAcct.subaccount;
    to = acct(recipient, null);
    amount = amount;
    fee = null;
    memo = null;
    created_at_time = ?now_ns
  });
  
  switch (res) {
    case (#Ok _) #ok(());
    case (#Err e) #err("Disbursement failed: " # debug_show e);
  };
};

public func getDevFeeBalance(
  selfPrincipal : Principal,
  tokenType : T.TokenType
) : async Nat {
  let l = ledgerOf(tokenType);
  let devAcct = acct(selfPrincipal, ?Blob.toArray(Utils.devFeeSubAcc()));
  await l.icrc1_balance_of(devAcct);
};
public func findStuckGames(
  games : Map.Map<Text, T.Game>,
  selfPrincipal : Principal,
  threshold : Nat
) : async [(Text, Nat, T.TokenType)] {
  let out = List.empty<(Text, Nat, T.TokenType)>();
  
  for ((gameId, game) in Map.entries(games)) {
    if (game.status == #completed and game.winner != null) {
      let l = ledgerOf(game.tokenType);
      let potAcct = acct(selfPrincipal, ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
      let balance = await l.icrc1_balance_of(potAcct);
      
      if (balance > threshold) {
        List.add(out, (gameId, balance, game.tokenType));
      };
    };
  };
  
  List.toArray(out);
};
};
