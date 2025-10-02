import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { asyncHandler } from '../middleware/errorHandler';
import { 
  authenticateToken, 
  requireUser, 
  AuthenticatedRequest 
} from '../middleware/auth';
import { 
  ValidationError,
  createSuccessResponse 
} from '@win5x/common';

const router: Router = Router();
const prisma = new PrismaClient();

// Get referral bonus tiers from database or use defaults
async function getReferralBonusTiers() {
  try {
    const config = await prisma.adminConfig.findFirst({
      orderBy: { createdAt: 'desc' }
    });

    const defaultTiers = [
      { id: 1, reward: 58, invitees: 2, depositPerPerson: 200 },
      { id: 2, reward: 188, invitees: 4, depositPerPerson: 200 },
      { id: 3, reward: 338, invitees: 10, depositPerPerson: 500 },
      { id: 4, reward: 1678, invitees: 30, depositPerPerson: 800 },
      { id: 5, reward: 2678, invitees: 50, depositPerPerson: 1200 },
      { id: 6, reward: 3678, invitees: 75, depositPerPerson: 1200 },
      { id: 7, reward: 6678, invitees: 100, depositPerPerson: 1200 },
      { id: 8, reward: 11678, invitees: 200, depositPerPerson: 1200 },
      { id: 9, reward: 27678, invitees: 500, depositPerPerson: 1200 },
      { id: 10, reward: 55678, invitees: 1000, depositPerPerson: 1200 },
      { id: 11, reward: 111678, invitees: 2000, depositPerPerson: 1200 },
      { id: 12, reward: 266678, invitees: 5000, depositPerPerson: 1200 },
    ];

    if (config?.referralTiers) {
      try {
        const customTiers = JSON.parse(config.referralTiers as string);
        return customTiers.map((tier: any) => ({
          id: tier.id,
          reward: tier.bonus,
          invitees: tier.requiredReferrals,
          depositPerPerson: tier.depositPerPerson
        }));
      } catch (error) {
        console.warn('Failed to parse referral tiers from config, using defaults');
      }
    }

    return defaultTiers;
  } catch (error) {
    console.warn('Failed to fetch referral config from database, using defaults:', error);
    // Return default tiers if database query fails
    return [
      { id: 1, reward: 58, invitees: 2, depositPerPerson: 200 },
      { id: 2, reward: 188, invitees: 4, depositPerPerson: 200 },
      { id: 3, reward: 338, invitees: 10, depositPerPerson: 500 },
      { id: 4, reward: 1678, invitees: 30, depositPerPerson: 800 },
      { id: 5, reward: 2678, invitees: 50, depositPerPerson: 1200 },
      { id: 6, reward: 3678, invitees: 75, depositPerPerson: 1200 },
      { id: 7, reward: 6678, invitees: 100, depositPerPerson: 1200 },
      { id: 8, reward: 11678, invitees: 200, depositPerPerson: 1200 },
      { id: 9, reward: 27678, invitees: 500, depositPerPerson: 1200 },
      { id: 10, reward: 55678, invitees: 1000, depositPerPerson: 1200 },
      { id: 11, reward: 111678, invitees: 2000, depositPerPerson: 1200 },
      { id: 12, reward: 266678, invitees: 5000, depositPerPerson: 1200 },
    ];
  }
}

