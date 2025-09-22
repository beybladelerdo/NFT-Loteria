import Ids "ids";
import Enums "enums";

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
    status : Enums.GameStatus;
    mode : Enums.GameMode;
    tokenType : Enums.TokenType;
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

};
