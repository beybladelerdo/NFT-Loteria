import Hash "mo:base/Hash";
import Result "mo:base/Result";
import Nat32 "mo:core/Nat32";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import T "types";
import Ids "ids";
import Queries "queries";
import List "mo:core/List";
import VarArray "mo:core/VarArray";
import Array "mo:core/Array";
import Constants "constants";

module Utilities {

  public let eqNat32 = func(a : Nat32, b : Nat32) : Bool {
    a == b;
  };
  public let  paidCmp = func(a : T.PaidKey, b : T.PaidKey) : {#less;#equal;#greater} {
    let c = Text.compare(a.0, b.0); if (c != #equal) return c;
    Principal.compare(a.1, b.1);
  };

  public let hashNat32 = func(key : Nat32) : Hash.Hash {
    Nat32.fromNat(Nat32.toNat(key) % (2 ** 32 - 1));
  };
  public func bitIndex(row : Nat, col : Nat, size : Nat) : Nat {
    row * size + col;
  };

  public func bitAt(row : Nat, col : Nat, size : Nat) : Nat32 {
    Nat32.fromNat(1) << Nat32.fromNat(bitIndex(row, col, size));
  };
  public func makeMasks(size : Nat) : T.Masks {
    // rows
    var rowL = List.empty<Nat32>();
    var r : Nat = 0;
    while (r < size) {
      var m : Nat32 = 0;
      var c : Nat = 0;
      while (c < size) { m := m | bitAt(r, c, size); c += 1 };
      List.add<Nat32>(rowL, m);
      r += 1;
    };
    let rows = List.toArray(rowL);

    // cols
    var colL = List.empty<Nat32>();
    var c2 : Nat = 0;
    while (c2 < size) {
      var m2 : Nat32 = 0;
      var r2 : Nat = 0;
      while (r2 < size) { m2 := m2 | bitAt(r2, c2, size); r2 += 1 };
      List.add<Nat32>(colL, m2);
      c2 += 1;
    };
    let cols = List.toArray(colL);

    // diagonals
    var diagMain : Nat32 = 0;
    var i : Nat = 0;
    while (i < size) { diagMain := diagMain | bitAt(i, i, size); i += 1 };

    var diagOther : Nat32 = 0;
    var j : Nat = 0;
    while (j < size) {
      diagOther := diagOther | bitAt(j, size - 1 - j, size);
      j += 1;
    };

    let totalBits = size * size;
    let allMask : Nat32 = ((1 : Nat32) << Nat32.fromNat(totalBits)) - 1;

    {
      size = size;
      rows = rows;
      cols = cols;
      diagMain = diagMain;
      diagOther = diagOther;
      allMask = allMask;
    };
  };
  public func buildDrawnSet(totalCards : Nat, drawn : [Ids.CardId]) : [Bool] {
    let set = VarArray.repeat<Bool>(false, totalCards + 1);
    for (c in Array.values<Ids.CardId>(drawn)) {
      let i = Nat32.toNat(c);
      if (i <= totalCards) { set[i] := true };
    };
    Array.fromVarArray(set);
  };
  public func isDrawn(drawnSet : [Bool], id : Ids.CardId) : Bool {
    let i = Nat32.toNat(id);
    i < drawnSet.size() and drawnSet[i];
  };
  public func markMaskFor(
    game : T.Game,
    player : Principal,
    tablaId : Ids.TablaId,
    size : Nat,
    drawnSet : [Bool],
    cardAt : (Ids.TablaId, T.Position) -> Result.Result<Ids.CardId, Text>,
  ) : Result.Result<Nat32, Text> {
    var mask : Nat32 = 0;
    for (m in Array.values<T.Marca>(game.marcas)) {
      if (m.playerId == player and m.tablaId == tablaId) {
        switch (cardAt(tablaId, m.position)) {
          case (#ok cid) {
            if (isDrawn(drawnSet, cid)) {
              mask := mask | bitAt(m.position.row, m.position.col, size);
            };
          };
          case (#err e) { return #err(e) };
        };
      };
    };
    #ok(mask);
  };
  public func hasLine(markMask : Nat32, m : T.Masks) : Bool {
    for (rm in Array.values<Nat32>(m.rows)) if ((markMask & rm) == rm) return true;
    for (cm in Array.values<Nat32>(m.cols)) if ((markMask & cm) == cm) return true;
    if ((markMask & m.diagMain) == m.diagMain) return true;
    if ((markMask & m.diagOther) == m.diagOther) return true;
    false;
  };

  public func isBlackout(markMask : Nat32, m : T.Masks) : Bool {
    markMask == m.allMask;
  };
  public func toGameView(g : T.Game) : Queries.GameView = {
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
};
