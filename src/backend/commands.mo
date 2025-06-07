import Ids "./ids";
import Enums "./enums";

module Commands {
        public type CreateGame = {
                name: Text;
                mode: Enums.GameMode;
                tokenType: Enums.TokenType;
                entryFee: Nat;
                hostFeePercent: Nat;
        };

        public type JoinGame = {
                gameId: Ids.GameId;
                rentedTablaId: Ids.TablaId;
        };

        public type StartGame = {
                gameId: Ids.GameId;
        };

        public type EndGame = {
                gameId: Ids.GameId;
        };

        public type DrawCard = {
                gameId: Ids.GameId;
        };

        public type MarkPosition = {
                gameId: Ids.GameId;
        };

        public type ClaimWin = {
                gameId: Ids.GameId;
        };

        public type UpdateTablaRentalFee = {
                tablaId: Ids.TablaId; 
                newFee: Nat
        };
}