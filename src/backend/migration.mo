import Map "mo:core/Map";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";
import Text "mo:core/Text";

import Ids "ids";
import Enums "enums";
import Types "types";

module {
  module OldEnums {
    public type TokenType = { #ICP; #ckBTC };
  };

  module OldTypes {
    public type RentalRecord = {
      renter : Ids.RenterId;
      gameId : ?Text;
      startTime : Int;
      endTime : ?Int;
      fee : Nat;
      tokenType : OldEnums.TokenType;
    };

    public type Tabla = {
      id : Ids.TablaId;
      owner : Ids.OwnerId;
      renter : ?Ids.RenterId;
      gameId : ?Text;
      rentalFee : Nat;
      tokenType : OldEnums.TokenType;
      rarity : Enums.Rarity;
      metadata : Types.TablaMetadata;
      rentalHistory : [RentalRecord];
      status : Enums.RentalStatus;
      createdAt : Int;
      updatedAt : Int;
    };

    public type Game = {
      id : Text;
      name : Text;
      host : Ids.PlayerId;
      createdAt : Int;
      status : Enums.GameStatus;
      mode : Enums.GameMode;
      tokenType : OldEnums.TokenType;
      entryFee : Nat;
      hostFeePercent : Nat;
      players : [Ids.PlayerId];
      tablas : [(Ids.PlayerId, Ids.TablaId)];
      drawnCards : [Ids.CardId];
      currentCard : ?Ids.CardId;
      marcas : [Types.Marca];
      winner : ?Ids.PlayerId;
      prizePool : Nat;
    };
  };

  func toNewTokenType(t : OldEnums.TokenType) : Enums.TokenType {
    switch (t) { case (#ICP) #ICP; case (#ckBTC) #ckBTC };
  };

  func toNewRentalRecord(r : OldTypes.RentalRecord) : Types.RentalRecord {
    {
      r with 
      tokenType = toNewTokenType(r.tokenType);
    }
  };

  func toNewTabla(t : OldTypes.Tabla) : Types.Tabla {
    {
      id = t.id;
      owner = t.owner;
      renter = t.renter;
      gameId = t.gameId;
      rentalFee = t.rentalFee;
      tokenType = toNewTokenType(t.tokenType);
      rarity = t.rarity;
      metadata = t.metadata;
      rentalHistory = Array.map<OldTypes.RentalRecord, Types.RentalRecord>(
        t.rentalHistory,
        toNewRentalRecord
      );
      status = t.status;
      createdAt = t.createdAt;
      updatedAt = t.updatedAt;
    }
  };

  func toNewGame(g : OldTypes.Game) : Types.Game {
    {
      g with
      tokenType = toNewTokenType(g.tokenType);
    }
  };

  public func migration(
    old : {
      var games  : Map.Map<Text, OldTypes.Game>;
      var tablas : Map.Map<Ids.TablaId, OldTypes.Tabla>;
    }
  ) : {
    var games  : Map.Map<Text, Types.Game>;
    var tablas : Map.Map<Ids.TablaId, Types.Tabla>;
  } {
    let tablasOut = Map.empty<Ids.TablaId, Types.Tabla>();
    for ((id, v) in Map.entries<Ids.TablaId, OldTypes.Tabla>(old.tablas)) {
      Map.add(tablasOut, Nat32.compare, id, toNewTabla(v));
    };

    let gamesOut = Map.empty<Text, Types.Game>();
    for ((k, v) in Map.entries<Text, OldTypes.Game>(old.games)) {
      Map.add(gamesOut, Text.compare, k, toNewGame(v));
    };

    { var games = gamesOut; var tablas = tablasOut };
  };
}
