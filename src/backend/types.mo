import Ids "ids";
import BaseIds "mo:waterway-mops/base/ids";
import Nat32 "mo:core/Nat32";

module Types {
  public type Entry = (Nat32, Text);
  public type PaidKey = (Text, Principal);
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
  public type Profile = {
    principalId : BaseIds.PrincipalId;
    username : Text;
    games : Nat;
    wins : Nat;
    winRate : Float;
  };

  // Card positions in tabla
  public type Position = {
    row : Nat;
    col : Nat;
  };

  // Marca (player mark on a tabla)
  public type Marca = {
    playerId : Ids.PlayerId;
    tablaId : Ids.TablaId;
    position : Position;
    timestamp : Int;
  };

  // Win claim
  public type WinClaim = {
    playerId : Ids.PlayerId;
    tablaId : Ids.TablaId;
    positions : [Position];
    timestamp : Int;
  };

  // Game
  public type Game = {
    id : Text;
    name : Text;
    host : Ids.PlayerId;
    createdAt : Int;
    status : GameStatus;
    mode : GameMode;
    tokenType : TokenType;
    entryFee : Nat;
    hostFeePercent : Nat;
    players : [Ids.PlayerId];
    tablas : [(Ids.PlayerId, Ids.TablaId)]; // Tracks which tablas are used by which players
    drawnCards : [Ids.CardId];
    currentCard : ?Ids.CardId;
    marcas : [Marca];
    winner : ?Ids.PlayerId;
    prizePool : Nat;
  };
  public type ChatMessage = {
  sender : Principal;
  username : Text;
  message : Text;
  timestamp : Int;
};

  // Tabla NFT
  public type Tabla = {
    id : Ids.TablaId;
    owner : Ids.OwnerId;
    renter : ?Ids.RenterId;
    gameId : ?Text;
    rentalFee : Nat;
    tokenType : TokenType;
    rarity : Rarity;
    metadata : TablaMetadata;
    rentalHistory : [RentalRecord];
    status : RentalStatus;
    createdAt : Int;
    updatedAt : Int;
  };

  // Tabla metadata
  public type TablaMetadata = {
    name : Text;
    description : Text;
    image : Text; // URL or IPFS hash
    cards : [Nat]; // The IDs of cards on this tabla in row-major order
  };

  // Rental record
  public type RentalRecord = {
    renter : Ids.RenterId;
    gameId : ?Text;
    startTime : Int;
    endTime : ?Int;
    fee : Nat;
    tokenType : TokenType;
  };

  // Tabla info (public view)
  public type TablaInfo = {
    id : Ids.TablaId;
    owner : Ids.OwnerId;
    renter : ?Ids.RenterId;
    gameId : ?Text;
    rentalFee : Nat;
    tokenType : TokenType;
    rarity : Rarity;
    name : Text;
    image : Text;
    status : RentalStatus;
    isAvailable : Bool;
  };
  public type Masks = {
    size : Nat;
    rows : [Nat32];
    cols : [Nat32];
    diagMain : Nat32;
    diagOther : Nat32;
    allMask : Nat32;
  };
  public type PayoutStatus = {
  devFeePaid : Bool;
  tablaOwnerPaid : Bool;
  winnerPaid : Bool;
  hostPaid : Bool;
};

public type FailedClaim = {
  gameId : Text;
  tablaId : Nat32;
  player : Principal;
  host : Principal;
  tablaOwnerPayment : ?{ #icrc1: Principal; #icpAccount: Blob };
  winnerAmount : Nat;
  hostFee : Nat;
  tablaOwnerFee : Nat;
  devFee : Nat;
  tokenType : TokenType;
  failedAt : Int;
  payoutStatus : PayoutStatus;
  lastError : Text;
};
};
