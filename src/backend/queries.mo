import Ids "ids";
import Enums "enums";

module Queries {

        public type GetOpenGames = {
                page: Nat;
        };

        public type OpenGames = {
                page: Nat;
                openGames: [Game];
        };

        public type GetActiveGames = {
                page: Nat;
        };

        public type ActiveGames = {
                page: Nat;
                activeGames: [Game];
        };

        public type GetGame = {
                gameId: Ids.GameId;
        };

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
                playerCount: Nat;
                maxPlayers: Nat;
                drawnCardCount: Nat;
                currentCard: ?Ids.CardId;
                winner: ?Ids.PlayerId;
                prizePool: Nat;
        };

        public type GetDrawHistory = {
                gameId: Ids.GameId
        };

        public type DrawHistory = {
                cardsDrawn: [Ids.CardId]
        };
        
}