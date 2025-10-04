import React from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  Gamepad2, 
  Trophy, 
  Shield, 
  Zap, 
  Users, 
  Star,
  ArrowRight,
  Play,
  LogIn,
  UserPlus,
  Crown,
  Coins,
  Target
} from 'lucide-react';

const LandingPage: React.FC = () => {
  const features = [
    {
      icon: Zap,
      title: "Lightning Fast",
      description: "Real-time betting with instant results"
    },
    {
      icon: Shield,
      title: "Secure & Fair",
      description: "Provably fair gaming with encrypted results"
    },
    {
      icon: Trophy,
      title: "Big Wins",
      description: "5x multiplier on all winning bets"
    },
    {
      icon: Users,
      title: "Live Community",
      description: "Play with thousands of players worldwide"
    }
  ];

  const stats = [
    { number: "10,000+", label: "Active Players" },
    { number: "₹50M+", label: "Won Daily" },
    { number: "99.9%", label: "Uptime" },
    { number: "24/7", label: "Support" }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      {/* Navigation */}
      <nav className="relative z-10 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <motion.div 
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            className="flex items-center space-x-3"
          >
            <div className="h-10 w-10 bg-gradient-to-br from-gold-400 to-gold-600 rounded-lg flex items-center justify-center">
              <Gamepad2 className="h-6 w-6 text-white" />
            </div>
            <span className="text-2xl font-bold text-white">Win5x</span>
          </motion.div>
          
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="flex items-center space-x-4"
          >
            <Link
              to="/login"
              className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
            >
              Login
            </Link>
            <Link
              to="/register"
              className="px-6 py-2 bg-gradient-to-r from-gold-500 to-gold-600 text-white rounded-lg hover:from-gold-600 hover:to-gold-700 transition-all duration-200 flex items-center space-x-2"
            >
              <UserPlus className="h-4 w-4" />
              <span>Sign Up</span>
            </Link>
          </motion.div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 py-20">
          <div className="text-center">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
              className="mb-8"
            >
              <h1 className="text-5xl md:text-7xl font-bold text-white mb-6">
                Win <span className="text-transparent bg-clip-text bg-gradient-to-r from-gold-400 to-gold-600">5x</span> Your Bet
              </h1>
              <p className="text-xl md:text-2xl text-gray-300 mb-8 max-w-3xl mx-auto">
                Experience the thrill of real-time wheel spinning with the fairest gaming system. 
                Place your bets and watch the wheel spin to victory!
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-6"
            >
              <Link
                to="/register"
                className="px-8 py-4 bg-gradient-to-r from-gold-500 to-gold-600 text-white rounded-xl hover:from-gold-600 hover:to-gold-700 transition-all duration-200 flex items-center space-x-3 text-lg font-semibold shadow-2xl hover:shadow-gold-500/25"
              >
                <Play className="h-6 w-6" />
                <span>Start Playing</span>
                <ArrowRight className="h-5 w-5" />
              </Link>
              
              <Link
                to="/login"
                className="px-8 py-4 border-2 border-gold-500 text-gold-400 rounded-xl hover:bg-gold-500 hover:text-white transition-all duration-200 flex items-center space-x-3 text-lg font-semibold"
              >
                <LogIn className="h-6 w-6" />
                <span>Login</span>
              </Link>
            </motion.div>
          </div>
        </div>

        {/* Animated Background Elements */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute -top-40 -right-40 w-80 h-80 bg-gold-500/10 rounded-full blur-3xl"></div>
          <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-gold-500/10 rounded-full blur-3xl"></div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 bg-gray-800/50">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="grid grid-cols-2 md:grid-cols-4 gap-8"
          >
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl md:text-4xl font-bold text-gold-400 mb-2">
                  {stat.number}
                </div>
                <div className="text-gray-300">
                  {stat.label}
                </div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Why Choose Win5x?
            </h2>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto">
              Experience the ultimate wheel spinning gaming platform with cutting-edge features
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: index * 0.1 }}
                className="bg-gray-800/50 backdrop-blur-sm rounded-xl p-6 border border-gray-700 hover:border-gold-500/50 transition-all duration-300"
              >
                <div className="h-12 w-12 bg-gradient-to-br from-gold-400 to-gold-600 rounded-lg flex items-center justify-center mb-4">
                  <feature.icon className="h-6 w-6 text-white" />
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-300">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* How to Play Section */}
      <section className="py-20 bg-gray-800/30">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              How to Play
            </h2>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto">
              Simple steps to start winning big
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              {
                step: "01",
                title: "Sign Up",
                description: "Create your account in seconds",
                icon: UserPlus
              },
              {
                step: "02", 
                title: "Deposit",
                description: "Add funds to your wallet",
                icon: Coins
              },
              {
                step: "03",
                title: "Play & Win",
                description: "Place bets and win 5x your money",
                icon: Target
              }
            ].map((step, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: index * 0.2 }}
                className="text-center"
              >
                <div className="relative mb-6">
                  <div className="h-20 w-20 bg-gradient-to-br from-gold-400 to-gold-600 rounded-full flex items-center justify-center mx-auto mb-4">
                    <step.icon className="h-8 w-8 text-white" />
                  </div>
                  <div className="absolute -top-2 -right-2 h-8 w-8 bg-white rounded-full flex items-center justify-center">
                    <span className="text-sm font-bold text-gray-900">{step.step}</span>
                  </div>
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">
                  {step.title}
                </h3>
                <p className="text-gray-300">
                  {step.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="bg-gradient-to-r from-gold-500/10 to-gold-600/10 rounded-2xl p-12 border border-gold-500/20">
              <Crown className="h-16 w-16 text-gold-400 mx-auto mb-6" />
              <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
                Ready to Win Big?
              </h2>
              <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
                Join thousands of players and start your winning streak today. 
                The wheel is waiting for you!
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-6">
                <Link
                  to="/register"
                  className="px-8 py-4 bg-gradient-to-r from-gold-500 to-gold-600 text-white rounded-xl hover:from-gold-600 hover:to-gold-700 transition-all duration-200 flex items-center space-x-3 text-lg font-semibold shadow-2xl hover:shadow-gold-500/25"
                >
                  <Play className="h-6 w-6" />
                  <span>Get Started Now</span>
                  <ArrowRight className="h-5 w-5" />
                </Link>
                
                <Link
                  to="/login"
                  className="px-8 py-4 border-2 border-gold-500 text-gold-400 rounded-xl hover:bg-gold-500 hover:text-white transition-all duration-200 flex items-center space-x-3 text-lg font-semibold"
                >
                  <LogIn className="h-6 w-6" />
                  <span>Already a Player?</span>
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-col md:flex-row items-center justify-between">
            <div className="flex items-center space-x-3 mb-4 md:mb-0">
              <div className="h-8 w-8 bg-gradient-to-br from-gold-400 to-gold-600 rounded-lg flex items-center justify-center">
                <Gamepad2 className="h-5 w-5 text-white" />
              </div>
              <span className="text-xl font-bold text-white">Win5x</span>
            </div>
            
            <div className="flex items-center space-x-6 text-gray-400">
              <Link to="/rules" className="hover:text-white transition-colors">
                Rules
              </Link>
              <Link to="/about" className="hover:text-white transition-colors">
                About
              </Link>
              <Link to="/support" className="hover:text-white transition-colors">
                Support
              </Link>
            </div>
          </div>
          
          <div className="mt-8 pt-8 border-t border-gray-700 text-center text-gray-400">
            <p>&copy; 2024 Win5x. All rights reserved. Play responsibly.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;