// Generate referral code
function generateReferralCode(username: string): string {
  const randomSuffix = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${username.substring(0, 3).toUpperCase()}${randomSuffix}`;
}

// Get user's referral statistics
router.get('/stats', authenticateToken, requireUser, asyncHandler(async (req: AuthenticatedRequest, res) => {
  const userId = req.user!.id;

  // Get user's referral code
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { referralCode: true, username: true }
  });

  if (!user) {
    throw new ValidationError('User not found');
  }

  // Generate referral code if not exists
  let referralCode = user.referralCode;
  if (!referralCode) {
    referralCode = generateReferralCode(user.username);
    await prisma.user.update({
      where: { id: userId },
      data: { referralCode }
    });
  }

  // Get total referrals count
  const totalReferrals = await prisma.referral.count({
    where: { parentId: userId }
  });

  // Get valid referrals (those who have made deposits)
  const validReferrals = await prisma.referral.findMany({
    where: { parentId: userId },
    include: {
      user: {
        include: {
          depositRequests: {
            where: { status: 'APPROVED' }
          }
        }
      }
    }
  });

  const validReferralsCount = validReferrals.filter(ref => 
    ref.user.depositRequests.length > 0
  ).length;

  // Calculate total earnings from referrals
  const totalEarnings = await prisma.referralEarning.aggregate({
    where: { userId },
    _sum: { amount: true }
  });

  // Calculate progress for each tier
  const REFERRAL_BONUS_TIERS = await getReferralBonusTiers();
  const tiersWithProgress = REFERRAL_BONUS_TIERS.map((tier: any) => {
    const progress = Math.min(validReferralsCount, tier.invitees);
    const isCompleted = progress >= tier.invitees;
    
    return {
      id: tier.id,
      name: `Bonus ${tier.id}`,
      requiredReferrals: tier.invitees,
      bonus: tier.reward,
      depositPerPerson: tier.depositPerPerson,
      progress,
      validReferrals: progress,
      isCompleted,
      isClaimed: false, // TODO: Check if already claimed
      status: isCompleted ? 'completed' : 'unfinished'
    };
  });

  // Get recent referrals
  const recentReferrals = await prisma.referral.findMany({
    where: { parentId: userId },
    include: {
      user: {
        select: {
          id: true,
          username: true,
          referralCode: true,
          createdAt: true,
          depositRequests: {
            where: { status: 'APPROVED' },
            select: { amount: true, createdAt: true }
          }
        }
      }
    },
    orderBy: { createdAt: 'desc' },
    take: 10
  });

  // Generate invitation link
  const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3002';
  const invitationLink = `${baseUrl}/register?ref=${referralCode}`;

  const stats = {
    referralCode,
    invitationLink,
    totalReferrals,
    validReferrals: validReferralsCount,
    totalEarnings: totalEarnings._sum.amount || 0,
    tiers: tiersWithProgress,
    recentReferrals: recentReferrals.map(ref => ({
      id: ref.id,
      username: ref.user.username,
      referralCode: ref.user.referralCode,
      joinedAt: ref.user.createdAt,
      hasDeposited: ref.user.depositRequests.length > 0,
      totalDeposits: ref.user.depositRequests.reduce((sum, dep) => sum + dep.amount, 0)
    }))
  };

  res.json(createSuccessResponse(stats, 'Referral statistics retrieved successfully'));
}));

// Get referral records
router.get('/records', authenticateToken, requireUser, asyncHandler(async (req: AuthenticatedRequest, res) => {
  const userId = req.user!.id;
  const { page = 1, limit = 20 } = req.query;

  const skip = (Number(page) - 1) * Number(limit);

  const referrals = await prisma.referral.findMany({
    where: { parentId: userId },
    include: {
      user: {
        select: {
          id: true,
          username: true,
          email: true,
          referralCode: true,
          createdAt: true,
          depositRequests: {
            where: { status: 'APPROVED' },
            select: { amount: true, createdAt: true }
          }
        }
      }
    },
    orderBy: { createdAt: 'desc' },
    skip,
    take: Number(limit)
  });

  const total = await prisma.referral.count({
    where: { parentId: userId }
  });

  const records = referrals.map(ref => ({
    id: ref.id,
    username: ref.user.username,
    email: ref.user.email,
    referralCode: ref.user.referralCode,
    joinedAt: ref.user.createdAt,
    hasDeposited: ref.user.depositRequests.length > 0,
    totalDeposits: ref.user.depositRequests.reduce((sum, dep) => sum + dep.amount, 0),
    firstDepositAt: ref.user.depositRequests.length > 0 ? ref.user.depositRequests[0].createdAt : null
  }));

  res.json(createSuccessResponse({
    records,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit))
    }
  }, 'Referral records retrieved successfully'));
}));

// Claim referral bonus
router.post('/claim/:tierId', authenticateToken, requireUser, asyncHandler(async (req: AuthenticatedRequest, res) => {
  const userId = req.user!.id;
  const tierId = parseInt(req.params.tierId);

  const REFERRAL_BONUS_TIERS = await getReferralBonusTiers();
  const tier = REFERRAL_BONUS_TIERS.find((t: any) => t.id === tierId);
  if (!tier) {
    throw new ValidationError('Invalid tier ID');
  }

  // Check if user has completed this tier
  const validReferrals = await prisma.referral.findMany({
    where: { parentId: userId },
    include: {
      user: {
        include: {
          depositRequests: {
            where: { status: 'APPROVED' }
          }
        }
      }
    }
  });

  const validReferralsCount = validReferrals.filter(ref => 
    ref.user.depositRequests.length > 0
  ).length;

  if (validReferralsCount < tier.invitees) {
    throw new ValidationError(`You need ${tier.invitees} valid referrals to claim this bonus`);
  }

  // Check if bonus already claimed
  const existingClaim = await prisma.transaction.findFirst({
    where: {
      userId,
      type: 'BONUS_CREDIT',
      description: `Referral bonus for tier ${tierId}`
    }
  });

  if (existingClaim) {
    throw new ValidationError('Bonus already claimed for this tier');
  }

  // Create bonus transaction
  const transaction = await prisma.transaction.create({
    data: {
      userId,
      type: 'BONUS_CREDIT',
      amount: tier.reward,
      status: 'COMPLETED',
      description: `Referral bonus for tier ${tierId} - ${tier.invitees} referrals`
    }
  });

  // Update user's bonus balance
  await prisma.user.update({
    where: { id: userId },
    data: {
      bonusBalance: {
        increment: tier.reward
      }
    }
  });

  // Get updated user balance for real-time update
  const updatedUser = await prisma.user.findUnique({
    where: { id: userId },
    select: { walletBetting: true, walletGaming: true, bonusBalance: true },
  });

  // Emit balance update to user via socket
  const { SocketService } = await import('../websocket/SocketService');
  const socketService = SocketService.getInstance();
  if (socketService) {
    await socketService.notifyUser(userId, 'user_balance_update', {
      bettingWallet: Number(updatedUser?.walletBetting || 0),
      gamingWallet: Number(updatedUser?.walletGaming || 0),
      bonusBalance: Number(updatedUser?.bonusBalance || 0),
    });
  }

  res.json(createSuccessResponse({
    transactionId: transaction.id,
    amount: tier.reward,
    tier: tierId
  }, 'Referral bonus claimed successfully'));
}));

// Get invitation link and QR code
router.get('/link', authenticateToken, requireUser, asyncHandler(async (req: AuthenticatedRequest, res) => {
  const userId = req.user!.id;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { referralCode: true, username: true }
  });

  if (!user) {
    throw new ValidationError('User not found');
  }

  const referralCode = user.referralCode || generateReferralCode(user.username);
  
  if (!user.referralCode) {
    await prisma.user.update({
      where: { id: userId },
      data: { referralCode }
    });
  }

  const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3002';
  const invitationLink = `${baseUrl}/register?ref=${referralCode}`;
  
  // Generate QR code data (you can use a QR code library here)
  const qrCodeData = invitationLink;

  res.json(createSuccessResponse({
    referralCode,
    invitationLink,
    qrCodeData,
    shareText: `Join me on Win5x! Use my referral code: ${referralCode}`
  }, 'Invitation link generated successfully'));
}));

export default router;
