import Ids "ids";
import Enums "enums";
import T "types";

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
    status : Enums.GameStatus;
    mode : Enums.GameMode;
    tokenType : Enums.TokenType;
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

};
