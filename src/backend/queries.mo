/**
 * NFT Lotería - Queries
 * Read-only operations and data retrieval
 * 
 * @author Demali Gregg
 * @company Canister Software Inc.
 */

import Ids "Ids";
import T "Types";
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Enums "mo:waterway-mops/base/enums";
import Principal "mo:core/Principal";
import Array "mo:core/Array";
import Nat32 "mo:core/Nat32";
import Result "mo:core/Result";
import Constants "Constants";
import List "mo:core/List";

module Queries {

  public type GetOpenGames = {
    page : Nat;
  };

  public type OpenGames = {
    page : Nat;
    openGames : [GameView];
  };

  public type GetActiveGames = {
    page : Nat;
  };

  public type ActiveGames = {
    page : Nat;
    activeGames : [GameView];
  };

  public type GetGame = {
    gameId : Text;
  };

  public type GameView = {
    id : Text;
    name : Text;
    host : Ids.PlayerId;
    createdAt : Int;
    status : T.GameStatus;
    mode : T.GameMode;
    tokenType : T.TokenType;
    entryFee : Nat;
    hostFeePercent : Nat;
    playerCount : Nat;
    maxPlayers : Nat;
    drawnCardCount : Nat;
    currentCard : ?Ids.CardId;
    winner : ?Ids.PlayerId;
    prizePool : Nat;
  };

  public type GetDrawHistory = {
    gameId : Text;
  };

  public type DrawHistory = {
    cardsDrawn : [Ids.CardId];
  };

  public type BasicProfile = {
    principal : Ids.PlayerId;
    username : ?Text;
  };

  public type TablaInGame = {
    tablaId : Ids.TablaId;
    name : Text;
    image : Text;
    cards : [Nat];
  };

  public type PlayerSummary = {
    principal : Ids.PlayerId;
    username : ?Text;
    tablas : [TablaInGame];
  };

  public type MarcaView = T.Marca;

  public type GameDetail = {
    id : Text;
    name : Text;
    host : BasicProfile;
    status : T.GameStatus;
    mode : T.GameMode;
    tokenType : T.TokenType;
    entryFee : Nat;
    hostFeePercent : Nat;
    createdAt : Int;
    drawnCards : [Ids.CardId];
    currentCard : ?Ids.CardId;
    prizePool : Nat;
    players : [PlayerSummary];
    playerCount : Nat;
    maxPlayers : Nat;
    marks : [MarcaView];
    winner : ?Ids.PlayerId;
  };
   public func toGameView(g : T.Game) : GameView = {
    id = g.id;
    name = g.name;
    host = g.host;
    createdAt = g.createdAt;
    status = g.status;
    mode = g.mode;
    tokenType = g.tokenType;
    entryFee = g.entryFee;
    hostFeePercent = g.hostFeePercent;
    playerCount = g.players.size();
    maxPlayers = Constants.MAX_PLAYERS_PER_GAME;
    drawnCardCount = g.drawnCards.size();
    currentCard = g.currentCard;
    winner = g.winner;
    prizePool = g.prizePool;
  };
  public func ownerOf(
    owners : Map.Map<Nat32, Text>,
    ownerPrincipals : Map.Map<Nat32, ?Principal>,
    idx : Nat32
  ) : (?Text, ?Principal) {
    let ownerText = Map.get(owners, Nat32.compare, idx);
    let ownerPrincipal = switch (Map.get(ownerPrincipals, Nat32.compare, idx)) {
      case null { null };
      case (?inner) { inner };
    };
    (ownerText, ownerPrincipal);
  };

  public func isTagAvailable(tags : Map.Map<Text, Principal>, tag : Text) : Bool {
    switch (Map.get(tags, Text.compare, tag)) {
      case null true;
      case (?_) false;
    };
  };

