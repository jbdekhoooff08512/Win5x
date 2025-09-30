import React, { useState } from 'react';
import { motion } from 'framer-motion';
import ChipSelector from './ChipSelector';
import BettingBoard from './BettingBoard';

const BettingSystemTest: React.FC = () => {
  const [selectedChip, setSelectedChip] = useState<number>(20);
  const [bets, setBets] = useState<Record<string, number>>({});
  const [testLog, setTestLog] = useState<string[]>([]);

  const addLog = (message: string) => {
    setTestLog(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  const handleChipSelect = (amount: number) => {
    setSelectedChip(amount);
    addLog(`Chip selected: ₹${amount}`);
  };

  const handleCustomBetPlacement = (amount: number) => {
    addLog(`Custom bet amount selected: ₹${amount}`);
  };

  const handlePlaceBet = (betType: string, betValue: string | number) => {
    const key = `${betType}_${betValue}`;
    const currentAmount = bets[key] || 0;
    const newAmount = currentAmount + selectedChip;
    
    setBets(prev => ({
      ...prev,
      [key]: newAmount
    }));
    
    addLog(`Bet placed: ₹${selectedChip} on ${betType} ${betValue} (Total: ₹${newAmount})`);
  };

  const clearBets = () => {
    setBets({});
    setTestLog([]);
    addLog('All bets cleared');
  };

  const getNumberBetAmount = (number: number) => {
    return bets[`single_${number}`] || 0;
  };

  return (
    <div className="min-h-screen bg-gray-900 p-4">
      <div className="max-w-4xl mx-auto space-y-6">
        <h1 className="text-2xl font-bold text-white text-center mb-6">
          Betting System Test
        </h1>

        {/* Test Controls */}
        <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
          <div className="flex gap-4 mb-4">
            <button
              onClick={clearBets}
              className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
            >
              Clear All Bets
            </button>
            <div className="text-white">
              Selected Chip: ₹{selectedChip}
            </div>
          </div>
        </div>

        {/* Chip Selector */}
        <ChipSelector
          selectedChip={selectedChip}
          onChipSelect={handleChipSelect}
          onPlaceBet={handleCustomBetPlacement}
          disabled={false}
        />

        {/* Betting Board */}
        <BettingBoard
          selectedChip={selectedChip}
          bets={bets}
          onPlaceBet={handlePlaceBet}
          disabled={false}
          getNumberBetAmount={getNumberBetAmount}
        />

        {/* Current Bets Display */}
        <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
          <h3 className="text-lg font-semibold text-white mb-3">Current Bets</h3>
          {Object.keys(bets).length === 0 ? (
            <p className="text-gray-400">No bets placed</p>
          ) : (
            <div className="space-y-2">
              {Object.entries(bets).map(([key, amount]) => (
                <div key={key} className="flex justify-between text-white">
                  <span>{key}</span>
                  <span>₹{amount.toLocaleString()}</span>
                </div>
              ))}
              <div className="border-t border-gray-600 pt-2 mt-2">
                <div className="flex justify-between text-gold-400 font-bold">
                  <span>Total Bet</span>
                  <span>₹{Object.values(bets).reduce((sum, amount) => sum + amount, 0).toLocaleString()}</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Test Log */}
        <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
          <h3 className="text-lg font-semibold text-white mb-3">Test Log</h3>
          <div className="bg-gray-900 rounded p-3 max-h-60 overflow-y-auto">
            {testLog.length === 0 ? (
              <p className="text-gray-400">No activity yet</p>
            ) : (
              <div className="space-y-1">
                {testLog.map((log, index) => (
                  <div key={index} className="text-sm text-gray-300 font-mono">
                    {log}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Test Instructions */}
        <div className="bg-blue-900 rounded-lg p-4 border border-blue-700">
          <h3 className="text-lg font-semibold text-blue-300 mb-3">Test Instructions</h3>
          <div className="text-blue-200 space-y-2 text-sm">
            <p><strong>1. Predefined Chips:</strong> Click any chip (₹10-₹2000) to select it</p>
            <p><strong>2. Custom Input:</strong> Type a number between 10-5000 in the input field</p>
            <p><strong>3. Validation:</strong> Try typing invalid values (letters, numbers &lt; 10, &gt; 5000)</p>
            <p><strong>4. Bet Placement:</strong> Click on numbers or odd/even to place bets</p>
            <p><strong>5. Sync Test:</strong> Switch between chips and custom input to test synchronization</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BettingSystemTest;



