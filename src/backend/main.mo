import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import PRNG "mo:core/internal/PRNG";
import Text  "mo:core/Text";
import Nat64 "mo:core/Nat64";
import Nat32 "mo:core/Nat32";
import Int "mo:core/Int";
import Time "mo:core/Time";
import Result "mo:core/Result";
import T "types";
import IC "ic:aaaaa-aa";
import Constants "constants";
import Utilities "utilities";
import Ledger "mo:waterway-mops/base/def/icp-ledger";
import Account "mo:waterway-mops/base/def/account";
import Enums "mo:waterway-mops/base/enums";
import Map "mo:core/Map";
import Random "mo:core/Random";
import VarArray "mo:core/VarArray";
import Array "mo:core/Array";
import List "mo:core/List";
import Ids "ids";
import Commands "commands";
import Queries "queries";

persistent actor GameLogic {

  private var games = Map.empty<Text, T.Game>() ;
  private var profiles = Map.empty<Principal, T.Profile>() ;
  private var tags = Map.empty<Text, Principal>() ;

  let letters = Text.toArray("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  let digits  = Text.toArray("0123456789");
  transient let rng = PRNG.sfc64a();
  rng.init(Nat64.fromIntWrap(Time.now()));

  func pick(arr : [Char], bound : Nat64) : Char {
    let idx = Nat64.toNat(Nat64.rem(rng.next(), bound));
    arr[idx];
  };
  func genGameId() : Text {
    var out : [var Char] = [var ' ', ' ', ' ', ' ', ' ', ' '];
    let b26 : Nat64 = 26;
    let b10 : Nat64 = 10;
    var i = 0;
      while (i < 6) {
        if (Nat64.rem(rng.next(), 2) == 0) {
          out[i] := pick(letters, b26);
        } else {
          out[i] := pick(digits, b10);
        };
        i += 1;
      };
      Text.fromVarArray(out)
    };

  func toGameView(g : T.Game) : Queries.GameView = {
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
    maxPlayers = 50;
    drawnCardCount = g.drawnCards.size();
    currentCard = g.currentCard;
    winner = g.winner;
    prizePool = g.prizePool;
  };

  public query({caller}) func getProfile() : async Result.Result<T.Profile, Text> {
    switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, caller)){
      case null {#err("no profile found")};
      case (?profile) {#ok(profile)}
    }
  };
  public shared({caller}) func createProfile(tag : Text) : async Result.Result<(),Text>{
   switch(Map.get<Principal, T.Profile>(profiles, Principal.compare, caller)){
    case null {
      Map.add<Principal, T.Profile>(
        profiles,
        Principal.compare,
        caller,
        {
          principalId = Principal.toText(caller);
          username = tag;
          games = 0;
          wins = 0;
          winRate = 0.00;
        }
      );
      Map.add<Text,Principal>(tags, Text.compare, tag, caller);
      #ok();
    };
      case _existing {#err("Profile Already exists")};
    }
  };

  public shared ({ caller }) func updateTag(newTag : Text) : async Result.Result<(), Text> {
  switch (Map.get<Principal, T.Profile>(profiles, Principal.compare, caller)) {
    case null { return #err("no profile found") };
    case (?prof) {
      let old = prof.username;
      switch (Map.get<Text, Principal>(tags, Text.compare, newTag)) {
        case (?owner) { if (owner != caller) return #err("username taken") };
        case null {};
      };
      if (old == newTag) return #ok(());
      ignore Map.take<Text, Principal>(tags, Text.compare, old);
      Map.add<Text, Principal>(tags, Text.compare, newTag, caller);
      Map.add<Principal, T.Profile>(profiles, Principal.compare, caller, { prof with username = newTag });
      return #ok(());
    }
  }
};

  /* ----- Game Queries ----- */

  public query func getOpenGames(dto : Queries.GetOpenGames): async Result.Result<Queries.OpenGames, Text> {
  let start = dto.page * Constants.PAGE_COUNT;

  var matched : Nat = 0;
  let out = List.empty<Queries.GameView>();

  label scan for (g in Map.values(games)) {
    if (g.status == #lobby) {
      if (matched >= start and List.size(out) < Constants.PAGE_COUNT) {
        List.add<Queries.GameView>(out, toGameView(g));
        if (List.size(out) == Constants.PAGE_COUNT) break scan;
      };
      matched += 1;
    };
  };
    #ok({ page = dto.page; openGames = List.toArray(out) })
  };

  public query func getActiveGames(dto: Queries.GetActiveGames) : async Result.Result<Queries.ActiveGames, Enums.Error> {
   let start = dto.page * Constants.PAGE_COUNT;

  var matched : Nat = 0;
  let out = List.empty<Queries.GameView>();

  label scan for (g in Map.values(games)) {
    if (g.status == #active) {
      if (matched >= start and List.size(out) < Constants.PAGE_COUNT) {
        List.add<Queries.GameView>(out, toGameView(g));
        if (List.size(out) == Constants.PAGE_COUNT) break scan;
      };
      matched += 1;
    };
  };

  #ok({ page = dto.page; activeGames = List.toArray(out) })
  };

  public query func getGame(dto: Queries.GetGame) : async Result.Result<?Queries.GameView, Text> {
    switch (Map.get<Text, T.Game>(games, Text.compare, dto.gameId)){
      case null {#err("No Game found")};
      case (?g) {#ok(?toGameView(g))};
    }
  };
  
  public query func getDrawHistory(dto: Queries.GetDrawHistory) : async Result.Result<[Ids.CardId], Text> {
    switch(Map.get<Text,T.Game>(games, Text.compare, dto.gameId)){
      case null {#err("No Game found")};
      case (?g) {#ok(g.drawnCards)};
    }
  };


  public shared({caller}) func createGame(params: Commands.CreateGame) : async Result.Result<Text, Text> {

    let nextGameId = genGameId();

    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot create games");
    };

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

    Map.add<Text,T.Game>(games, Text.compare, nextGameId, newGame);
    #ok(newGame.id)
  };

  public shared({caller}) func joinGame(dto: Commands.JoinGame) : async Result.Result<(), Text> {

    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot join games");
    };
    
    switch (Map.get<Text,T.Game>(games, Text.compare, dto.gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #lobby) {
          return #err("Game is not in lobby state");
        };
        
        if (game.players.size() >= Constants.MAX_PLAYERS_PER_GAME) {
          return #err("Game is full");
        };
        for (player in game.players.vals()) {
          if (Principal.equal(player, caller)) {
            return #err("Player already in game");
          };
        };


        if (game.tokenType == #ICP) {
          let ledger : Ledger.Interface = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");

          let paymentResult = await ledger.transfer({
            from_subaccount = ?Account.principalToSubaccount(caller);
            to = Principal.toBlob(Principal.fromActor(GameLogic));
            amount = { e8s = Nat64.fromNat(game.entryFee * 100_000_000) };
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
        let playerlist = List.fromArray<Ids.PlayerId>(game.players);
        List.add<Ids.PlayerId>(playerlist, caller);
        let updatedPlayers = List.toArray(playerlist);
        switch (addTablaToGame(caller, dto.gameId, dto.rentedTablaId)){
          case (#ok(r)) {r};
          case (#err(e)) {return #err(e)};
        };
        ignore Map.replace<Text,T.Game>(games, Text.compare, dto.gameId, {game with players = updatedPlayers; prizePool = game.prizePool + game.entryFee; });
        #ok(())
      };
    }
  };
  
  func addTablaToGame(caller:Principal, gameId: Text, tablaId: Ids.TablaId) : Result.Result<(), Text> {
    
    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        // Check if player is in the game
        var playerFound = false;
        for (player in game.players.vals()) {
          if (player == caller) {
            playerFound := true;
          };
        };
        if (not playerFound) {
          return #err("Player not in game");
        };
        for ((player, tabla) in game.tablas.vals()) {
          if (tabla == tablaId) {
            return #err("Tabla already in use in this game");
          };
        };

        var playerTablaCount = 0;
        for ((player, _) in game.tablas.vals()) {
          if (player == caller) {
            playerTablaCount += 1;
          };
        };
        
        if (playerTablaCount >= Constants.MAX_TABLAS_PER_PLAYER) {
          return #err("Player already has maximum number of tablas");
        };
        
        let tablalist = List.fromArray<(Ids.PlayerId, Ids.TablaId)>(game.tablas);
            List.add<(Ids.PlayerId, Ids.TablaId)>(tablalist, (caller,tablaId));
            let updatedTablas = List.toArray(tablalist);
            ignore Map.replace<Text,T.Game>(games, Text.compare, gameId, {game with tablas = updatedTablas});
        #ok(())
      };
    }
  };
  
  public shared({caller}) func startGame(gameId: Text) : async Result.Result<(), Text> {
    
    switch (Map.get<Text, T.Game>(games,Text.compare, gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (caller != game.host) {
          return #err("Only the host can start the game");
        };
        
        if (game.status != #lobby) {
          return #err("Game is not in lobby state");
        };
        
        if (game.players.size() < 2) {
          return #err("Need at least 2 players to start");
        };
        ignore Map.replace<Text, T.Game>(games, Text.compare, gameId, {game with status = #active });
        #ok(())
      };
    }
  };
  transient let crypto = Random.crypto();
  let drawLocks = Map.empty<Text, Bool>();
  func lock(id : Text) : Bool {
    switch (Map.get<Text, Bool>(drawLocks, Text.compare, id)) {
      case (?_) { false };
      case null { Map.add<Text, Bool>(drawLocks, Text.compare, id, true); true };
    }
  };
  func unlock(id : Text) { ignore Map.take<Text, Bool>(drawLocks, Text.compare, id) };

  public shared ({ caller }) func drawCard(gameId : Text)
  : async Result.Result<Ids.CardId, Text>
{
  if (not lock(gameId)) return #err("draw in progress");

  switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
    case (null) { unlock(gameId); return #err("Game not found") };
    case (?game) {
      if (caller != game.host)     { unlock(gameId); return #err("Only the host can draw cards") };
      if (game.status != #active)  { unlock(gameId); return #err("Game is not active") };
      if (game.drawnCards.size() >= Constants.TOTAL_CARDS) { unlock(gameId); return #err("All cards have been drawn") };

      // bitmap of drawn cards (1..54) using VarArray.repeat + index assignment
      let taken = VarArray.repeat<Bool>(false, Constants.TOTAL_CARDS + 1);
      for (c in Array.values<Ids.CardId>(game.drawnCards)) {
        let i = Nat32.toNat(c);
        if (i <= Constants.TOTAL_CARDS) { taken[i] := true };
      };

      let remaining = Constants.TOTAL_CARDS - game.drawnCards.size();
      let k : Nat = await* crypto.natRange(0, remaining);  // index inside undrawn set

      // locate k-th undrawn card
      var seen : Nat = 0;
      var chosen : Nat = 0;
      var v : Nat = 1;
      label find while (v <= Constants.TOTAL_CARDS) {
        if (not taken[v]) {
          if (seen == k) { chosen := v; break find };
          seen += 1;
        };
        v += 1;
      };
      if (chosen == 0) { unlock(gameId); return #err("Internal error") };

      let cardId : Ids.CardId = Nat32.fromNat(chosen);

      // append to drawnCards via core/List
      var drawnL = List.fromArray<Ids.CardId>(game.drawnCards);
      List.add<Ids.CardId>(drawnL, cardId);
      let updatedDrawn = List.toArray<Ids.CardId>(drawnL);

      Map.add<Text, T.Game>(
        games, Text.compare, gameId,
        { game with drawnCards = updatedDrawn; currentCard = ?cardId }
      );

      unlock(gameId);
      #ok(cardId)
    }
  }
};
  
  public shared({caller}) func markPosition(gameId: Text, tablaId: Ids.TablaId, position: T.Position) : async Result.Result<(), Text> {
    
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous identity cannot mark positions");
    };
    
    switch (Map.get<Text, T.Game>(games, Text.compare, gameId)) {
      case (null) { #err("Game not found") };
      case (?game) {
        if (game.status != #active) {
          return #err("Game is not active");
        };
        
        // Check if position is valid
        if (position.row >= Constants.TABLA_SIZE or position.col >= Constants.TABLA_SIZE) {
          return #err("Invalid position");
        };
        
        // Check if player owns the tabla
        var ownsTabla = false;
        for ((player, tabla) in game.tablas.vals()) {
          if (player == caller and tabla == tablaId) {
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
        let currentMarcas = List.fromArray<T.Marca>(game.marcas);
        List.add<T.Marca>(currentMarcas, {
          playerId = caller;
          tablaId = tablaId;
          position = position;
          timestamp = Time.now();
        });
        ignore Map.replace<Text,T.Game>(games, Text.compare, gameId, {game with marcas= List.toArray(currentMarcas)});
        #ok(())
      };
    }
  };
  
  public shared(msg) func claimWin(gameId: Text, tablaId: Ids.TablaId) : async Result.Result<(), Enums.Error> {
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
    */
  };
  
  public shared(msg) func endGame(gameId: Text) : async Result.Result<(), Enums.Error> {
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
        
        let updatedTabla : T.Tabla = {
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

  public query func getAvailableTablas() : async Result.Result<[T.TablaInfo], Enums.Error> {
    return #err(#NotFound);
    /*
    let availableTablas = Buffer.Buffer<T.TablaInfo>(10);
    
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
  
  public query func getTabla(tablaId: Ids.TablaId) : async Result.Result<?T.TablaInfo, Enums.Error> {
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

  /* Isn't this done through starting a game?
  // Rent a tabla
  public shared(msg) func rentTabla(tablaId: Ids.TablaId, gameId: ?Text) : async Result.Result<(), Enums.Error> {
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
        let rentalRecord : T.RentalRecord = {
          renter = caller;
          gameId = gameId;
          startTime = Time.now();
          endTime = null; // Will be set when returned
          fee = tabla.rentalFee;
          tokenType = tabla.tokenType;
        };
        
        // Update the tabla
        let updatedRentalHistory = Array.append<T.RentalRecord>(tabla.rentalHistory, [rentalRecord]);
        
        let updatedTabla : T.Tabla = {
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
            let updatedRentalHistory = Array.map<T.RentalRecord, T.RentalRecord>(
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
            let updatedTabla : T.Tabla = {
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
        
        let updatedTabla : T.Tabla = {
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
  private stable var nextGameId: T.GameId = 1;
  */

  /* //Removed to be replaced with single arrays as id in game type

  private stable var tablaEntries: [(Ids.TablaId, T.Tabla)] = [];
  private stable var gameEntries: [(Text, T.Game)] = [];
  
  */

  /* Removed as should just be a constant
    // Cards for each tabla (4x4 grid)
    private stable var tablaCards : [[(Nat, Nat, Nat, Nat)]] = [];
  */
  

  /*

  Can be done in an easier way

  private var tablas = HashMap.fromIter<Ids.TablaId, T.Tabla>(
    tablaEntries.vals(), 
    10, 
    Utilities.eqNat32, 
    Utilities.hashNat32
  );

  private var games = HashMap.fromIter<Text, T.Game>(
    gameEntries.vals(), 
    10, 
    Utilities.eqNat32, 
    Utilities.hashNat32
  );
  */


  // Get drawn cards for a game
  
  /* If you have the draw history you won't need this
  // Get current card for a game
  public query func getCurrentCard(gameId: Text) : async Result.Result<?Ids.CardId, Enums.Error> {
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
      let rarity : T.Rarity = if (i % 100 == 0) {
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
      let metadata : T.TablaMetadata = {
        name = "Tabla #" # Nat.toText(Nat32.toNat(nextTablaId));
        description = "A crypto-themed lotería tabla with unique card combinations";
        image = "https://example.com/tablas/" # Nat.toText(Nat32.toNat(nextTablaId)) # ".png"; // Placeholder
        cards = cards;
      };
      
      // Create the tabla
      let newTabla : T.Tabla = {
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
  public query func getRentedTablasByUser(renter: Principal) : async [T.TablaInfo] {
    let rentedTablas = Buffer.Buffer<T.TablaInfo>(10);
    
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
  public query func getOwnedTablasByUser(owner: Principal) : async [T.TablaInfo] {
    let ownedTablas = Buffer.Buffer<T.TablaInfo>(10);
    
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
}