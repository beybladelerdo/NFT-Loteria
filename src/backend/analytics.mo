/**
 * NFT Lotería - Analytics
 * Platform statistics and metrics tracking
 * 
 * @author Demali Gregg
 * @company Canister Software Inc.
 */
import Map "mo:core/Map";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Time "mo:core/Time";
import Int "mo:core/Int";
import List "mo:core/List";
import T "Types";

module {
  public type VolumeData = {
    totalICP : Nat;
    totalCkBTC : Nat;
    totalGLDT : Nat;
  };

  public type VolumeRecord = {
    tokenType : T.TokenType;
    amount : Nat;
    timestamp : Int;
  };

  public type TablaEarnings = {
    tablaId : Nat32;
    earningsICP : Nat;
    earningsCkBTC : Nat;
    earningsGLDT : Nat;
    gamesPlayed : Nat;
    lastUsed : Int;
  };

  public type AnalyticsState = {
    var volumeICP : Nat;
    var volumeCkBTC : Nat;
    var volumeGLDT : Nat;
    var volumeHistory : List.List<VolumeRecord>;
    var largestPotICP : Nat;
    var largestPotCkBTC : Nat;
    var largestPotGLDT : Nat;
    var tablaStats : Map.Map<Nat32, TablaEarnings>;
  };

  public func emptyState() : AnalyticsState {
    {
      var volumeICP = 0;
      var volumeCkBTC = 0;
      var volumeGLDT = 0;
      var volumeHistory = List.empty<VolumeRecord>();
      var largestPotICP = 0;
      var largestPotCkBTC = 0;
      var largestPotGLDT = 0;
      var tablaStats = Map.empty<Nat32, TablaEarnings>();
    }
  };

  public func recordVolume(state : AnalyticsState, tokenType : T.TokenType, amount : Nat) {
    switch (tokenType) {
      case (#ICP) { state.volumeICP += amount };
      case (#ckBTC) { state.volumeCkBTC += amount };
      case (#gldt) { state.volumeGLDT += amount };
    };
    
    List.add(state.volumeHistory, {
      tokenType = tokenType;
      amount = amount;
      timestamp = Time.now();
    });
  };

  public func recordLargestPot(state : AnalyticsState, tokenType : T.TokenType, potSize : Nat) {
    switch (tokenType) {
      case (#ICP) { if (potSize > state.largestPotICP) state.largestPotICP := potSize };
      case (#ckBTC) { if (potSize > state.largestPotCkBTC) state.largestPotCkBTC := potSize };
      case (#gldt) { if (potSize > state.largestPotGLDT) state.largestPotGLDT := potSize };
    };
  };

  public func recordTablaEarning(state : AnalyticsState, tablaId : Nat32, tokenType : T.TokenType, amount : Nat) {
    let current = switch (Map.get(state.tablaStats, Nat32.compare, tablaId)) {
      case (?stats) stats;
      case null {
        {
          tablaId = tablaId;
          earningsICP = 0;
          earningsCkBTC = 0;
          earningsGLDT = 0;
          gamesPlayed = 0;
          lastUsed = Time.now();
        }
      };
    };
    
    let updated = switch (tokenType) {
      case (#ICP) { { current with earningsICP = current.earningsICP + amount; lastUsed = Time.now() } };
      case (#ckBTC) { { current with earningsCkBTC = current.earningsCkBTC + amount; lastUsed = Time.now() } };
      case (#gldt) { { current with earningsGLDT = current.earningsGLDT + amount; lastUsed = Time.now() } };
    };
    
    Map.add(state.tablaStats, Nat32.compare, tablaId, updated);
  };

  public func recordTablaPlayed(state : AnalyticsState, tablaId : Nat32) {
    let current = switch (Map.get(state.tablaStats, Nat32.compare, tablaId)) {
      case (?stats) stats;
      case null {
        {
          tablaId = tablaId;
          earningsICP = 0;
          earningsCkBTC = 0;
          earningsGLDT = 0;
          gamesPlayed = 0;
          lastUsed = Time.now();
        }
      };
    };
    
    Map.add(state.tablaStats, Nat32.compare, tablaId, { 
      current with 
      gamesPlayed = current.gamesPlayed + 1;
      lastUsed = Time.now();
    });
  };

  public func getVolume(state : AnalyticsState) : VolumeData {
    {
      totalICP = state.volumeICP;
      totalCkBTC = state.volumeCkBTC;
      totalGLDT = state.volumeGLDT;
    }
  };

  public func get24hVolume(state : AnalyticsState) : VolumeData {
    let now = Time.now();
    let oneDayAgo = now - 86_400_000_000_000;
    
    var icp : Nat = 0;
    var ckbtc : Nat = 0;
    var gldt : Nat = 0;
    
    for (record in List.values(state.volumeHistory)) {
      if (record.timestamp >= oneDayAgo) {
        switch (record.tokenType) {
          case (#ICP) { icp += record.amount };
          case (#ckBTC) { ckbtc += record.amount };
          case (#gldt) { gldt += record.amount };
        };
      };
    };
    
    { totalICP = icp; totalCkBTC = ckbtc; totalGLDT = gldt }
  };

  public func getLargestPots(state : AnalyticsState) : VolumeData {
    {
      totalICP = state.largestPotICP;
      totalCkBTC = state.largestPotCkBTC;
      totalGLDT = state.largestPotGLDT;
    }
  };

  public func getTablaEarnings(state : AnalyticsState, tablaId : Nat32) : ?TablaEarnings {
    Map.get(state.tablaStats, Nat32.compare, tablaId)
  };

  public func getAllTablaEarnings(state : AnalyticsState) : [TablaEarnings] {
    let out = List.empty<TablaEarnings>();
    for (stats in Map.values(state.tablaStats)) {
      List.add(out, stats);
    };
    List.toArray(out)
  };
};