import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle, X, ArrowRight } from 'lucide-react';
import { useBettingWarning } from '../contexts/BettingWarningContext';

const BettingWarningModal: React.FC = () => {
  const {
    showWarning,
    cancelNavigation,
    confirmNavigation,
    currentRoundId
  } = useBettingWarning();

  return (
    <AnimatePresence>
      {showWarning && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
            onClick={cancelNavigation}
          />
          
          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: "spring", duration: 0.3 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4"
          >
            <div className="bg-gray-800 rounded-2xl shadow-2xl border border-gray-700 max-w-md w-full mx-4">
              {/* Header */}
              <div className="flex items-center justify-between p-6 border-b border-gray-700">
                <div className="flex items-center space-x-3">
                  <div className="p-2 bg-red-500/20 rounded-full">
                    <AlertTriangle className="h-6 w-6 text-red-400" />
                  </div>
                  <h3 className="text-xl font-bold text-white">
                    Active Bet Warning
                  </h3>
                </div>
                <button
                  onClick={cancelNavigation}
                  className="p-2 hover:bg-gray-700 rounded-full transition-colors"
                >
                  <X className="h-5 w-5 text-gray-400" />
                </button>
              </div>

              {/* Content */}
              <div className="p-6 space-y-4">
                <div className="text-gray-300 leading-relaxed">
                  <p className="mb-3">
                    You have an active bet in the current round. If you leave now, you will lose your bet amount and any potential winnings.
                  </p>
                  
                  {currentRoundId && (
                    <div className="bg-gray-700/50 rounded-lg p-3 border border-gray-600">
                      <p className="text-sm text-gray-400 mb-1">Round ID:</p>
                      <p className="text-gold-300 font-mono text-sm">{currentRoundId}</p>
                    </div>
                  )}
                  
                  <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3 mt-4">
                    <p className="text-red-300 text-sm font-medium">
                      ⚠️ Your bet will be forfeited if you navigate away from the game page.
                    </p>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex space-x-3 pt-4">
                  <button
                    onClick={cancelNavigation}
                    className="flex-1 px-4 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors"
                  >
                    Stay on Game
                  </button>
                  <button
                    onClick={confirmNavigation}
                    className="flex-1 px-4 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center space-x-2"
                  >
                    <span>Leave Anyway</span>
                    <ArrowRight className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Footer */}
              <div className="px-6 py-4 bg-gray-900/50 border-t border-gray-700 rounded-b-2xl">
                <p className="text-xs text-gray-500 text-center">
                  This warning helps prevent accidental loss of your betting money
                </p>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};

export default BettingWarningModal;
