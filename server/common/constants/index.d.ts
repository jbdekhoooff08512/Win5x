export declare const GAME_CONFIG: {
    readonly DEFAULT_BETTING_DURATION: 30;
    readonly DEFAULT_SPIN_PREPARATION_DURATION: 10;
    readonly DEFAULT_SPINNING_DURATION: 11;
    readonly DEFAULT_RESULT_DURATION: 9;
    readonly DEFAULT_TRANSITION_DURATION: 3;
    readonly MIN_BET_AMOUNT: 10;
    readonly MAX_BET_AMOUNT: 5000;
    readonly PAYOUT_MULTIPLIER: 5;
    readonly CASHBACK_PERCENTAGE: 10;
    readonly MAX_EXPOSURE_MULTIPLIER: 100;
    readonly oddNumbers: readonly [1, 3, 5, 7, 9];
    readonly evenNumbers: readonly [0, 2, 4, 6, 8];
    readonly payoutMultiplier: 5;
    readonly minBet: 10;
    readonly maxBet: 5000;
};
export declare const WAGERING_CONFIG: {
    readonly DEPOSIT_MULTIPLIER: 5;
    readonly MIN_WAGERING_AMOUNT: 0;
    readonly MAX_WAGERING_AMOUNT: 100000;
    readonly ENABLE_WAGERING: true;
    readonly WAGERING_DESCRIPTION: "You need to wager 5x your deposit amount before withdrawal";
};
export declare enum GamePhase {
    BETTING = "BETTING",// 30 seconds - Players place bets
    SPIN_PREPARATION = "SPIN_PREPARATION",// 10 seconds - Analyze bets and prepare wheel
    SPINNING = "SPINNING",// 10-12 seconds - Wheel animates to winning number
    RESULT = "RESULT",// 8-10 seconds - Display results
    TRANSITION = "TRANSITION"
}
export declare const NUMBER_COLORS: {
    readonly 0: "red";
    readonly 1: "black";
    readonly 2: "red";
    readonly 3: "black";
    readonly 4: "red";
    readonly 5: "black";
    readonly 6: "red";
    readonly 7: "black";
    readonly 8: "red";
    readonly 9: "black";
};
export declare const SOCKET_EVENTS: {
    readonly JOIN_ROOM: "join_room";
    readonly LEAVE_ROOM: "leave_room";
    readonly PLACE_BET: "place_bet";
    readonly ADMIN_ACTION: "admin_action";
    readonly ROUND_UPDATE: "round_update";
    readonly PHASE_UPDATE: "phase_update";
    readonly BET_UPDATE: "bet_update";
    readonly TIMER_UPDATE: "timer_update";
    readonly ROUND_WINNER: "round_winner";
    readonly BET_DISTRIBUTION: "bet_distribution";
    readonly USER_BALANCE_UPDATE: "user_balance_update";
    readonly ERROR: "error";
    readonly ADMIN_NOTIFICATION: "admin_notification";
    readonly CONNECT: "connect";
    readonly DISCONNECT: "disconnect";
    readonly CONNECTION_ERROR: "connect_error";
};
export declare const API_ENDPOINTS: {
    readonly LOGIN: "/api/auth/login";
    readonly REGISTER: "/api/auth/register";
    readonly REFRESH: "/api/auth/refresh";
    readonly LOGOUT: "/api/auth/logout";
    readonly VERIFY: "/api/auth/verify";
    readonly ADMIN_SET_TEMP_PASSWORD: "/api/admin/users/:userId/set-temp-password";
    readonly PROFILE: "/api/user/profile";
    readonly CHANGE_PASSWORD: "/api/user/change-password";
    readonly BALANCE: "/api/user/balance";
    readonly TRANSACTIONS: "/api/user/transactions";
    readonly DEPOSIT: "/api/user/deposit";
    readonly WITHDRAW: "/api/user/withdraw";
    readonly BET_HISTORY: "/api/user/bets";
    readonly CURRENT_ROUND: "/api/game/current-round";
    readonly ROUND_HISTORY: "/api/game/rounds";
    readonly PLACE_BET: "/api/game/bet";
    readonly LEADERBOARD: "/api/game/leaderboard";
    readonly ADMIN_LOGIN: "/api/auth/admin/login";
    readonly USERS: "/api/admin/users";
    readonly ROUNDS: "/api/admin/rounds";
    readonly BETS: "/api/admin/bets";
    readonly TRANSACTIONS_ADMIN: "/api/admin/transactions";
    readonly ANALYTICS: "/api/admin/analytics";
    readonly GAME_CONFIG: "/api/admin/game-config";
    readonly EMERGENCY_STOP: "/api/admin/emergency-stop";
    readonly MANUAL_SPIN: "/api/admin/manual-spin";
};
export declare const ERROR_CODES: {
    readonly INVALID_CREDENTIALS: "INVALID_CREDENTIALS";
    readonly TOKEN_EXPIRED: "TOKEN_EXPIRED";
    readonly TOKEN_INVALID: "TOKEN_INVALID";
    readonly UNAUTHORIZED: "UNAUTHORIZED";
    readonly VALIDATION_ERROR: "VALIDATION_ERROR";
    readonly INVALID_BET_AMOUNT: "INVALID_BET_AMOUNT";
    readonly INVALID_BET_TYPE: "INVALID_BET_TYPE";
    readonly BETTING_CLOSED: "BETTING_CLOSED";
    readonly ROUND_NOT_FOUND: "ROUND_NOT_FOUND";
    readonly INSUFFICIENT_BALANCE: "INSUFFICIENT_BALANCE";
    readonly BET_LIMIT_EXCEEDED: "BET_LIMIT_EXCEEDED";
    readonly GAME_SUSPENDED: "GAME_SUSPENDED";
    readonly SERVER_ERROR: "SERVER_ERROR";
    readonly DATABASE_ERROR: "DATABASE_ERROR";
    readonly NETWORK_ERROR: "NETWORK_ERROR";
};
export declare const VALIDATION_RULES: {
    readonly USERNAME: {
        readonly MIN_LENGTH: 3;
        readonly MAX_LENGTH: 20;
        readonly PATTERN: RegExp;
    };
    readonly PASSWORD: {
        readonly MIN_LENGTH: 8;
        readonly MAX_LENGTH: 128;
        readonly REQUIRE_UPPERCASE: true;
        readonly REQUIRE_LOWERCASE: true;
        readonly REQUIRE_DIGIT: true;
        readonly REQUIRE_SPECIAL: false;
    };
    readonly EMAIL: {
        readonly PATTERN: RegExp;
    };
    readonly BET_AMOUNT: {
        readonly MIN: 10;
        readonly MAX: 5000;
    };
};
export declare const SOCKET_ROOMS: {
    readonly GAME: "game";
    readonly ADMIN: "admin";
    readonly USER_PREFIX: "user_";
};
export declare const CACHE_KEYS: {
    readonly CURRENT_ROUND: "current_round";
    readonly BET_DISTRIBUTION: "bet_distribution";
    readonly LEADERBOARD_DAILY: "leaderboard_daily";
    readonly LEADERBOARD_WEEKLY: "leaderboard_weekly";
    readonly LEADERBOARD_MONTHLY: "leaderboard_monthly";
    readonly USER_BALANCE: "user_balance_";
    readonly GAME_CONFIG: "game_config";
};
export declare const TIME_CONSTANTS: {
    readonly ONE_MINUTE: number;
    readonly ONE_HOUR: number;
    readonly ONE_DAY: number;
    readonly ONE_WEEK: number;
    readonly ONE_MONTH: number;
};
export declare const PAGINATION: {
    readonly DEFAULT_PAGE_SIZE: 20;
    readonly MAX_PAGE_SIZE: 100;
};
