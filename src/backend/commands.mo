import Ids "./ids";
import Enums "./enums";

module Commands {
  public type CreateGame = {
    name : Text;
    mode : Enums.GameMode;
    tokenType : Enums.TokenType;
    entryFee : Nat;
    hostFeePercent : Nat;
  };

  public type JoinGame = {
    gameId : Text;
    rentedTablaId : Ids.TablaId;
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
    rarity : Enums.Rarity;
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
