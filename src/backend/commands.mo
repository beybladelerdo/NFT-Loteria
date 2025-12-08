/**
 * NFT Lotería - Commands
 * Game state mutations and business logic
 * 
 * @author Demali Gregg
 * @company Canister Software Inc.
 */

import Ids "Ids";
import T "Types";
import Map "mo:core/Map";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import List "mo:core/List";
import VarArray "mo:core/VarArray";
import PRNG "mo:core/internal/PRNG";
import Time "mo:core/Time";
import Analytics "Analytics";
import ProfileStats "ProfileStats";
import Array "mo:core/Array";
import Constants "Constants";
import Nat32 "mo:core/Nat32";
import Utils "Utilities";


module Commands {
  public type CreateGame = {
    name : Text;
    mode : T.GameMode;
    tokenType : T.TokenType;
    entryFee : Nat;
    hostFeePercent : Nat;
  };

  public type JoinGame = {
    gameId : Text;
    rentedTablaIds : [Ids.TablaId];
  };

  public type StartGame = {
    gameId : Text;
  };

  public type EndGame = {
    gameId : Text;
  };

  public type DrawCard = {
    gameId : Text;
  };

  public type MarkPosition = {
    gameId : Text;
  };

  public type ClaimWin = {
    gameId : Text;
  };

  public type UpdateTablaRentalFee = {
    tablaId : Ids.TablaId;
    newFee : Nat;
  };

