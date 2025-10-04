import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  Users, 
  Plus, 
  Edit, 
  Trash2, 
  Save, 
  X, 
  TrendingUp,
  DollarSign,
  UserCheck
} from 'lucide-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminService } from '../services/adminService';
import { toast } from 'react-hot-toast';
import LoadingSpinner from '../components/LoadingSpinner';

interface ReferralTier {
  id: number;
  name: string;
  requiredReferrals: number;
  bonus: number;
  depositPerPerson: number;
  isActive: boolean;
}

interface ReferralStats {
  totalReferrals: number;
  validReferrals: number;
  totalReferralEarnings: number;
  conversionRate: string;
  topReferrers: Array<{
    id: string;
    username: string;
    totalReferrals: number;
    validReferrals: number;
    totalEarnings: number;
  }>;
  recentReferrals: Array<{
    id: string;
    referredUser: string;
    referrer: string;
    createdAt: string;
    hasDeposited: boolean;
  }>;
}

const ReferralManagementPage: React.FC = () => {
  const [editingTier, setEditingTier] = useState<ReferralTier | null>(null);
  const [isAddingTier, setIsAddingTier] = useState(false);
  const [newTier, setNewTier] = useState<Partial<ReferralTier>>({
    name: '',
    requiredReferrals: 0,
    bonus: 0,
    depositPerPerson: 0,
    isActive: true
  });
  const queryClient = useQueryClient();

  // Fetch referral configuration
  const { data: config, isLoading: configLoading } = useQuery({
    queryKey: ['referral-config'],
    queryFn: adminService.getReferralConfig,
  });

  // Fetch referral statistics
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['referral-stats'],
    queryFn: () => adminService.getReferralStats({ period: 'all' }),
  });

  // Update referral configuration mutation
  const updateConfigMutation = useMutation({
    mutationFn: adminService.updateReferralConfig,
    onSuccess: () => {
      toast.success('Referral configuration updated successfully!');
      queryClient.invalidateQueries({ queryKey: ['referral-config'] });
      queryClient.invalidateQueries({ queryKey: ['referral-stats'] });
      setEditingTier(null);
      setIsAddingTier(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to update configuration');
    },
  });

  const handleSaveTier = () => {
    if (!config?.referralTiers) return;

    let updatedTiers = [...config.referralTiers];

    if (editingTier) {
      // Update existing tier
      const index = updatedTiers.findIndex((tier: ReferralTier) => tier.id === editingTier.id);
      if (index !== -1) {
        updatedTiers[index] = editingTier;
      }
    } else if (isAddingTier) {
      // Add new tier
      const maxId = Math.max(...updatedTiers.map((tier: ReferralTier) => tier.id), 0);
      updatedTiers.push({
        id: maxId + 1,
        name: newTier.name || `Bonus ${maxId + 1}`,
        requiredReferrals: newTier.requiredReferrals || 0,
        bonus: newTier.bonus || 0,
        depositPerPerson: newTier.depositPerPerson || 0,
        isActive: newTier.isActive ?? true
      });
    }

    updateConfigMutation.mutate({ referralTiers: updatedTiers });
  };

  const handleDeleteTier = (tierId: number) => {
    if (!config?.referralTiers) return;

    const updatedTiers = config.referralTiers.filter((tier: ReferralTier) => tier.id !== tierId);
    updateConfigMutation.mutate({ referralTiers: updatedTiers });
  };

  const handleEditTier = (tier: ReferralTier) => {
    setEditingTier({ ...tier });
    setIsAddingTier(false);
  };

  const handleAddTier = () => {
    setNewTier({
      name: '',
      requiredReferrals: 0,
      bonus: 0,
      depositPerPerson: 0,
      isActive: true
    });
    setIsAddingTier(true);
    setEditingTier(null);
  };

  const handleCancelEdit = () => {
    setEditingTier(null);
    setIsAddingTier(false);
    setNewTier({
      name: '',
      requiredReferrals: 0,
      bonus: 0,
      depositPerPerson: 0,
      isActive: true
    });
  };

  if (configLoading || statsLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const referralTiers = config?.referralTiers || [];
  const referralStats = stats as ReferralStats;

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="space-y-6"
      >
      {/* Header */}
        <div className="flex items-center justify-between">
        <div>
            <h1 className="text-3xl font-bold text-gray-900">Referral Management</h1>
            <p className="text-gray-600 mt-2">Manage referral bonus tiers and track referral performance</p>
        </div>
          <button
            onClick={handleAddTier}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="h-4 w-4" />
            Add Tier
          </button>
      </div>

        {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <Users className="h-8 w-8 text-blue-600 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-600">Total Referrals</p>
                <p className="text-2xl font-bold text-gray-900">{referralStats?.totalReferrals || 0}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <UserCheck className="h-8 w-8 text-green-600 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-600">Valid Referrals</p>
                <p className="text-2xl font-bold text-gray-900">{referralStats?.validReferrals || 0}</p>
          </div>
        </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <DollarSign className="h-8 w-8 text-purple-600 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-600">Total Earnings</p>
                <p className="text-2xl font-bold text-gray-900">₹{referralStats?.totalReferralEarnings || 0}</p>
          </div>
        </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <TrendingUp className="h-8 w-8 text-orange-600 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-600">Conversion Rate</p>
                <p className="text-2xl font-bold text-gray-900">{referralStats?.conversionRate || '0'}%</p>
              </div>
            </div>
          </div>
        </div>

        {/* Referral Tiers */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900">Referral Bonus Tiers</h2>
            <p className="text-gray-600 mt-1">Configure the bonus tiers for referral rewards</p>
      </div>

          <div className="p-6">
            <div className="space-y-4">
              {referralTiers.map((tier: ReferralTier) => (
                <div key={tier.id} className="border border-gray-200 rounded-lg p-4">
                  {editingTier?.id === tier.id ? (
                    <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <input
              type="text"
                          value={editingTier?.name || ''}
                          onChange={(e) => editingTier && setEditingTier({ ...editingTier, name: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Required Referrals</label>
                        <input
                          type="number"
                          value={editingTier?.requiredReferrals || 0}
                          onChange={(e) => editingTier && setEditingTier({ ...editingTier, requiredReferrals: parseInt(e.target.value) || 0 })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Bonus Amount (₹)</label>
                        <input
                          type="number"
                          value={editingTier?.bonus || 0}
                          onChange={(e) => editingTier && setEditingTier({ ...editingTier, bonus: parseInt(e.target.value) || 0 })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Deposit per Person (₹)</label>
                        <input
                          type="number"
                          value={editingTier?.depositPerPerson || 0}
                          onChange={(e) => editingTier && setEditingTier({ ...editingTier, depositPerPerson: parseInt(e.target.value) || 0 })}
                          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <div className="flex items-end gap-2">
                        <button
                          onClick={handleSaveTier}
                          disabled={updateConfigMutation.isPending}
                          className="flex items-center gap-1 px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
                        >
                          <Save className="h-4 w-4" />
                          Save
                        </button>
                        <button
                          onClick={handleCancelEdit}
                          className="flex items-center gap-1 px-3 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700"
                        >
                          <X className="h-4 w-4" />
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-6">
                        <div>
                          <h3 className="font-semibold text-gray-900">{tier.name}</h3>
                          <p className="text-sm text-gray-600">Tier {tier.id}</p>
                        </div>
                        <div>
                          <p className="text-sm text-gray-600">Required Referrals</p>
                          <p className="font-semibold text-gray-900">{tier.requiredReferrals}</p>
                        </div>
                        <div>
                          <p className="text-sm text-gray-600">Bonus Amount</p>
                          <p className="font-semibold text-gray-900">₹{tier.bonus}</p>
                        </div>
                        <div>
                          <p className="text-sm text-gray-600">Deposit per Person</p>
                          <p className="font-semibold text-gray-900">₹{tier.depositPerPerson}</p>
                        </div>
                        <div>
                          <p className="text-sm text-gray-600">Status</p>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            tier.isActive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                          }`}>
                            {tier.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleEditTier(tier)}
                          className="flex items-center gap-1 px-3 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                        >
                          <Edit className="h-4 w-4" />
                          Edit
                        </button>
            <button
                          onClick={() => handleDeleteTier(tier.id)}
                          className="flex items-center gap-1 px-3 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
                          <Trash2 className="h-4 w-4" />
                          Delete
            </button>
          </div>
        </div>
      )}
                </div>
              ))}

              {/* Add New Tier Form */}
              {isAddingTier && (
                <div className="border border-gray-200 rounded-lg p-4 bg-blue-50">
                  <h3 className="font-semibold text-gray-900 mb-4">Add New Tier</h3>
                  <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                      <input
                        type="text"
                        value={newTier.name || ''}
                        onChange={(e) => setNewTier({ ...newTier, name: e.target.value })}
                        placeholder="Bonus X"
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Required Referrals</label>
                      <input
                        type="number"
                        value={newTier.requiredReferrals || ''}
                        onChange={(e) => setNewTier({ ...newTier, requiredReferrals: parseInt(e.target.value) })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Bonus Amount (₹)</label>
                      <input
                        type="number"
                        value={newTier.bonus || ''}
                        onChange={(e) => setNewTier({ ...newTier, bonus: parseInt(e.target.value) })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Deposit per Person (₹)</label>
                      <input
                        type="number"
                        value={newTier.depositPerPerson || ''}
                        onChange={(e) => setNewTier({ ...newTier, depositPerPerson: parseInt(e.target.value) })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div className="flex items-end gap-2">
                      <button
                        onClick={handleSaveTier}
                        disabled={updateConfigMutation.isPending}
                        className="flex items-center gap-1 px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
                      >
                        <Save className="h-4 w-4" />
                        Save
                      </button>
                      <button
                        onClick={handleCancelEdit}
                        className="flex items-center gap-1 px-3 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700"
                      >
                        <X className="h-4 w-4" />
                        Cancel
                      </button>
                </div>
                </div>
                </div>
              )}
              </div>
          </div>
        </div>

        {/* Top Referrers */}
        {referralStats?.topReferrers && referralStats.topReferrers.length > 0 && (
          <div className="bg-white rounded-lg shadow">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="text-xl font-semibold text-gray-900">Top Referrers</h2>
              <p className="text-gray-600 mt-1">Users with the most successful referrals</p>
            </div>
            <div className="p-6">
              <div className="space-y-3">
                {referralStats.topReferrers.map((referrer, index) => (
                  <div key={referrer.id} className="flex items-center justify-between py-3 border-b border-gray-200 last:border-b-0">
                    <div className="flex items-center">
                      <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mr-3">
                        <span className="text-blue-600 font-semibold">{index + 1}</span>
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">{referrer.username}</p>
                        <p className="text-sm text-gray-600">
                          {referrer.validReferrals}/{referrer.totalReferrals} valid referrals
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-gray-900">₹{referrer.totalEarnings}</p>
                      <p className="text-sm text-gray-600">Total earnings</p>
                    </div>
                  </div>
                ))}
              </div>
          </div>
        </div>
      )}
      </motion.div>
    </div>
  );
};

export default ReferralManagementPage;