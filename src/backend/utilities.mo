/**
 * NFT Lotería - Utilities
 * Helper functions and common operations
 * 
 * @author Demali Gregg
 * @company Canister Software Inc.
 */
import Hash "mo:base/Hash";
import Result "mo:core/Result";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Map "mo:core/Map";
import Blob "mo:core/Blob";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import T "Types";
import Ids "Ids";
import List "mo:core/List";
import VarArray "mo:core/VarArray";
import Sha256 "mo:sha2/Sha256";
import PRNG "mo:core/internal/PRNG";
import Array "mo:core/Array";

module Utilities {
  let letters : [Char] = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
  let digits : [Char] = ['0','1','2','3','4','5','6','7','8','9'];

  func pick(rng : PRNG.SFC64, arr : [Char], bound : Nat64) : Char {
    let idx = Nat64.toNat(Nat64.rem(rng.next(), bound));
    arr[idx];
  };

  public func genGameId(rng : PRNG.SFC64) : Text {
    var out : [var Char] = [var ' ', ' ', ' ', ' ', ' ', ' '];
    let b26 : Nat64 = 26;
    let b10 : Nat64 = 10;
    var i = 0;
    while (i < 6) {
      if (Nat64.rem(rng.next(), 2) == 0) {
        out[i] := pick(rng, letters, b26);
      } else {
        out[i] := pick(rng, digits, b10);
      };
      i += 1;
    };
    Text.fromVarArray(out);
  };

  public let eqNat32 = func(a : Nat32, b : Nat32) : Bool {
    a == b;
  };

  public let  paidCmp = func(a : T.PaidKey, b : T.PaidKey) : {#less;#equal;#greater} {
    let c = Text.compare(a.0, b.0); if (c != #equal) return c;
    Principal.compare(a.1, b.1);
  };
  public func hasPaid(paidSet : Map.Map<(Text, Principal), Bool>, gid : Text, p : Principal) : Bool {
    switch (Map.get(paidSet, paidCmp, (gid, p))) {
      case (?_) true;
      case null false;
    };
  };

  public func markPaid(paidSet : Map.Map<(Text, Principal), Bool>, gid : Text, p : Principal) {
    Map.add(paidSet, paidCmp, (gid, p), true);
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

  public func prizePoolSubAcc(gameId : Text) : Blob {
    Sha256.fromArray(#sha256, Blob.toArray(Text.encodeUtf8("pot:" # gameId)))
  };
  public func devFeeSubAcc() : Blob {
    Sha256.fromArray(#sha256, Blob.toArray(Text.encodeUtf8("dev-fee")))
  };

  public let burnAddress = "0000000000000000000000000000000000000000000000000000000000000001";
  let ext : actor { getRegistry : shared query () -> async [T.Entry] } = actor ("psaup-3aaaa-aaaak-qsxlq-cai");

  public func refresh(owners : Map.Map<Nat32, Text>) : async () {
    let entries = await ext.getRegistry();
    for ((id, owner) in Array.values(entries)) {
      if (owner != burnAddress) {
        Map.add<Nat32, Text>(owners, Nat32.compare, id + 1, owner);
      };
    };
  };
  public func lock(lockMap: Map.Map<Text,Bool>, id : Text) : Bool  {
    switch (Map.get<Text, Bool>(lockMap, Text.compare, id)) {
      case (?_) { false };
      case null { Map.add<Text, Bool>(lockMap, Text.compare, id, true); true };
    };
  };
  public func unlock(lockMap: Map.Map<Text,Bool>, id : Text) {
    ignore Map.take<Text, Bool>(lockMap, Text.compare, id);
  }
};