  public type CreateTabla = {
    tablaId : Nat32;
    cards : [Nat];
    rarity : T.Rarity;
    imageUrl : Text;
  };
  public type UpdateTablaMetadata = {
    tablaId : Nat32;
    name : ?Text;
    description : ?Text;
    imageUrl : ?Text;
    cards : ?[Nat];
  };
  public func createProfile(
    profiles : Map.Map<Principal, T.Profile>,
    tags : Map.Map<Text, Principal>,
    caller : Principal,
    tag : Text
  ) : Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) return #err("anonymous not allowed");
    switch (Map.get(tags, Text.compare, tag)) {
      case (?_) { return #err("username taken") };
      case null {};
    };
    switch (Map.get(profiles, Principal.compare, caller)) {
      case (?_) { return #err("Profile Already exists") };
      case null {
        Map.add(
          profiles,
          Principal.compare,
          caller,
          {
            principalId = Principal.toText(caller);
            username = tag;
            games = 0;
            wins = 0;
            winRate = 0.0;
          },
        );
        Map.add(tags, Text.compare, tag, caller);
        #ok();
      };
    };
  };

  public func updateTag(
    profiles : Map.Map<Principal, T.Profile>,
    tags : Map.Map<Text, Principal>,
    caller : Principal,
    newTag : Text
  ) : Result.Result<(), Text> {
    switch (Map.get(profiles, Principal.compare, caller)) {
      case null { return #err("no profile found") };
      case (?prof) {
        let old = prof.username;
        switch (Map.get(tags, Text.compare, newTag)) {
          case (?owner) { if (owner != caller) return #err("username taken") };
          case null {};
        };
        if (old == newTag) return #ok(());
        ignore Map.take(tags, Text.compare, old);
        Map.add(tags, Text.compare, newTag, caller);
        Map.add(profiles, Principal.compare, caller, { prof with username = newTag });
        #ok();
      };
    };
  };
  public func createGame(
  games : Map.Map<Text, T.Game>,
  gameSubaccounts : Map.Map<Text, Blob>,
  rng : PRNG.SFC64,
  caller : Principal,
  params : CreateGame
) : Result.Result<Text, Text> {
  if (Principal.isAnonymous(caller)) {
    return #err("Anonymous identity cannot create games");
  };
  if (params.hostFeePercent > 20) {
    return #err("Host fee cannot exceed 20%");
  };
  if (params.name == "") {
    return #err("Game name cannot be empty");
  };
  
  let nextGameId = Utils.genGameId(rng);
  let newGame : T.Game = {
    id = nextGameId;
    name = params.name;
    host = caller;
    createdAt = Time.now();
    status = #lobby;
    mode = params.mode;
    tokenType = params.tokenType;
    entryFee = params.entryFee;
    hostFeePercent = params.hostFeePercent;
    players = [];
    tablas = [];
    drawnCards = [];
    currentCard = null;
    marcas = [];
    winner = null;
    prizePool = 0;
  };
  
  Map.add(games, Text.compare, nextGameId, newGame);
  Map.add(gameSubaccounts, Text.compare, nextGameId, Utils.prizePoolSubAcc(nextGameId));
  #ok(nextGameId);
};
public func validateDrawCard(
  games : Map.Map<Text, T.Game>,
  drawLocks : Map.Map<Text, Bool>,
  caller : Principal,
  gameId : Text
) : Result.Result<T.Game, Text> {
  if (not Utils.lock(drawLocks, gameId)) return #err("draw in progress");
  
  switch (Map.get(games, Text.compare, gameId)) {
    case null {
      Utils.unlock(drawLocks, gameId);
      #err("Game not found");
    };
    case (?game) {
      if (caller != game.host) {
        Utils.unlock(drawLocks, gameId);
        return #err("Only the host can draw cards");
      };
      if (game.status != #active) {
        Utils.unlock(drawLocks, gameId);
        return #err("Game is not active");
      };
      if (game.drawnCards.size() >= Constants.TOTAL_CARDS) {
        Utils.unlock(drawLocks, gameId);
        return #err("All cards have been drawn");
      };
      #ok(game);
    };
  };
};

public func selectCard(
  game : T.Game,
  k : Nat
) : Result.Result<Ids.CardId, Text> {
  let taken = VarArray.repeat<Bool>(false, Constants.TOTAL_CARDS + 1);
  for (c in Array.values(game.drawnCards)) {
    let i = Nat32.toNat(c);
    if (i <= Constants.TOTAL_CARDS) { taken[i] := true };
  };
  
  var seen : Nat = 0;
  var chosen : Nat = 0;
  var v : Nat = 1;
  label find while (v <= Constants.TOTAL_CARDS) {
    if (not taken[v]) {
      if (seen == k) { chosen := v; break find };
      seen += 1;
    };
    v += 1;
  };
  
  if (chosen == 0) return #err("Internal error");
  #ok(Nat32.fromNat(chosen));
};

public func applyDrawCard(
  games : Map.Map<Text, T.Game>,
  game : T.Game,
  gameId : Text,
  cardId : Ids.CardId
) {
  var drawnL = List.fromArray<Ids.CardId>(game.drawnCards);
  List.add(drawnL, cardId);
  let updatedDrawn = List.toArray(drawnL);
  Map.add(games, Text.compare, gameId, { game with drawnCards = updatedDrawn; currentCard = ?cardId });
};

public func markPosition(
  games : Map.Map<Text, T.Game>,
  caller : Principal,
  gameId : Text,
  tablaId : Ids.TablaId,
  position : T.Position
) : Result.Result<(), Text> {
  if (Principal.isAnonymous(caller)) {
    return #err("Anonymous identity cannot mark positions");
  };
  
  switch (Map.get(games, Text.compare, gameId)) {
    case null { #err("Game not found") };
    case (?game) {
      if (game.status != #active) {
        return #err("Game is not active");
      };
      if (position.row >= Constants.TABLA_SIZE or position.col >= Constants.TABLA_SIZE) {
        return #err("Invalid position");
      };
      
      var ownsTabla = false;
      for ((player, tabla) in game.tablas.values()) {
        if (player == caller and tabla == tablaId) {
          ownsTabla := true;
        };
      };
      if (not ownsTabla) {
        return #err("Player does not own this tabla in this game");
      };
      
      for (marca in game.marcas.values()) {
        if (
          marca.tablaId == tablaId and
          marca.position.row == position.row and
          marca.position.col == position.col
        ) {
          return #err("Position already marked");
        };
      };
      
      let currentMarcas = List.fromArray<T.Marca>(game.marcas);
      List.add(
        currentMarcas,
        {
          playerId = caller;
          tablaId = tablaId;
          position = position;
          timestamp = Time.now();
        },
      );
      Map.add(games, Text.compare, gameId, { game with marcas = List.toArray(currentMarcas) });
      #ok();
    };
  };
};
public func validateJoinGame(
  games : Map.Map<Text, T.Game>,
  caller : Principal,
  dto : JoinGame
) : Result.Result<T.Game, Text> {
  if (Principal.isAnonymous(caller)) return #err("Anonymous identity cannot join games");
  
  for ((gameId, game) in Map.entries(games)) {
    if (gameId == dto.gameId) { /* skip */ } else {
      let isRelevantStatus = switch (game.status) {
        case (#lobby) { true };
        case (#active) { true };
        case (_) { false };
      };
      
      if (isRelevantStatus) {
        if (game.host == caller) {
          return #err("You are hosting game " # gameId # ". Please end that game first.");
        };
        for ((playerId, _) in Array.values(game.tablas)) {
          if (playerId == caller) {
            return #err("You are already in game " # gameId # ". Please leave that game first.");
          };
        };
      };
    };
  };
  
  if (dto.rentedTablaIds.size() == 0) return #err("At least one tabla must be selected");
  if (dto.rentedTablaIds.size() > Constants.MAX_TABLAS_PER_PLAYER) return #err("Too many tablas selected");
  
  let ?game = Map.get(games, Text.compare, dto.gameId)
    else return #err("Game not found");
  
  if (Principal.equal(caller, game.host)) return #err("Host cannot join their own game");
  if (game.status != #lobby) return #err("Game is not in lobby state");
  if (game.players.size() >= Constants.MAX_PLAYERS_PER_GAME) return #err("Game is full");
  
  for (p in game.players.values()) {
    if (Principal.equal(p, caller)) return #err("Player already in game");
  };
  
  for (tablaId in dto.rentedTablaIds.values()) {
    for ((player, tabla) in game.tablas.values()) {
      if (tabla == tablaId) {
        return #err("Tabla #" # Nat32.toText(tablaId) # " already in use in this game");
      };
    };
  };
  
  var playerTablaCount = 0;
  for ((player, _) in game.tablas.values()) {
    if (Principal.equal(player, caller)) {
      playerTablaCount += 1;
    };
  };
  
  let totalTablasAfter = playerTablaCount + dto.rentedTablaIds.size();
  if (totalTablasAfter > Constants.MAX_TABLAS_PER_PLAYER) {
    return #err("Player would exceed maximum number of tablas");
  };
  
  #ok(game);
};

public func reserveTablas(
  games : Map.Map<Text, T.Game>,
  game : T.Game,
  gameId : Text,
  caller : Principal,
  tablaIds : [Ids.TablaId]
) {
  let tablalist = List.fromArray<(Ids.PlayerId, Ids.TablaId)>(game.tablas);
  for (tablaId in tablaIds.values()) {
    List.add(tablalist, (caller, tablaId));
  };
  let reservedTablas = List.toArray(tablalist);
  Map.add(games, Text.compare, gameId, { game with tablas = reservedTablas });
};

public func removeTablaReservation(
  games : Map.Map<Text, T.Game>,
  gameId : Text,
  player : Principal,
  tablaIds : [Ids.TablaId]
) {
  switch (Map.get(games, Text.compare, gameId)) {
    case null {};
    case (?game) {
      let filteredTablas = Array.filter<(Ids.PlayerId, Ids.TablaId)>(
        game.tablas,
        func((p, t)) {
          let isInArray = switch (Array.indexOf<Ids.TablaId>(tablaIds, Nat32.equal, t)) {
            case null { false };
            case (?_) { true };
          };
          not (Principal.equal(p, player) and isInArray);
        }
      );
      Map.add(games, Text.compare, gameId, { game with tablas = filteredTablas });
    };
  };
};

public func addPlayerToGame(
  games : Map.Map<Text, T.Game>,
  gameId : Text,
  caller : Principal
) : Result.Result<(), Text> {
  let ?finalGame = Map.get(games, Text.compare, gameId)
    else return #err("Game not found");
  
  let playerlist = List.fromArray<Ids.PlayerId>(finalGame.players);
  List.add(playerlist, caller);
  let updatedPlayers = List.toArray(playerlist);
  
  Map.add(games, Text.compare, gameId, { finalGame with players = updatedPlayers });
  #ok();
};

public func validateStartGame(
  games : Map.Map<Text, T.Game>,
  paidSet : Map.Map<(Text, Principal), Bool>,
  gameLocks : Map.Map<Text, Bool>,
  caller : Principal,
  gameId : Text
) : Result.Result<T.Game, Text> {
  if (not Utils.lock(gameLocks, gameId)) return #err("Game state changing action in progress");
  
  switch (Map.get(games, Text.compare, gameId)) {
    case null {
      Utils.unlock(gameLocks, gameId);
      #err("Game not found");
    };
    case (?game) {
      if (caller != game.host) {
        Utils.unlock(gameLocks, gameId);
        return #err("Only the host can start the game");
      };
      if (game.status != #lobby) {
        Utils.unlock(gameLocks, gameId);
        return #err("Game is not in lobby state");
      };
      if (game.players.size() < 2) {
        Utils.unlock(gameLocks, gameId);
        return #err("Need at least 2 players to start");
      };
      for (p in Array.values(game.players)) {
        if (not Utils.hasPaid(paidSet, gameId, p)) {
          Utils.unlock(gameLocks, gameId);
          return #err("All players must approve/pay before starting");
        };
      };
      #ok(game);
    };
  };
};

public func applyStartGame(
  games : Map.Map<Text, T.Game>,
  gameLocks : Map.Map<Text, Bool>,
  game : T.Game,
  gameId : Text
) {
  Map.add(games, Text.compare, gameId, { game with status = #active });
  Utils.unlock(gameLocks, gameId);
};

public func validateLeaveGame(
  games : Map.Map<Text, T.Game>,
  paidSet : Map.Map<(Text, Principal), Bool>,
  gameLocks : Map.Map<Text, Bool>,
  caller : Principal,
  gameId : Text
) : Result.Result<{ game : T.Game; tablaCount : Nat; playerPaid : Bool }, Text> {
  if (not Utils.lock(gameLocks, gameId)) return #err("Action in progress");
  
  switch (Map.get(games, Text.compare, gameId)) {
    case null {
      Utils.unlock(gameLocks, gameId);
      #err("Game not found");
    };
    case (?game) {
      if (game.status != #lobby) {
        Utils.unlock(gameLocks, gameId);
        return #err("Cannot leave; game already started");
      };
      
      var tablaCount : Nat = 0;
      for ((p, _) in Array.values(game.tablas)) {
        if (p == caller) { tablaCount += 1 };
      };
      
      let isInPlayers = Array.indexOf<Ids.PlayerId>(game.players, Principal.equal, caller) != null;
      if (tablaCount == 0 and not isInPlayers) {
        Utils.unlock(gameLocks, gameId);
        return #err("Player not in game");
      };
      
      let playerPaid = Utils.hasPaid(paidSet, gameId, caller);
      
      #ok({ game; tablaCount; playerPaid });
    };
  };
};

public func applyLeaveGame(
  games : Map.Map<Text, T.Game>,
  paidSet : Map.Map<(Text, Principal), Bool>,
  gameLocks : Map.Map<Text, Bool>,
  game : T.Game,
  gameId : Text,
  caller : Principal,
  clearPaid : Bool
) {
  if (clearPaid) {
    Map.remove(paidSet, Utils.paidCmp, (gameId, caller));
  };
  
  let filteredPlayers = Array.filter<Ids.PlayerId>(
    game.players,
    func(p : Ids.PlayerId) : Bool { p != caller }
  );
  
  let filteredTablas = Array.filter<(Ids.PlayerId, Ids.TablaId)>(
    game.tablas,
    func(entry : (Ids.PlayerId, Ids.TablaId)) : Bool {
      let (p, _) = entry;
      p != caller;
    }
  );
  
  Map.add(games, Text.compare, gameId, { game with players = filteredPlayers; tablas = filteredTablas });
  Utils.unlock(gameLocks, gameId);
};
public func validateClaimWin(
  games : Map.Map<Text, T.Game>,
  tablas : Map.Map<Nat32, T.Tabla>,
  caller : Principal,
  gameId : Text,
  tablaId : Ids.TablaId
) : Result.Result<T.Game, Text> {
  let ?game = Map.get(games, Text.compare, gameId)
    else return #err("Game not found");
  if (game.status != #active) return #err("Game is not active");
  if (game.winner != null) return #err("Game already has a winner");
  
  var owns : Bool = false;
  for ((p, t) in Array.values(game.tablas)) {
    if (p == caller and t == tablaId) { owns := true };
  };
  if (not owns) return #err("Player does not own this tabla in this game");
  
  #ok(game);
};

public func checkWinCondition(
  game : T.Game,
  tablas : Map.Map<Nat32, T.Tabla>,
  caller : Principal,
  tablaId : Ids.TablaId,
  cardAt : (Ids.TablaId, T.Position) -> Result.Result<Ids.CardId, Text>
) : Result.Result<Bool, Text> {
  let drawnSet = Utils.buildDrawnSet(Constants.TOTAL_CARDS, game.drawnCards);
  let masks = Utils.makeMasks(Constants.TABLA_SIZE);
  let mres = Utils.markMaskFor(game, caller, tablaId, Constants.TABLA_SIZE, drawnSet, cardAt);
  let #ok mm = mres else { let #err e = mres; return #err(e) };
  
  let won = switch (game.mode) {
    case (#line) Utils.hasLine(mm, masks);
    case (#blackout) Utils.isBlackout(mm, masks);
  };
  
  #ok(won);
};

public func applyWinner(
  games : Map.Map<Text, T.Game>,
  profiles : Map.Map<Principal, T.Profile>,
  analytics : Analytics.AnalyticsState,
  game : T.Game,
  gameId : Text,
  tablaId : Ids.TablaId,
  caller : Principal
) {
  Map.add(games, Text.compare, gameId, { game with winner = ?caller; status = #completed });
  ProfileStats.updateAllPlayers(profiles, game.tablas, caller);
  Analytics.recordTablaPlayed(analytics, tablaId);
};

public func resolveTablaOwnerPayment(
  owners : Map.Map<Nat32, Text>,
  ownerPrincipals : Map.Map<Nat32, ?Principal>,
  tablaId : Ids.TablaId,
  tokenType : T.TokenType
) : ?{ #icrc1 : Principal; #icpAccount : Blob } {
  let ownerPrincipal = Map.get(ownerPrincipals, Nat32.compare, tablaId);
  switch (ownerPrincipal) {
    case (?(?principal)) { ?#icrc1(principal) };
    case _ {
      switch (tokenType) {
        case (#ICP) {
          switch (Map.get(owners, Nat32.compare, tablaId)) {
            case (?accountId) { ?#icpAccount(Text.encodeUtf8(accountId)) };
            case null { null };
          };
        };
        case _ { null };
      };
    };
  };
};

public func calculatePayouts(
  pot : Nat,
  tablaOwnerPayment : ?{ #icrc1 : Principal; #icpAccount : Blob },
  hostFeePercent : Nat,
  icrcFee : Nat
) : Result.Result<{ devFee : Nat; tablaOwnerFee : Nat; hostFee : Nat; winnerAmount : Nat }, Text> {
  let ownerViaIcrc1 : Bool = switch (tablaOwnerPayment) { case (?#icrc1(_)) true; case _ false };
  let baseIcrcDebits : Nat = 1 + 1 + (if (ownerViaIcrc1) 1 else 0);
  let icrcDebits : Nat = baseIcrcDebits + 1;
  let icpClassicFee : Nat = 10_000;
  let needsClassic : Bool = switch (tablaOwnerPayment) { case (?#icpAccount(_)) true; case _ false };
  let classicFeeBudget : Nat = if (needsClassic) icpClassicFee else 0;
  let feeBudget : Nat = icrcFee * icrcDebits + classicFeeBudget;
  
  if (pot <= feeBudget) return #err("Pot too small to cover network fees");
  
  let netPot : Nat = pot - feeBudget;
  let devFee = netPot * Constants.PLATFORM_FEE_PERCENT / 100;
  let tablaOwnerFee = switch (tablaOwnerPayment) { case null 0; case _ netPot * Constants.OWNER_FEE_PERCENT / 100 };
  let hostFee = netPot * hostFeePercent / 100;
  let winnerAmount = netPot - devFee - tablaOwnerFee - hostFee;
  
  #ok({ devFee; tablaOwnerFee; hostFee; winnerAmount });
};

public func buildFailedClaim(
  gameId : Text,
  tablaId : Ids.TablaId,
  caller : Principal,
  game : T.Game,
  tablaOwnerPayment : ?{ #icrc1 : Principal; #icpAccount : Blob },
  payouts : { devFee : Nat; tablaOwnerFee : Nat; hostFee : Nat; winnerAmount : Nat }
) : T.FailedClaim {
  {
    gameId = gameId;
    tablaId = tablaId;
    player = caller;
    host = game.host;
    tablaOwnerPayment = tablaOwnerPayment;
    winnerAmount = payouts.winnerAmount;
    hostFee = payouts.hostFee;
    tablaOwnerFee = payouts.tablaOwnerFee;
    devFee = payouts.devFee;
    tokenType = game.tokenType;
    failedAt = Time.now();
    payoutStatus = { devFeePaid = false; tablaOwnerPaid = false; winnerPaid = false; hostPaid = false };
    lastError = "";
  };
};

public func buildPlayerTablaCounts(
  game : T.Game
) : Map.Map<Principal, Nat> {
  var playerTablaCounts = Map.empty<Principal, Nat>();
  
  for ((playerId, tablaId) in Array.values(game.tablas)) {
    let currentCount = switch (Map.get(playerTablaCounts, Principal.compare, playerId)) {
      case (?count) count;
      case null 0;
    };
    Map.add(playerTablaCounts, Principal.compare, playerId, currentCount + 1);
  };
  
  playerTablaCounts;
};
 public func endGame(
  games : Map.Map<Text, T.Game>,
  caller : Principal,
  gameId : Text
) : Result.Result<(), Text> {
  switch (Map.get(games, Text.compare, gameId)) {
    case null { #err("Game not found") };
    case (?g) {
      if (caller != g.host) return #err("Only the host can end the game");
      if (g.status != #active) return #err("Game is not active");
      Map.add(games, Text.compare, gameId, { g with status = #completed });
      #ok();
    };
  };
};

public func sendChatMessage(
  games : Map.Map<Text, T.Game>,
  gameChats : Map.Map<Text, List.List<T.ChatMessage>>,
  profiles : Map.Map<Principal, T.Profile>,
  caller : Principal,
  gameId : Text,
  message : Text
) : Result.Result<(), Text> {
  let ?game = Map.get(games, Text.compare, gameId)
    else return #err("Game not found");
  
  var isParticipant = game.host == caller;
  if (not isParticipant) {
    for ((p, _) in Array.values(game.tablas)) {
      if (p == caller) { isParticipant := true };
    };
  };
  if (not isParticipant) return #err("Not a participant");
  
  let ?profile = Map.get(profiles, Principal.compare, caller)
    else return #err("Profile not found");
  
  let newMessage : T.ChatMessage = {
    sender = caller;
    username = profile.username;
    message = message;
    timestamp = Time.now();
  };
  
  let existing = switch (Map.get(gameChats, Text.compare, gameId)) {
    case (?msgs) msgs;
    case null List.empty<T.ChatMessage>();
  };
  
  List.add(existing, newMessage);
  Map.add(gameChats, Text.compare, gameId, existing);
  
  #ok();
};

public func clearGameChat(
  gameChats : Map.Map<Text, List.List<T.ChatMessage>>,
  gameId : Text
) {
  ignore Map.delete(gameChats, Text.compare, gameId);
};
};
