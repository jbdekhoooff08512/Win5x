import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { asyncHandler } from '../middleware/errorHandler';
import { 
  authenticateToken, 
  requireAdmin, 
  requirePermission, 
  AuthenticatedRequest 
} from '../middleware/auth';
import { 
  ValidationError,
  createSuccessResponse 
} from '@win5x/common';

const router: Router = Router();
const prisma = new PrismaClient();

// Referral bonus tiers - exactly as specified
const REFERRAL_BONUS_TIERS = [
  { id: 1, reward: 58, invitees: 2, depositPerPerson: 200 },
  { id: 2, reward: 188, invitees: 4, depositPerPerson: 200 },
  { id: 3, reward: 338, invitees: 10, depositPerPerson: 500 }, // Updated to ₹338 as specified
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

// Generate referral code
function generateReferralCode(username: string): string {
  const randomSuffix = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${username.substring(0, 3).toUpperCase()}${randomSuffix}`;
}

// Get user's referral statistics (admin view)
router.get('/stats/:userId', requirePermission('MANAGE_USERS'), asyncHandler(async (req: AuthenticatedRequest, res) => {
  const { userId } = req.params;

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
  const tiersWithProgress = REFERRAL_BONUS_TIERS.map(tier => {
    const progress = Math.min(validReferralsCount, tier.invitees);
    const isCompleted = progress >= tier.invitees;
    
    return {
      ...tier,
      progress,
      validReferrals: progress,
      status: isCompleted ? 'completed' : 'unfinished',
      isCompleted
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
  const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
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

// Get referral records (admin view)
router.get('/records/:userId', requirePermission('MANAGE_USERS'), asyncHandler(async (req: AuthenticatedRequest, res) => {
  const { userId } = req.params;
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

export default router;
