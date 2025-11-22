import Ids "ids";
import T "types";

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
};
