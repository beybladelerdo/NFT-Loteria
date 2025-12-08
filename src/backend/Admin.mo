/**
 * NFT Lotería - Admin
 * Administrative functions and access control
 * 
 * @author Demali Gregg
 * @company Canister Software Inc.
 */

import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Commands "Commands";
import T "Types";
import Array "mo:core/Array";
import Text "mo:core/Text";
import List "mo:core/List";
import Constants "Constants";
import Nat32 "mo:core/Nat32";
import Nat "mo:core/Nat";
import Time "mo:core/Time";
import Utils "Utilities";
module Admin {
    public func isAdmin(map: Map.Map<Principal, Bool>,p : Principal) : Bool {
    switch (Map.get<Principal, Bool>(map, Principal.compare, p)) {
      case (?_) true;
      case null false;
    }
  };
  public func add(admins : Map.Map<Principal, Bool>, p : Principal) {
    Map.add(admins, Principal.compare, p, true);
  };

  public func bootstrap(admins : Map.Map<Principal, Bool>, caller : Principal) : Result.Result<(), Text> {
    if (Map.size(admins) > 0) return #err("already bootstrapped");
    Map.add(admins, Principal.compare, caller, true);
    #ok(());
  };
  public func createTabla(admins : Map.Map<Principal, Bool>,
    tablas : Map.Map<Nat32, T.Tabla>,
    owners : Map.Map<Nat32, Text>,
    dto : Commands.CreateTabla, caller: Principal ) : Result.Result<Nat32, Text> {
    if (not isAdmin(admins, caller)) return #err("unauthorized");
    
    if (Array.size(dto.cards) != Constants.TABLA_SIZE * Constants.TABLA_SIZE) {
      return #err("Invalid card layout: must have exactly 16 cards");
    };

    for (cardId in Array.values(dto.cards)) {
      if (cardId < 1 or cardId > Constants.TOTAL_CARDS) {
        return #err("Invalid card ID: must be between 1-54");
      };
    };
    switch (Map.get<Nat32, T.Tabla>(tablas, Nat32.compare, dto.tablaId)) {
      case (?_) { return #err("Tabla already exists") };
      case null {};
    };

    let ownerAccountId = switch (Map.get<Nat32, Text>(owners, Nat32.compare, dto.tablaId)) {
      case (?accountId) { accountId };
      case null { return #err("Owner not found in registry. Run refreshRegistry() first.") };
    };
    
    let rentalFee : Nat = 0;
    
    let metadata : T.TablaMetadata = {
      name = "Tabla #" # Nat.toText(Nat32.toNat(dto.tablaId));
      description = "A crypto-themed lotería tabla with unique card combinations";
      image = dto.imageUrl;
      cards = dto.cards;
    };
    
    let newTabla : T.Tabla = {
      id = dto.tablaId;
      owner = ownerAccountId;
      renter = null;
      gameId = null;
      rentalFee = rentalFee;
      tokenType = #ICP;
      rarity = dto.rarity;
      metadata = metadata;
      rentalHistory = [];
      status = #available;
      createdAt = Time.now();
      updatedAt = Time.now();
    };
    
    Map.add<Nat32, T.Tabla>(tablas, Nat32.compare, dto.tablaId, newTabla);
    #ok(dto.tablaId);
  };
  public func listGameSubaccounts(
  admins : Map.Map<Principal, Bool>,
  gameSubaccounts : Map.Map<Text, Blob>,
  caller : Principal
) : Result.Result<[(Text, Blob)], Text> {
  if (not Admin.isAdmin(admins, caller)) return #err("unauthorized");
  let out = List.empty<(Text, Blob)>();
  for ((gameId, sub) in Map.entries(gameSubaccounts)) {
    List.add(out, (gameId, sub));
  };
  #ok(List.toArray(out));
};
public func deleteTabla(
  admins : Map.Map<Principal, Bool>,
  tablas : Map.Map<Nat32, T.Tabla>,
  caller : Principal,
  tablaId : Nat32
) : Result.Result<(), Text> {
  if (not isAdmin(admins, caller)) return #err("unauthorized");
  
  switch (Map.take(tablas, Nat32.compare, tablaId)) {
    case (?_) { #ok(()) };
    case null { #err("Tabla not found") };
  };
};

public func deleteGame(
  admins : Map.Map<Principal, Bool>,
  games : Map.Map<Text, T.Game>,
  caller : Principal,
  gameId : Text
) : Result.Result<(), Text> {
  if (not isAdmin(admins, caller)) return #err("unauthorized");
  
  switch (Map.take(games, Text.compare, gameId)) {
    case (?_) { #ok(()) };
    case null { #err("Game not found") };
  };
};

public func batchTablas(
  admins : Map.Map<Principal, Bool>,
  tablas : Map.Map<Nat32, T.Tabla>,
  owners : Map.Map<Nat32, Text>,
  caller : Principal,
  dtos : [Commands.CreateTabla]
) : Result.Result<[Nat32], Text> {
  if (not isAdmin(admins, caller)) return #err("unauthorized");
  
  let results = List.empty<Nat32>();
  var errors : Text = "";
  
  for (dto in Array.values(dtos)) {
    switch (createTabla(admins, tablas, owners, dto, caller)) {
      case (#ok(id)) { List.add(results, id) };
      case (#err(e)) { errors := errors # "Tabla " # Nat32.toText(dto.tablaId) # ": " # e # "; " };
    };
  };
  
  if (errors != "") {
    return #err(errors);
  };
  
  #ok(List.toArray(results));
};

public func updateTablaMetadata(
  admins : Map.Map<Principal, Bool>,
  tablas : Map.Map<Nat32, T.Tabla>,
  caller : Principal,
  dto : Commands.UpdateTablaMetadata
) : Result.Result<(), Text> {
  if (not isAdmin(admins, caller)) return #err("unauthorized");
  
  let ?tabla = Map.get(tablas, Nat32.compare, dto.tablaId) else return #err("Tabla not found");
  
  let updatedMetadata = {
    name = switch (dto.name) { case (?n) n; case null tabla.metadata.name };
    description = switch (dto.description) { case (?d) d; case null tabla.metadata.description };
    image = switch (dto.imageUrl) { case (?i) i; case null tabla.metadata.image };
    cards = switch (dto.cards) { case (?c) c; case null tabla.metadata.cards };
  };
  
  Map.add(
    tablas,
    Nat32.compare,
    dto.tablaId,
    { tabla with metadata = updatedMetadata; updatedAt = Time.now() }
  );
  
  #ok();
};
public func validateTerminateGame(
  admins : Map.Map<Principal, Bool>,
  games : Map.Map<Text, T.Game>,
  caller : Principal,
  gameId : Text
) : Result.Result<T.Game, Text> {
  let ?game = Map.get(games, Text.compare, gameId)
    else return #err("Game not found");
  
  switch (game.status) {
    case (#completed) { return #err("Cannot terminate completed game") };
    case (#active) {
      if (not isAdmin(admins, caller)) {
        return #err("Unauthorized: only admin can terminate active games");
      };
    };
    case (#lobby) {
      if (caller != game.host and not isAdmin(admins, caller)) {
        return #err("Unauthorized: only game host or admin can terminate lobby games");
      };
    };
  };
  
  #ok(game);
};
public func getGameSubaccount(
  admins : Map.Map<Principal, Bool>,
  gameSubaccounts : Map.Map<Text, Blob>,
  caller : Principal,
  gameId : Text
) : Result.Result<Blob, Text> {
  if (not isAdmin(admins, caller)) return #err("unauthorized");
  switch (Map.get(gameSubaccounts, Text.compare, gameId)) {
    case (?sub) { #ok(sub) };
    case null { #err("No subaccount stored for this gameId") };
  };
};

public func initRegistry(
  admins : Map.Map<Principal, Bool>,
  owners : Map.Map<Nat32, Text>,
  caller : Principal,
  r : [(Nat32, Text)]
) : Result.Result<(), Text> {
  if (not isAdmin(admins, caller)) return #err("Not authorized");
  if (Array.size(r) == 0) return #err("Empty tuple");
  
  for ((id, owner) in Array.values(r)) {
    if (owner != Utils.burnAddress) {
      Map.add(owners, Nat32.compare, id + 1, owner);
    };
  };
  #ok();
};

public func upsertOwnerPrincipals(
  admins : Map.Map<Principal, Bool>,
  ownerPrincipals : Map.Map<Nat32, ?Principal>,
  caller : Principal,
  entries : [(Nat32, ?Principal)]
) : Result.Result<(), Text> {
  if (not isAdmin(admins, caller)) return #err("unauthorized");
  
  for ((tablaId, maybePrincipal) in Array.values(entries)) {
    Map.add(ownerPrincipals, Nat32.compare, tablaId + 1, maybePrincipal);
  };
  
  #ok();
};
}