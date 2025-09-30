import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { vi } from 'vitest';
import GameWheel from '../../components/GameWheel';

// Mock framer-motion
vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
  },
}));

describe('GameWheel Component', () => {
  test('renders wheel with all numbers', () => {
    render(
      <GameWheel 
        gamePhase="betting"
        winningNumber={null} 
      />
    );

    // Check if all numbers 0-9 are rendered
    for (let i = 0; i <= 9; i++) {
      expect(screen.getByText(i.toString())).toBeInTheDocument();
    }
  });

  test('displays winning number when provided', () => {
    render(
      <GameWheel 
        gamePhase="result"
        winningNumber={7} 
      />
    );

    expect(screen.getByText('Winner: 7')).toBeInTheDocument();
  });

  test('shows spinning state correctly', () => {
    const { rerender } = render(
      <GameWheel 
        gamePhase="spinning"
        winningNumber={5} 
      />
    );

    // When spinning, winning number should not be displayed yet
    expect(screen.queryByText('Winner: 5')).not.toBeInTheDocument();

    // After spinning stops
    rerender(
      <GameWheel 
        gamePhase="result"
        winningNumber={5} 
      />
    );

    expect(screen.getByText('Winner: 5')).toBeInTheDocument();
  });

  test('calls onSpinComplete when spin animation finishes', (done) => {
    const mockOnSpinComplete = vi.fn();
    
    render(
      <GameWheel 
        gamePhase="spinning"
        winningNumber={3} 
        onSpinComplete={mockOnSpinComplete}
      />
    );

    // The component should call onSpinComplete after 11 seconds (spinning duration)
    setTimeout(() => {
      expect(mockOnSpinComplete).toHaveBeenCalled();
      done();
    }, 11100);
  });

  test('applies correct colors to numbers', () => {
    render(
      <GameWheel 
        gamePhase="betting"
        winningNumber={null} 
      />
    );

    // Numbers 1, 3, 5, 7, 9 should be red (odd numbers)
    // Numbers 0, 2, 4, 6, 8 should be black (even numbers)
    
    // This test would need to check the computed styles or class names
    // depending on how colors are applied in your implementation
  });

  test('renders internal pointer at top of wheel', () => {
    render(
      <GameWheel 
        gamePhase="betting"
        winningNumber={null} 
      />
    );

    // Check if the internal pointer element exists
    const pointerElement = document.querySelector('.wheel-pointer-internal');
    expect(pointerElement).toBeInTheDocument();
  });

  test('highlights winning segment during result phase', () => {
    render(
      <GameWheel 
        gamePhase="result"
        winningNumber={5} 
      />
    );

    // Check if the winning segment has highlighting classes
    const winningSegment = document.querySelector('[data-testid="segment-5"]');
    expect(winningSegment).toBeInTheDocument();
    
    // The highlighting classes are applied to the segment background div
    const segmentBackground = winningSegment?.querySelector('div');
    expect(segmentBackground).toHaveClass('ring-4', 'ring-gold-300');
  });

  test('clears highlight when not in result phase', () => {
    const { rerender } = render(
      <GameWheel 
        gamePhase="result"
        winningNumber={3} 
      />
    );

    // Move to betting phase
    rerender(
      <GameWheel 
        gamePhase="betting"
        winningNumber={null} 
      />
    );

    // Highlight should be cleared
    const segment = document.querySelector('[data-testid="segment-3"]');
    expect(segment).toBeInTheDocument();
    
    const segmentBackground = segment?.querySelector('div');
    expect(segmentBackground).not.toHaveClass('ring-4', 'ring-gold-300');
  });
});