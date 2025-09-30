import { getTotalBet, calculateIndividualBetAmounts, getExpandedBetDetails } from '../betCalculations';

describe('Bet Calculations', () => {
  describe('getTotalBet', () => {
    it('should calculate total bet from simple bets', () => {
      const bets = {
        'single_5': 10,
        'single_7': 20,
        'odd_odd': 15,
      };
      expect(getTotalBet(bets)).toBe(45);
    });

    it('should return 0 for empty bets', () => {
      expect(getTotalBet({})).toBe(0);
    });

    it('should ignore zero amounts', () => {
      const bets = {
        'single_5': 10,
        'single_7': 0,
        'odd_odd': 15,
      };
      expect(getTotalBet(bets)).toBe(25);
    });
  });

  describe('calculateIndividualBetAmounts', () => {
    it('should calculate individual amounts for single bets', () => {
      const bets = {
        'single_5': 10,
        'single_7': 20,
      };
      const result = calculateIndividualBetAmounts(bets);
      
      expect(result[5]).toBe(10);
      expect(result[7]).toBe(20);
      expect(result[0]).toBe(0);
      expect(result[1]).toBe(0);
    });

    it('should expand odd bets to all odd numbers', () => {
      const bets = {
        'odd_odd': 10,
      };
      const result = calculateIndividualBetAmounts(bets);
      
      // Odd numbers: [1, 3, 5, 7, 9]
      expect(result[1]).toBe(10);
      expect(result[3]).toBe(10);
      expect(result[5]).toBe(10);
      expect(result[7]).toBe(10);
      expect(result[9]).toBe(10);
      
      // Even numbers should be 0
      expect(result[0]).toBe(0);
      expect(result[2]).toBe(0);
      expect(result[4]).toBe(0);
      expect(result[6]).toBe(0);
      expect(result[8]).toBe(0);
    });

    it('should expand even bets to all even numbers', () => {
      const bets = {
        'even_even': 15,
      };
      const result = calculateIndividualBetAmounts(bets);
      
      // Even numbers: [0, 2, 4, 6, 8]
      expect(result[0]).toBe(15);
      expect(result[2]).toBe(15);
      expect(result[4]).toBe(15);
      expect(result[6]).toBe(15);
      expect(result[8]).toBe(15);
      
      // Odd numbers should be 0
      expect(result[1]).toBe(0);
      expect(result[3]).toBe(0);
      expect(result[5]).toBe(0);
      expect(result[7]).toBe(0);
      expect(result[9]).toBe(0);
    });

    it('should combine single and parity bets correctly', () => {
      const bets = {
        'single_5': 10,
        'odd_odd': 20,
        'even_even': 15,
      };
      const result = calculateIndividualBetAmounts(bets);
      
      // Number 5: single bet (10) + odd bet (20) = 30
      expect(result[5]).toBe(30);
      
      // Other odd numbers: only odd bet (20)
      expect(result[1]).toBe(20);
      expect(result[3]).toBe(20);
      expect(result[7]).toBe(20);
      expect(result[9]).toBe(20);
      
      // Even numbers: only even bet (15)
      expect(result[0]).toBe(15);
      expect(result[2]).toBe(15);
      expect(result[4]).toBe(15);
      expect(result[6]).toBe(15);
      expect(result[8]).toBe(15);
    });

    it('should handle multiple bets on same number', () => {
      const bets = {
        'single_5': 10,
        'odd_odd': 20,
        'single_5': 5, // This should overwrite the previous single_5
      };
      const result = calculateIndividualBetAmounts(bets);
      
      // Number 5: single bet (5) + odd bet (20) = 25
      expect(result[5]).toBe(25);
    });
  });

  describe('getExpandedBetDetails', () => {
    it('should return expanded bet details for single bets', () => {
      const bets = {
        'single_5': 10,
        'single_7': 20,
      };
      const result = getExpandedBetDetails(bets);
      
      expect(result).toHaveLength(2);
      expect(result).toContainEqual({ number: 5, amount: 10, source: 'single' });
      expect(result).toContainEqual({ number: 7, amount: 20, source: 'single' });
    });

    it('should return expanded bet details for parity bets', () => {
      const bets = {
        'odd_odd': 10,
      };
      const result = getExpandedBetDetails(bets);
      
      expect(result).toHaveLength(5); // 5 odd numbers
      expect(result).toContainEqual({ number: 1, amount: 10, source: 'odd' });
      expect(result).toContainEqual({ number: 3, amount: 10, source: 'odd' });
      expect(result).toContainEqual({ number: 5, amount: 10, source: 'odd' });
      expect(result).toContainEqual({ number: 7, amount: 10, source: 'odd' });
      expect(result).toContainEqual({ number: 9, amount: 10, source: 'odd' });
    });

    it('should return empty array for no bets', () => {
      const result = getExpandedBetDetails({});
      expect(result).toHaveLength(0);
    });
  });
});
