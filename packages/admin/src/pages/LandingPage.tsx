import React from 'react';
import { Link } from 'react-router-dom';
import { 
  Shield, 
  BarChart3, 
  Users, 
  CreditCard, 
  Settings, 
  LogIn,
  ArrowRight,
  CheckCircle,
  Star
} from 'lucide-react';

const LandingPage: React.FC = () => {
  const features = [
    {
      icon: <BarChart3 className="h-8 w-8 text-primary-600" />,
      title: "Analytics Dashboard",
      description: "Comprehensive analytics and reporting tools to track platform performance"
    },
    {
      icon: <Users className="h-8 w-8 text-primary-600" />,
      title: "User Management",
      description: "Complete user management system with detailed user profiles and activity tracking"
    },
    {
      icon: <CreditCard className="h-8 w-8 text-primary-600" />,
      title: "Payment Management",
      description: "Secure payment processing and transaction management system"
    },
    {
      icon: <Settings className="h-8 w-8 text-primary-600" />,
      title: "System Settings",
      description: "Advanced configuration options and system diagnostics"
    }
  ];

  const stats = [
    { label: "Active Users", value: "10,000+" },
    { label: "Transactions", value: "₹50M+" },
    { label: "Success Rate", value: "99.9%" },
    { label: "Uptime", value: "24/7" }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-primary-100">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center">
              <Shield className="h-8 w-8 text-primary-600 mr-3" />
              <h1 className="text-2xl font-bold text-gray-900">Win5x Admin</h1>
            </div>
            <Link
              to="/login"
              className="btn btn-primary flex items-center"
            >
              <LogIn className="h-4 w-4 mr-2" />
              Admin Login
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            Win5x Admin Panel
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
            Comprehensive administration platform for managing your gaming platform. 
            Monitor users, transactions, analytics, and system performance with powerful tools.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              to="/login"
              className="btn btn-primary btn-lg flex items-center justify-center"
            >
              Access Admin Panel
              <ArrowRight className="h-5 w-5 ml-2" />
            </Link>
            <button className="btn btn-outline btn-lg">
              Learn More
            </button>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl font-bold text-primary-600 mb-2">
                  {stat.value}
                </div>
                <div className="text-gray-600">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              Powerful Admin Features
            </h2>
            <p className="text-lg text-gray-600">
              Everything you need to manage your gaming platform effectively
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <div key={index} className="card text-center">
                <div className="card-content">
                  <div className="flex justify-center mb-4">
                    {feature.icon}
                  </div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-3">
                    {feature.title}
                  </h3>
                  <p className="text-gray-600">
                    {feature.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Benefits Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-3xl font-bold text-gray-900 mb-6">
                Why Choose Win5x Admin?
              </h2>
              <div className="space-y-4">
                <div className="flex items-start">
                  <CheckCircle className="h-6 w-6 text-green-500 mr-3 mt-1" />
                  <div>
                    <h3 className="font-semibold text-gray-900">Real-time Monitoring</h3>
                    <p className="text-gray-600">Monitor platform activity and performance in real-time</p>
                  </div>
                </div>
                <div className="flex items-start">
                  <CheckCircle className="h-6 w-6 text-green-500 mr-3 mt-1" />
                  <div>
                    <h3 className="font-semibold text-gray-900">Secure Access</h3>
                    <p className="text-gray-600">Enterprise-grade security with role-based access control</p>
                  </div>
                </div>
                <div className="flex items-start">
                  <CheckCircle className="h-6 w-6 text-green-500 mr-3 mt-1" />
                  <div>
                    <h3 className="font-semibold text-gray-900">Comprehensive Analytics</h3>
                    <p className="text-gray-600">Detailed insights and reporting for data-driven decisions</p>
                  </div>
                </div>
                <div className="flex items-start">
                  <CheckCircle className="h-6 w-6 text-green-500 mr-3 mt-1" />
                  <div>
                    <h3 className="font-semibold text-gray-900">24/7 Support</h3>
                    <p className="text-gray-600">Round-the-clock technical support and maintenance</p>
                  </div>
                </div>
              </div>
            </div>
            <div className="text-center">
              <div className="bg-gradient-to-br from-primary-100 to-primary-200 rounded-2xl p-8">
                <Star className="h-16 w-16 text-primary-600 mx-auto mb-4" />
                <h3 className="text-2xl font-bold text-gray-900 mb-4">
                  Trusted by Thousands
                </h3>
                <p className="text-gray-600 mb-6">
                  Join thousands of administrators who trust Win5x for their platform management needs.
                </p>
                <Link
                  to="/login"
                  className="btn btn-primary"
                >
                  Get Started Today
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <div className="flex items-center mb-4">
                <Shield className="h-6 w-6 text-primary-400 mr-2" />
                <span className="text-lg font-semibold">Win5x Admin</span>
              </div>
              <p className="text-gray-400">
                Professional administration platform for gaming platforms.
              </p>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
              <div className="space-y-2">
                <Link to="/login" className="block text-gray-400 hover:text-white">
                  Admin Login
                </Link>
                <a href="#" className="block text-gray-400 hover:text-white">
                  Documentation
                </a>
                <a href="#" className="block text-gray-400 hover:text-white">
                  Support
                </a>
              </div>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4">Contact</h3>
              <div className="space-y-2 text-gray-400">
                <p>Email: admin@win5x.com</p>
                <p>Phone: +91 12345 67890</p>
                <p>Support: 24/7 Available</p>
              </div>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
            <p>&copy; 2024 Win5x Admin. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;
