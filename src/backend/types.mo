
module Types {
// Types
  public type GameId = Nat32;
  public type PlayerId = Principal;
  public type TablaId = Nat32;
  public type CardId = Nat32;

  // Card positions in tabla
  public type Position = {
    row: Nat;
    col: Nat;
  };

  // Game status
  public type GameStatus = {
    #lobby;    // Players can join
    #active;   // Game in progress
    #completed; // Game finished
  };

  // Game mode
  public type GameMode = {
    #line;     // Win by completing a line, row, or diagonal
    #blackout; // Win by marking all positions
  };

  // Token type
  public type TokenType = {
    #ICP;
    #ckBTC;
  };

  // Marca (player mark on a tabla)
  public type Marca = {
    playerId: PlayerId;
    tablaId: TablaId;
    position: Position;
    timestamp: Int;
  };

  // Win claim
  public type WinClaim = {
    playerId: PlayerId;
    tablaId: TablaId;
    positions: [Position];
    timestamp: Int;
  };

  // Game
  public type Game = {
    id: GameId;
    name: Text;
    host: PlayerId;
    createdAt: Int;
    status: GameStatus;
    mode: GameMode;
    tokenType: TokenType;
    entryFee: Nat;
    hostFeePercent: Nat;
    players: [PlayerId];
    tablas: [(PlayerId, TablaId)]; // Tracks which tablas are used by which players
    drawnCards: [CardId];
    currentCard: ?CardId;
    marcas: [Marca];
    winner: ?PlayerId;
    prizePool: Nat;
  };

  // Game creation parameters
  public type GameParams = {
    name: Text;
    mode: GameMode;
    tokenType: TokenType;
    entryFee: Nat;
    hostFeePercent: Nat;
  };

  // Game info (public view)
  public type GameInfo = {
    id: GameId;
    name: Text;
    host: PlayerId;
    createdAt: Int;
    status: GameStatus;
    mode: GameMode;
    tokenType: TokenType;
    entryFee: Nat;
    hostFeePercent: Nat;
    playerCount: Nat;
    maxPlayers: Nat;
    drawnCardCount: Nat;
    currentCard: ?CardId;
    winner: ?PlayerId;
    prizePool: Nat;
  };


  public type OwnerId = Principal;
  public type RenterId = Principal;
  
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
  
  // Tabla NFT
  public type Tabla = {
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
  public type TablaMetadata = {
    name: Text;
    description: Text;
    image: Text; // URL or IPFS hash
    cards: [Nat]; // The IDs of cards on this tabla in row-major order
  };
  
  // Rental record
  public type RentalRecord = {
    renter: RenterId;
    gameId: ?GameId;
    startTime: Int;
    endTime: ?Int;
    fee: Nat;
    tokenType: TokenType;
  };
  
  // Tabla info (public view)
  public type TablaInfo = {
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

};
