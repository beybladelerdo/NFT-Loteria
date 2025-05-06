import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Random "mo:base/Random";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import T "./types";

actor GameLogic {
  

  // State variables
  private stable var nextGameId: T.GameId = 1;
  private stable var gameEntries: [(T.GameId, T.Game)] = [];
  private var games = HashMap.fromIter<T.GameId, T.Game>(
    gameEntries.vals(), 
    10, 
    eqNat32, 
    hashNat32
  );

  // Constants
  let MAX_PLAYERS_PER_GAME = 50;
  let MAX_TABLAS_PER_PLAYER = 4;
  let TABLA_SIZE = 4; // 4x4 tabla
  let TOTAL_CARDS = 54; // Total number of cards in the deck

  // Create a new game
  public shared(msg) func createGame(params: T.GameParams) : async Result.Result<T.GameId, Text> {
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot create games");
    };
    
    // Validate params
    if (params.hostFeePercent > 20) {
      return #err("Host fee cannot exceed 20%");
    };
    
    if (params.name == "") {
      return #err("Game name cannot be empty");
    };
    
    let newGame: T.Game = {
      id = nextGameId;
      name = params.name;
      host = caller;
      createdAt = Time.now();
      status = #lobby;
      mode = params.mode;
      tokenType = params.tokenType;
      entryFee = params.entryFee;
      hostFeePercent = params.hostFeePercent;
      players = [caller]; // Host is automatically a player
      tablas = [];
      drawnCards = [];
      currentCard = null;
      marcas = [];
      winner = null;
      prizePool = 0;
    };
    
    games.put(nextGameId, newGame);
    nextGameId += 1;
    
    #ok(newGame.id)
  };
  
  // Get games in lobby state
  public query func getOpenGames() : async [T.GameInfo] {
    let openGames = Buffer.Buffer<T.GameInfo>(10);
    
    for ((id, game) in games.entries()) {
      if (game.status == #lobby) {
        openGames.add({
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          playerCount = game.players.size();
          maxPlayers = MAX_PLAYERS_PER_GAME;
          drawnCardCount = game.drawnCards.size();
          currentCard = game.currentCard;
          winner = game.winner;
          prizePool = game.prizePool;
        });
      }
    };
    
    Buffer.toArray(openGames)
  };
  
  // Get games in active state
  public query func getActiveGames() : async [T.GameInfo] {
    let activeGames = Buffer.Buffer<T.GameInfo>(10);
    
    for ((id, game) in games.entries()) {
      if (game.status == #active) {
        activeGames.add({
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          playerCount = game.players.size();
          maxPlayers = MAX_PLAYERS_PER_GAME;
          drawnCardCount = game.drawnCards.size();
          currentCard = game.currentCard;
          winner = game.winner;
          prizePool = game.prizePool;
        });
      }
    };
    
    Buffer.toArray(activeGames)
  };
  
  // Get a specific game
  public query func getGame(gameId: T.GameId) : async ?T.GameInfo {
    switch (games.get(gameId)) {
      case (null) { null };
      case (?game) {
        ?{
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          playerCount = game.players.size();
          maxPlayers = MAX_PLAYERS_PER_GAME;
          drawnCardCount = game.drawnCards.size();
          currentCard = game.currentCard;
          winner = game.winner;
          prizePool = game.prizePool;
        }
      };
    }
  };
  
  // Join a game
  public shared(msg) func joinGame(gameId: T.GameId) : async Result.Result<(), Text> {
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot join games");
    };
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #lobby) {
          return #err("Game is not in lobby state");
        };
        
        if (game.players.size() >= MAX_PLAYERS_PER_GAME) {
          return #err("Game is full");
        };
        
        // Check if player is already in the game
        for (player in game.players.vals()) {
          if (Principal.equal(player, caller)) {
            return #err("Player already in game");
          };
        };
        
        // Add player to the game
        let updatedPlayers = Array.append<T.PlayerId>(game.players, [caller]);
        
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = updatedPlayers;
          tablas = game.tablas;
          drawnCards = game.drawnCards;
          currentCard = game.currentCard;
          marcas = game.marcas;
          winner = game.winner;
          prizePool = game.prizePool + game.entryFee; // Add entry fee to prize pool
        };
        
        games.put(gameId, updatedGame);
        #ok(())
      };
    }
  };
  
  // Add tabla to player in a game
  public shared(msg) func addTablaToGame(gameId: T.GameId, tablaId: T.TablaId) : async Result.Result<(), Text> {
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot add tablas");
    };
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        // Check if player is in the game
        var playerFound = false;
        for (player in game.players.vals()) {
          if (Principal.equal(player, caller)) {
            playerFound := true;
          };
        };
        
        if (not playerFound) {
          return #err("Player not in game");
        };
        
        // Check if tabla is already in use in this game
        for ((player, tabla) in game.tablas.vals()) {
          if (tabla == tablaId) {
            return #err("Tabla already in use in this game");
          };
        };
        
        // Count how many tablas the player already has
        var playerTablaCount = 0;
        for ((player, _) in game.tablas.vals()) {
          if (Principal.equal(player, caller)) {
            playerTablaCount += 1;
          };
        };
        
        if (playerTablaCount >= MAX_TABLAS_PER_PLAYER) {
          return #err("Player already has maximum number of tablas");
        };
        
        // Add tabla to the game
        let updatedTablas = Array.append<(T.PlayerId, T.TablaId)>(game.tablas, [(caller, tablaId)]);
        
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = game.players;
          tablas = updatedTablas;
          drawnCards = game.drawnCards;
          currentCard = game.currentCard;
          marcas = game.marcas;
          winner = game.winner;
          prizePool = game.prizePool;
        };
        
        games.put(gameId, updatedGame);
        #ok(())
      };
    }
  };
  
  // Start the game (host only)
  public shared(msg) func startGame(gameId: T.GameId) : async Result.Result<(), Text> {
    let caller = msg.caller;
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (not Principal.equal(caller, game.host)) {
          return #err("Only the host can start the game");
        };
        
        if (game.status != #lobby) {
          return #err("Game is not in lobby state");
        };
        
        if (game.players.size() < 2) {
          return #err("Need at least 2 players to start");
        };
        
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = #active;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = game.players;
          tablas = game.tablas;
          drawnCards = game.drawnCards;
          currentCard = game.currentCard;
          marcas = game.marcas;
          winner = game.winner;
          prizePool = game.prizePool;
        };
        
        games.put(gameId, updatedGame);
        #ok(())
      };
    }
  };
  
  // Draw a card (host only)
  public shared(msg) func drawCard(gameId: T.GameId) : async Result.Result<T.CardId, Text> {
    let caller = msg.caller;
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (not Principal.equal(caller, game.host)) {
          return #err("Only the host can draw cards");
        };
        
        if (game.status != #active) {
          return #err("Game is not active");
        };
        
        if (game.drawnCards.size() >= TOTAL_CARDS) {
          return #err("All cards have been drawn");
        };
        
        // Use game ID and timestamp for pseudo-randomness
        let seed = Nat32.toNat((Text.hash(Int.toText(Time.now())) + game.id)) % TOTAL_CARDS; 
        
        // Find a card that hasn't been drawn yet
        var cardId : T.CardId = Nat32.fromNat((seed % TOTAL_CARDS)) + 1;
        var attempts = 0;
        
        // Keep trying until we find an undrawn card
        while (Array.find<T.CardId>(game.drawnCards, func(c) { c == cardId }) != null and attempts < TOTAL_CARDS) {
          cardId := (cardId % Nat32.fromNat(TOTAL_CARDS)) + 1;
          attempts += 1;
        };
        
        // Make sure we found an undrawn card
        if (Array.find<T.CardId>(game.drawnCards, func(c) { c == cardId }) != null) {
          return #err("Could not find an undrawn card");
        };
        
        // Update the game with the new card
        let updatedDrawnCards = Array.append<T.CardId>(game.drawnCards, [cardId]);
        
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = game.players;
          tablas = game.tablas;
          drawnCards = updatedDrawnCards;
          currentCard = ?cardId;
          marcas = game.marcas;
          winner = game.winner;
          prizePool = game.prizePool;
        };
        
        games.put(gameId, updatedGame);
        #ok(cardId)
      };
    }
  };
  
  // Mark a position on a tabla
  public shared(msg) func markPosition(gameId: T.GameId, tablaId: T.TablaId, position: T.Position) : async Result.Result<(), Text> {
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot mark positions");
    };
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #active) {
          return #err("Game is not active");
        };
        
        // Check if position is valid
        if (position.row >= TABLA_SIZE or position.col >= TABLA_SIZE) {
          return #err("Invalid position");
        };
        
        // Check if player owns the tabla
        var ownsTabla = false;
        for ((player, tabla) in game.tablas.vals()) {
          if (Principal.equal(player, caller) and tabla == tablaId) {
            ownsTabla := true;
          };
        };
        
        if (not ownsTabla) {
          return #err("Player does not own this tabla in this game");
        };
        
        // Check if position is already marked
        for (marca in game.marcas.vals()) {
          if (marca.tablaId == tablaId and 
              marca.position.row == position.row and 
              marca.position.col == position.col) {
            return #err("Position already marked");
          };
        };
        
        // Add the mark
        let newMarca: T.Marca = {
          playerId = caller;
          tablaId = tablaId;
          position = position;
          timestamp = Time.now();
        };
        
        let updatedMarcas = Array.append<T.Marca>(game.marcas, [newMarca]);
        
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = game.status;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = game.players;
          tablas = game.tablas;
          drawnCards = game.drawnCards;
          currentCard = game.currentCard;
          marcas = updatedMarcas;
          winner = game.winner;
          prizePool = game.prizePool;
        };
        
        games.put(gameId, updatedGame);
        #ok(())
      };
    }
  };
  
  // Claim a win
  public shared(msg) func claimWin(gameId: T.GameId, tablaId: T.TablaId) : async Result.Result<(), Text> {
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot claim wins");
    };
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #active) {
          return #err("Game is not active");
        };
        
        if (game.winner != null) {
          return #err("Game already has a winner");
        };
        
        // Check if player owns the tabla
        var ownsTabla = false;
        for ((player, tabla) in game.tablas.vals()) {
          if (Principal.equal(player, caller) and tabla == tablaId) {
            ownsTabla := true;
          };
        };
        
        if (not ownsTabla) {
          return #err("Player does not own this tabla in this game");
        };
        
        // Get all marked positions for this tabla by this player
        let playerMarks = Array.filter<T.Marca>(
          game.marcas, 
          func(m) { Principal.equal(m.playerId, caller) and m.tablaId == tablaId }
        );
        
        // Check win condition based on game mode
        var hasWon = false;
        
        switch (game.mode) {
          case (#line) {
            // Check rows
            for (row in Iter.range(0, TABLA_SIZE - 1)) {
              var rowComplete = true;
              for (col in Iter.range(0, TABLA_SIZE - 1)) {

                let obj = Array.find<T.Marca>(
                    playerMarks, 
                    func(m) { m.position.row == row and m.position.col == col }
                );

                switch(obj){
                    case(?found){
                        if (not found.isValid()) { // TODO there is no function to validate on here
                            rowComplete := false;
                        };
                    };
                    case (null){ }
                };
              };
              
              if (rowComplete) {
                hasWon := true;
              };
            };
            
            // Check columns
            if (not hasWon) {
              for (col in Iter.range(0, TABLA_SIZE - 1)) {
                var colComplete = true;
                for (row in Iter.range(0, TABLA_SIZE - 1)) {

                    let obj = Array.find<T.Marca>(
                        playerMarks, 
                        func(m) { m.position.row == row and m.position.col == col }
                    );

                    switch(obj){
                        case(?found){
                            if (not found.isValid()) { // TODO there is no function to validate on here
                                colComplete := false;
                            };
                        };
                        case (null){ }
                    };
                };
                
                if (colComplete) {
                  hasWon := true;
                };
              };
            };
            
            // Check diagonals
            if (not hasWon) {
              // Main diagonal
              var diagComplete = true;
              for (i in Iter.range(0, TABLA_SIZE - 1)) {

                let obj = Array.find<T.Marca>(
                    playerMarks, 
                    func(m) { m.position.row == i and m.position.col == i }
                );

                switch(obj){
                    case(?found){
                        if (not found.isValid()) { // TODO there is no function to validate on here
                            diagComplete := false;
                        };
                    };
                    case (null){ }
                };
              };
              
              if (diagComplete) {
                hasWon := true;
              };
              
              // Other diagonal
              diagComplete := true;
              for (i in Iter.range(0, TABLA_SIZE - 1)) {

                let obj = Array.find<T.Marca>(
                    playerMarks, 
                     func(m) { m.position.row == i and m.position.col == (TABLA_SIZE - 1 - i) }
                );

                switch(obj){
                    case(?found){
                        if (not found.isValid()) { // TODO there is no function to validate on here
                            diagComplete := false;
                        };
                    };
                    case (null){ }
                };
              };
              
              if (diagComplete) {
                hasWon := true;
              };
            };
          };
          
          case (#blackout) {
            // Check if all positions are marked
            var allMarked = true;
            for (row in Iter.range(0, TABLA_SIZE - 1)) {
              for (col in Iter.range(0, TABLA_SIZE - 1)) {

                let obj = Array.find<T.Marca>(
                    playerMarks, 
                    func(m) { m.position.row == row and m.position.col == col }
                );

                switch(obj){
                    case(?found){
                        if (not found.isValid()) { // TODO there is no function to validate on here
                            allMarked := false;
                        };
                    };
                    case (null){ }
                };
              };
            };
            
            hasWon := allMarked;
          };
        };
        
        if (not hasWon) {
          return #err("Win condition not met");
        };
        
        // Update game with the winner
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = #completed;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = game.players;
          tablas = game.tablas;
          drawnCards = game.drawnCards;
          currentCard = game.currentCard;
          marcas = game.marcas;
          winner = ?caller;
          prizePool = game.prizePool;
        };
        
        games.put(gameId, updatedGame);
        #ok(())
      };
    }
  };
  
  // Get drawn cards for a game
  public query func getDrawnCards(gameId: T.GameId) : async Result.Result<[T.CardId], Text> {
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        #ok(game.drawnCards)
      };
    }
  };
  
  // Get current card for a game
  public query func getCurrentCard(gameId: T.GameId) : async Result.Result<?T.CardId, Text> {
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        #ok(game.currentCard)
      };
    }
  };
  
  // End game (host only)
  public shared(msg) func endGame(gameId: T.GameId) : async Result.Result<(), Text> {
    let caller = msg.caller;
    
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (not Principal.equal(caller, game.host)) {
          return #err("Only the host can end the game");
        };
        
        if (game.status != #active) {
          return #err("Game is not active");
        };
        
        let updatedGame = {
          id = game.id;
          name = game.name;
          host = game.host;
          createdAt = game.createdAt;
          status = #completed;
          mode = game.mode;
          tokenType = game.tokenType;
          entryFee = game.entryFee;
          hostFeePercent = game.hostFeePercent;
          players = game.players;
          tablas = game.tablas;
          drawnCards = game.drawnCards;
          currentCard = game.currentCard;
          marcas = game.marcas;
          winner = game.winner;
          prizePool = game.prizePool;
        };
        
        games.put(gameId, updatedGame);
        #ok(())
      };
    }
  };
  
  // System upgrade hooks
  system func preupgrade() {
    gameEntries := Iter.toArray(games.entries());
  };
  
  system func postupgrade() {
    gameEntries := [];
  };

  //Added by JB

  private let eqNat = func(a : Nat, b : Nat) : Bool {
    a == b;
  };

  private let hashNat = func(key : Nat) : Hash.Hash {
    Nat32.fromNat(key % (2 ** 8 - 1));
  };

  private let eqNat32 = func(a : Nat32, b : Nat32) : Bool {
    a == b;
  };

  private let hashNat32 = func(key : Nat32) : Hash.Hash {
    Nat32.fromNat(Nat32.toNat(key) % (2 ** 32 - 1));
  };
}