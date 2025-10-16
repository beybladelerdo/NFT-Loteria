module Enums {

  // Game status
  public type GameStatus = {
    #lobby; // Players can join
    #active; // Game in progress
    #completed; // Game finished
  };

  // Game mode
  public type GameMode = {
    #line; // Win by completing a line, row, or diagonal
    #blackout; // Win by marking all positions
  };

  // Token type
  public type TokenType = {
    #ICP;
    #ckBTC;
    #gldt;
  };

  // Rarity types
  public type Rarity = {
    #common;
    #uncommon;
    #rare;
    #epic;
    #legendary;
  };

  // Rental status
  public type RentalStatus = {
    #available;
    #rented;
    #burned;
  };

};
