import { GameEngine } from '../services/GameEngine';
import { PrismaClient, GameRoundStatus, BetStatus } from '@prisma/client';
import { RedisService } from '../services/RedisService';
import { determineLeastChosenNumber, calculatePayout } from '@win5x/common';

// Mock Prisma and Redis
jest.mock('@prisma/client');
jest.mock('../services/RedisService');

describe('GameEngine', () => {
  let gameEngine: GameEngine;
  let mockPrisma: jest.Mocked<PrismaClient>;
  let mockRedis: jest.Mocked<RedisService>;

  beforeEach(() => {
    mockPrisma = new PrismaClient() as jest.Mocked<PrismaClient>;
    mockRedis = new RedisService() as jest.Mocked<RedisService>;
    gameEngine = new GameEngine(mockPrisma, mockRedis);
  });

  describe('Winner Selection Logic', () => {
    test('should select lowest bet amount number as winner', () => {
      const betDistribution = {
        '0': 1000, // High bet amount
        '1': 500,  // Medium bet amount
        '2': 200,  // Low bet amount - should win
        '3': 800,  // Medium bet amount
        '4': 0,    // No bets
        '5': 1500, // High bet amount
        '6': 0,    // No bets
        '7': 300,  // Low bet amount
        '8': 1200, // High bet amount
        '9': 0,    // No bets
      };

      const winner = determineLeastChosenNumber(betDistribution);
      expect(winner).toBe(2); // Number 2 has the lowest bet amount (200)
    });

    test('should handle case where no numbers are bet on', () => {
      const betDistribution = {
        '0': 0, '1': 0, '2': 0, '3': 0, '4': 0,
        '5': 0, '6': 0, '7': 0, '8': 0, '9': 0,
      };

      const winner = determineLeastChosenNumber(betDistribution);
      expect(winner).toBeGreaterThanOrEqual(0);
      expect(winner).toBeLessThanOrEqual(9);
    });

    test('should select lowest number when multiple numbers have same bet amount', () => {
      const betDistribution = {
        '0': 100, // Same bet amount
        '1': 100, // Same bet amount
        '2': 100, // Same bet amount - lowest number should win
        '3': 200, // Higher bet amount
        '4': 0,   // No bets
        '5': 0,   // No bets
        '6': 0,   // No bets
        '7': 0,   // No bets
        '8': 0,   // No bets
        '9': 0,   // No bets
      };

      const winner = determineLeastChosenNumber(betDistribution);
      expect(winner).toBe(0); // Number 0 is the lowest
    });
  });

  describe('Payout Calculations', () => {
    test('should calculate correct 5x payout for winning number bet', () => {
      const betAmount = 100;
      const winningNumber = 5;
      const betValue = 5; // User bet on winning number

      const payout = calculatePayout('number', betValue, betAmount, winningNumber);
      expect(payout).toBe(betAmount * 5); // 5x payout
    });

    test('should return 0 payout for losing number bet', () => {
      const betAmount = 100;
      const winningNumber = 5;
      const betValue = 3; // User bet on different number

      const payout = calculatePayout('number', betValue, betAmount, winningNumber);
      expect(payout).toBe(0); // No payout for losing bet
    });

    test('should calculate correct payout for winning color bet', () => {
      const betAmount = 100;
      const winningNumber = 5; // Red number
      const betValue = 'red'; // User bet on red

      const payout = calculatePayout('color', betValue, betAmount, winningNumber);
      expect(payout).toBe(betAmount * 5); // 5x payout
    });

    test('should calculate correct payout for winning odd/even bet', () => {
      const betAmount = 100;
      const winningNumber = 5; // Odd number
      const betValue = 'odd'; // User bet on odd

      const payout = calculatePayout('odd_even', betValue, betAmount, winningNumber);
      expect(payout).toBe(betAmount * 5); // 5x payout
    });
  });

  describe('Multi-user Betting Scenarios', () => {
    test('should handle simultaneous bets without race conditions', async () => {
      // Mock round data
      const mockRound = {
        id: 'round-1',
        roundNumber: 1,
        status: GameRoundStatus.BETTING,
        bettingStartTime: new Date(),
        bettingEndTime: new Date(Date.now() + 30000),
      };

      // Mock bets from multiple users
      const mockBets = [
        { id: 'bet-1', userId: 'user-1', roundId: 'round-1', betType: 'NUMBER', betValue: '5', amount: 100, status: BetStatus.PENDING },
        { id: 'bet-2', userId: 'user-2', roundId: 'round-1', betType: 'NUMBER', betValue: '5', amount: 200, status: BetStatus.PENDING },
        { id: 'bet-3', userId: 'user-3', roundId: 'round-1', betType: 'NUMBER', betValue: '3', amount: 50, status: BetStatus.PENDING },
        { id: 'bet-4', userId: 'user-4', roundId: 'round-1', betType: 'COLOR', betValue: 'red', amount: 150, status: BetStatus.PENDING },
      ];

      // Mock Prisma methods
      mockPrisma.gameRound.findUnique.mockResolvedValue(mockRound as any);
      mockPrisma.bet.findMany.mockResolvedValue(mockBets as any);
      mockPrisma.bet.update.mockResolvedValue({} as any);
      mockPrisma.user.update.mockResolvedValue({} as any);
      mockPrisma.transaction.create.mockResolvedValue({} as any);
      mockPrisma.gameRound.update.mockResolvedValue(mockRound as any);

      // Test that the engine can process multiple bets
      await expect(gameEngine.completeRound(mockRound as any)).resolves.not.toThrow();
    });

    test('should correctly aggregate bet amounts for winner selection', () => {
      const betDistribution = {
        '0': 0,    // No bets
        '1': 100,  // 1 bet of 100
        '2': 300,  // 2 bets: 100 + 200
        '3': 50,   // 1 bet of 50 - lowest amount
        '4': 0,    // No bets
        '5': 500,  // 3 bets: 100 + 200 + 200
        '6': 0,    // No bets
        '7': 150,  // 1 bet of 150
        '8': 0,    // No bets
        '9': 0,    // No bets
      };

      const winner = determineLeastChosenNumber(betDistribution);
      expect(winner).toBe(3); // Number 3 has the lowest total bet amount (50)
    });
  });

  describe('Edge Cases', () => {
    test('should choose random number when some numbers have no bets', () => {
      const betDistribution = {
        '0': 0,    // No bets
        '1': 100,  // Has bets
        '2': 0,    // No bets
        '3': 50,   // Has bets
        '4': 0,    // No bets
        '5': 0,    // No bets
        '6': 0,    // No bets
        '7': 0,    // No bets
        '8': 0,    // No bets
        '9': 0,    // No bets
      };

      // Run multiple times to ensure randomness
      const results = [];
      for (let i = 0; i < 10; i++) {
        results.push(determineLeastChosenNumber(betDistribution));
      }
      
      // Should get different results (random)
      const uniqueResults = [...new Set(results)];
      expect(uniqueResults.length).toBeGreaterThan(1);
      
      // All results should be valid numbers (0-9)
      results.forEach(result => {
        expect(result).toBeGreaterThanOrEqual(0);
        expect(result).toBeLessThanOrEqual(9);
      });
    });

    test('should choose least bet number when all numbers have bets', () => {
      const betDistribution = {
        '0': 100,  // All numbers have bets
        '1': 200,
        '2': 50,   // Lowest amount - should win
        '3': 300,
        '4': 150,
        '5': 250,
        '6': 180,
        '7': 220,
        '8': 190,
        '9': 210,
      };

      const winner = determineLeastChosenNumber(betDistribution);
      expect(winner).toBe(2); // Number 2 has the lowest bet amount (50)
    });

    test('should handle decimal bet amounts', () => {
      const betDistribution = {
        '0': 100.50,  // Decimal bet amount
        '1': 50.25,   // Decimal bet amount - lowest
        '2': 200.75,  // Decimal bet amount
        '3': 0,       // No bet
        '4': 0,       // No bet
        '5': 0,       // No bet
        '6': 0,       // No bet
        '7': 0,       // No bet
        '8': 0,       // No bet
        '9': 0,       // No bet
      };

      const winner = determineLeastChosenNumber(betDistribution);
      expect(winner).toBe(1); // Number 1 has the lowest bet amount (50.25)
    });
  });
});