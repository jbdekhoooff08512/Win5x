export declare const BET_TYPES: {
    readonly SINGLE: "single";
    readonly ODD: "odd";
    readonly EVEN: "even";
};
export interface ExpandedBet {
    number: number;
    bet: number;
}
export interface BetExpansion {
    totalBet: number;
    bets: ExpandedBet[];
    betType: string;
    originalAmount: number;
}
/**
 * Expands a bet according to the betting rules
 * @param betType - Type of bet (single, odd, even)
 * @param number - Number for single bets (ignored for odd/even)
 * @param amount - Amount to bet
 * @returns Expanded bet information
 */
export declare function expandBet(betType: string, number: number, amount: number): BetExpansion;
/**
 * Calculates the potential payout for a winning number
 * @param betType - Type of bet
 * @param winningNumber - The winning number
 * @param amount - Original bet amount
 * @returns Potential payout amount
 */
export declare function calculatePotentialPayout(betType: string, winningNumber: number, amount: number): number;
/**
 * Gets the numbers that would be covered by a bet type
 * @param betType - Type of bet
 * @param number - Number for single bets
 * @returns Array of numbers that would be covered
 */
export declare function getCoveredNumbers(betType: string, number?: number): number[];
/**
 * Calculates payout for multiple bets
 * @param bets - Array of expanded bets
 * @param winningNumber - The winning number
 * @returns Total payout amount
 */
export declare function calculateBetsPayout(bets: ExpandedBet[], winningNumber: number): number;
