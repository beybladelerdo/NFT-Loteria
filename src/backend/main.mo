import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Random "mo:base/Random";
import Nat64 "mo:base/Nat64";
import Types "./types";
import Constants "constants";
import Utilities "utilities";
import Ledger "mo:waterway-mops/base/def/icp-ledger";
import Account "mo:waterway-mops/base/def/account";
import Enums "mo:waterway-mops/base/enums";
import Ids "ids";
import Commands "commands";
import Queries "queries";

actor GameLogic {
  
  private stable var games: [Types.Game] = [];
  

  /* ----- Game Queries ----- */

  public query func getOpenGames(dto: Queries.GetOpenGames) : async Result.Result<Queries.OpenGames, Enums.Error> {
    return #err(#NotFound);
    /*
    let openGames = Array.filter<Types.Game>(games, func(game: Types.Game) {
      game.status == #lobby
    });

    let paginatedOpenGames = Array.map<Types.GameInfo, Queries.OpenGame>(openGames, func(game: Types.GameInfo){
      return {

      };
    });

    return {
      page: dto.page;
      openGames: paginatedOpenGames;
    }
    */
  };
  
  public query func getActiveGames(dto: Queries.GetActiveGames) : async Result.Result<Queries.ActiveGames, Enums.Error> {
    return #err(#NotFound);
    /*
    let activeGames = Buffer.Buffer<Types.GameInfo>(10);
    
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
    */
  };

  public query func getGame(dto: Queries.GetGame) : async Result.Result<?Queries.Game, Enums.Error> {
    return #err(#NotFound);
    /*
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
    */
  };
  
  public query func getDrawHistory(dto: Queries.GetDrawHistory) : async Result.Result<[Ids.CardId], Enums.Error> {
    return #err(#NotFound);
    /*
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        #ok(game.drawnCards)
      };
    }
    */
  };


  /* ----- Game Commands ----- */

  public shared(msg) func createGame(params: Commands.CreateGame) : async Result.Result<Ids.GameId, Enums.Error> {
    return #err(#NotFound);
    /*
    let nextGameId = getNextGameId();
    
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
    
    let newGame: Types.Game = {
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

    let gamesBuffer = Buffer.fromArray<Types.Game>(games);
    gamesBuffer.add(newGame);
    games := Buffer.toArray(gamesBuffer);
    
    #ok(newGame.id)
    */
  };
  
  public shared(msg) func joinGame(dto: Commands.JoinGame) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot join games");
    };
    
    switch (games.get(dto.gameId)) {
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
        
        // Verify payment (entry fee in ICP)
        if (game.tokenType == #ICP) {
          let ledger : Ledger.Interface = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");

          let paymentResult = await ledger.transfer({
            from_subaccount = ?Account.principalToSubaccount(caller);
            to = Principal.toBlob(Principal.fromActor(GameLogic)); // Canister principal
            amount = { e8s = Nat64.fromNat(game.entryFee * 100_000_000) }; // Convert to e8s (1 ICP = 10^8 e8s)
            fee = { e8s = 10_000 }; // Standard transaction fee
            memo = 0;
            created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())) };
          });
          
          switch (paymentResult) {
            case (#Err(e)) { return #err("Payment failed: " # debug_show(e)) };
            case (#Ok(_)) {  };
          };
        };
        
        // Add player to the game
        let updatedPlayers = Array.append<Ids.PlayerId>(game.players, [caller]);
        
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
    */
  };
  
  public shared(msg) func addTablaToGame(gameId: Ids.GameId, tablaId: Ids.TablaId) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
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
        let updatedTablas = Array.append<(Ids.PlayerId, Ids.TablaId)>(game.tablas, [(caller, tablaId)]);
        
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
    */
  };
  
  public shared(msg) func startGame(gameId: Ids.GameId) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
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
    */
  };
  
  public shared(msg) func drawCard(gameId: Ids.GameId) : async Result.Result<Ids.CardId, Enums.Error> {
    return #err(#NotFound);
    /*
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
        
        // Generate a random card ID
        let seed : Blob = "\14\C9\72\09\03\D4\D5\72\82\95\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3\6E\C7\B0\87\DC\76\08\69\14\CF";
        let random = Random.Finite(seed);
        var cardId : Ids.CardId = 0;
        var attempts = 0;
        
        while (attempts < TOTAL_CARDS) {
          let randNat = random.range(32); // Generate a random 32-bit number
          switch(randNat){
            case (?foundNat){
              cardId := Nat32.fromNat(foundNat % TOTAL_CARDS) + 1;
            };
            case (null){}
          };
          
          // Check if card is undrawn
          if (Array.find<Ids.CardId>(game.drawnCards, func(c) { c == cardId }) == null) {
            // Found an undrawn card
            let updatedDrawnCards = Array.append<Ids.CardId>(game.drawnCards, [cardId]);
            
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
            return #ok(cardId);
          };
          
          attempts += 1;
        };
        
        #err("Could not find an undrawn card")
      };
    }
    */
  };
  
  public shared(msg) func markPosition(gameId: Ids.GameId, tablaId: Ids.TablaId, position: Types.Position) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
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
        let newMarca: Types.Marca = {
          playerId = caller;
          tablaId = tablaId;
          position = position;
          timestamp = Time.now();
        };
        
        let updatedMarcas = Array.append<Types.Marca>(game.marcas, [newMarca]);
        
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
    */
  };
  
  public shared(msg) func claimWin(gameId: Ids.GameId, tablaId: Ids.TablaId) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
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
        let playerMarks = Array.filter<Types.Marca>(
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

                let obj = Array.find<Types.Marca>(
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

                    let obj = Array.find<Types.Marca>(
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

                let obj = Array.find<Types.Marca>(
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

                let obj = Array.find<Types.Marca>(
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

                let obj = Array.find<Types.Marca>(
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
    */
  };
  
  public shared(msg) func endGame(gameId: Ids.GameId) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
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
    */
  };


  /* ----- Tabla Commands ----- */

  public shared(msg) func updateRentalFee(dto: Commands.UpdateTablaRentalFee) : async Result.Result<(), Enums.Error> {
    return #err(#NotFound);
    /*
    let caller = msg.caller;
    
    switch (tablas.get(tablaId)) {
      case (null) { #err("Tabla not found") };
      case (?tabla) {
        if (not Principal.equal(caller, tabla.owner)) {
          return #err("Only the owner can update rental fee");
        };
        
        if (tabla.status != #available) {
          return #err("Cannot update fee while tabla is rented");
        };
        
        let updatedTabla : Types.Tabla = {
          id = tabla.id;
          owner = tabla.owner;
          renter = tabla.renter;
          gameId = tabla.gameId;
          rentalFee = newFee;
          tokenType = tabla.tokenType;
          rarity = tabla.rarity;
          metadata = tabla.metadata;
          rentalHistory = tabla.rentalHistory;
          status = tabla.status;
          createdAt = tabla.createdAt;
          updatedAt = Time.now();
        };
        
        tablas.put(tablaId, updatedTabla);
        #ok(())
      };
    }
    */
  };
  

  /* ----- Tabla Queries ----- */

  public query func getAvailableTablas() : async Result.Result<[Types.TablaInfo], Enums.Error> {
    return #err(#NotFound);
    /*
    let availableTablas = Buffer.Buffer<Types.TablaInfo>(10);
    
    for ((id, tabla) in tablas.entries()) {
      if (tabla.status == #available) {
        availableTablas.add({
          id = tabla.id;
          owner = tabla.owner;
          renter = tabla.renter;
          gameId = tabla.gameId;
          rentalFee = tabla.rentalFee;
          tokenType = tabla.tokenType;
          rarity = tabla.rarity;
          name = tabla.metadata.name;
          image = tabla.metadata.image;
          status = tabla.status;
          isAvailable = true;
        });
      };
    };
    
    Buffer.toArray(availableTablas)
    */
  };
  
  public query func getTabla(tablaId: Ids.TablaId) : async Result.Result<?Types.TablaInfo, Enums.Error> {
    return #err(#NotFound);
    /*
    
    switch (tablas.get(tablaId)) {
      case (null) { null };
      case (?tabla) {
        ?{
          id = tabla.id;
          owner = tabla.owner;
          renter = tabla.renter;
          gameId = tabla.gameId;
          rentalFee = tabla.rentalFee;
          tokenType = tabla.tokenType;
          rarity = tabla.rarity;
          name = tabla.metadata.name;
          image = tabla.metadata.image;
          status = tabla.status;
          isAvailable = tabla.status == #available;
        }
      };
    }
    */
  };
  
  public query func getTablaCards(tablaId: Ids.TablaId) : async Result.Result<[Nat], Enums.Error> {
    return #err(#NotFound);
    /*
    switch (tablas.get(tablaId)) {
      case (null) { #err("Tabla not found") };
      case (?tabla) {
        #ok(tabla.metadata.cards)
      };
    }
    */
  };


  /* ----- Private Functions ----- */

  private func getNextGameId() : Ids.GameId {
    return 0; // TODO
  };

  private func getNextTablaId() : Ids.GameId {
    return 0; // TODO
  }
}



  /* Isn't this done through starting a game?
  // Rent a tabla
  public shared(msg) func rentTabla(tablaId: Ids.TablaId, gameId: ?Ids.GameId) : async Result.Result<(), Enums.Error> {
    let caller = msg.caller;
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot rent tablas");
    };
    
    switch (tablas.get(tablaId)) {
      case (null) { #err("Tabla not found") };
      case (?tabla) {
        if (tabla.status != #available) {
          return #err("Tabla is not available for rent");
        };
        
        // In a real implementation, we would check payment here
        // and transfer fees to the owner and platform
        
        // Create rental record
        let rentalRecord : Types.RentalRecord = {
          renter = caller;
          gameId = gameId;
          startTime = Time.now();
          endTime = null; // Will be set when returned
          fee = tabla.rentalFee;
          tokenType = tabla.tokenType;
        };
        
        // Update the tabla
        let updatedRentalHistory = Array.append<Types.RentalRecord>(tabla.rentalHistory, [rentalRecord]);
        
        let updatedTabla : Types.Tabla = {
          id = tabla.id;
          owner = tabla.owner;
          renter = ?caller;
          gameId = gameId;
          rentalFee = tabla.rentalFee;
          tokenType = tabla.tokenType;
          rarity = tabla.rarity;
          metadata = tabla.metadata;
          rentalHistory = updatedRentalHistory;
          status = #rented;
          createdAt = tabla.createdAt;
          updatedAt = Time.now();
        };
        
        tablas.put(tablaId, updatedTabla);
        #ok(())
      };
    }
  };
  
  //Isn't this just get tabla?
  // Return a rented tabla
  public shared(msg) func returnTabla(tablaId: Ids.TablaId) : async Result.Result<(), Enums.Error> {
    let caller = msg.caller;
    
    switch (tablas.get(tablaId)) {
      case (null) { #err("Tabla not found") };
      case (?tabla) {
        if (tabla.status != #rented) {
          return #err("Tabla is not currently rented");
        };
        
        switch (tabla.renter) {
          case (null) { #err("Tabla has no renter") };
          case (?renter) {
            if (not Principal.equal(caller, renter) and not Principal.equal(caller, tabla.owner)) {
              return #err("Only the renter or owner can return a tabla");
            };
            
            // Update the last rental record with an end time
            let updatedRentalHistory = Array.map<Types.RentalRecord, Types.RentalRecord>(
              tabla.rentalHistory,
              func (record) {
                if (record.endTime == null and Principal.equal(record.renter, renter)) {
                  {
                    renter = record.renter;
                    gameId = record.gameId;
                    startTime = record.startTime;
                    endTime = ?Time.now();
                    fee = record.fee;
                    tokenType = record.tokenType;
                  }
                } else {
                  record
                }
              }
            );
            
            // Update the tabla
            let updatedTabla : Types.Tabla = {
              id = tabla.id;
              owner = tabla.owner;
              renter = null;
              gameId = null;
              rentalFee = tabla.rentalFee;
              tokenType = tabla.tokenType;
              rarity = tabla.rarity;
              metadata = tabla.metadata;
              rentalHistory = updatedRentalHistory;
              status = #available;
              createdAt = tabla.createdAt;
              updatedAt = Time.now();
            };
            
            tablas.put(tablaId, updatedTabla);
            #ok(())
          };
        }
      };
    }
  };
  */


  // Update rental fee (owner only)
  
  /* Is this not done by buying and selling the NFT?
  // Transfer ownership (owner only)
  public shared(msg) func transferOwnership(tablaId: Ids.TablaId, newOwner: Principal) : async Result.Result<(), Enums.Error> {
    let caller = msg.caller;
    
    switch (tablas.get(tablaId)) {
      case (null) { #err("Tabla not found") };
      case (?tabla) {
        if (not Principal.equal(caller, tabla.owner)) {
          return #err("Only the owner can transfer ownership");
        };
        
        if (tabla.status == #rented) {
          return #err("Cannot transfer ownership while tabla is rented");
        };
        
        let updatedTabla : Types.Tabla = {
          id = tabla.id;
          owner = newOwner;
          renter = tabla.renter;
          gameId = tabla.gameId;
          rentalFee = tabla.rentalFee;
          tokenType = tabla.tokenType;
          rarity = tabla.rarity;
          metadata = tabla.metadata;
          rentalHistory = tabla.rentalHistory;
          status = tabla.status;
          createdAt = tabla.createdAt;
          updatedAt = Time.now();
        };
        
        tablas.put(tablaId, updatedTabla);
        #ok(())
      };
    }
  };
  */







  // State variables
  
  /* //Removed to be replaced with function to get the next tabla id

  private stable var nextTablaId: Ids.TablaId = 1;
  private stable var nextGameId: Types.GameId = 1;
  */

  /* //Removed to be replaced with single arrays as id in game type

  private stable var tablaEntries: [(Ids.TablaId, Types.Tabla)] = [];
  private stable var gameEntries: [(Ids.GameId, Types.Game)] = [];
  
  */

  /* Removed as should just be a constant
    // Cards for each tabla (4x4 grid)
    private stable var tablaCards : [[(Nat, Nat, Nat, Nat)]] = [];
  */
  

  /*

  Can be done in an easier way

  private var tablas = HashMap.fromIter<Ids.TablaId, Types.Tabla>(
    tablaEntries.vals(), 
    10, 
    Utilities.eqNat32, 
    Utilities.hashNat32
  );

  private var games = HashMap.fromIter<Ids.GameId, Types.Game>(
    gameEntries.vals(), 
    10, 
    Utilities.eqNat32, 
    Utilities.hashNat32
  );
  */


  // Get drawn cards for a game
  
  /* If you have the draw history you won't need this
  // Get current card for a game
  public query func getCurrentCard(gameId: Ids.GameId) : async Result.Result<?Ids.CardId, Enums.Error> {
    switch (games.get(gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        #ok(game.currentCard)
      };
    }
  };
  */


  /* I believe this should just be a constants file?
  
  // Initialize the canister with tablas
  public shared(msg) func initialize() : async Result.Result<(), Enums.Error> {
    let nextTablaId = getNextTablaId();

    if (tablas.size() > 0) {
      return #err("Already initialized");
    };
    
    if (not Principal.isController(msg.caller)) {
      return #err("Only controllers can initialize");
    };
    
    // Create sample tabla cards (4x4 grids with IDs from 1-54)
    let numTablas = 100; // Create 100 tablas
    let admin = msg.caller;
    
    for (i in Iter.range(0, numTablas - 1)) {
      // Generate pseudo-random cards for this tabla
      // In a real implementation, this would use a proper random generator
      let seed = i * 13 + 7;
      let cardBuffer = Buffer.Buffer<Nat>(16);
      
      // Generate 16 unique card IDs (for a 4x4 grid)
      var counter = 0;
      while (cardBuffer.size() < 16) {
        let cardId = (((seed + counter) * 31) % Constants.MAX_CARDS) + 1;
        
        // Check if card already exists in the buffer
        var exists = false;
        for (existing in cardBuffer.vals()) {
          if (existing == cardId) {
            exists := true;
          };
        };
        
        if (not exists) {
          cardBuffer.add(cardId);
        };
        
        counter += 1;
      };
      
      let cards = Buffer.toArray(cardBuffer);
      
      // Determine rarity based on tabla ID
      let rarity : Types.Rarity = if (i % 100 == 0) {
        #legendary
      } else if (i % 25 == 0) {
        #epic
      } else if (i % 10 == 0) {
        #rare
      } else if (i % 5 == 0) {
        #uncommon 
      } else {
        #common
      };
      
      // Set rental fee based on rarity
      let rentalFee = switch (rarity) {
        case (#common) { 10 }; // 0.1 ICP
        case (#uncommon) { 20 };
        case (#rare) { 50 };
        case (#epic) { 100 };
        case (#legendary) { 200 };
      };
      
      // Create the tabla metadata
      let metadata : Types.TablaMetadata = {
        name = "Tabla #" # Nat.toText(Nat32.toNat(nextTablaId));
        description = "A crypto-themed lotería tabla with unique card combinations";
        image = "https://example.com/tablas/" # Nat.toText(Nat32.toNat(nextTablaId)) # ".png"; // Placeholder
        cards = cards;
      };
      
      // Create the tabla
      let newTabla : Types.Tabla = {
        id = nextTablaId;
        owner = admin; // Initially owned by admin
        renter = null;
        gameId = null;
        rentalFee = rentalFee;
        tokenType = #ICP;
        rarity = rarity;
        metadata = metadata;
        rentalHistory = [];
        status = #available;
        createdAt = Time.now();
        updatedAt = Time.now();
      };
      
      tablas.put(nextTablaId, newTabla);
    };
    
    #ok(())
  };
  */




  /* Not sure why this is needed
  // Get tablas rented by a user
  public query func getRentedTablasByUser(renter: Principal) : async [Types.TablaInfo] {
    let rentedTablas = Buffer.Buffer<Types.TablaInfo>(10);
    
    for ((id, tabla) in tablas.entries()) {
      switch (tabla.renter) {
        case (null) { };
        case (?currentRenter) {
          if (Principal.equal(currentRenter, renter)) {
            rentedTablas.add({
              id = tabla.id;
              owner = tabla.owner;
              renter = tabla.renter;
              gameId = tabla.gameId;
              rentalFee = tabla.rentalFee;
              tokenType = tabla.tokenType;
              rarity = tabla.rarity;
              name = tabla.metadata.name;
              image = tabla.metadata.image;
              status = tabla.status;
              isAvailable = false;
            });
          };
        };
      };
    };
    
    Buffer.toArray(rentedTablas)
  };
  */
  
  /* Not sure this is needed just yet, also the caller can't get owned tablas without mapping from internet identity to nft or logging in with the wallet holding the nft
  // Get tablas owned by a user
  public query func getOwnedTablasByUser(owner: Principal) : async [Types.TablaInfo] {
    let ownedTablas = Buffer.Buffer<Types.TablaInfo>(10);
    
    for ((id, tabla) in tablas.entries()) {
      if (Principal.equal(tabla.owner, owner)) {
        ownedTablas.add({
          id = tabla.id;
          owner = tabla.owner;
          renter = tabla.renter;
          gameId = tabla.gameId;
          rentalFee = tabla.rentalFee;
          tokenType = tabla.tokenType;
          rarity = tabla.rarity;
          name = tabla.metadata.name;
          image = tabla.metadata.image;
          status = tabla.status;
          isAvailable = tabla.status == #available;
        });
      };
    };
    
    Buffer.toArray(ownedTablas)
  };
  */