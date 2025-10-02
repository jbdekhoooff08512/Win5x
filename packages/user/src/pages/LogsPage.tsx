import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Clock, LogIn, LogOut, Calendar, Filter } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useQuery } from '@tanstack/react-query';
import { userService } from '../services/userService';
import LoadingSpinner from '../components/LoadingSpinner';

interface LogEntry {
  action: 'login' | 'logout';
  timestamp: Date;
  ipAddress?: string;
  userAgent?: string;
}

const LogsPage: React.FC = () => {
  const { user } = useAuth();
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);

  // User logs query
  const { data: logsData, isLoading } = useQuery({
    queryKey: ['user-logs', user?.id, page, pageSize],
    queryFn: () => userService.getUserLogs(user!.id, { page, pageSize }),
    enabled: !!user,
    refetchInterval: 30000,
  });

  const formatDateTime = (date: Date) => {
    return new Date(date).toLocaleString('en-IN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffInMinutes < 1) return 'Just now';
    if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)}h ago`;
    return `${Math.floor(diffInMinutes / 1440)}d ago`;
  };

  const getActionIcon = (action: string) => {
    switch (action.toLowerCase()) {
      case 'login':
        return <LogIn className="h-4 w-4 text-green-400" />;
      case 'logout':
        return <LogOut className="h-4 w-4 text-red-400" />;
      default:
        return <Clock className="h-4 w-4 text-gray-400" />;
    }
  };

  const getActionColor = (action: string) => {
    switch (action.toLowerCase()) {
      case 'login':
        return 'text-green-400';
      case 'logout':
        return 'text-red-400';
      default:
        return 'text-gray-400';
    }
  };

  const getActionBgColor = (action: string) => {
    switch (action.toLowerCase()) {
      case 'login':
        return 'bg-green-900/20';
      case 'logout':
        return 'bg-red-900/20';
      default:
        return '';
    }
  };

  return (
    <div className="min-h-screen bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center space-x-3 mb-4"
          >
            <div className="p-2 bg-gold-500 rounded-lg">
              <Clock className="h-6 w-6 text-black" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-white">Log Section</h1>
              <p className="text-gray-400">Your login and logout history</p>
            </div>
          </motion.div>
        </div>

        {/* Main Content */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-gray-800 rounded-lg border border-gray-700 shadow-lg"
        >
          <div className="px-6 py-4 border-b border-gray-700">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-xl font-semibold text-white">Activity Logs</h2>
                <p className="text-gray-400 text-sm">
                  Track your account access history
                </p>
              </div>
              <div className="flex items-center space-x-2">
                <Filter className="h-5 w-5 text-gray-400" />
                <span className="text-gray-400 text-sm">All Activities</span>
              </div>
            </div>
          </div>

          <div className="p-6">
            {isLoading ? (
              <div className="flex justify-center py-12">
                <LoadingSpinner size="lg" />
              </div>
            ) : !logsData?.items || logsData.items.length === 0 ? (
              <div className="text-center py-12">
                <Clock className="h-16 w-16 text-gray-600 mx-auto mb-4" />
                <h3 className="text-xl font-semibold text-white mb-2">No Logs Found</h3>
                <p className="text-gray-400">
                  Your login/logout history will appear here.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {logsData.items.map((log, index) => (
                  <motion.div
                    key={`${log.action}-${log.timestamp}-${index}`}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.05 }}
                    className={`p-4 rounded-lg border border-gray-700 hover:border-gray-600 transition-colors ${getActionBgColor(log.action)}`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4">
                        <div className="flex items-center justify-center w-10 h-10 rounded-full bg-gray-700">
                          {getActionIcon(log.action)}
                        </div>
                        <div>
                          <div className="flex items-center space-x-2">
                            <span className={`font-medium ${getActionColor(log.action)}`}>
                              {log.action.toUpperCase()}
                            </span>
                            <span className="text-gray-400 text-sm">
                              {formatTimeAgo(new Date(log.timestamp))}
                            </span>
                          </div>
                          <div className="text-gray-400 text-sm mt-1">
                            {formatDateTime(new Date(log.timestamp))}
                          </div>
                          {log.ipAddress && (
                            <div className="text-gray-500 text-xs mt-1">
                              IP: {log.ipAddress}
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-gray-400 text-sm">
                          {new Date(log.timestamp).toLocaleDateString()}
                        </div>
                        <div className="text-gray-500 text-xs">
                          {new Date(log.timestamp).toLocaleTimeString()}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            )}

            {/* Pagination */}
            {logsData && logsData.items.length > 0 && (
              <div className="flex items-center justify-between mt-6 pt-4 border-t border-gray-700">
                <div>
                  {page > 1 && (
                    <button
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors"
                      onClick={() => setPage(p => p - 1)}
                    >
                      Previous
                    </button>
                  )}
                </div>
                <div className="text-gray-400 text-sm">
                  Page {page} of {logsData.totalPages}
                </div>
                <div>
                  {page < logsData.totalPages && (
                    <button
                      className="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors"
                      onClick={() => setPage(p => p + 1)}
                    >
                      Next
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default LogsPage;
