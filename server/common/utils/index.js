"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.storage = void 0;
exports.getNumberColor = getNumberColor;
exports.isNumberOdd = isNumberOdd;
exports.calculatePayout = calculatePayout;
exports.calculateCashbackAmount = calculateCashbackAmount;
exports.get_winner = get_winner;
exports.determineLeastChosenNumber = determineLeastChosenNumber;
exports.formatTimeRemaining = formatTimeRemaining;
exports.getTimeAgo = getTimeAgo;
exports.isDateToday = isDateToday;
exports.getDateRange = getDateRange;
exports.formatCurrency = formatCurrency;
exports.formatNumber = formatNumber;
exports.calculatePercentage = calculatePercentage;
exports.roundToDecimal = roundToDecimal;
exports.generateId = generateId;
exports.capitalizeFirst = capitalizeFirst;
exports.truncateText = truncateText;
exports.shuffleArray = shuffleArray;
exports.groupBy = groupBy;
exports.isValidEmail = isValidEmail;
exports.isValidUsername = isValidUsername;
exports.sanitizeInput = sanitizeInput;
exports.createErrorResponse = createErrorResponse;
exports.createSuccessResponse = createSuccessResponse;
exports.debounce = debounce;
exports.throttle = throttle;
exports.deepClone = deepClone;
const constants_1 = require("../constants");
// Game Utilities
function getNumberColor(number) {
    return constants_1.NUMBER_COLORS[number] || 'black';
}
function isNumberOdd(number) {
    return number % 2 === 1;
}
function calculatePayout(betType, betValue, amount, winningNumber) {
    const multiplier = 5; // 5x payout for all bet types
    switch (betType) {
        case 'number':
            return betValue === winningNumber ? amount * multiplier : 0;
        case 'odd_even':
            const isWinningOdd = isNumberOdd(winningNumber);
            const betIsOdd = betValue === 'odd';
            return (isWinningOdd === betIsOdd) ? amount * multiplier : 0;
        default:
            return 0;
    }
}
function calculateCashbackAmount(betAmount) {
    // 10% cashback on losing bets
    return parseFloat((betAmount * 0.10).toFixed(2));
}
/**
 * Admin-safe winner determination function
 * @param bets - Array or object of bet amounts for numbers 0-9
 * @returns The winning number (0-9)
 */
function get_winner(bets) {
    // Convert to array format if object is provided
    let betArray;
    if (Array.isArray(bets)) {
        betArray = bets;
    }
    else {
        // Convert object to array (assuming keys are '0', '1', ..., '9')
        betArray = [];
        for (let i = 0; i <= 9; i++) {
            betArray[i] = bets[i.toString()] || 0;
        }
    }
    // Validate input size
    if (betArray.length !== 10) {
        throw new Error('Bets array must have exactly 10 elements (indexes 0-9)');
    }
    // Rule 1: If all bet amounts are zero → return a random number between 0–9
    const allZero = betArray.every(amount => amount === 0);
    if (allZero) {
        return Math.floor(Math.random() * 10);
    }
    // Rule 2-5: Find the number with the lowest bet amount
    let minAmount = betArray[0];
    let winner = 0;
    for (let i = 1; i < 10; i++) {
        if (betArray[i] < minAmount) {
            minAmount = betArray[i];
            winner = i;
        }
    }
    // Check if all amounts are equal (constant betting)
    const allEqual = betArray.every(amount => amount === minAmount);
    if (allEqual) {
        // If all amounts are equal, return a random number for fairness
        return Math.floor(Math.random() * 10);
    }
    return winner;
}
function determineLeastChosenNumber(betDistribution) {
    // Convert to array format for get_winner function
    const betArray = [];
    for (let i = 0; i <= 9; i++) {
        betArray[i] = betDistribution[i.toString()] || 0;
    }
    return get_winner(betArray);
}
// Time Utilities
function formatTimeRemaining(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    if (minutes > 0) {
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }
    return `${remainingSeconds}s`;
}
function getTimeAgo(date) {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    if (diffMs < constants_1.TIME_CONSTANTS.ONE_MINUTE) {
        return 'just now';
    }
    else if (diffMs < constants_1.TIME_CONSTANTS.ONE_HOUR) {
        const minutes = Math.floor(diffMs / constants_1.TIME_CONSTANTS.ONE_MINUTE);
        return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
    }
    else if (diffMs < constants_1.TIME_CONSTANTS.ONE_DAY) {
        const hours = Math.floor(diffMs / constants_1.TIME_CONSTANTS.ONE_HOUR);
        return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    }
    else if (diffMs < constants_1.TIME_CONSTANTS.ONE_WEEK) {
        const days = Math.floor(diffMs / constants_1.TIME_CONSTANTS.ONE_DAY);
        return `${days} day${days > 1 ? 's' : ''} ago`;
    }
    else {
        return date.toLocaleDateString();
    }
}
function isDateToday(date) {
    const today = new Date();
    return date.toDateString() === today.toDateString();
}
function getDateRange(period) {
    const now = new Date();
    const end = new Date(now);
    end.setHours(23, 59, 59, 999);
    const start = new Date(now);
    start.setHours(0, 0, 0, 0);
    switch (period) {
        case 'daily':
            // Already set to today
            break;
        case 'weekly':
            start.setDate(now.getDate() - now.getDay()); // Start of week (Sunday)
            break;
        case 'monthly':
            start.setDate(1); // Start of month
            break;
    }
    return { start, end };
}
// Number Utilities
function formatCurrency(amount, currency = '₹') {
    // Handle undefined, null, or NaN values safely
    if (amount === undefined || amount === null || isNaN(Number(amount))) {
        return `${currency}0.00`;
    }
    const numAmount = Number(amount);
    if (isNaN(numAmount)) {
        return `${currency}0.00`;
    }
    return numAmount.toLocaleString("en-IN", {
        style: "currency",
        currency: "INR",
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
}
function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    }
    else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}
