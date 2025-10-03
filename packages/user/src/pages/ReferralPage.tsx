import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Share2, Copy, Check, ArrowLeft, Gift, Users, TrendingUp } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { userService } from '../services/userService';

const ReferralPage: React.FC = () => {
  const { user } = useAuth();
  const [copied, setCopied] = useState(false);
  const [activeTab, setActiveTab] = useState<'rules' | 'records'>('rules');
  
  const { data: referralStats, isLoading } = useQuery({
    queryKey: ['referral-stats'],
    queryFn: () => userService.getReferralStats(),
    refetchInterval: 30000,
  });

  const { data: referralRecords } = useQuery({
    queryKey: ['referral-records'],
    queryFn: () => userService.getReferralRecords(),
    enabled: activeTab === 'records',
  });

  const copyReferralLink = async () => {
    try {
      if (referralStats?.invitationLink) {
        // Try modern clipboard API first
        if (navigator.clipboard && window.isSecureContext) {
          await navigator.clipboard.writeText(referralStats.invitationLink);
        } else {
          // Fallback for older browsers or non-secure contexts
          const textArea = document.createElement('textarea');
          textArea.value = referralStats.invitationLink;
          textArea.style.position = 'fixed';
          textArea.style.left = '-999999px';
          textArea.style.top = '-999999px';
          document.body.appendChild(textArea);
          textArea.focus();
          textArea.select();
          document.execCommand('copy');
          textArea.remove();
        }
        setCopied(true);
        toast.success('Referral link copied to clipboard!');
        setTimeout(() => setCopied(false), 2000);
      } else {
        toast.error('Referral link not available');
      }
    } catch (error) {
      console.error('Copy failed:', error);
      toast.error('Failed to copy referral link');
    }
  };

  const claimBonus = async (tierId: number) => {
    try {
      await userService.claimReferralBonus(tierId);
      toast.success('Bonus claimed successfully!');
      // Refetch data
      window.location.reload();
    } catch (error: any) {
      toast.error(error.message || 'Failed to claim bonus');
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Header */}
      <div className="bg-gradient-to-br from-gold-600 to-gold-700 text-white p-4">
        <div className="flex items-center gap-4">
          <Link to="/profile" className="text-white hover:text-gray-200">
            <ArrowLeft className="h-6 w-6" />
          </Link>
          <h1 className="text-lg font-semibold">Invite & Earn</h1>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="p-4 space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="flex items-center gap-2 mb-2">
              <Users className="h-5 w-5 text-blue-400" />
              <span className="text-sm text-gray-400">Total Referrals</span>
            </div>
            <div className="text-2xl font-bold text-white">{referralStats?.totalReferrals || 0}</div>
          </div>
          
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp className="h-5 w-5 text-green-400" />
              <span className="text-sm text-gray-400">Valid Referrals</span>
            </div>
            <div className="text-2xl font-bold text-white">{referralStats?.validReferrals || 0}</div>
          </div>
        </div>

        <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
          <div className="flex items-center gap-2 mb-2">
            <Gift className="h-5 w-5 text-yellow-400" />
            <span className="text-sm text-gray-400">Total Earnings</span>
          </div>
          <div className="text-2xl font-bold text-white">₹{(referralStats?.totalEarnings || 0).toLocaleString('en-IN')}</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-4 pb-4">
        <div className="flex bg-gray-800 rounded-lg p-1">
          <button
            onClick={() => setActiveTab('rules')}
            className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
              activeTab === 'rules'
                ? 'bg-gold-600 text-white'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Bonus Rules
          </button>
          <button
            onClick={() => setActiveTab('records')}
            className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
              activeTab === 'records'
                ? 'bg-gold-600 text-white'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Referral Records
          </button>
        </div>
      </div>

      {/* Content */}
      {activeTab === 'rules' && (
        <div className="px-4 pb-6">
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <h3 className="text-white font-semibold mb-4">Referral Bonus Tiers</h3>
            <div className="space-y-3">
              {referralStats?.tiers?.slice(0, 6).map((tier: any) => (
                <div key={tier.id} className={`p-3 rounded-lg border ${
                  tier.status === 'completed' ? 'bg-green-900/20 border-green-500/50' : 'bg-gray-700 border-gray-600'
                }`}>
                  <div className="flex justify-between items-center mb-2">
                    <span className="font-medium text-white">Tier {tier.id}</span>
                    <span className={`text-xs px-2 py-1 rounded ${
                      tier.status === 'completed' ? 'bg-green-500 text-white' : 'bg-gray-600 text-gray-300'
                    }`}>
                      {tier.status === 'completed' ? 'Completed' : 'In Progress'}
                    </span>
                  </div>
                  <div className="text-sm text-gray-300 mb-1">
                    {tier.progress} / {tier.invitees} referrals
                  </div>
                  <div className="w-full bg-gray-600 rounded-full h-2 mb-2">
                    <div 
                      className={`h-2 rounded-full ${
                        tier.status === 'completed' ? 'bg-green-500' : 'bg-gold-500'
                      }`}
                      style={{ width: `${Math.min(100, (tier.progress / tier.invitees) * 100)}%` }}
                    ></div>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-300">
                      Reward: ₹{tier.reward.toLocaleString('en-IN')}
                    </span>
                    {tier.status === 'completed' && (
                      <button
                        onClick={() => claimBonus(tier.id)}
                        className="bg-gold-600 hover:bg-gold-700 text-white px-3 py-1 rounded text-xs font-medium"
                      >
                        Claim
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {activeTab === 'records' && (
        <div className="px-4 pb-6">
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <h3 className="text-white font-semibold mb-4">Recent Referrals</h3>
            {referralRecords?.records?.length > 0 ? (
              <div className="space-y-2">
                {referralRecords.records.map((ref: any) => (
                  <div key={ref.id} className="flex justify-between items-center p-3 bg-gray-700 rounded-lg">
                    <div>
                      <div className="text-white font-medium">{ref.username}</div>
                      <div className="text-sm text-gray-400">
                        Joined: {new Date(ref.joinedAt).toLocaleDateString()}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className={`text-xs px-2 py-1 rounded ${
                        ref.hasDeposited ? 'bg-green-500 text-white' : 'bg-gray-600 text-gray-300'
                      }`}>
                        {ref.hasDeposited ? 'Deposited' : 'No Deposit'}
                      </div>
                      <div className="text-sm text-gray-300 mt-1">
                        ₹{ref.totalDeposits.toLocaleString('en-IN')}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <Users className="h-12 w-12 text-gray-600 mx-auto mb-4" />
                <p className="text-gray-400">No referrals yet</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Share Section */}
      <div className="px-4 pb-6">
        <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
          <h3 className="text-white font-semibold mb-3">Share your referral link</h3>
          <div className="flex items-center gap-2 mb-3">
            <input
              type="text"
              value={referralStats?.invitationLink || ''}
              readOnly
              className="flex-1 bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm text-white"
            />
            <button
              onClick={copyReferralLink}
              className="bg-gold-500 hover:bg-gold-600 text-white px-4 py-2 rounded flex items-center gap-2 transition-colors"
            >
              {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
            </button>
          </div>
          <div className="flex items-center gap-2">
            <Share2 className="h-4 w-4 text-gold-400" />
            <span className="text-sm text-gray-300">Share this link with friends to earn rewards!</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReferralPage;
