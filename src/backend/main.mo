import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import PRNG "mo:core/internal/PRNG";
import Text "mo:core/Text";
import Nat64 "mo:core/Nat64";
import Nat32 "mo:core/Nat32";
import Int "mo:core/Int";
import Time "mo:core/Time";
import Result "mo:core/Result";
import T "types";
import Constants "constants";
import Enums "mo:waterway-mops/base/enums";
import Map "mo:core/Map";
import Random "mo:core/Random";
import VarArray "mo:core/VarArray";
import Array "mo:core/Array";
import List "mo:core/List";
import Sha256 "mo:sha2/Sha256";
import Blob "mo:core/Blob";
import Escrow "escrow";
import E "enums";
import Utils "utilities";
import Ids "ids";
import Commands "commands";
import Queries "queries";

persistent actor GameLogic {

  type Entry = (Nat32, Text);
  type PaidKey = (Text, Principal);
  let burnAddress = "0000000000000000000000000000000000000000000000000000000000000001";
  let ext : actor { getRegistry : shared query () -> async [Entry] } = actor ("psaup-3aaaa-aaaak-qsxlq-cai");
  func devFeeSubAcc() : Blob {
  Sha256.fromArray(#sha256, Blob.toArray(Text.encodeUtf8("dev-fee")))
};

  private var games = Map.empty<Text, T.Game>();
  private var profiles = Map.empty<Principal, T.Profile>();
  private var owners = Map.empty<Nat32, Text>();
  private var ownerPrincipals = Map.empty<Nat32, ?Principal>();
  private var tags = Map.empty<Text, Principal>();
  private var tablas = Map.empty<Nat32, T.Tabla>();
  private var admins = Map.empty<Principal, Bool>();
  private var devWallet : ?Principal = null;
  private var paidSet = Map.empty<PaidKey, Bool>();

  let e8 : Nat = 100_000_000;
  let letters = Text.toArray("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  let digits = Text.toArray("0123456789");
  transient let rng = PRNG.sfc64a();
  rng.init(Nat64.fromIntWrap(Time.now()));

  func isAdmin(p : Principal) : Bool {
    switch (Map.get<Principal, Bool>(admins, Principal.compare, p)) {
      case (?_) true;
      case null false;
    }
  };
  
  func paidCmp(a : PaidKey, b : PaidKey) : {#less;#equal;#greater} {
    let c = Text.compare(a.0, b.0); if (c != #equal) return c;
    Principal.compare(a.1, b.1);
  };
  func hasPaid(gid : Text, p : Principal) : Bool =
    switch (Map.get(paidSet, paidCmp, (gid, p))) { case (?_) true; case null false };
  func markPaid(gid : Text, p : Principal) =
    Map.add(paidSet, paidCmp, (gid, p), true);
  
  func prizePoolSubAcc(gameId : Text) : Blob {
  Sha256.fromArray(#sha256 ,Blob.toArray(Text.encodeUtf8("pot:" # gameId)))
  };

  public shared ({ caller }) func bootstrapAdmin() : async Result.Result<(), Text> {
    if (Map.size(admins) > 0) return #err("already bootstrapped");
    Map.add<Principal, Bool>(admins, Principal.compare, caller, true);
    #ok(())
  };

  public shared ({ caller }) func adminAdd(p : Principal) : async Result.Result<(), Text> {
    if (not isAdmin(caller)) return #err("unauthorized");
    Map.add<Principal, Bool>(admins, Principal.compare, p, true);
    #ok(())
  };

  func pick(arr : [Char], bound : Nat64) : Char {
    let idx = Nat64.toNat(Nat64.rem(rng.next(), bound));
    arr[idx];
  };
  func genGameId() : Text {
    var out : [var Char] = [var ' ', ' ', ' ', ' ', ' ', ' '];
    let b26 : Nat64 = 26;
    let b10 : Nat64 = 10;
    var i = 0;
    while (i < 6) {
      if (Nat64.rem(rng.next(), 2) == 0) {
        out[i] := pick(letters, b26);
      } else {
        out[i] := pick(digits, b10);
      };
      i += 1;
    };
    Text.fromVarArray(out);
  };

  func cardAt(tablaId : Ids.TablaId, pos : T.Position) : Result.Result<Ids.CardId, Text> {
    let size = Constants.TABLA_SIZE;
    let idx = pos.row * size + pos.col;
    switch (Map.get<Nat32, T.Tabla>(tablas, Nat32.compare, tablaId)) {
      case (?tabla) {
        if (idx < Array.size(tabla.metadata.cards)) #ok(Nat32.fromNat(tabla.metadata.cards[idx])) else {
          #err("cardAt: index out of bounds");
        };
      };
      case null { #err("cardAt: tabla layout not found") };
    };
  };
  
  public func refreshRegistry() : async () {
    let entries = await ext.getRegistry();
    for ((id, owner) in Array.values(entries)){
      if (owner != burnAddress){
        Map.add<Nat32, Text>(owners, Nat32.compare, id + 1, owner);
      };
    };
  };
  public query func ownerOf(idx : Nat32) : async (?Text, ?Principal) {
    let ownerText = Map.get<Nat32,Text>(owners, Nat32.compare, idx);
    let ownerPrincipal = switch (Map.get<Nat32, ?Principal>(ownerPrincipals, Nat32.compare, idx)) {
        case null { null };
        case (?inner) { inner };
    };
    (ownerText, ownerPrincipal)
  };
  public query func isTagAvailable(tag : Text) : async Bool {
    switch (Map.get<Text, Principal>(tags, Text.compare, tag)) {
      case null true;
      case (?_) false;
    };
  };

  public query ({ caller }) func getProfile() : async Result.Result<T.Profile, Text> {
    switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, caller)) {
      case null { #err("no profile found") };
      case (?profile) { #ok(profile) };
    };
  };

  public query func getPlayerProfile(t:Text) :async Result.Result<T.Profile,Text>{
    switch (Map.get<Text, Principal>(tags, Text.compare, t)){
      case null { #err("No Principal associated with tag")};
      case (?p) {
        switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, p)) {
          case null { #err("no profile found") };
          case (?profile) { #ok(profile) };
        };
      };
    };
  };
  public shared ({ caller }) func createProfile(tag : Text) : async Result.Result<(), Text> {
  if (Principal.isAnonymous(caller)) return #err("anonymous not allowed");

  switch (Map.get<Text, Principal>(tags, Text.compare, tag)) {
    case (?_) { return #err("username taken") };
    case null {};
  };
  switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, caller)) {
    case (?_) { return #err("Profile Already exists") };
    case null {
      Map.add<Principal, T.Profile>(
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
      Map.add<Text, Principal>(tags, Text.compare, tag, caller);
      #ok();
      };
    };
  };

  public shared ({ caller }) func updateTag(newTag : Text) : async Result.Result<(), Text> {
    switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, caller)) {
      case null { return #err("no profile found") };
      case (?prof) {
        let old = prof.username;
        switch (Map.get<Text, Principal>(tags, Text.compare, newTag)) {
          case (?owner) { if (owner != caller) return #err("username taken") };
          case null {};
        };
        if (old == newTag) return #ok(());
        ignore Map.take<Text, Principal>(tags, Text.compare, old);
        Map.add<Text, Principal>(tags, Text.compare, newTag, caller);
        Map.add<Principal, T.Profile>(profiles, Principal.compare, caller, { prof with username = newTag });
        return #ok(());
      };
    };
  };

  /* ----- Game Queries ----- */

  public query func getOpenGames(dto : Queries.GetOpenGames) : async Result.Result<Queries.OpenGames, Text> {
    let start = dto.page * Constants.PAGE_COUNT;

    var matched : Nat = 0;
    let out = List.empty<Queries.GameView>();

    label scan for (g in Map.values(games)) {
      if (g.status == #lobby) {
        if (matched >= start and List.size(out) < Constants.PAGE_COUNT) {
          List.add<Queries.GameView>(out, Utils.toGameView(g));
          if (List.size(out) == Constants.PAGE_COUNT) break scan;
        };
        matched += 1;
      };
    };
    #ok({ page = dto.page; openGames = List.toArray(out) });
  };

  public query func getActiveGames(dto : Queries.GetActiveGames) : async Result.Result<Queries.ActiveGames, Enums.Error> {
    let start = dto.page * Constants.PAGE_COUNT;

    var matched : Nat = 0;
    let out = List.empty<Queries.GameView>();

    label scan for (g in Map.values(games)) {
      if (g.status == #active) {
        if (matched >= start and List.size(out) < Constants.PAGE_COUNT) {
          List.add<Queries.GameView>(out, Utils.toGameView(g));
          if (List.size(out) == Constants.PAGE_COUNT) break scan;
        };
        matched += 1;
      };
    };

    #ok({ page = dto.page; activeGames = List.toArray(out) });
  };

  public query func getGame(dto : Queries.GetGame) : async Result.Result<?Queries.GameView, Text> {
    switch (Map.get<Text, T.Game>(games, Text.compare, dto.gameId)) {
      case null { #err("No Game found") };
      case (?g) { #ok(?Utils.toGameView(g)) };
    };
  };
  public query func getGameDetail(dto : Queries.GetGame) : async Result.Result<Queries.GameDetail, Text> {
    let ?game = Map.get<Text, T.Game>(games, Text.compare, dto.gameId)
      else return #err("No Game found");

    let hostProfile : Queries.BasicProfile = {
      principal = game.host;
      username = switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, game.host)) {
        case (?prof) ?prof.username;
        case null null;
      };
    };

    let playerSummaries = Array.map<Ids.PlayerId, Queries.PlayerSummary>(
      game.players,
      func (player : Ids.PlayerId) : Queries.PlayerSummary {
        let username = switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, player)) {
          case (?prof) ?prof.username;
          case null null;
        };

        let tablasForPlayer = Array.filter<(Ids.PlayerId, Ids.TablaId)>(
          game.tablas,
          func (entry : (Ids.PlayerId, Ids.TablaId)) : Bool {
            Principal.equal(entry.0, player);
          },
        );

        let tablaSummaries = Array.map<(Ids.PlayerId, Ids.TablaId), Queries.TablaInGame>(
          tablasForPlayer,
          func (entry : (Ids.PlayerId, Ids.TablaId)) : Queries.TablaInGame {
            let tablaId = entry.1;
            switch (Map.get<Nat32, T.Tabla>(tablas, Nat32.compare, tablaId)) {
              case (?tabla) {
                {
                  tablaId = tablaId;
                  name = tabla.metadata.name;
                  image = tabla.metadata.image;
                  cards = tabla.metadata.cards;
                };
              };
              case null {
                {
                  tablaId = tablaId;
                  name = "Tabla #" # Nat.toText(Nat32.toNat(tablaId));
                  image = "";
                  cards = [];
                };
              };
            };
          },
        );

        {
          principal = player;
          username = username;
          tablas = tablaSummaries;
        };
      },
    );

    #ok({
      id = game.id;
      name = game.name;
      host = hostProfile;
      status = game.status;
      mode = game.mode;
      tokenType = game.tokenType;
      entryFee = game.entryFee;
      hostFeePercent = game.hostFeePercent;
      createdAt = game.createdAt;
      drawnCards = game.drawnCards;
      currentCard = game.currentCard;
      prizePool = game.prizePool;
      players = playerSummaries;
      playerCount = Array.size(game.players);
      maxPlayers = Constants.MAX_PLAYERS_PER_GAME;
      marks = game.marcas;
      winner = game.winner;
    });
  };

  public query func getDrawHistory(dto : Queries.GetDrawHistory) : async Result.Result<[Ids.CardId], Text> {
    switch (Map.get<Text, T.Game>(games, Text.compare, dto.gameId)) {
      case null { #err("No Game found") };
      case (?g) { #ok(g.drawnCards) };
    };
  };

  public shared ({ caller }) func createGame(params : Commands.CreateGame) : async Result.Result<Text, Text> {

    let nextGameId = genGameId();

    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot create games");
    };

    if (params.hostFeePercent > 20) {
      return #err("Host fee cannot exceed 20%");
    };

    if (params.name == "") {
      return #err("Game name cannot be empty");
    };

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
    Map.add<Text, T.Game>(games, Text.compare, nextGameId, newGame);
    #ok(newGame.id);
  };

  public shared ({ caller }) func joinGame(dto : Commands.JoinGame) : async Result.Result<(), Text> {
  if (Principal.isAnonymous(caller)) return #err("Anonymous identity cannot join games");
  
  if (dto.rentedTablaIds.size() == 0) return #err("At least one tabla must be selected");
  if (dto.rentedTablaIds.size() > Constants.MAX_TABLAS_PER_PLAYER) return #err("Too many tablas selected");
  
  let ?game = Map.get<Text, T.Game>(games, Text.compare, dto.gameId)
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
  
  let tablalist = List.fromArray<(Ids.PlayerId, Ids.TablaId)>(game.tablas);
  for (tablaId in dto.rentedTablaIds.values()) {
    List.add<(Ids.PlayerId, Ids.TablaId)>(tablalist, (caller, tablaId));
  };
  let reservedTablas = List.toArray(tablalist);
  
  Map.add<Text, T.Game>(
    games, 
    Text.compare, 
    dto.gameId, 
    { game with tablas = reservedTablas }
  );
  
  if (not hasPaid(dto.gameId, caller)) {
    let totalEntryFee = game.entryFee * dto.rentedTablaIds.size();
    
    let l       = Escrow.ledgerOf(game.tokenType);
    let now_ns  = Nat64.fromNat(Int.abs(Time.now()));
    let from    = Escrow.acct(caller, null);
    let to      = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(prizePoolSubAcc(dto.gameId)));
    let spender = Escrow.acct(Principal.fromActor(GameLogic), null);
    
    let a = await l.icrc2_allowance({ account = from; spender });
    switch (a.expires_at) { 
      case (?exp) { 
        if (exp <= now_ns / 1_000_000_000) {
          removeTablaReservation(dto.gameId, caller, dto.rentedTablaIds);
          return #err("Allowance expired; approve again");
        };
      }; 
      case null {};
    };
    
    if (a.allowance < totalEntryFee) {
      removeTablaReservation(dto.gameId, caller, dto.rentedTablaIds);
      return #err("Allowance too low; approve at least " # Nat.toText(totalEntryFee));
    };
    
    let pulled = await l.icrc2_transfer_from({
      from; to; amount = totalEntryFee;
      fee = null; memo = null;
      created_at_time = ?now_ns;
      spender_subaccount = null
    });
    
    switch (pulled) {
      case (#Ok _) { markPaid(dto.gameId, caller) };
      case (#Err err) {
        removeTablaReservation(dto.gameId, caller, dto.rentedTablaIds);
        return #err(
          switch err {
            case (#InsufficientAllowance) "Insufficient allowance";
            case (#InsufficientFunds)     "Insufficient funds";
            case (#Expired)               "Transfer expired; try again";
            case (#TemporarilyUnavailable) "Ledger temporarily unavailable";
            case (#BadFee {})             "Bad fee";
            case (#Duplicate {})          "Duplicate transfer";
            case (#BadBurn {})            "Bad burn";
            case (#GenericError { message }) "Ledger error: " # message;
          }
        );
      };
    };
  };
  
  let ?finalGame = Map.get<Text, T.Game>(games, Text.compare, dto.gameId)
    else return #err("Game not found");
  
  let playerlist = List.fromArray<Ids.PlayerId>(finalGame.players);
  List.add<Ids.PlayerId>(playerlist, caller);
  let updatedPlayers = List.toArray(playerlist);
  
  Map.add<Text, T.Game>(
    games, 
    Text.compare, 
    dto.gameId, 
    { finalGame with players = updatedPlayers }
  );
  
  #ok(())
};

func removeTablaReservation(gameId : Text, player : Principal, tablaIds : [Ids.TablaId]) {
  switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
    case (null) {};
    case (?game) {
      let filteredTablas = Array.filter<(Ids.PlayerId, Ids.TablaId)>(
        game.tablas,
        func((p, t)) { 
          let isInArray = switch (Array.indexOf<Ids.TablaId>( tablaIds, Nat32.equal, t)) {
            case null { false };
            case (?_) { true };
          };
          not (Principal.equal(p, player) and isInArray)
        }
      );
      Map.add<Text, T.Game>(
        games,
        Text.compare,
        gameId,
        { game with tablas = filteredTablas }
      );
    };
  };
};

  public shared ({ caller }) func startGame(gameId : Text) : async Result.Result<(), Text> {

    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (caller != game.host) {
          return #err("Only the host can start the game");
        };

        if (game.status != #lobby) {
          return #err("Game is not in lobby state");
        };

        if (game.players.size() < 2) {
          return #err("Need at least 2 players to start");
        };
        for (p in Array.values(game.players)) {
        if (not hasPaid(gameId, p)) {
          return #err("All players must approve/pay before starting");
        };
      };
        Map.add<Text, T.Game>(games, Text.compare, gameId, { game with status = #active });
        #ok(());
      };
    };
  };
  transient let crypto = Random.crypto();
  let drawLocks = Map.empty<Text, Bool>();
  func lock(id : Text) : Bool {
    switch (Map.get<Text, Bool>(drawLocks, Text.compare, id)) {
      case (?_) { false };
      case null { Map.add<Text, Bool>(drawLocks, Text.compare, id, true); true };
    };
  };
  func unlock(id : Text) {
    ignore Map.take<Text, Bool>(drawLocks, Text.compare, id);
  };

  public shared ({ caller }) func drawCard(gameId : Text) : async Result.Result<Ids.CardId, Text> {
    if (not lock(gameId)) return #err("draw in progress");

    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case (null) { unlock(gameId); return #err("Game not found") };
      case (?game) {
        if (caller != game.host) {
          unlock(gameId);
          return #err("Only the host can draw cards");
        };
        if (game.status != #active) {
          unlock(gameId);
          return #err("Game is not active");
        };
        if (game.drawnCards.size() >= Constants.TOTAL_CARDS) {
          unlock(gameId);
          return #err("All cards have been drawn");
        };

        let taken = VarArray.repeat<Bool>(false, Constants.TOTAL_CARDS + 1);
        for (c in Array.values<Ids.CardId>(game.drawnCards)) {
          let i = Nat32.toNat(c);
          if (i <= Constants.TOTAL_CARDS) { taken[i] := true };
        };

        let remaining = Constants.TOTAL_CARDS - game.drawnCards.size();
        let k : Nat = await* crypto.natRange(0, remaining);

        // locate k-th undrawn card
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
        if (chosen == 0) { unlock(gameId); return #err("Internal error") };

        let cardId : Ids.CardId = Nat32.fromNat(chosen);
        var drawnL = List.fromArray<Ids.CardId>(game.drawnCards);
        List.add<Ids.CardId>(drawnL, cardId);
        let updatedDrawn = List.toArray<Ids.CardId>(drawnL);

        Map.add<Text, T.Game>(
          games,
          Text.compare,
          gameId,
          { game with drawnCards = updatedDrawn; currentCard = ?cardId },
        );

        unlock(gameId);
        #ok(cardId);
      };
    };
  };

  public shared ({ caller }) func markPosition(gameId : Text, tablaId : Ids.TablaId, position : T.Position) : async Result.Result<(), Text> {

    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot mark positions");
    };

    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #active) {
          return #err("Game is not active");
        };

        // Check if position is valid
        if (position.row >= Constants.TABLA_SIZE or position.col >= Constants.TABLA_SIZE) {
          return #err("Invalid position");
        };

        // Check if player owns the tabla
        var ownsTabla = false;
        for ((player, tabla) in game.tablas.values()) {
          if (player == caller and tabla == tablaId) {
            ownsTabla := true;
          };
        };
        if (not ownsTabla) {
          return #err("Player does not own this tabla in this game");
        };
        // Check if position is already marked
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
        List.add<T.Marca>(
          currentMarcas,
          {
            playerId = caller;
            tablaId = tablaId;
            position = position;
            timestamp = Time.now();
          },
        );
        Map.add<Text, T.Game>(games, Text.compare, gameId, { game with marcas = List.toArray(currentMarcas) });
        #ok(());
      };
    };
  };
  public shared ({ caller }) func claimWin(gameId : Text, tablaId : Ids.TablaId) : async Result.Result<(), Text> {
  let ?game = Map.get<Text, T.Game>(games, Text.compare, gameId)
    else return #err("Game not found");
  if (game.status != #active) return #err("Game is not active");
  if (game.winner != null) return #err("Game already has a winner");

  var owns : Bool = false;
  for ((p, t) in Array.values<(Ids.PlayerId, Ids.TablaId)>(game.tablas)) {
    if (p == caller and t == tablaId) { owns := true };
  };
  if (not owns) return #err("Player does not own this tabla in this game");

  let drawnSet = Utils.buildDrawnSet(Constants.TOTAL_CARDS, game.drawnCards);
  let masks = Utils.makeMasks(Constants.TABLA_SIZE);
  let mres = Utils.markMaskFor(game, caller, tablaId, Constants.TABLA_SIZE, drawnSet, cardAt);
  let #ok mm = mres else { let #err e = mres; return #err(e) };

  let won = switch (game.mode) {
    case (#line) Utils.hasLine(mm, masks);
    case (#blackout) Utils.isBlackout(mm, masks);
  };
  if (not won) return #err("Win condition not met");

  Map.add<Text, T.Game>(games, Text.compare, gameId, { game with winner = ?caller });

  let l = Escrow.ledgerOf(game.tokenType);
  let potAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(prizePoolSubAcc(gameId)));
  let pot = await l.icrc1_balance_of(potAcct);
  let now_ns = Nat64.fromNat(Int.abs(Time.now()));

  var actualTablaOwnerFee : Nat = 0;
  var tablaOwnerPayment : ?{ #icrc1: Principal; #icpAccount: Blob } = null;

  let ownerPrincipal = Map.get<Nat32, ?Principal>(ownerPrincipals, Nat32.compare, tablaId);
  switch (ownerPrincipal) {
    case (?(?principal)) { tablaOwnerPayment := ?#icrc1(principal) };
    case _ {
      switch (game.tokenType) {
        case (#ICP) {
          switch (Map.get<Nat32, Text>(owners, Nat32.compare, tablaId)) {
            case (?accountId) { tablaOwnerPayment := ?#icpAccount(Text.encodeUtf8(accountId)) };
            case null {};
          };
        };
        case _ {};
      };
    };
  };

  let icrcFee : Nat = await l.icrc1_fee();
  let ownerViaIcrc1 : Bool = switch (tablaOwnerPayment) { case (?#icrc1(_)) true; case _ false };
  let baseIcrcDebits : Nat = 1 + 1 + (if (ownerViaIcrc1) 1 else 0);
  var icrcDebits : Nat = baseIcrcDebits + 1;
  let icpClassicFee : Nat = 10_000;
  let needsClassic : Bool = switch (tablaOwnerPayment) { case (?#icpAccount(_)) true; case _ false };
  let classicFeeBudget : Nat = if (needsClassic) icpClassicFee else 0;
  var feeBudget : Nat = icrcFee * icrcDebits + classicFeeBudget;
  if (pot <= feeBudget) return #err("Pot too small to cover network fees");
  let netPot : Nat = pot - feeBudget;

  var devFee = netPot * Constants.PLATFORM_FEE_PERCENT / 100;
  var tablaOwnerFee = switch (tablaOwnerPayment) { case null 0; case _ netPot * Constants.OWNER_FEE_PERCENT / 100 };
  var hostFee = netPot * game.hostFeePercent / 100;
  var winnerAmount = netPot - devFee - tablaOwnerFee - hostFee;

  if (devFee == 0 and icrcDebits > baseIcrcDebits) {
    icrcDebits -= 1;
    let newBudget = icrcFee * icrcDebits + classicFeeBudget;
    if (feeBudget > newBudget) { winnerAmount += (feeBudget - newBudget) };
    feeBudget := newBudget;
  };

  let payIcrc1 = func (toOwner : Principal, amt : Nat, fromSub : ?[Nat8]) : async Result.Result<(), Text> {
    if (amt == 0) return #ok(());
    let res = await l.icrc1_transfer({
      from_subaccount = fromSub;
      to = Escrow.acct(toOwner, null);
      amount = amt;
      fee = null;
      memo = null;
      created_at_time = ?now_ns
    });
    switch (res) { case (#Ok _) #ok(()); case (#Err e) #err("payout failed: " # debug_show e) };
  };

  let payIcpAccount = func (toAccountBlob : Blob, amt : Nat, fromSub : ?[Nat8]) : async Result.Result<(), Text> {
    if (amt == 0) return #ok(());
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
      to = toAccountBlob;
      fee = { e8s = 10_000 };
      memo = 0;
      from_subaccount = switch (fromSub) { case (?arr) ?Blob.fromArray(arr); case null null };
      created_at_time = ?{ timestamp_nanos = now_ns };
      amount = { e8s = Nat64.fromNat(amt) };
    });
    switch (res) { case (#Ok _) #ok(()); case (#Err e) #err("ICP payout failed: " # debug_show e) };
  };

  var remaining : Nat = pot;

  if (devFee > 0) {
    if (remaining < devFee + icrcFee) return #err("Insufficient funds for dev fee");
    remaining -= (devFee + icrcFee);
    let devAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(devFeeSubAcc()));
    let res = await l.icrc1_transfer({
      from_subaccount = potAcct.subaccount;
      to = devAcct;
      amount = devFee;
      fee = null;
      memo = null;
      created_at_time = ?now_ns
    });
    switch (res) { case (#Err e) return #err("Dev fee transfer failed: " # debug_show e); case (#Ok _) {} };
    switch (devWallet) { case (?wallet) { ignore await payIcrc1(wallet, devFee, ?Blob.toArray(devFeeSubAcc())) }; case null {} };
  };

  switch (tablaOwnerPayment) {
    case (?#icrc1(principal)) {
      if (remaining < tablaOwnerFee + icrcFee) return #err("Insufficient funds for owner payout");
      remaining -= (tablaOwnerFee + icrcFee);
      switch (await payIcrc1(principal, tablaOwnerFee, potAcct.subaccount)) { case (#err e) return #err(e); case (#ok ()) {} };
      actualTablaOwnerFee := tablaOwnerFee;
    };
    case (?#icpAccount(accountBlob)) {
      if (remaining < tablaOwnerFee + icpClassicFee) return #err("Insufficient funds for owner payout");
      remaining -= (tablaOwnerFee + icpClassicFee);
      switch (await payIcpAccount(accountBlob, tablaOwnerFee, potAcct.subaccount)) { case (#err e) return #err(e); case (#ok ()) {} };
      actualTablaOwnerFee := tablaOwnerFee;
    };
    case null { actualTablaOwnerFee := 0 };
  };

  if (remaining < winnerAmount + icrcFee) return #err("Insufficient funds for winner payout");
  remaining -= (winnerAmount + icrcFee);
  switch (await payIcrc1(caller, winnerAmount, potAcct.subaccount)) { case (#err e) return #err(e); case (#ok ()) {} };

  if (remaining < hostFee + icrcFee) return #err("Insufficient funds for host payout");
  remaining -= (hostFee + icrcFee);
  switch (await payIcrc1(game.host, hostFee, potAcct.subaccount)) { case (#err e) return #err(e); case (#ok ()) {} };

  Map.add<Text, T.Game>(games, Text.compare, gameId, { game with status = #completed });
  #ok(());
};

  public shared ({ caller }) func endGame(gameId : Text) : async Result.Result<(), Text> {
    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case null { #err("Game not found") };
      case (?g) {
        if (caller != g.host) return #err("Only the host can end the game");
        if (g.status != #active) return #err("Game is not active");
        Map.add<Text, T.Game>(games, Text.compare, gameId, { g with status = #completed });
        #ok(());
      };
    };
  };

  /* ----- Tabla Commands ----- */
  public shared ({ caller }) func deleteTabla(tablaId : Nat32) : async Result.Result<(), Text> {
  if (not isAdmin(caller)) return #err("unauthorized");
  
  switch (Map.take<Nat32, T.Tabla>(tablas, Nat32.compare, tablaId)) {
    case (?_) { #ok(()) };
    case null { #err("Tabla not found") };
  };
};

  func adminCreateTabla(dto : Commands.CreateTabla, caller: Principal ) : async* Result.Result<Nat32, Text> {
    if (not isAdmin(caller)) return #err("unauthorized");
    
    if (Array.size(dto.cards) != Constants.TABLA_SIZE * Constants.TABLA_SIZE) {
      return #err("Invalid card layout: must have exactly 16 cards");
    };

    for (cardId in Array.values(dto.cards)) {
      if (cardId < 1 or cardId > Constants.TOTAL_CARDS) {
        return #err("Invalid card ID: must be between 1-54");
      };
    };
    switch (Map.get<Nat32, T.Tabla>(tablas, Nat32.compare, dto.tablaId)) {
      case (?_) { return #err("Tabla already exists") };
      case null {};
    };

    let ownerAccountId = switch (Map.get<Nat32, Text>(owners, Nat32.compare, dto.tablaId)) {
      case (?accountId) { accountId };
      case null { return #err("Owner not found in registry. Run refreshRegistry() first.") };
    };
    
    let rentalFee : Nat = 0;
    
    let metadata : T.TablaMetadata = {
      name = "Tabla #" # Nat.toText(Nat32.toNat(dto.tablaId));
      description = "A crypto-themed lotería tabla with unique card combinations";
      image = dto.imageUrl;
      cards = dto.cards;
    };
    
    let newTabla : T.Tabla = {
      id = dto.tablaId;
      owner = ownerAccountId;
      renter = null;
      gameId = null;
      rentalFee = rentalFee;
      tokenType = #ICP;
      rarity = dto.rarity;
      metadata = metadata;
      rentalHistory = [];
      status = #available;
      createdAt = Time.now();
      updatedAt = Time.now();
    };
    
    Map.add<Nat32, T.Tabla>(tablas, Nat32.compare, dto.tablaId, newTabla);
    #ok(dto.tablaId);
  };
  public shared ({ caller }) func adminBatchTablas(dtos : [Commands.CreateTabla]) : async Result.Result<[Nat32], Text> {
  if (not isAdmin(caller)) return #err("unauthorized");
  
  let results = List.empty<Nat32>();
  var errors : Text = "";
  
  for (dto in Array.values(dtos)) {
    switch (await* adminCreateTabla( dto, caller)) {
      case (#ok(id)) { List.add<Nat32>(results, id) };
      case (#err(e)) { errors := errors # "Tabla " # Nat32.toText(dto.tablaId) # ": " # e # "; " };
    };
  };
  
  if (errors != "") {
    return #err(errors);
  };
  
  #ok(List.toArray(results));
};
public shared ({ caller }) func adminUpdateTablaMetadata(dto : Commands.UpdateTablaMetadata) : async Result.Result<(), Text> {
  if (not isAdmin(caller)) return #err("unauthorized");
  
  let ?tabla = Map.get<Nat32, T.Tabla>(tablas, Nat32.compare, dto.tablaId) else return #err("Tabla not found");
  
  let updatedMetadata = {
    name = switch (dto.name) { case (?n) n; case null tabla.metadata.name };
    description = switch (dto.description) { case (?d) d; case null tabla.metadata.description };
    image = switch (dto.imageUrl) { case (?i) i; case null tabla.metadata.image };
    cards = switch (dto.cards) { case (?c) c; case null tabla.metadata.cards };
  };
  
  Map.add<Nat32, T.Tabla>(
    tablas,
    Nat32.compare,
    dto.tablaId,
    { tabla with metadata = updatedMetadata; updatedAt = Time.now() }
  );
  
  #ok(());
};

  /* ----- Tabla Queries ----- */

  public query func getAvailableTablas() : async Result.Result<[T.TablaInfo], Text> {
    let out = List.empty<T.TablaInfo>();
    for (tabla in Map.values(tablas)) {
      if (tabla.status != #burned) {
        List.add<T.TablaInfo>(
          out,
          {
            id = tabla.id;
            owner = tabla.owner;
            renter = tabla.renter;
            gameId = tabla.gameId;
            rentalFee = 0;
            tokenType = tabla.tokenType;
            rarity = tabla.rarity;
            name = tabla.metadata.name;
            image = tabla.metadata.image;
            status = tabla.status;
            isAvailable = true;
          },
        );
      };
    };
    let arr = List.toArray(out);
    if (Array.size(arr) == 0) { #err("NotFound") } else { #ok(arr) };
  };

  public query func getTabla(tablaId : Ids.TablaId) : async Result.Result<?T.TablaInfo, Text> {
    let tOpt = Map.get<Ids.TablaId, T.Tabla>(tablas, Nat32.compare, tablaId);
    let ?tabla = tOpt else return #err("NotFound");
    #ok(
      ?{
        id = tabla.id;
        owner = tabla.owner;
        renter = tabla.renter;
        gameId = tabla.gameId;
        rentalFee = 0;
        tokenType = tabla.tokenType;
        rarity = tabla.rarity;
        name = tabla.metadata.name;
        image = tabla.metadata.image;
        status = tabla.status;
        isAvailable = (tabla.status != #burned);
      }
    );
  };

  public query func getTablaCards(tablaId : Ids.TablaId) : async Result.Result<[Nat], Text> {
    let ?tabla = Map.get<Ids.TablaId, T.Tabla>(tablas, Nat32.compare, tablaId) else return #err("NotFound");
    #ok(tabla.metadata.cards);
  };
  public query func tablaCount() : async Nat {
    Map.size(tablas);
  };
  public composite query func getPot(gameId : Text) : async Result.Result<{ amountBaseUnits : Nat; symbol : Text; decimals : Nat8 }, Text> {
  let ?game = Map.get<Text, T.Game>(games, Text.compare, gameId)
    else return #err("Game not found");

  let l = Escrow.ledgerOf(game.tokenType);
  let potAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(prizePoolSubAcc(gameId)));

  let bal      = await l.icrc1_balance_of(potAcct);
  let symbol   = await l.icrc1_symbol();
  let decimals = await l.icrc1_decimals();

  #ok({
    amountBaseUnits = bal;
    symbol;
    decimals;
    });
  };
  public shared ({caller}) func initRegistry(r:[(tabla:Nat32, owner : Text)]) : async Result.Result<(),Text>{
    if (not isAdmin(caller)) return #err("Not authorized");
    if (Array.size(r) == 0) return #err("Empty tuple")
      else {
        for ((id, owner) in Array.values(r)){
          if (owner != burnAddress){
            Map.add<Nat32, Text>(owners, Nat32.compare, id + 1, owner);
          };
        };
      #ok(());
    }
  };
  public query func gameCount() : async Nat {
    Map.size(games);
  };
  public shared ({ caller }) func upsertOwnerPrincipals(
  entries : [(Nat32, ?Principal)]
) : async Result.Result<(), Text> {
  if (not isAdmin(caller)) return #err("unauthorized");
  
  for ((tablaId, maybePrincipal) in Array.values(entries)) {
    Map.add<Nat32, ?Principal>(ownerPrincipals, Nat32.compare, tablaId, maybePrincipal);
  };
  
  #ok(())
  };
  public shared ({ caller }) func setDevWallet(wallet : ?Principal) : async Result.Result<(), Text> {
  if (not isAdmin(caller)) return #err("unauthorized");
  devWallet := wallet;
  #ok(())
};

public shared ({ caller }) func disburseDevFees(
  tokenType : E.TokenType,
  recipient : Principal,
  amount : Nat
) : async Result.Result<(), Text> {
  if (not isAdmin(caller)) return #err("unauthorized");
  
  let l = Escrow.ledgerOf(tokenType);
  let devAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(devFeeSubAcc()));
  let balance = await l.icrc1_balance_of(devAcct);
  
  if (balance < amount) return #err("Insufficient dev fee balance");
  
  let now_ns = Nat64.fromNat(Int.abs(Time.now()));
  let res = await l.icrc1_transfer({
    from_subaccount = devAcct.subaccount;
    to = Escrow.acct(recipient, null);
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

public composite query func getDevFeeBalance(tokenType : E.TokenType) : async Nat {
  let l = Escrow.ledgerOf(tokenType);
  let devAcct = Escrow.acct(Principal.fromActor(GameLogic), ?Blob.toArray(devFeeSubAcc()));
  await l.icrc1_balance_of(devAcct)
  };
  public query func getAvailableTablasForGame(gameId : Text) : async Result.Result<[T.TablaInfo], Text> {
  let ?game = Map.get<Text, T.Game>(games, Text.compare, gameId)
    else return #err("Game not found");
  
  let usedTablaIds = Array.map<(Ids.PlayerId, Ids.TablaId), Ids.TablaId>(
    game.tablas,
    func((_, tablaId)) { tablaId }
  );
  
  let out = List.empty<T.TablaInfo>();
  for (tabla in Map.values(tablas)) {
    if (tabla.status != #burned) {
      let isUsedInGame = Array.indexOf<Ids.TablaId>(usedTablaIds, Nat32.equal, tabla.id) != null;
      if (not isUsedInGame) {
        List.add<T.TablaInfo>(
          out,
          {
            id = tabla.id;
            owner = tabla.owner;
            renter = tabla.renter;
            gameId = tabla.gameId;
            rentalFee = 0;
            tokenType = tabla.tokenType;
            rarity = tabla.rarity;
            name = tabla.metadata.name;
            image = tabla.metadata.image;
            status = tabla.status;
            isAvailable = true;
          },
        );
      };
    };
  };
  
  let arr = List.toArray(out);
  if (Array.size(arr) == 0) { #err("No tablas available for this game") } else { #ok(arr) };
};
};
