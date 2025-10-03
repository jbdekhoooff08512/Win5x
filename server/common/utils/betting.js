"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BET_TYPES = void 0;
exports.expandBet = expandBet;
exports.calculatePotentialPayout = calculatePotentialPayout;
exports.getCoveredNumbers = getCoveredNumbers;
exports.calculateBetsPayout = calculateBetsPayout;
const constants_1 = require("../constants");
exports.BET_TYPES = {
    SINGLE: 'single',
    ODD: 'odd',
    EVEN: 'even',
};
/**
 * Expands a bet according to the betting rules
 * @param betType - Type of bet (single, odd, even)
 * @param number - Number for single bets (ignored for odd/even)
 * @param amount - Amount to bet
 * @returns Expanded bet information
 */
function expandBet(betType, number, amount) {
    // Validate minimum bet amount
    if (amount < constants_1.GAME_CONFIG.minBet) {
        throw new Error(`Minimum bet amount is ₹${constants_1.GAME_CONFIG.minBet}`);
    }
    // Validate maximum bet amount
    if (amount > constants_1.GAME_CONFIG.maxBet) {
        throw new Error(`Maximum bet amount is ₹${constants_1.GAME_CONFIG.maxBet}`);
    }
    switch (betType) {
        case exports.BET_TYPES.SINGLE:
            return {
                totalBet: amount,
                bets: [{ number, bet: amount }],
                betType: exports.BET_TYPES.SINGLE,
                originalAmount: amount,
            };
        case exports.BET_TYPES.ODD:
            return {
                totalBet: amount * constants_1.GAME_CONFIG.oddNumbers.length,
                bets: constants_1.GAME_CONFIG.oddNumbers.map(num => ({ number: num, bet: amount })),
                betType: exports.BET_TYPES.ODD,
                originalAmount: amount,
            };
        case exports.BET_TYPES.EVEN:
            return {
                totalBet: amount * constants_1.GAME_CONFIG.evenNumbers.length,
                bets: constants_1.GAME_CONFIG.evenNumbers.map(num => ({ number: num, bet: amount })),
                betType: exports.BET_TYPES.EVEN,
                originalAmount: amount,
            };
        default:
            throw new Error(`Invalid bet type: ${betType}`);
    }
}
/**
 * Calculates the potential payout for a winning number
 * @param betType - Type of bet
 * @param winningNumber - The winning number
 * @param amount - Original bet amount
 * @returns Potential payout amount
 */
function calculatePotentialPayout(betType, winningNumber, amount) {
    switch (betType) {
        case exports.BET_TYPES.SINGLE:
            return amount * constants_1.GAME_CONFIG.payoutMultiplier;
        case exports.BET_TYPES.ODD:
            return constants_1.GAME_CONFIG.oddNumbers.includes(winningNumber)
                ? amount * constants_1.GAME_CONFIG.payoutMultiplier
                : 0;
        case exports.BET_TYPES.EVEN:
            return constants_1.GAME_CONFIG.evenNumbers.includes(winningNumber)
                ? amount * constants_1.GAME_CONFIG.payoutMultiplier
                : 0;
        default:
            return 0;
    }
}
/**
 * Gets the numbers that would be covered by a bet type
 * @param betType - Type of bet
 * @param number - Number for single bets
 * @returns Array of numbers that would be covered
 */
function getCoveredNumbers(betType, number) {
    switch (betType) {
        case exports.BET_TYPES.SINGLE:
            return number !== undefined ? [number] : [];
        case exports.BET_TYPES.ODD:
            return [...constants_1.GAME_CONFIG.oddNumbers];
        case exports.BET_TYPES.EVEN:
            return [...constants_1.GAME_CONFIG.evenNumbers];
        default:
            return [];
    }
}
/**
 * Calculates payout for multiple bets
 * @param bets - Array of expanded bets
 * @param winningNumber - The winning number
 * @returns Total payout amount
 */
function calculateBetsPayout(bets, winningNumber) {
    return bets.reduce((total, bet) => {
        return total + (bet.number === winningNumber ? bet.bet * constants_1.GAME_CONFIG.payoutMultiplier : 0);
    }, 0);
}
