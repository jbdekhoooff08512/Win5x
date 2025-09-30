import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { vi } from 'vitest';
import ChipSelector from '../ChipSelector';

// Mock the common package
vi.mock('@win5x/common', () => ({
  GAME_CONFIG: {
    minBet: 10,
    maxBet: 5000,
  },
}));

describe('ChipSelector Component', () => {
  const mockOnChipSelect = vi.fn();
  const mockOnPlaceBet = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders predefined chips correctly', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    expect(screen.getByText('₹10')).toBeInTheDocument();
    expect(screen.getByText('₹20')).toBeInTheDocument();
    expect(screen.getByText('₹50')).toBeInTheDocument();
    expect(screen.getByText('₹100')).toBeInTheDocument();
  });

  it('handles predefined chip selection', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    fireEvent.click(screen.getByText('₹50'));
    expect(mockOnChipSelect).toHaveBeenCalledWith(50);
  });

  it('allows typing in custom amount input', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    fireEvent.change(input, { target: { value: '100' } });
    
    expect(input).toHaveValue('100');
  });

  it('validates custom amount input correctly', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    
    // Test valid amount
    fireEvent.change(input, { target: { value: '100' } });
    expect(screen.queryByText('Minimum bet is ₹10')).not.toBeInTheDocument();
    expect(screen.queryByText('Maximum bet is ₹5000')).not.toBeInTheDocument();

    // Test invalid amounts
    fireEvent.change(input, { target: { value: '5' } });
    expect(screen.getByText('Minimum bet is ₹10')).toBeInTheDocument();

    fireEvent.change(input, { target: { value: '5001' } });
    expect(screen.getByText('Maximum bet is ₹5000')).toBeInTheDocument();
  });

  it('handles custom bet placement correctly', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    const betButton = screen.getByText('Bet');

    // Test valid bet placement
    fireEvent.change(input, { target: { value: '100' } });
    fireEvent.click(betButton);

    expect(mockOnChipSelect).toHaveBeenCalledWith(100);
    expect(mockOnPlaceBet).toHaveBeenCalledWith(100);
  });

  it('disables bet button for invalid amounts', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    const betButton = screen.getByText('Bet');

    // Test with invalid amount
    fireEvent.change(input, { target: { value: '5' } });
    expect(betButton).toBeDisabled();

    // Test with empty input
    fireEvent.change(input, { target: { value: '' } });
    expect(betButton).toBeDisabled();
  });

  it('only allows numeric input', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    
    // Try to type letters
    fireEvent.change(input, { target: { value: 'abc' } });
    expect(input).toHaveValue('');

    // Try to type numbers with letters
    fireEvent.change(input, { target: { value: '100abc' } });
    expect(input).toHaveValue('100');
  });

  it('shows success message for valid custom amount', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    const betButton = screen.getByText('Bet');

    fireEvent.change(input, { target: { value: '100' } });
    fireEvent.click(betButton);

    expect(screen.getByText('Custom amount selected: ₹100')).toBeInTheDocument();
  });

  it('clears custom input when predefined chip is selected', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    
    // Type custom amount
    fireEvent.change(input, { target: { value: '100' } });
    expect(input).toHaveValue('100');

    // Click predefined chip
    fireEvent.click(screen.getByText('₹50'));
    expect(input).toHaveValue('');
  });

  it('handles disabled state correctly', () => {
    render(
      <ChipSelector
        selectedChip={20}
        onChipSelect={mockOnChipSelect}
        onPlaceBet={mockOnPlaceBet}
        disabled={true}
      />
    );

    const input = screen.getByPlaceholderText('Enter Amount (10 - 5000)');
    const betButton = screen.getByText('Bet');
    const chipButtons = screen.getAllByRole('button');

    expect(input).toBeDisabled();
    expect(betButton).toBeDisabled();
    chipButtons.forEach(button => {
      if (button.textContent?.includes('₹')) {
        expect(button).toBeDisabled();
      }
    });
  });
});
