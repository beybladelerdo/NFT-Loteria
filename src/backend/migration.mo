import Array "mo:core/Array";
import Map "mo:core/Map";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";
import Float "mo:core/Float";
import Ids "ids";
import Enums "enums";
import BaseIds "mo:waterway-mops/base/ids";
import T "types";

module {
  public type OldProfile = {
    principalId : BaseIds.PrincipalId;
    username : Text;
  };

  public type OldGame = {
    id : Nat32;
    name : Text;
    host : Ids.PlayerId;
    createdAt : Int;
    status : Enums.GameStatus;
    mode : Enums.GameMode;
    tokenType : Enums.TokenType;
    entryFee : Nat;
    hostFeePercent : Nat;
    players : [Ids.PlayerId];
    tablas : [(Ids.PlayerId, Ids.TablaId)];
    drawnCards : [Ids.CardId];
    currentCard : ?Ids.CardId;
    marcas : [T.Marca];
    winner : ?Ids.PlayerId;
    prizePool : Nat;
  };

  public func migration(
    old : { games : [OldGame]; profiles : [OldProfile] }
  ) : {
    var games : Map.Map<Text, T.Game>;
    var profiles : Map.Map<Principal, T.Profile>;
  } {

    // Maps to accumulate stats while we walk old games
    let played = Map.empty<Principal, Nat>();
    let won    = Map.empty<Principal, Nat>();

    // Helper to increment counters
    func incPlayed(pid : Principal) {
      let cur = switch (Map.get<Principal, Nat>(played, Principal.compare, pid)) { case (?n) n; case null 0 };
      Map.add<Principal, Nat>(played, Principal.compare, pid, cur + 1);
    };
    func incWins(pid : Principal) {
      let cur = switch (Map.get<Principal, Nat>(won, Principal.compare, pid)) { case (?n) n; case null 0 };
      Map.add<Principal, Nat>(won, Principal.compare, pid, cur + 1);
    };

    // Build the new games map (Text id) and tally stats
    let gmap = Map.empty<Text, T.Game>();
    for (og in Array.values<OldGame>(old.games)) {
      let idTxt = Nat32.toText(og.id);

      for (p in Array.values<Ids.PlayerId>(og.players)) { incPlayed(p) };
      switch (og.winner) { case (?w) { incWins(w) }; case null {} };

      let ng : T.Game = {
        id = idTxt;
        name = og.name;
        host = og.host;
        createdAt = og.createdAt;
        status = og.status;
        mode = og.mode;
        tokenType = og.tokenType;
        entryFee = og.entryFee;
        hostFeePercent = og.hostFeePercent;
        players = og.players;
        tablas = og.tablas;
        drawnCards = og.drawnCards;
        currentCard = og.currentCard;
        marcas = og.marcas;
        winner = og.winner;
        prizePool = og.prizePool;
      };
      Map.add<Text, T.Game>(gmap, Text.compare, idTxt, ng);
    };

    // Build the new profiles map, using tallied stats
    let pmap = Map.empty<Principal, T.Profile>();
    for (op in Array.values<OldProfile>(old.profiles)) {
      let pid = Principal.fromText(op.principalId);
      let g = switch (Map.get<Principal, Nat>(played, Principal.compare, pid)) { case (?n) n; case null 0 };
      let w = switch (Map.get<Principal, Nat>(won,    Principal.compare, pid)) { case (?n) n; case null 0 };
      let wr = if (g == 0) 0.0 else Float.fromInt(w) / Float.fromInt(g);

      let np : T.Profile = {
        principalId = op.principalId;
        username = op.username;
        games = g;
        wins = w;
        winRate = wr;
      };
      Map.add<Principal, T.Profile>(pmap, Principal.compare, pid, np);
    };

    { var games = gmap; var profiles = pmap }
  }
}
