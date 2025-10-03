import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { userService } from '../services/userService';
import { toast } from 'react-hot-toast';
import { 
  Copy, 
  Users, 
  Gift, 
  TrendingUp, 
  CheckCircle,
  AlertCircle,
  Loader2
} from 'lucide-react';

interface ReferralStats {
  referralCode: string;
  totalReferrals: number;
  validReferrals: number;
  totalEarnings: number;
  currentTier: number;
  nextTierReferrals: number;
  tiers: Array<{
    id: number;
    name: string;
    requiredReferrals: number;
    bonus: number;
    depositPerPerson: number;
    isCompleted: boolean;
    isClaimed: boolean;
  }>;
}

interface ReferralRecord {
  id: string;
  referredUser: {
    username: string;
    createdAt: string;
  };
  status: string;
  createdAt: string;
}

const InviteEarnPage: React.FC = () => {
  const [copied, setCopied] = useState(false);
  const queryClient = useQueryClient();

  // Fetch referral stats
  const { data: stats, isLoading: statsLoading, error: statsError } = useQuery({
    queryKey: ['referralStats'],
    queryFn: userService.getReferralStats,
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  // Fetch referral records
  const { data: records, isLoading: recordsLoading } = useQuery({
    queryKey: ['referralRecords'],
    queryFn: () => userService.getReferralRecords({ page: 1, limit: 10 }),
    refetchInterval: 30000,
  });

  // Claim bonus mutation
  const claimBonusMutation = useMutation({
    mutationFn: userService.claimReferralBonus,
    onSuccess: (data) => {
      toast.success(data.message || 'Bonus claimed successfully!');
      queryClient.invalidateQueries({ queryKey: ['referralStats'] });
      queryClient.invalidateQueries({ queryKey: ['wallet'] });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to claim bonus');
    },
  });

  // Copy referral code to clipboard
  const copyReferralCode = async () => {
    if (stats?.referralCode) {
      try {
        await navigator.clipboard.writeText(stats.referralCode);
        setCopied(true);
        toast.success('Referral code copied to clipboard!');
        setTimeout(() => setCopied(false), 2000);
      } catch (err) {
        toast.error('Failed to copy referral code');
      }
    }
  };

  // Copy referral link to clipboard
  const copyReferralLink = async () => {
    if (stats?.referralCode) {
      const referralLink = `${window.location.origin}/register?ref=${stats.referralCode}`;
      try {
        await navigator.clipboard.writeText(referralLink);
        setCopied(true);
        toast.success('Referral link copied to clipboard!');
        setTimeout(() => setCopied(false), 2000);
      } catch (err) {
        toast.error('Failed to copy referral link');
      }
    }
  };

  if (statsLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4 text-gold-400" />
          <p className="text-gray-300">Loading referral data...</p>
        </div>
      </div>
    );
  }

  if (statsError) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-white mb-2">Error Loading Data</h2>
          <p className="text-gray-300 mb-4">Failed to load referral information</p>
          <button 
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-gold-500 text-white rounded-lg hover:bg-gold-600 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  const referralData = stats as ReferralStats;

  return (
    <div className="min-h-screen bg-gray-900 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Invite & Earn</h1>
          <p className="text-gray-300">Invite friends and earn bonuses for each successful referral!</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-gray-800 border border-gray-700 rounded-lg p-6">
            <div className="flex items-center">
              <Users className="h-8 w-8 text-gold-400 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-300">Total Invites</p>
                <p className="text-2xl font-bold text-white">{referralData?.totalReferrals || 0}</p>
              </div>
            </div>
          </div>

          <div className="bg-gray-800 border border-gray-700 rounded-lg p-6">
            <div className="flex items-center">
              <CheckCircle className="h-8 w-8 text-green-400 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-300">Valid Invites</p>
                <p className="text-2xl font-bold text-white">{referralData?.validReferrals || 0}</p>
              </div>
            </div>
          </div>

          <div className="bg-gray-800 border border-gray-700 rounded-lg p-6">
            <div className="flex items-center">
              <Gift className="h-8 w-8 text-purple-400 mr-3" />
              <div>
                <p className="text-sm font-medium text-gray-300">Total Earnings</p>
                <p className="text-2xl font-bold text-white">₹{referralData?.totalEarnings || 0}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Referral Code Section */}
        <div className="bg-gray-800 border border-gray-700 rounded-lg p-6 mb-8">
          <h2 className="text-xl font-semibold text-white mb-4">Your Referral Code</h2>
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Referral Code
              </label>
              <div className="flex">
                <input
                  type="text"
                  value={referralData?.referralCode || ''}
                  readOnly
                  className="flex-1 px-3 py-2 border border-gray-600 rounded-l-md bg-gray-700 text-white font-mono"
                />
                <button
                  onClick={copyReferralCode}
                  className="px-4 py-2 bg-gold-500 text-white rounded-r-md hover:bg-gold-600 flex items-center transition-colors"
                >
                  {copied ? <CheckCircle className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                </button>
              </div>
            </div>
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Referral Link
              </label>
              <div className="flex">
                <input
                  type="text"
                  value={referralData?.referralCode ? `${window.location.origin}/register?ref=${referralData.referralCode}` : ''}
                  readOnly
                  className="flex-1 px-3 py-2 border border-gray-600 rounded-l-md bg-gray-700 text-white text-sm"
                />
                <button
                  onClick={copyReferralLink}
                  className="px-4 py-2 bg-green-500 text-white rounded-r-md hover:bg-green-600 flex items-center transition-colors"
                >
                  {copied ? <CheckCircle className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Bonus Tiers */}
        <div className="bg-gray-800 border border-gray-700 rounded-lg p-6 mb-8">
          <h2 className="text-xl font-semibold text-white mb-4">Bonus Tiers</h2>
          <div className="space-y-4">
            {referralData?.tiers?.map((tier) => (
              <div
                key={tier.id}
                className={`border rounded-lg p-4 ${
                  tier.isCompleted
                    ? 'border-green-500/50 bg-green-900/20'
                    : 'border-gray-600 bg-gray-700/50'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center mr-3 ${
                      tier.isCompleted ? 'bg-green-500' : 'bg-gray-500'
                    }`}>
                      {tier.isCompleted ? (
                        <CheckCircle className="h-5 w-5 text-white" />
                      ) : (
                        <span className="text-white font-semibold">{tier.id}</span>
                      )}
                    </div>
                    <div>
                      <h3 className="font-semibold text-white">{tier.name}</h3>
                      <p className="text-sm text-gray-300">
                        {tier.requiredReferrals} referrals = ₹{tier.bonus} bonus
                      </p>
                      <p className="text-xs text-gray-400">
                        Deposit per person: ₹{tier.depositPerPerson}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    {tier.isCompleted ? (
                      tier.isClaimed ? (
                        <span className="text-green-400 font-medium">Claimed</span>
                      ) : (
                        <button
                          onClick={() => claimBonusMutation.mutate(tier.id)}
                          disabled={claimBonusMutation.isPending}
                          className="px-4 py-2 bg-gold-500 text-white rounded-lg hover:bg-gold-600 disabled:opacity-50 flex items-center transition-colors"
                        >
                          {claimBonusMutation.isPending ? (
                            <Loader2 className="h-4 w-4 animate-spin mr-2" />
                          ) : null}
                          Claim ₹{tier.bonus}
                        </button>
                      )
                    ) : (
                      <span className="text-gray-400">
                        {Math.max(0, tier.requiredReferrals - (referralData?.validReferrals || 0))} more needed
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Referrals */}
        <div className="bg-gray-800 border border-gray-700 rounded-lg p-6">
          <h2 className="text-xl font-semibold text-white mb-4">Recent Referrals</h2>
          {recordsLoading ? (
            <div className="text-center py-8">
              <Loader2 className="h-6 w-6 animate-spin mx-auto mb-2 text-gold-400" />
              <p className="text-gray-300">Loading referrals...</p>
            </div>
          ) : records?.items?.length > 0 ? (
            <div className="space-y-3">
              {records.items.map((record: ReferralRecord) => (
                <div key={record.id} className="flex items-center justify-between py-3 border-b border-gray-600 last:border-b-0">
                  <div className="flex items-center">
                    <div className="w-8 h-8 bg-gold-500/20 rounded-full flex items-center justify-center mr-3">
                      <Users className="h-4 w-4 text-gold-400" />
                    </div>
                    <div>
                      <p className="font-medium text-white">{record.referredUser.username}</p>
                      <p className="text-sm text-gray-300">
                        {new Date(record.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                    record.status === 'ACTIVE' 
                      ? 'bg-green-500/20 text-green-400' 
                      : 'bg-yellow-500/20 text-yellow-400'
                  }`}>
                    {record.status}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <Users className="h-12 w-12 text-gray-500 mx-auto mb-4" />
              <p className="text-gray-400">No referrals yet</p>
              <p className="text-sm text-gray-500">Share your referral code to start earning!</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default InviteEarnPage;
