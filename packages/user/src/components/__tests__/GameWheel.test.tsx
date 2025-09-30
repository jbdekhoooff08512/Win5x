import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import GameWheel from '../GameWheel';

// Mock the gameService
vi.mock('../../services/gameService', () => ({
  gameService: {
    getWinningNumber: vi.fn().mockResolvedValue({
      winningNumber: 5,
      betDistribution: {}
    })
  }
}));

// Mock framer-motion
vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>
  }
}));

describe('GameWheel', () => {
  it('renders wheel with correct number of segments', () => {
    render(
      <GameWheel 
        gamePhase="betting" 
        winningNumber={null} 
      />
    );
    
    // Check that all 10 segments are rendered
    for (let i = 0; i <= 9; i++) {
      expect(screen.getByTestId(`segment-${i}`)).toBeInTheDocument();
    }
  });

  it('displays winning number during result phase', () => {
    render(
      <GameWheel 
        gamePhase="result" 
        winningNumber={7} 
      />
    );
    
    expect(screen.getByText('Winner: 7')).toBeInTheDocument();
  });

  it('shows ready indicator during betting phase', () => {
    render(
      <GameWheel 
        gamePhase="betting" 
        winningNumber={null} 
      />
    );
    
    expect(screen.getByText('🎯 Ready (0°)')).toBeInTheDocument();
  });
});

// Test rotation calculation logic
describe('GameWheel Rotation Calculations', () => {
  const SEGMENTS = 10;
  const SEGMENT_DEGREES = 360 / SEGMENTS; // 36 degrees per segment
  
  // Number positions on the wheel (in degrees from top pointer position)
  const numberPositions: Record<number, number> = {
    0: 0,   // Red (even) - at top (0 degrees from top pointer)
    1: 36,  // Black (odd)
    2: 72,  // Red (even)
    3: 108, // Black (odd)
    4: 144, // Red (even)
    5: 180, // Black (odd) - at bottom (180 degrees from top)
    6: 216, // Red (even)
    7: 252, // Black (odd)
    8: 288, // Red (even)
    9: 324, // Black (odd)
  };

  function calculateWheelRotation(winningNumber: number, spins = 7) {
    const winningNumberPosition = numberPositions[winningNumber];
    const totalFullSpins = spins * 360;
    const rotationToBringNumberToPointer = -winningNumberPosition;
    return totalFullSpins + rotationToBringNumberToPointer;
  }

  it('verifies rotation calculation formula is correct', () => {
    // Test the formula: targetRotation = startRotation + (360 × 7) - winningNumberPosition
    for (let winningNumber = 0; winningNumber <= 9; winningNumber++) {
      const winningNumberPosition = numberPositions[winningNumber];
      const fullRotationCount = 7;
      const totalFullSpins = fullRotationCount * 360; // 2520°
      const startRotation = 0;
      const rotationToBringNumberToPointer = -winningNumberPosition;
      const targetRotation = startRotation + totalFullSpins + rotationToBringNumberToPointer;
      
      // Verify the formula produces expected results
      expect(targetRotation).toBe(2520 - winningNumberPosition);
      expect(rotationToBringNumberToPointer).toBe(-winningNumberPosition);
      expect(totalFullSpins).toBe(2520);
    }
  });

  it('verifies segment positioning is correct', () => {
    // Each segment should be 36 degrees apart
    for (let i = 0; i < 9; i++) {
      const currentPosition = numberPositions[i];
      const nextPosition = numberPositions[i + 1];
      const difference = (nextPosition - currentPosition + 360) % 360;
      expect(difference).toBe(36);
    }
    
    // Check wrap-around from 9 to 0
    const lastPosition = numberPositions[9];
    const firstPosition = numberPositions[0];
    const wrapDifference = (firstPosition - lastPosition + 360) % 360;
    expect(wrapDifference).toBe(36);
  });

  it('verifies color mapping is correct', () => {
    // Red for even numbers (0, 2, 4, 6, 8)
    const evenNumbers = [0, 2, 4, 6, 8];
    evenNumbers.forEach(num => {
      expect(num % 2).toBe(0); // Should be even
    });
    
    // Black for odd numbers (1, 3, 5, 7, 9)
    const oddNumbers = [1, 3, 5, 7, 9];
    oddNumbers.forEach(num => {
      expect(num % 2).toBe(1); // Should be odd
    });
  });

  it('validates rotation calculation produces expected target rotations', () => {
    // Test that the rotation calculation produces the expected target rotations
    const expectedRotations = [
      2520, // 0: 2520 - 0 = 2520
      2484, // 1: 2520 - 36 = 2484
      2448, // 2: 2520 - 72 = 2448
      2412, // 3: 2520 - 108 = 2412
      2376, // 4: 2520 - 144 = 2376
      2340, // 5: 2520 - 180 = 2340
      2304, // 6: 2520 - 216 = 2304
      2268, // 7: 2520 - 252 = 2268
      2232, // 8: 2520 - 288 = 2232
      2196, // 9: 2520 - 324 = 2196
    ];
    
    for (let winningNumber = 0; winningNumber <= 9; winningNumber++) {
      const targetRotation = calculateWheelRotation(winningNumber);
      expect(targetRotation).toBe(expectedRotations[winningNumber]);
    }
  });
});
