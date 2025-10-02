import { apiService } from './apiService';

export const adminService = {
  // Analytics
  getAnalytics: apiService.getAnalytics,

  // Users
  getUsers: apiService.getUsers,
  getUserById: apiService.getUserById,
  updateUserStatus: apiService.updateUserStatus,
  adjustUserBalance: apiService.adjustUserBalance,
  setTemporaryPassword: apiService.setTemporaryPassword,

  // Bets
  getBets: apiService.getBets,

  // Rounds
  getRounds: apiService.getRounds,

  // Transactions
  getTransactions: apiService.getTransactions,
  approveTransaction: apiService.approveTransaction,

  // Promotions
  getPromotions: apiService.getPromotions,
  createPromotion: apiService.createPromotion,
  updatePromotion: apiService.updatePromotion,
  deletePromotion: apiService.deletePromotion,

  // Admin Config
  getAdminConfig: apiService.getAdminConfig,
  updateAdminConfig: apiService.updateAdminConfig,

  // Referral Management
  getReferralConfig: apiService.getReferralConfig,
  updateReferralConfig: apiService.updateReferralConfig,
  getReferralStats: apiService.getReferralStats,
  getReferralRecords: apiService.getReferralRecords,
  getUserReferralStats: apiService.getUserReferralStats,
  getUserReferralRecords: apiService.getUserReferralRecords,

  // User Wallets
  getUserWallets: apiService.getUserWallets,
  getUserWalletHistory: apiService.getUserWalletHistory,
  adjustUserCoins: apiService.adjustUserCoins,

  // Gift Codes
  getGiftCodes: apiService.getGiftCodes,
  createGiftCode: apiService.createGiftCode,
  updateGiftCode: apiService.updateGiftCode,
  deleteGiftCode: apiService.deleteGiftCode,

  // Payment Methods
  getAllPaymentMethods: apiService.getAllPaymentMethods,
  getPaymentOptions: apiService.getPaymentOptions,
  updatePaymentMethod: apiService.updatePaymentMethod,
  uploadQrCode: apiService.uploadQrCode,
  getAdminDeposits: apiService.getAdminDeposits,
  processDepositRequest: apiService.processDepositRequest,
  getAdminWithdrawals: apiService.getAdminWithdrawals,
  processWithdrawalRequest: apiService.processWithdrawalRequest,
  getPaymentStats: apiService.getPaymentStats,

  // Audit Logs
  getAuditLogs: apiService.getAuditLogs,
};