  public func getProfile(
    profiles : Map.Map<Principal, T.Profile>,
    caller : Principal
  ) : Result.Result<T.Profile, Text> {
    switch (Map.get(profiles, Principal.compare, caller)) {
      case null { #err("no profile found") };
      case (?profile) { #ok(profile) };
    };
  };

  public func getPlayerProfile(
    tags : Map.Map<Text, Principal>,
    profiles : Map.Map<Principal, T.Profile>,
    t : Text
  ) : Result.Result<T.Profile, Text> {
    switch (Map.get(tags, Text.compare, t)) {
      case null { #err("No Principal associated with tag") };
      case (?p) {
        switch (Map.get(profiles, Principal.compare, p)) {
          case null { #err("no profile found") };
          case (?profile) { #ok(profile) };
        };
      };
    };
  };
  public func getOpenGames(games : Map.Map<Text, T.Game>, dto : GetOpenGames) : Result.Result<OpenGames, Text> {
    let start = dto.page * Constants.PAGE_COUNT;

    var matched : Nat = 0;
    let out = List.empty<GameView>();

    label scan for (g in Map.values(games)) {
      if (g.status == #lobby) {
        if (matched >= start and List.size(out) < Constants.PAGE_COUNT) {
          List.add<GameView>(out, toGameView(g));
          if (List.size(out) == Constants.PAGE_COUNT) break scan;
        };
        matched += 1;
      };
    };
    #ok({ page = dto.page; openGames = List.toArray(out) });
  };
  public func getActiveGames(games : Map.Map<Text, T.Game> , dto : GetActiveGames) : Result.Result<ActiveGames, Enums.Error> {
    let start = dto.page * Constants.PAGE_COUNT;

    var matched : Nat = 0;
    let out = List.empty<GameView>();

    label scan for (g in Map.values(games)) {
      if (g.status == #active) {
        if (matched >= start and List.size(out) < Constants.PAGE_COUNT) {
          List.add<GameView>(out, toGameView(g));
          if (List.size(out) == Constants.PAGE_COUNT) break scan;
        };
        matched += 1;
      };
    };

    #ok({ page = dto.page; activeGames = List.toArray(out) });
  };
  public func getGame(games : Map.Map<Text, T.Game> , dto : GetGame) : Result.Result<?GameView, Text> {
    switch (Map.get<Text, T.Game>(games, Text.compare, dto.gameId)) {
      case null { #err("No Game found") };
      case (?g) { #ok(?toGameView(g)) };
    };
  };
  public  func getGameDetail(games : Map.Map<Text, T.Game>, 
  profiles : Map.Map<Principal, T.Profile>,
  tablas : Map.Map<Nat32, T.Tabla>,
  dto : GetGame) : Result.Result<GameDetail, Text> {
    let ?game = Map.get<Text, T.Game>(games, Text.compare, dto.gameId)
      else return #err("No Game found");

    let hostProfile : BasicProfile = {
      principal = game.host;
      username = switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, game.host)) {
        case (?prof) ?prof.username;
        case null null;
      };
    };

    let playerSummaries = Array.map<Ids.PlayerId, PlayerSummary>(
      game.players,
      func (player : Ids.PlayerId) : PlayerSummary {
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

        let tablaSummaries = Array.map<(Ids.PlayerId, Ids.TablaId), TablaInGame>(
          tablasForPlayer,
          func (entry : (Ids.PlayerId, Ids.TablaId)) : TablaInGame {
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
  public func getDrawHistory(games:Map.Map<Text, T.Game>, dto : GetDrawHistory) :  Result.Result<[Ids.CardId], Text> {
    switch (Map.get<Text, T.Game>(games, Text.compare, dto.gameId)) {
      case null { #err("No Game found") };
      case (?g) { #ok(g.drawnCards) };
    };
  };
  public func isPlayerInGame(
    games : Map.Map<Text, T.Game>,
    caller : Principal,
  ) : ?{ gameId : Text; role : { #host; #player } } {
    if (Principal.isAnonymous(caller)) {
      return null;
    };

    for ((gameId, game) in Map.entries(games)) {
      let isRelevantStatus = switch (game.status) {
        case (#lobby) true;
        case (#active) true;
        case (_) false;
      };

      if (isRelevantStatus) {
        if (game.host == caller) {
          return ?{ gameId = gameId; role = #host };
        };

        for ((playerId, _) in Array.values(game.tablas)) {
          if (playerId == caller) {
            return ?{ gameId = gameId; role = #player };
          };
        };
      };
    };

    null
  };
  public func getRecentGamesForPlayer(
  games : Map.Map<Text, T.Game>,
  caller : Principal,
  limit : Nat
) : [{
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
  let out = List.empty<{
    gameId : Text;
    mode : T.GameMode;
    tokenType : T.TokenType;
    entryFee : Nat;
    status : T.GameStatus;
    winner : ?Principal;
    createdAt : Int;
    isWinner : Bool;
    isHost : Bool;
  }>();
  var count = 0;
  
  for ((gameId, game) in Map.entries(games)) {
    if (count >= limit) return List.toArray(out);
    
    var isPlayer = false;
    for ((p, _) in Array.values(game.tablas)) {
      if (p == caller) { isPlayer := true };
    };
    
    let isHost = game.host == caller;
    
    if (isPlayer or isHost) {
      let isWinner = switch (game.winner) {
        case (?w) w == caller;
        case null false;
      };
      
      List.add(out, {
        gameId = gameId;
        mode = game.mode;
        tokenType = game.tokenType;
        entryFee = game.entryFee;
        status = game.status;
        winner = game.winner;
        createdAt = game.createdAt;
        isWinner = isWinner;
        isHost = isHost;
      });
      
      count += 1;
    };
  };
  
  List.toArray(out);
};
public func getAvailableTablas(
  tablas : Map.Map<Ids.TablaId, T.Tabla>
) : Result.Result<[T.TablaInfo], Text> {
  let out = List.empty<T.TablaInfo>();
  for (tabla in Map.values(tablas)) {
    if (tabla.status != #burned) {
      List.add(
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

public func getTabla(
  tablas : Map.Map<Ids.TablaId, T.Tabla>,
  tablaId : Ids.TablaId
) : Result.Result<?T.TablaInfo, Text> {
  let ?tabla = Map.get(tablas, Nat32.compare, tablaId) else return #err("NotFound");
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

public func getTablaCards(
  tablas : Map.Map<Ids.TablaId, T.Tabla>,
  tablaId : Ids.TablaId
) : Result.Result<[Nat], Text> {
  let ?tabla = Map.get(tablas, Nat32.compare, tablaId) else return #err("NotFound");
  #ok(tabla.metadata.cards);
};

public func getAvailableTablasForGame(
  games : Map.Map<Text, T.Game>,
  tablas : Map.Map<Ids.TablaId, T.Tabla>,
  gameId : Text
) : Result.Result<[T.TablaInfo], Text> {
  let ?game = Map.get(games, Text.compare, gameId)
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
        List.add(
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
public func getChatMessages(
  gameChats : Map.Map<Text, List.List<T.ChatMessage>>,
  gameId : Text
) : [T.ChatMessage] {
  switch (Map.get(gameChats, Text.compare, gameId)) {
    case (?msgs) List.toArray(msgs);
    case null [];
  };
};

public func getFailedClaims(
  failedClaims : Map.Map<Text, T.FailedClaim>,
  caller : Principal
) : [T.FailedClaim] {
  let out = List.empty<T.FailedClaim>();
  for (claim in Map.values(failedClaims)) {
    if (claim.player == caller) {
      List.add(out, claim);
    };
  };
  List.toArray(out);
};
};
