import { z } from 'zod';
import { BetType } from '../types';
export declare const loginSchema: z.ZodObject<{
    username: z.ZodString;
    password: z.ZodString;
}, "strip", z.ZodTypeAny, {
    username: string;
    password: string;
}, {
    username: string;
    password: string;
}>;
export declare const registerSchema: z.ZodObject<{
    username: z.ZodString;
    email: z.ZodString;
    password: z.ZodEffects<z.ZodString, string, string>;
    referralCode: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    username: string;
    password: string;
    email: string;
    referralCode?: string | undefined;
}, {
    username: string;
    password: string;
    email: string;
    referralCode?: string | undefined;
}>;
export declare const placeBetSchema: z.ZodObject<{
    roundId: z.ZodString;
    betType: z.ZodEnum<["number", "odd_even", "color"]>;
    betValue: z.ZodUnion<[z.ZodNumber, z.ZodEnum<["odd", "even"]>, z.ZodEnum<["red", "black"]>]>;
    amount: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    roundId: string;
    betType: "number" | "odd_even" | "color";
    betValue: number | "red" | "black" | "odd" | "even";
    amount: number;
}, {
    roundId: string;
    betType: "number" | "odd_even" | "color";
    betValue: number | "red" | "black" | "odd" | "even";
    amount: number;
}>;
export declare const depositSchema: z.ZodObject<{
    amount: z.ZodNumber;
    paymentMethod: z.ZodString;
    reference: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    amount: number;
    paymentMethod: string;
    reference?: string | undefined;
}, {
    amount: number;
    paymentMethod: string;
    reference?: string | undefined;
}>;
export declare const withdrawalSchema: z.ZodObject<{
    amount: z.ZodNumber;
    paymentMethod: z.ZodString;
    accountDetails: z.ZodString;
}, "strip", z.ZodTypeAny, {
    amount: number;
    paymentMethod: string;
    accountDetails: string;
}, {
    amount: number;
    paymentMethod: string;
    accountDetails: string;
}>;
export declare const gameConfigSchema: z.ZodObject<{
    bettingDuration: z.ZodNumber;
    spinDuration: z.ZodNumber;
    resultDuration: z.ZodNumber;
    minBetAmount: z.ZodNumber;
    maxBetAmount: z.ZodNumber;
    payoutMultiplier: z.ZodNumber;
    cashbackPercentage: z.ZodNumber;
    maxExposure: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    bettingDuration: number;
    spinDuration: number;
    resultDuration: number;
    minBetAmount: number;
    maxBetAmount: number;
    payoutMultiplier: number;
    cashbackPercentage: number;
    maxExposure: number;
}, {
    bettingDuration: number;
    spinDuration: number;
    resultDuration: number;
    minBetAmount: number;
    maxBetAmount: number;
    payoutMultiplier: number;
    cashbackPercentage: number;
    maxExposure: number;
}>;
export declare const adminActionSchema: z.ZodObject<{
    action: z.ZodEnum<["emergency_stop", "manual_spin", "extend_betting", "cancel_round"]>;
    data: z.ZodOptional<z.ZodAny>;
    reason: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    action: "emergency_stop" | "manual_spin" | "extend_betting" | "cancel_round";
    data?: any;
    reason?: string | undefined;
}, {
    action: "emergency_stop" | "manual_spin" | "extend_betting" | "cancel_round";
    data?: any;
    reason?: string | undefined;
}>;
export declare const paginationSchema: z.ZodObject<{
    page: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
    pageSize: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
}, "strip", z.ZodTypeAny, {
    page: number;
    pageSize: number;
}, {
    page?: string | undefined;
    pageSize?: string | undefined;
}>;
export declare const dateRangeSchema: z.ZodObject<{
    startDate: z.ZodOptional<z.ZodString>;
    endDate: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    startDate?: string | undefined;
    endDate?: string | undefined;
}, {
    startDate?: string | undefined;
    endDate?: string | undefined;
}>;
export declare const userQuerySchema: z.ZodObject<{
    page: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
    pageSize: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
} & {
    search: z.ZodOptional<z.ZodString>;
    isActive: z.ZodOptional<z.ZodBoolean>;
    sortBy: z.ZodDefault<z.ZodEnum<["username", "email", "balance", "createdAt"]>>;
    sortOrder: z.ZodDefault<z.ZodEnum<["asc", "desc"]>>;
}, "strip", z.ZodTypeAny, {
    page: number;
    pageSize: number;
    sortBy: "username" | "email" | "balance" | "createdAt";
    sortOrder: "asc" | "desc";
    search?: string | undefined;
    isActive?: boolean | undefined;
}, {
    page?: string | undefined;
    pageSize?: string | undefined;
    search?: string | undefined;
    isActive?: boolean | undefined;
    sortBy?: "username" | "email" | "balance" | "createdAt" | undefined;
    sortOrder?: "asc" | "desc" | undefined;
}>;
export declare const betHistorySchema: z.ZodObject<{
    page: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
    pageSize: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
} & {
    startDate: z.ZodOptional<z.ZodString>;
    endDate: z.ZodOptional<z.ZodString>;
    userId: z.ZodOptional<z.ZodString>;
    roundId: z.ZodOptional<z.ZodString>;
    betType: z.ZodOptional<z.ZodEnum<["number", "odd_even", "color"]>>;
    status: z.ZodOptional<z.ZodEnum<["pending", "won", "lost", "cancelled", "refunded"]>>;
}, "strip", z.ZodTypeAny, {
    page: number;
    pageSize: number;
    status?: "cancelled" | "pending" | "won" | "lost" | "refunded" | undefined;
    roundId?: string | undefined;
    betType?: "number" | "odd_even" | "color" | undefined;
    startDate?: string | undefined;
    endDate?: string | undefined;
    userId?: string | undefined;
}, {
    status?: "cancelled" | "pending" | "won" | "lost" | "refunded" | undefined;
    roundId?: string | undefined;
    betType?: "number" | "odd_even" | "color" | undefined;
    page?: string | undefined;
    pageSize?: string | undefined;
    startDate?: string | undefined;
    endDate?: string | undefined;
    userId?: string | undefined;
}>;
export declare const transactionHistorySchema: z.ZodObject<{
    page: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
    pageSize: z.ZodDefault<z.ZodPipeline<z.ZodEffects<z.ZodString, number, string>, z.ZodNumber>>;
} & {
    startDate: z.ZodOptional<z.ZodString>;
    endDate: z.ZodOptional<z.ZodString>;
    userId: z.ZodOptional<z.ZodString>;
    type: z.ZodOptional<z.ZodEnum<["deposit", "withdrawal", "bet_placed", "bet_won", "bet_lost", "cashback", "DEPOSIT", "WITHDRAWAL", "BET_PLACED", "BET_WON", "BET_LOST", "CASHBACK"]>>;
    status: z.ZodOptional<z.ZodEnum<["pending", "approved", "rejected", "completed", "cancelled", "PENDING", "APPROVED", "REJECTED", "COMPLETED", "CANCELLED"]>>;
}, "strip", z.ZodTypeAny, {
    page: number;
    pageSize: number;
    type?: "deposit" | "withdrawal" | "bet_placed" | "bet_won" | "bet_lost" | "cashback" | "DEPOSIT" | "WITHDRAWAL" | "BET_PLACED" | "BET_WON" | "BET_LOST" | "CASHBACK" | undefined;
    status?: "completed" | "cancelled" | "pending" | "approved" | "rejected" | "PENDING" | "APPROVED" | "REJECTED" | "COMPLETED" | "CANCELLED" | undefined;
    startDate?: string | undefined;
    endDate?: string | undefined;
    userId?: string | undefined;
}, {
    type?: "deposit" | "withdrawal" | "bet_placed" | "bet_won" | "bet_lost" | "cashback" | "DEPOSIT" | "WITHDRAWAL" | "BET_PLACED" | "BET_WON" | "BET_LOST" | "CASHBACK" | undefined;
    status?: "completed" | "cancelled" | "pending" | "approved" | "rejected" | "PENDING" | "APPROVED" | "REJECTED" | "COMPLETED" | "CANCELLED" | undefined;
    page?: string | undefined;
    pageSize?: string | undefined;
    startDate?: string | undefined;
    endDate?: string | undefined;
    userId?: string | undefined;
}>;
export declare function validateBetValue(betType: BetType, betValue: number | string): boolean;
export declare function validatePassword(password: string): {
    isValid: boolean;
    errors: string[];
};
export type LoginRequest = z.infer<typeof loginSchema>;
export type RegisterRequest = z.infer<typeof registerSchema>;
export type PlaceBetRequest = z.infer<typeof placeBetSchema>;
export type DepositRequest = z.infer<typeof depositSchema>;
export type WithdrawalRequest = z.infer<typeof withdrawalSchema>;
export type GameConfigRequest = z.infer<typeof gameConfigSchema>;
export type AdminActionRequest = z.infer<typeof adminActionSchema>;
export type PaginationQuery = z.infer<typeof paginationSchema>;
export type DateRangeQuery = z.infer<typeof dateRangeSchema>;
export type UserQuery = z.infer<typeof userQuerySchema>;
export type BetHistoryQuery = z.infer<typeof betHistorySchema>;
export type TransactionHistoryQuery = z.infer<typeof transactionHistorySchema>;
