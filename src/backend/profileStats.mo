import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Float "mo:core/Float";
import T "types";

module {
  public func updateStats(
    profiles : Map.Map<Principal, T.Profile>,
    playerId : Principal,
    wonGame : Bool
  ) {
    let ?profile = Map.get<Principal, T.Profile>(profiles, Principal.compare, playerId)
      else return;
    
    let newGames = profile.games + 1;
    let newWins = if (wonGame) profile.wins + 1 else profile.wins;
    
    let newWinRate : Float = if (newGames == 0) {
      0.0
    } else {
      Float.fromInt(newWins) / Float.fromInt(newGames)
    };
    
    Map.add<Principal, T.Profile>(
      profiles,
      Principal.compare,
      playerId,
      {
        profile with
        games = newGames;
        wins = newWins;
        winRate = newWinRate;
      }
    );
  };

  public func updateAllPlayers(
    profiles : Map.Map<Principal, T.Profile>,
    players : [(Principal, Nat32)],
    winnerId : Principal
  ) {
    for ((playerId, _) in players.vals()) {
      let isWinner = playerId == winnerId;
      updateStats(profiles, playerId, isWinner);
    };
  };
};