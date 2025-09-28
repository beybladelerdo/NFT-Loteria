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
import Ledger "mo:waterway-mops/base/def/icp-ledger";
import Account "mo:waterway-mops/base/def/account";
import Enums "mo:waterway-mops/base/enums";
import Map "mo:core/Map";
import Random "mo:core/Random";
import VarArray "mo:core/VarArray";
import Array "mo:core/Array";
import List "mo:core/List";
import Utils "utilities";
import Ids "ids";
import Commands "commands";
import Queries "queries";
import {migration} "migration";

(with migration)
persistent actor GameLogic {

  type Entry = (Nat32, Text);
  let burnAddress = "0000000000000000000000000000000000000000000000000000000000000001";
  let ext : actor { getRegistry : shared query () -> async [Entry] } = actor ("psaup-3aaaa-aaaak-qsxlq-cai");

  private var games = Map.empty<Text, T.Game>();
  private var profiles = Map.empty<Principal, T.Profile>();
  private var owners = Map.empty<Nat32, Text>();
  private var tags = Map.empty<Text, Principal>();
  private var tablas = Map.empty<Nat32, T.Tabla>();

  let letters = Text.toArray("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  let digits = Text.toArray("0123456789");
  transient let rng = PRNG.sfc64a();
  rng.init(Nat64.fromIntWrap(Time.now()));

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
  public query func ownerOf(idx : Nat32) : async ?Text {
    Map.get<Nat32,Text>(owners, Nat32.compare, idx)
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
      players = [caller]; // Host is automatically a player
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

    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot join games");
    };

    switch (Map.get<Text, T.Game>(games, Text.compare, dto.gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #lobby) {
          return #err("Game is not in lobby state");
        };

        if (game.players.size() >= Constants.MAX_PLAYERS_PER_GAME) {
          return #err("Game is full");
        };
        for (player in game.players.values()) {
          if (Principal.equal(player, caller)) {
            return #err("Player already in game");
          };
        };

        if (game.tokenType == #ICP) {
          let ledger : Ledger.Interface = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

          let paymentResult = await ledger.transfer({
            from_subaccount = ?Account.principalToSubaccount(caller);
            to = Principal.toBlob(Principal.fromActor(GameLogic));
            amount = { e8s = Nat64.fromNat(game.entryFee * 100_000_000) };
            fee = { e8s = 10_000 }; // Standard transaction fee
            memo = 0;
            created_at_time = ?{
              timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()));
            };
          });

          switch (paymentResult) {
            case (#Err(e)) { return #err("Payment failed: " # debug_show (e)) };
            case (#Ok(_)) {};
          };
        };

        // Add player to the game
        let playerlist = List.fromArray<Ids.PlayerId>(game.players);
        List.add<Ids.PlayerId>(playerlist, caller);
        let updatedPlayers = List.toArray(playerlist);
        switch (addTablaToGame(caller, dto.gameId, dto.rentedTablaId)) {
          case (#ok(r)) { r };
          case (#err(e)) { return #err(e) };
        };
        Map.add<Text, T.Game>(games, Text.compare, dto.gameId, { game with players = updatedPlayers; prizePool = game.prizePool + game.entryFee });
        #ok(());
      };
    };
  };

  func addTablaToGame(caller : Principal, gameId : Text, tablaId : Ids.TablaId) : Result.Result<(), Text> {

    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        // Check if player is in the game
        var playerFound = false;
        for (player in game.players.values()) {
          if (player == caller) {
            playerFound := true;
          };
        };
        if (not playerFound) {
          return #err("Player not in game");
        };
        for ((player, tabla) in game.tablas.values()) {
          if (tabla == tablaId) {
            return #err("Tabla already in use in this game");
          };
        };

        var playerTablaCount = 0;
        for ((player, _) in game.tablas.values()) {
          if (player == caller) {
            playerTablaCount += 1;
          };
        };

        if (playerTablaCount >= Constants.MAX_TABLAS_PER_PLAYER) {
          return #err("Player already has maximum number of tablas");
        };

        let tablalist = List.fromArray<(Ids.PlayerId, Ids.TablaId)>(game.tablas);
        List.add<(Ids.PlayerId, Ids.TablaId)>(tablalist, (caller, tablaId));
        let updatedTablas = List.toArray(tablalist);
        Map.add<Text, T.Game>(games, Text.compare, gameId, { game with tablas = updatedTablas });
        #ok(());
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

        // bitmap of drawn cards (1..54) using VarArray.repeat + index assignment
        let taken = VarArray.repeat<Bool>(false, Constants.TOTAL_CARDS + 1);
        for (c in Array.values<Ids.CardId>(game.drawnCards)) {
          let i = Nat32.toNat(c);
          if (i <= Constants.TOTAL_CARDS) { taken[i] := true };
        };

        let remaining = Constants.TOTAL_CARDS - game.drawnCards.size();
        let k : Nat = await* crypto.natRange(0, remaining); // index inside undrawn set

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
    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case null { #err("Game not found") };
      case (?game) {
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

        Map.add<Text, T.Game>(games, Text.compare, gameId, { game with status = #completed; winner = ?caller });
        #ok(());
      };
    };
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

  public shared ({ caller }) func updateRentalFee(dto : Commands.UpdateTablaRentalFee) : async Result.Result<(), Text> {
    let ?tabla = Map.get<Ids.TablaId, T.Tabla>(tablas, Nat32.compare, dto.tablaId) else return #err("Tabla not found");
    if (caller != tabla.owner) return #err("Only the owner can update rental fee");
    if (tabla.status != #available) return #err("Cannot update fee while tabla is rented");
    Map.add<Ids.TablaId, T.Tabla>(
      tablas,
      Nat32.compare,
      dto.tablaId,
      {
        tabla with rentalFee = dto.newFee;
        updatedAt = Time.now();
      },
    );
    #ok(());
  };

  /* ----- Tabla Queries ----- */

  public query func getAvailableTablas() : async Result.Result<[T.TablaInfo], Text> {
    let out = List.empty<T.TablaInfo>();
    for (tabla in Map.values(tablas)) {
      if (tabla.status == #available) {
        List.add<T.TablaInfo>(
          out,
          {
            id = tabla.id;
            owner = tabla.owner;
            renter = tabla.renter;
            gameId = tabla.gameId;
            rentalFee = tabla.rentalFee;
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
        rentalFee = tabla.rentalFee;
        tokenType = tabla.tokenType;
        rarity = tabla.rarity;
        name = tabla.metadata.name;
        image = tabla.metadata.image;
        status = tabla.status;
        isAvailable = (tabla.status == #available);
      }
    );
  };

  public query func getTablaCards(tablaId : Ids.TablaId) : async Result.Result<[Nat], Text> {
    let ?tabla = Map.get<Ids.TablaId, T.Tabla>(tablas, Nat32.compare, tablaId) else return #err("NotFound");
    #ok(tabla.metadata.cards);
  };
};
