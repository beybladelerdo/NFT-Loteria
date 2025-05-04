import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
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
import Trie "mo:base/Trie";

actor TablaRental {
  // Types
  type TablaId = Nat;
  type OwnerId = Principal;
  type RenterId = Principal;
  type GameId = Nat;
  
  // Rarity types
  type Rarity = {
    #common;
    #uncommon;
    #rare;
    #epic;
    #legendary;
  };
  
  // Token type
  type TokenType = {
    #ICP;
    #ckBTC;
  };
  
  // Rental status
  type RentalStatus = {
    #available;
    #rented;
    #burned;
  };
  
  // Tabla NFT
  type Tabla = {
    id: TablaId;
    owner: OwnerId;
    renter: ?RenterId;
    gameId: ?GameId;
    rentalFee: Nat;
    tokenType: TokenType;
    rarity: Rarity;
    metadata: TablaMetadata;
    rentalHistory: [RentalRecord];
    status: RentalStatus;
    createdAt: Int;
    updatedAt: Int;
  };
  
  // Tabla metadata
  type TablaMetadata = {
    name: Text;
    description: Text;
    image: Text; // URL or IPFS hash
    cards: [Nat]; // The IDs of cards on this tabla in row-major order
  };
  
  // Rental record
  type RentalRecord = {
    renter: RenterId;
    gameId: ?GameId;
    startTime: Int;
    endTime: ?Int;
    fee: Nat;
    tokenType: TokenType;
  };
  
  // Tabla info (public view)
  type TablaInfo = {
    id: TablaId;
    owner: OwnerId;
    renter: ?RenterId;
    gameId: ?GameId;
    rentalFee: Nat;
    tokenType: TokenType;
    rarity: Rarity;
    name: Text;
    image: Text;
    status: RentalStatus;
    isAvailable: Bool;
  };
  
  // State variables
  private stable var nextTablaId: TablaId = 1;
  private stable var tablaEntries: [(TablaId, Tabla)] = [];
  private var tablas = HashMap.fromIter<TablaId, Tabla>(
    tablaEntries.vals(), 
    10, 
    Nat.equal, 
    Hash.hash
  );
  
  // Cards for each tabla (4x4 grid)
  private stable var tablaCards : [[(Nat, Nat, Nat, Nat)]] = [];
  
  // Constants
  let OWNER_FEE_PERCENT = 80; // 80% of rental fees go to tabla owner
  let PLATFORM_FEE_PERCENT = 20; // 20% of rental fees go to platform
  let MAX_CARDS = 54; // Total number of cards
  let TABLA_SIZE = 4; // 4x4 tabla
  
  // Initialize the canister with tablas
  public shared(msg) func initialize() : async Result.Result<(), Text> {
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
        let cardId = (((seed + counter) * 31) % MAX_CARDS) + 1;
        
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
      let rarity : Rarity = if (i % 100 == 0) {
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
      let metadata : TablaMetadata = {
        name = "Tabla #" # Nat.toText(nextTablaId);
        description = "A crypto-themed lotería tabla with unique card combinations";
        image = "https://example.com/tablas/" # Nat.toText(nextTablaId) # ".png"; // Placeholder
        cards = cards;
      };
      
      // Create the tabla
      let newTabla : Tabla = {
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
      nextTablaId += 1;
    };
    
    #ok(())
  };
  
  // Get all available tablas
  public query func getAvailableTablas() : async [TablaInfo] {
    let availableTablas = Buffer.Buffer<TablaInfo>(10);
    
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
  };
  
  // Get a specific tabla
  public query func getTabla(tablaId: TablaId) : async ?TablaInfo {
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
  };
  
  // Rent a tabla
  public shared(msg) func rentTabla(tablaId: TablaId, gameId: ?GameId) : async Result.Result<(), Text> {
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
        let rentalRecord : RentalRecord = {
          renter = caller;
          gameId = gameId;
          startTime = Time.now();
          endTime = null; // Will be set when returned
          fee = tabla.rentalFee;
          tokenType = tabla.tokenType;
        };
        
        // Update the tabla
        let updatedRentalHistory = Array.append<RentalRecord>(tabla.rentalHistory, [rentalRecord]);
        
        let updatedTabla : Tabla = {
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
  
  // Return a rented tabla
  public shared(msg) func returnTabla(tablaId: TablaId) : async Result.Result<(), Text> {
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
            let updatedRentalHistory = Array.map<RentalRecord, RentalRecord>(
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
            let updatedTabla : Tabla = {
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
  
  // Get tablas rented by a user
  public query func getRentedTablasByUser(renter: Principal) : async [TablaInfo] {
    let rentedTablas = Buffer.Buffer<TablaInfo>(10);
    
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
  
  // Get tablas owned by a user
  public query func getOwnedTablasByUser(owner: Principal) : async [TablaInfo] {
    let ownedTablas = Buffer.Buffer<TablaInfo>(10);
    
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
  
  // Get the cards on a tabla
  public query func getTablaCards(tablaId: TablaId) : async Result.Result<[Nat], Text> {
    switch (tablas.get(tablaId)) {
      case (null) { #err("Tabla not found") };
      case (?tabla) {
        #ok(tabla.metadata.cards)
      };
    }
  };
  
  // Update rental fee (owner only)
  public shared(msg) func updateRentalFee(tablaId: TablaId, newFee: Nat) : async Result.Result<(), Text> {
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
        
        let updatedTabla : Tabla = {
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
  };
  
  // Transfer ownership (owner only)
  public shared(msg) func transferOwnership(tablaId: TablaId, newOwner: Principal) : async Result.Result<(), Text> {
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
        
        let updatedTabla : Tabla = {
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
  
  // System upgrade hooks
  system func preupgrade() {
    tablaEntries := Iter.toArray(tablas.entries());
  };
  
  system func postupgrade() {
    tablaEntries := [];
  };
}