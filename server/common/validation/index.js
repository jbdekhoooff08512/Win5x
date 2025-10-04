"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.transactionHistorySchema = exports.betHistorySchema = exports.userQuerySchema = exports.dateRangeSchema = exports.paginationSchema = exports.adminActionSchema = exports.gameConfigSchema = exports.withdrawalSchema = exports.depositSchema = exports.placeBetSchema = exports.registerSchema = exports.loginSchema = void 0;
exports.validateBetValue = validateBetValue;
exports.validatePassword = validatePassword;
const zod_1 = require("zod");
const constants_1 = require("../constants");
// Auth Schemas
exports.loginSchema = zod_1.z.object({
    username: zod_1.z.string().min(1, 'Username is required'),
    password: zod_1.z.string().min(1, 'Password is required'),
});
exports.registerSchema = zod_1.z.object({
    username: zod_1.z
        .string()
        .min(constants_1.VALIDATION_RULES.USERNAME.MIN_LENGTH, `Username must be at least ${constants_1.VALIDATION_RULES.USERNAME.MIN_LENGTH} characters`)
        .max(constants_1.VALIDATION_RULES.USERNAME.MAX_LENGTH, `Username must be at most ${constants_1.VALIDATION_RULES.USERNAME.MAX_LENGTH} characters`)
        .regex(constants_1.VALIDATION_RULES.USERNAME.PATTERN, 'Username can only contain letters, numbers, and underscores'),
    email: zod_1.z
        .string()
        .email('Invalid email format')
        .regex(constants_1.VALIDATION_RULES.EMAIL.PATTERN, 'Invalid email format'),
    password: zod_1.z
        .string()
        .min(constants_1.VALIDATION_RULES.PASSWORD.MIN_LENGTH, `Password must be at least ${constants_1.VALIDATION_RULES.PASSWORD.MIN_LENGTH} characters`)
        .max(constants_1.VALIDATION_RULES.PASSWORD.MAX_LENGTH, `Password must be at most ${constants_1.VALIDATION_RULES.PASSWORD.MAX_LENGTH} characters`)
        .refine((password) => {
        if (constants_1.VALIDATION_RULES.PASSWORD.REQUIRE_UPPERCASE && !/[A-Z]/.test(password)) {
            return false;
        }
        if (constants_1.VALIDATION_RULES.PASSWORD.REQUIRE_LOWERCASE && !/[a-z]/.test(password)) {
            return false;
        }
        if (constants_1.VALIDATION_RULES.PASSWORD.REQUIRE_DIGIT && !/\d/.test(password)) {
            return false;
        }
        return true;
    }, 'Password must contain uppercase, lowercase, and digit'),
    referralCode: zod_1.z.string().optional(),
});
// Bet Schemas
exports.placeBetSchema = zod_1.z.object({
    roundId: zod_1.z.string().uuid('Invalid round ID'),
    betType: zod_1.z.enum(['number', 'odd_even', 'color']),
    betValue: zod_1.z.union([
        zod_1.z.number().int().min(0).max(9), // for number bets
        zod_1.z.enum(['odd', 'even']), // for odd/even bets
        zod_1.z.enum(['red', 'black']), // for color bets
    ]),
    amount: zod_1.z
        .number()
        .min(constants_1.GAME_CONFIG.MIN_BET_AMOUNT, `Minimum bet amount is ${constants_1.GAME_CONFIG.MIN_BET_AMOUNT}`)
        .max(constants_1.GAME_CONFIG.MAX_BET_AMOUNT, `Maximum bet amount is ${constants_1.GAME_CONFIG.MAX_BET_AMOUNT}`),
});
// Transaction Schemas
exports.depositSchema = zod_1.z.object({
    amount: zod_1.z.number().positive('Amount must be positive'),
    paymentMethod: zod_1.z.string().min(1, 'Payment method is required'),
    reference: zod_1.z.string().optional(),
});
exports.withdrawalSchema = zod_1.z.object({
    amount: zod_1.z.number().positive('Amount must be positive'),
    paymentMethod: zod_1.z.string().min(1, 'Payment method is required'),
    accountDetails: zod_1.z.string().min(1, 'Account details are required'),
});
// Admin Schemas
exports.gameConfigSchema = zod_1.z.object({
    bettingDuration: zod_1.z.number().int().min(10).max(300),
    spinDuration: zod_1.z.number().int().min(5).max(60),
    resultDuration: zod_1.z.number().int().min(5).max(60),
    minBetAmount: zod_1.z.number().positive(),
    maxBetAmount: zod_1.z.number().positive(),
    payoutMultiplier: zod_1.z.number().positive(),
    cashbackPercentage: zod_1.z.number().min(0).max(100),
    maxExposure: zod_1.z.number().positive(),
});
exports.adminActionSchema = zod_1.z.object({
    action: zod_1.z.enum(['emergency_stop', 'manual_spin', 'extend_betting', 'cancel_round']),
    data: zod_1.z.any().optional(),
    reason: zod_1.z.string().optional(),
});
// Query Schemas
exports.paginationSchema = zod_1.z.object({
    page: zod_1.z.string().transform((val) => parseInt(val, 10)).pipe(zod_1.z.number().int().min(1)).default('1'),
    pageSize: zod_1.z.string().transform((val) => parseInt(val, 10)).pipe(zod_1.z.number().int().min(1).max(100)).default('20'),
});
exports.dateRangeSchema = zod_1.z.object({
    startDate: zod_1.z.string().datetime().optional(),
    endDate: zod_1.z.string().datetime().optional(),
});
exports.userQuerySchema = exports.paginationSchema.extend({
    search: zod_1.z.string().optional(),
    isActive: zod_1.z.boolean().optional(),
    sortBy: zod_1.z.enum(['username', 'email', 'balance', 'createdAt']).default('createdAt'),
    sortOrder: zod_1.z.enum(['asc', 'desc']).default('desc'),
});
exports.betHistorySchema = exports.paginationSchema.extend({
    userId: zod_1.z.string().uuid().optional(),
    roundId: zod_1.z.string().uuid().optional(),
    betType: zod_1.z.enum(['number', 'odd_even', 'color']).optional(),
    status: zod_1.z.enum(['pending', 'won', 'lost', 'cancelled', 'refunded']).optional(),
    ...exports.dateRangeSchema.shape,
});
exports.transactionHistorySchema = exports.paginationSchema.extend({
    userId: zod_1.z.string().uuid().optional(),
    type: zod_1.z.enum(['deposit', 'withdrawal', 'bet_placed', 'bet_won', 'bet_lost', 'cashback', 'DEPOSIT', 'WITHDRAWAL', 'BET_PLACED', 'BET_WON', 'BET_LOST', 'CASHBACK']).optional(),
    status: zod_1.z.enum(['pending', 'approved', 'rejected', 'completed', 'cancelled', 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED', 'CANCELLED']).optional(),
    ...exports.dateRangeSchema.shape,
});
// Validation Helpers
function validateBetValue(betType, betValue) {
    switch (betType) {
        case 'number':
            return typeof betValue === 'number' && betValue >= 0 && betValue <= 9 && Number.isInteger(betValue);
        default:
            return false;
    }
}
function validatePassword(password) {
    const errors = [];
    if (password.length < constants_1.VALIDATION_RULES.PASSWORD.MIN_LENGTH) {
        errors.push(`Password must be at least ${constants_1.VALIDATION_RULES.PASSWORD.MIN_LENGTH} characters long`);
    }
    if (password.length > constants_1.VALIDATION_RULES.PASSWORD.MAX_LENGTH) {
        errors.push(`Password must be at most ${constants_1.VALIDATION_RULES.PASSWORD.MAX_LENGTH} characters long`);
    }
    if (constants_1.VALIDATION_RULES.PASSWORD.REQUIRE_UPPERCASE && !/[A-Z]/.test(password)) {
        errors.push('Password must contain at least one uppercase letter');
    }
    if (constants_1.VALIDATION_RULES.PASSWORD.REQUIRE_LOWERCASE && !/[a-z]/.test(password)) {
        errors.push('Password must contain at least one lowercase letter');
    }
    if (constants_1.VALIDATION_RULES.PASSWORD.REQUIRE_DIGIT && !/\d/.test(password)) {
        errors.push('Password must contain at least one digit');
    }
    return {
        isValid: errors.length === 0,
        errors,
    };
}
