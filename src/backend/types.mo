import Ids "ids";
import Enums "enums";

module Types {

  // Card positions in tabla
  public type Position = {
    row: Nat;
    col: Nat;
  };

  // Marca (player mark on a tabla)
  public type Marca = {
    playerId: Ids.PlayerId;
    tablaId: Ids.TablaId;
    position: Position;
    timestamp: Int;
  };

  // Win claim
  public type WinClaim = {
    playerId: Ids.PlayerId;
    tablaId: Ids.TablaId;
    positions: [Position];
    timestamp: Int;
  };

  // Game
  public type Game = {
    id: Ids.GameId;
    name: Text;
    host: Ids.PlayerId;
    createdAt: Int;
    status: Enums.GameStatus;
    mode: Enums.GameMode;
    tokenType: Enums.TokenType;
    entryFee: Nat;
    hostFeePercent: Nat;
    players: [Ids.PlayerId];
    tablas: [(Ids.PlayerId, Ids.TablaId)]; // Tracks which tablas are used by which players
    drawnCards: [Ids.CardId];
    currentCard: ?Ids.CardId;
    marcas: [Marca];
    winner: ?Ids.PlayerId;
    prizePool: Nat;
  };
  
  // Tabla NFT
  public type Tabla = {
    id: Ids.TablaId;
    owner: Ids.OwnerId;
    renter: ?Ids.RenterId;
    gameId: ?Ids.GameId;
    rentalFee: Nat;
    tokenType: Enums.TokenType;
    rarity: Enums.Rarity;
    metadata: TablaMetadata;
    rentalHistory: [RentalRecord];
    status: Enums.RentalStatus;
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
    renter: Ids.RenterId;
    gameId: ?Ids.GameId;
    startTime: Int;
    endTime: ?Int;
    fee: Nat;
    tokenType: Enums.TokenType;
  };
  
  // Tabla info (public view)
  public type TablaInfo = {
    id: Ids.TablaId;
    owner: Ids.OwnerId;
    renter: ?Ids.RenterId;
    gameId: ?Ids.GameId;
    rentalFee: Nat;
    tokenType: Enums.TokenType;
    rarity: Enums.Rarity;
    name: Text;
    image: Text;
    status: Enums.RentalStatus;
    isAvailable: Bool;
  };

};