function calculatePercentage(value, total) {
    if (total === 0)
        return 0;
    return Math.round((value / total) * 100);
}
function roundToDecimal(num, decimals = 2) {
    return Math.round(num * Math.pow(10, decimals)) / Math.pow(10, decimals);
}
// String Utilities
function generateId() {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
}
function capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}
function truncateText(text, maxLength) {
    if (text.length <= maxLength)
        return text;
    return text.substring(0, maxLength - 3) + '...';
}
// Array Utilities
function shuffleArray(array) {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
}
function groupBy(array, keyFn) {
    return array.reduce((groups, item) => {
        const key = keyFn(item);
        if (!groups[key]) {
            groups[key] = [];
        }
        groups[key].push(item);
        return groups;
    }, {});
}
// Validation Utilities
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}
function isValidUsername(username) {
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    return username.length >= 3 && username.length <= 20 && usernameRegex.test(username);
}
function sanitizeInput(input) {
    return input.trim().replace(/[<>]/g, '');
}
// Error Utilities
function createErrorResponse(message, code, statusCode = 400) {
    return {
        success: false,
        error: message,
        code,
        statusCode,
    };
}
function createSuccessResponse(data, message) {
    return {
        success: true,
        data,
        message,
    };
}
// Local Storage Utilities (for frontend)
exports.storage = {
    get: (key) => {
        if (typeof window === 'undefined')
            return null;
        try {
            const item = window.localStorage.getItem(key);
            return item ? JSON.parse(item) : null;
        }
        catch {
            return null;
        }
    },
    set: (key, value) => {
        if (typeof window === 'undefined')
            return;
        try {
            window.localStorage.setItem(key, JSON.stringify(value));
        }
        catch {
            // Handle storage quota exceeded or other errors
        }
    },
    remove: (key) => {
        if (typeof window === 'undefined')
            return;
        window.localStorage.removeItem(key);
    },
    clear: () => {
        if (typeof window === 'undefined')
            return;
        window.localStorage.clear();
    },
};
// Debounce Utility
function debounce(func, wait) {
    let timeout;
    return (...args) => {
        clearTimeout(timeout);
        timeout = setTimeout(() => func(...args), wait);
    };
}
// Throttle Utility
function throttle(func, limit) {
    let inThrottle;
    return (...args) => {
        if (!inThrottle) {
            func(...args);
            inThrottle = true;
            setTimeout(() => (inThrottle = false), limit);
        }
    };
}
// Deep Clone Utility
function deepClone(obj) {
    if (obj === null || typeof obj !== 'object')
        return obj;
    if (obj instanceof Date)
        return new Date(obj.getTime());
    if (obj instanceof Array)
        return obj.map(item => deepClone(item));
    if (typeof obj === 'object') {
        const copy = {};
        Object.keys(obj).forEach(key => {
            copy[key] = deepClone(obj[key]);
        });
        return copy;
    }
    return obj;
}
// Betting Utilities
__exportStar(require("./betting"), exports);
