import React from 'react';
import { render, screen } from '@testing-library/react';
import Chip from '../Chip';

describe('Chip Component', () => {
  it('renders number correctly', () => {
    render(<Chip number={5} />);
    expect(screen.getByText('5')).toBeInTheDocument();
  });

  it('shows bet amount badge when betAmount > 0', () => {
    render(<Chip number={5} betAmount={50} />);
    expect(screen.getByText('₹50')).toBeInTheDocument();
  });

  it('does not show badge when betAmount is 0', () => {
    render(<Chip number={5} betAmount={0} />);
    expect(screen.queryByText('₹0')).not.toBeInTheDocument();
  });

  it('does not show badge when betAmount is undefined', () => {
    render(<Chip number={5} />);
    expect(screen.queryByText(/₹/)).not.toBeInTheDocument();
  });

  it('applies correct styling for red numbers', () => {
    render(<Chip number={1} betAmount={10} />);
    const chip = screen.getByRole('button');
    expect(chip).toHaveClass('bg-red-600');
  });

  it('applies correct styling for black numbers', () => {
    render(<Chip number={2} betAmount={10} />);
    const chip = screen.getByRole('button');
    expect(chip).toHaveClass('bg-gray-900');
  });

  it('shows distribution info when enabled', () => {
    render(
      <Chip 
        number={5} 
        betAmount={20} 
        showDistribution={true}
        distributionAmount={100}
        distributionCount={5}
      />
    );
    expect(screen.getByText('₹100')).toBeInTheDocument();
    expect(screen.getByText('5 bets')).toBeInTheDocument();
  });
});
