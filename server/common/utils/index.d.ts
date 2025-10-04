import { BetType } from '../types';
export declare function getNumberColor(number: number): 'red' | 'black';
export declare function isNumberOdd(number: number): boolean;
export declare function calculatePayout(betType: BetType, betValue: number | string, amount: number, winningNumber: number): number;
export declare function calculateCashbackAmount(betAmount: number): number;
/**
 * Admin-safe winner determination function
 * @param bets - Array or object of bet amounts for numbers 0-9
 * @returns The winning number (0-9)
 */
export declare function get_winner(bets: number[] | Record<string, number>): number;
export declare function determineLeastChosenNumber(betDistribution: Record<string, number>): number;
export declare function formatTimeRemaining(seconds: number): string;
export declare function getTimeAgo(date: Date): string;
export declare function isDateToday(date: Date): boolean;
export declare function getDateRange(period: 'daily' | 'weekly' | 'monthly'): {
    start: Date;
    end: Date;
};
export declare function formatCurrency(amount: number | undefined | null, currency?: string): string;
export declare function formatNumber(num: number): string;
export declare function calculatePercentage(value: number, total: number): number;
export declare function roundToDecimal(num: number, decimals?: number): number;
export declare function generateId(): string;
export declare function capitalizeFirst(str: string): string;
export declare function truncateText(text: string, maxLength: number): string;
export declare function shuffleArray<T>(array: T[]): T[];
export declare function groupBy<T, K extends string | number>(array: T[], keyFn: (item: T) => K): Record<K, T[]>;
export declare function isValidEmail(email: string): boolean;
export declare function isValidUsername(username: string): boolean;
export declare function sanitizeInput(input: string): string;
export declare function createErrorResponse(message: string, code?: string, statusCode?: number): {
    success: boolean;
    error: string;
    code: string | undefined;
    statusCode: number;
};
export declare function createSuccessResponse<T>(data: T, message?: string): {
    success: boolean;
    data: T;
    message: string | undefined;
};
export declare const storage: {
    get: <T>(key: string) => T | null;
    set: <T>(key: string, value: T) => void;
    remove: (key: string) => void;
    clear: () => void;
};
export declare function debounce<T extends (...args: any[]) => any>(func: T, wait: number): (...args: Parameters<T>) => void;
export declare function throttle<T extends (...args: any[]) => any>(func: T, limit: number): (...args: Parameters<T>) => void;
export declare function deepClone<T>(obj: T): T;
export * from './betting';
