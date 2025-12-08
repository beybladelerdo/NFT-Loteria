/**
 * NFT Lotería - Main Actor
 * Entry point and state management for the Lotería platform
 *
 * @author Demali Gregg
 * @company Canister Software Inc.
 *
 */

import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import PRNG "mo:core/internal/PRNG";
import Text "mo:core/Text";
import Nat64 "mo:core/Nat64";
import Nat32 "mo:core/Nat32";
import Int "mo:core/Int";
import Time "mo:core/Time";
import Result "mo:core/Result";
import T "Types";
import Constants "Constants";
import Enums "mo:waterway-mops/base/enums";
import Map "mo:core/Map";
import Random "mo:core/Random";
import Array "mo:core/Array";
import List "mo:core/List";
import Blob "mo:core/Blob";
import Escrow "Escrow";
import Analytics "Analytics";
import Utils "Utilities";
import Ids "Ids";
import Commands "Commands";
import Queries "Queries";
import Admin "Admin";

persistent actor GameLogic {

  /* ===== STATE ===== */
  
  // Core game state
  private var games = Map.empty<Text, T.Game>();
  private var activeGames = Map.empty<Text, T.Game>();
  private var gameChats = Map.empty<Text, List.List<T.ChatMessage>>();
  private var gameSubaccounts = Map.empty<Text, Blob>();
  
  // Player state
  private var profiles = Map.empty<Principal, T.Profile>();
  private var tags = Map.empty<Text, Principal>();
  private var paidSet = Map.empty<T.PaidKey, Bool>();
  
  // Tabla/NFT state
  private var tablas = Map.empty<Nat32, T.Tabla>();
  private var owners = Map.empty<Nat32, Text>();
  private var ownerPrincipals = Map.empty<Nat32, ?Principal>();
  
  // Admin state
  private var admins = Map.empty<Principal, Bool>();
  private var devWallet : ?Principal = null;
  
  // Analytics & claims
  private var analytics = Analytics.emptyState();
  private var failedClaims = Map.empty<Text, T.FailedClaim>();
  
  // Transient/locks
  transient let rng = PRNG.sfc64a();
  rng.init(Nat64.fromIntWrap(Time.now()));
  transient let crypto = Random.crypto();
  let gameLocks = Map.empty<Text, Bool>();
  let drawLocks = Map.empty<Text, Bool>();

  /* ===== HELPER ===== */
  
  func cardAt(tablaId : Ids.TablaId, pos : T.Position) : Result.Result<Ids.CardId, Text> {
    let size = Constants.TABLA_SIZE;
    let idx = pos.row * size + pos.col;
    switch (Map.get<Nat32, T.Tabla>(tablas, Nat32.compare, tablaId)) {
      case (?tabla) {
        if (idx < Array.size(tabla.metadata.cards)) #ok(Nat32.fromNat(tabla.metadata.cards[idx])) 
        else #err("cardAt: index out of bounds");
      };
      case null { #err("cardAt: tabla layout not found") };
    };
  };

  /* ===== ADMIN ===== */
  
  public shared ({ caller }) func bootstrapAdmin() : async Result.Result<(), Text> {
    Admin.bootstrap(admins, caller);
  };

  public shared ({ caller }) func adminAdd(p : Principal) : async Result.Result<(), Text> {
    if (not Admin.isAdmin(admins, caller)) return #err("unauthorized");
    Admin.add(admins, p);
    #ok();
  };

  public shared ({ caller }) func setDevWallet(wallet : ?Principal) : async Result.Result<(), Text> {
    if (not Admin.isAdmin(admins, caller)) return #err("unauthorized");
    devWallet := wallet;
    #ok();
  };

  public shared ({ caller }) func initRegistry(r : [(Nat32, Text)]) : async Result.Result<(), Text> {
    Admin.initRegistry(admins, owners, caller, r);
  };

  public shared ({ caller }) func upsertOwnerPrincipals(entries : [(Nat32, ?Principal)]) : async Result.Result<(), Text> {
    Admin.upsertOwnerPrincipals(admins, ownerPrincipals, caller, entries);
  };

  public shared query ({ caller }) func getGameSubaccount(gameId : Text) : async Result.Result<Blob, Text> {
    Admin.getGameSubaccount(admins, gameSubaccounts, caller, gameId);
  };

  public shared query ({ caller }) func listGameSubaccounts() : async Result.Result<[(Text, Blob)], Text> {
    Admin.listGameSubaccounts(admins, gameSubaccounts, caller);
  };

  public shared ({ caller }) func deleteTabla(tablaId : Nat32) : async Result.Result<(), Text> {
    Admin.deleteTabla(admins, tablas, caller, tablaId);
  };

  public shared ({ caller }) func deleteGame(gameId : Text) : async Result.Result<(), Text> {
    Admin.deleteGame(admins, games, caller, gameId);
  };

  public shared ({ caller }) func adminBatchTablas(dtos : [Commands.CreateTabla]) : async Result.Result<[Nat32], Text> {
    Admin.batchTablas(admins, tablas, owners, caller, dtos);
  };

  public shared ({ caller }) func adminUpdateTablaMetadata(dto : Commands.UpdateTablaMetadata) : async Result.Result<(), Text> {
    Admin.updateTablaMetadata(admins, tablas, caller, dto);
  };

  public shared ({ caller }) func adminDisburseFromSubaccount(gameId : Text, token : T.TokenType, recipient : Principal, amount : Nat) : async Result.Result<Nat, Text> {
    if (not Admin.isAdmin(admins, caller)) return #err("Not authorized");
    await Escrow.disburseFromSubaccount(Principal.fromActor(GameLogic), gameId, token, recipient, amount);
  };

  public shared ({ caller }) func adminDisburseStuckPrize(gameId : Text) : async Result.Result<Nat, Text> {
    if (not Admin.isAdmin(admins, caller)) return #err("Not authorized");
    let ?game = Map.get(games, Text.compare, gameId) else return #err("Game not found");
    let ?winner = game.winner else return #err("No winner set");
    await Escrow.disburseStuckPrize(Principal.fromActor(GameLogic), game, gameId, winner);
  };

  public shared ({ caller }) func terminateGame(gameId : Text) : async Result.Result<Text, Text> {
    let game = switch (Admin.validateTerminateGame(admins, games, caller, gameId)) {
      case (#ok(g)) g;
      case (#err(e)) return #err(e);
    };
    if (Array.size(game.tablas) == 0) {
      ignore Map.take(games, Text.compare, gameId);
      return #ok("Game deleted successfully (no players to refund)");
    };
    let playerTablaCounts = Commands.buildPlayerTablaCounts(game);
    let { successfulRefunds; refundErrors } = await Escrow.terminateGameRefunds(
      Principal.fromActor(GameLogic), game, gameId, playerTablaCounts
    );
    if (refundErrors == "") {
      ignore Map.take(games, Text.compare, gameId);
      #ok("Game terminated successfully. Refunded " # Nat.toText(successfulRefunds) # " player(s)");
    } else {
      #err("Game termination failed. Refunded " # Nat.toText(successfulRefunds) # " player(s). Errors: " # refundErrors);
    };
  };

  public shared ({ caller }) func disburseDevFees(tokenType : T.TokenType, recipient : Principal, amount : Nat) : async Result.Result<(), Text> {
    if (not Admin.isAdmin(admins, caller)) return #err("unauthorized");
    await Escrow.disburseDevFees(Principal.fromActor(GameLogic), tokenType, recipient, amount);
  };

  public shared func findStuckGames(threshold : Nat) : async [(Text, Nat, T.TokenType)] {
    await Escrow.findStuckGames(games, Principal.fromActor(GameLogic), threshold);
  };

  /* ===== PROFILE ===== */
  
  public shared ({ caller }) func createProfile(tag : Text) : async Result.Result<(), Text> {
    Commands.createProfile(profiles, tags, caller, tag);
  };

  public shared ({ caller }) func updateTag(newTag : Text) : async Result.Result<(), Text> {
    Commands.updateTag(profiles, tags, caller, newTag);
  };

  public query ({ caller }) func getProfile() : async Result.Result<T.Profile, Text> {
    Queries.getProfile(profiles, caller);
  };

  public query func getPlayerProfile(t : Text) : async Result.Result<T.Profile, Text> {
    Queries.getPlayerProfile(tags, profiles, t);
  };

  public query func isTagAvailable(tag : Text) : async Bool {
    Queries.isTagAvailable(tags, tag);
  };

  /* ===== REGISTRY ===== */
  
  public func refreshRegistry() : async () {
    await Utils.refresh(owners);
  };

  public query func ownerOf(idx : Nat32) : async (?Text, ?Principal) {
    Queries.ownerOf(owners, ownerPrincipals, idx);
  };

  /* ===== GAME LIFECYCLE ===== */
  
  public shared ({ caller }) func createGame(params : Commands.CreateGame) : async Result.Result<Text, Text> {
    Commands.createGame(games, gameSubaccounts, rng, caller, params);
  };

  public shared ({ caller }) func joinGame(dto : Commands.JoinGame) : async Result.Result<(), Text> {
    let game = switch (Commands.validateJoinGame(games, caller, dto)) {
      case (#ok(g)) g;
      case (#err(e)) return #err(e);
    };
    Commands.reserveTablas(games, game, dto.gameId, caller, dto.rentedTablaIds);
    if (not Utils.hasPaid(paidSet, dto.gameId, caller)) {
      let totalEntryFee = game.entryFee * dto.rentedTablaIds.size();
      let l = Escrow.ledgerOf(game.tokenType);
      let now_ns = Nat64.fromNat(Int.abs(Time.now()));
      let from = Escrow.acct(caller, null);
      let to = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(Utils.prizePoolSubAcc(dto.gameId)));
      let spender = Escrow.acct(Principal.fromActor(GameLogic), null);
      let a = await l.icrc2_allowance({ account = from; spender });
      switch (a.expires_at) {
        case (?exp) {
          if (exp <= now_ns / 1_000_000_000) {
            Commands.removeTablaReservation(games, dto.gameId, caller, dto.rentedTablaIds);
            return #err("Allowance expired; approve again");
          };
        };
        case null {};
      };
      if (a.allowance < totalEntryFee) {
        Commands.removeTablaReservation(games, dto.gameId, caller, dto.rentedTablaIds);
        return #err("Allowance too low; approve at least " # Nat.toText(totalEntryFee));
      };
      let pulled = await l.icrc2_transfer_from({
        from; to; amount = totalEntryFee;
        fee = null; memo = null;
        created_at_time = ?now_ns;
        spender_subaccount = null
      });
      switch (pulled) {
        case (#Ok amount) {
          Analytics.recordVolume(analytics, game.tokenType, amount);
          Utils.markPaid(paidSet, dto.gameId, caller);
        };
        case (#Err err) {
          Commands.removeTablaReservation(games, dto.gameId, caller, dto.rentedTablaIds);
          return #err(
            switch err {
              case (#InsufficientAllowance) "Insufficient allowance";
              case (#InsufficientFunds) "Insufficient funds";
              case (#Expired) "Transfer expired; try again";
              case (#TemporarilyUnavailable) "Ledger temporarily unavailable";
              case (#BadFee {}) "Bad fee";
              case (#Duplicate {}) "Duplicate transfer";
              case (#BadBurn {}) "Bad burn";
              case (#GenericError { message }) "Ledger error: " # message;
            }
          );
        };
      };
    };
    Commands.addPlayerToGame(games, dto.gameId, caller);
  };

  public shared ({ caller }) func startGame(gameId : Text) : async Result.Result<(), Text> {
    let game = switch (Commands.validateStartGame(games, paidSet, gameLocks, caller, gameId)) {
      case (#ok(g)) g;
      case (#err(e)) return #err(e);
    };
    Commands.applyStartGame(games, gameLocks, game, gameId);
    #ok();
  };

  public shared ({ caller }) func leaveGame(gameId : Text) : async Result.Result<(), Text> {
    let { game; tablaCount; playerPaid } = switch (Commands.validateLeaveGame(games, paidSet, gameLocks, caller, gameId)) {
      case (#ok(v)) v;
      case (#err(e)) return #err(e);
    };
    var clearPaid = false;
    if (playerPaid and tablaCount > 0) {
      let l = Escrow.ledgerOf(game.tokenType);
      let ledgerFee = await l.icrc1_fee();
      let potAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
      let totalPaid = game.entryFee * tablaCount;
      if (totalPaid <= ledgerFee) {
        Utils.unlock(gameLocks, gameId);
        return #err("Refund amount too small to cover network fee");
      };
      let refundAmount = totalPaid - ledgerFee;
      let now_ns = Nat64.fromNat(Int.abs(Time.now()));
      let transferResult = await l.icrc1_transfer({
        from_subaccount = potAcct.subaccount;
        to = Escrow.acct(caller, null);
        amount = refundAmount;
        fee = ?ledgerFee;
        memo = null;
        created_at_time = ?now_ns
      });
      switch (transferResult) {
        case (#Err e) {
          Utils.unlock(gameLocks, gameId);
          return #err("Refund failed: " # debug_show(e));
        };
        case (#Ok _) { clearPaid := true };
      };
    };
    Commands.applyLeaveGame(games, paidSet, gameLocks, game, gameId, caller, clearPaid);
    #ok();
  };

  public shared ({ caller }) func endGame(gameId : Text) : async Result.Result<(), Text> {
    Commands.endGame(games, caller, gameId);
  };

  /* ===== GAMEPLAY ===== */
  
  public shared ({ caller }) func drawCard(gameId : Text) : async Result.Result<Ids.CardId, Text> {
    let game = switch (Commands.validateDrawCard(games, drawLocks, caller, gameId)) {
      case (#ok(g)) g;
      case (#err(e)) return #err(e);
    };
    let remaining = Constants.TOTAL_CARDS - game.drawnCards.size();
    let k : Nat = await* crypto.natRange(0, remaining);
    let cardId = switch (Commands.selectCard(game, k)) {
      case (#ok(c)) c;
      case (#err(e)) {
        Utils.unlock(drawLocks, gameId);
        return #err(e);
      };
    };
    Commands.applyDrawCard(games, game, gameId, cardId);
    Utils.unlock(drawLocks, gameId);
    #ok(cardId);
  };

  public shared ({ caller }) func markPosition(gameId : Text, tablaId : Ids.TablaId, position : T.Position) : async Result.Result<(), Text> {
    Commands.markPosition(games, caller, gameId, tablaId, position);
  };

  public shared ({ caller }) func claimWin(gameId : Text, tablaId : Ids.TablaId) : async Result.Result<(), Text> {
    let game = switch (Commands.validateClaimWin(games, tablas, caller, gameId, tablaId)) {
      case (#ok(g)) g;
      case (#err(e)) return #err(e);
    };
    let won = switch (Commands.checkWinCondition(game, tablas, caller, tablaId, cardAt)) {
      case (#ok(w)) w;
      case (#err(e)) return #err(e);
    };
    if (not won) return #err("Win condition not met");
    Commands.applyWinner(games, profiles, analytics, game, gameId, tablaId, caller);
    let l = Escrow.ledgerOf(game.tokenType);
    let potAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(Utils.prizePoolSubAcc(gameId)));
    let pot = await l.icrc1_balance_of(potAcct);
    Analytics.recordLargestPot(analytics, game.tokenType, pot);
    let tablaOwnerPayment = Commands.resolveTablaOwnerPayment(owners, ownerPrincipals, tablaId, game.tokenType);
    let icrcFee = await l.icrc1_fee();
    let payouts = switch (Commands.calculatePayouts(pot, tablaOwnerPayment, game.hostFeePercent, icrcFee)) {
      case (#ok(p)) p;
      case (#err(e)) return #err(e);
    };
    let claim = Commands.buildFailedClaim(gameId, tablaId, caller, game, tablaOwnerPayment, payouts);
    Map.add(failedClaims, Text.compare, gameId, claim);
    await Escrow.processPayouts(Principal.fromActor(GameLogic), devWallet, analytics, failedClaims, gameId, claim);
  };

  /* ===== CHAT ===== */
  
  public shared ({ caller }) func sendChatMessage(gameId : Text, message : Text) : async Result.Result<(), Text> {
    Commands.sendChatMessage(games, gameChats, profiles, caller, gameId, message);
  };

  public query func getChatMessages(gameId : Text) : async [T.ChatMessage] {
    Queries.getChatMessages(gameChats, gameId);
  };

  public func clearGameChat(gameId : Text) : async () {
    Commands.clearGameChat(gameChats, gameId);
  };

  /* ===== CLAIMS ===== */
  
  public shared ({ caller }) func retryFailedClaim(gameId : Text) : async Result.Result<(), Text> {
    let ?claim = Map.get(failedClaims, Text.compare, gameId) else return #err("No failed claim found");
    if (claim.player != caller) return #err("Only the winner can retry");
    await Escrow.processPayouts(Principal.fromActor(GameLogic), devWallet, analytics, failedClaims, gameId, claim);
  };

  public shared query ({ caller }) func getFailedClaims() : async [T.FailedClaim] {
    Queries.getFailedClaims(failedClaims, caller);
  };

  /* ===== GAME QUERIES ===== */
  
  public query func getOpenGames(dto : Queries.GetOpenGames) : async Result.Result<Queries.OpenGames, Text> {
    Queries.getOpenGames(games, dto);
  };

  public query func getActiveGames(dto : Queries.GetActiveGames) : async Result.Result<Queries.ActiveGames, Enums.Error> {
    Queries.getActiveGames(games, dto);
  };

  public query func getGame(dto : Queries.GetGame) : async Result.Result<?Queries.GameView, Text> {
    Queries.getGame(games, dto);
  };

  public query func getGameDetail(dto : Queries.GetGame) : async Result.Result<Queries.GameDetail, Text> {
    Queries.getGameDetail(games, profiles, tablas, dto);
  };

  public query func getDrawHistory(dto : Queries.GetDrawHistory) : async Result.Result<[Ids.CardId], Text> {
    Queries.getDrawHistory(games, dto);
  };

  public query func gameCount() : async Nat {
    Map.size(games);
  };

  public query ({ caller }) func isPlayerInGame() : async ?{ gameId : Text; role : { #host; #player } } {
    Queries.isPlayerInGame(games, caller);
  };

  public shared query ({ caller }) func getRecentGamesForPlayer(limit : Nat) : async [{
    gameId : Text;
    mode : T.GameMode;
    tokenType : T.TokenType;
    entryFee : Nat;
    status : T.GameStatus;
    winner : ?Principal;
    createdAt : Int;
    isWinner : Bool;
    isHost : Bool;
  }] {
    Queries.getRecentGamesForPlayer(games, caller, limit);
  };

  public func getPot(gameId : Text) : async Result.Result<{ amountBaseUnits : Nat; symbol : Text; decimals : Nat8 }, Text> {
    let ?game = Map.get(games, Text.compare, gameId) else return #err("Game not found");
    #ok(await Escrow.getPot(game, Principal.fromActor(GameLogic), gameId));
  };

  public func getDevFeeBalance(tokenType : T.TokenType) : async Nat {
    await Escrow.getDevFeeBalance(Principal.fromActor(GameLogic), tokenType);
  };

  /* ===== TABLA QUERIES ===== */
  // All tablas are available by default as a result of change that allow tablas to be rented simultaneously
  public query func getAvailableTablas() : async Result.Result<[T.TablaInfo], Text> {
    Queries.getAvailableTablas(tablas);
  };

  public query func getTabla(tablaId : Ids.TablaId) : async Result.Result<?T.TablaInfo, Text> {
    Queries.getTabla(tablas, tablaId);
  };

  public query func getTablaCards(tablaId : Ids.TablaId) : async Result.Result<[Nat], Text> {
    Queries.getTablaCards(tablas, tablaId);
  };

  public query func getAvailableTablasForGame(gameId : Text) : async Result.Result<[T.TablaInfo], Text> {
    Queries.getAvailableTablasForGame(games, tablas, gameId);
  };

  public query func tablaCount() : async Nat {
    Map.size(tablas);
  };

  /* ===== ANALYTICS ===== */
  
  public query func getPlatformVolume() : async Analytics.VolumeData {
    Analytics.getVolume(analytics);
  };

  public query func getTablaStats(tablaId : Nat32) : async ?Analytics.TablaEarnings {
    Analytics.getTablaEarnings(analytics, tablaId);
  };

  public query func getAllTablaStats() : async [Analytics.TablaEarnings] {
    Analytics.getAllTablaEarnings(analytics);
  };

  public query func get24hVolume() : async Analytics.VolumeData {
    Analytics.get24hVolume(analytics);
  };

  public query func getLargestPots() : async Analytics.VolumeData {
    Analytics.getLargestPots(analytics);
  };
};