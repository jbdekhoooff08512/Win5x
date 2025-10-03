import React from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Info, Shield, Award } from 'lucide-react';

const RulesPage: React.FC = () => {
  return (
    <div className="p-6 max-w-4xl mx-auto">
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
        <div className="text-center">
          <div className="h-16 w-16 bg-gradient-to-br from-gold-400 to-gold-600 rounded-full flex items-center justify-center mx-auto mb-4">
            <BookOpen className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">Game Rules</h1>
          <p className="text-gray-400">Learn how to play Win5x responsibly and effectively</p>
        </div>

        <div className="card">
          <div className="card-header">
            <h3 className="card-title flex items-center gap-2"><Info className="h-5 w-5 text-gold-400" /> Basics</h3>
          </div>
          <div className="card-content space-y-3 text-gray-300">
            <p>- Select a bet option (Number 0-9 or Parity Odd/Even) and enter your amount.</p>
            <p>- Each round has a betting window. Bets after the timer closes are rejected.</p>
            <p>- All payouts are 5x your bet amount for both Number and Parity bets.</p>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3 className="card-title flex items-center gap-2"><Shield className="h-5 w-5 text-gold-400" /> Fair Play</h3>
          </div>
          <div className="card-content space-y-3 text-gray-300">
            <p>- One account per player. Suspicious activity may lead to account review.</p>
            <p>- Outcomes are server-verified. Any disputes are handled by support.</p>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3 className="card-title flex items-center gap-2"><Award className="h-5 w-5 text-gold-400" /> Tips</h3>
          </div>
          <div className="card-content space-y-3 text-gray-300">
            <p>- Set a budget and stick to it. Avoid chasing losses.</p>
            <p>- Review your Betting History to understand patterns over time.</p>
            <p>- Play responsibly. 18+ only.</p>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default RulesPage;


