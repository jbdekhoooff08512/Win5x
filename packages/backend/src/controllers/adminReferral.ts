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
import { logger } from '../utils/logger';

const router: Router = Router();
const prisma = new PrismaClient();

// Apply authentication to all admin routes
router.use(authenticateToken);
router.use(requireAdmin);

// Referral bonus tiers configuration
interface ReferralTier {
  id: number;
  name: string;
  requiredReferrals: number;
  bonus: number;
  depositPerPerson: number;
  isActive: boolean;
}

// Get current referral configuration
router.get('/config', requirePermission('MANAGE_USERS'), asyncHandler(async (req: AuthenticatedRequest, res) => {
  try {
    // Get referral tiers from admin config
    const config = await prisma.adminConfig.findFirst({
      orderBy: { createdAt: 'desc' }
    });

    const defaultTiers: ReferralTier[] = [
      { id: 1, name: 'Bonus 1', requiredReferrals: 2, bonus: 58, depositPerPerson: 200, isActive: true },
      { id: 2, name: 'Bonus 2', requiredReferrals: 4, bonus: 188, depositPerPerson: 200, isActive: true },
      { id: 3, name: 'Bonus 3', requiredReferrals: 10, bonus: 338, depositPerPerson: 500, isActive: true },
      { id: 4, name: 'Bonus 4', requiredReferrals: 30, bonus: 1678, depositPerPerson: 800, isActive: true },
      { id: 5, name: 'Bonus 5', requiredReferrals: 50, bonus: 2678, depositPerPerson: 1200, isActive: true },
      { id: 6, name: 'Bonus 6', requiredReferrals: 75, bonus: 3678, depositPerPerson: 1200, isActive: true },
      { id: 7, name: 'Bonus 7', requiredReferrals: 100, bonus: 6678, depositPerPerson: 1200, isActive: true },
      { id: 8, name: 'Bonus 8', requiredReferrals: 200, bonus: 11678, depositPerPerson: 1200, isActive: true },
      { id: 9, name: 'Bonus 9', requiredReferrals: 500, bonus: 27678, depositPerPerson: 1200, isActive: true },
      { id: 10, name: 'Bonus 10', requiredReferrals: 1000, bonus: 55678, depositPerPerson: 1200, isActive: true },
      { id: 11, name: 'Bonus 11', requiredReferrals: 2000, bonus: 111678, depositPerPerson: 1200, isActive: true },
      { id: 12, name: 'Bonus 12', requiredReferrals: 5000, bonus: 266678, depositPerPerson: 1200, isActive: true },
    ];

    // Parse referral tiers from config if exists
    let referralTiers = defaultTiers;
    if (config?.referralTiers) {
      try {
        referralTiers = JSON.parse(config.referralTiers as string);
      } catch (error) {
        logger.warn('Failed to parse referral tiers from config, using defaults');
      }
    }

    res.json(createSuccessResponse({
      referralTiers,
      lastUpdated: config?.updatedAt || null
    }));
  } catch (error) {
    logger.warn('Failed to fetch referral config from database, using defaults:', error);
    // Return default tiers if database query fails
    const defaultTiers: ReferralTier[] = [
      { id: 1, name: 'Bonus 1', requiredReferrals: 2, bonus: 58, depositPerPerson: 200, isActive: true },
      { id: 2, name: 'Bonus 2', requiredReferrals: 4, bonus: 188, depositPerPerson: 200, isActive: true },
      { id: 3, name: 'Bonus 3', requiredReferrals: 10, bonus: 338, depositPerPerson: 500, isActive: true },
      { id: 4, name: 'Bonus 4', requiredReferrals: 30, bonus: 1678, depositPerPerson: 800, isActive: true },
      { id: 5, name: 'Bonus 5', requiredReferrals: 50, bonus: 2678, depositPerPerson: 1200, isActive: true },
      { id: 6, name: 'Bonus 6', requiredReferrals: 75, bonus: 3678, depositPerPerson: 1200, isActive: true },
      { id: 7, name: 'Bonus 7', requiredReferrals: 100, bonus: 6678, depositPerPerson: 1200, isActive: true },
      { id: 8, name: 'Bonus 8', requiredReferrals: 200, bonus: 11678, depositPerPerson: 1200, isActive: true },
      { id: 9, name: 'Bonus 9', requiredReferrals: 500, bonus: 27678, depositPerPerson: 1200, isActive: true },
      { id: 10, name: 'Bonus 10', requiredReferrals: 1000, bonus: 55678, depositPerPerson: 1200, isActive: true },
      { id: 11, name: 'Bonus 11', requiredReferrals: 2000, bonus: 111678, depositPerPerson: 1200, isActive: true },
      { id: 12, name: 'Bonus 12', requiredReferrals: 5000, bonus: 266678, depositPerPerson: 1200, isActive: true },
    ];

    res.json(createSuccessResponse({
      referralTiers: defaultTiers,
      lastUpdated: null
    }));
  }
}));

// Update referral configuration
router.post('/config', requirePermission('MANAGE_USERS'), asyncHandler(async (req: AuthenticatedRequest, res) => {
  const { referralTiers } = req.body;

  if (!referralTiers || !Array.isArray(referralTiers)) {
    throw new ValidationError('Referral tiers must be an array');
  }

  // Validate each tier
  for (const tier of referralTiers) {
    if (!tier.id || !tier.name || !tier.requiredReferrals || !tier.bonus || !tier.depositPerPerson) {
      throw new ValidationError('Each tier must have id, name, requiredReferrals, bonus, and depositPerPerson');
    }
    if (tier.requiredReferrals < 1 || tier.bonus < 0 || tier.depositPerPerson < 0) {
      throw new ValidationError('Invalid tier values');
    }
  }

  try {
    // Update or create admin config
    const config = await prisma.adminConfig.upsert({
      where: { id: 'referral-config' },
      update: {
        referralTiers: JSON.stringify(referralTiers),
        updatedAt: new Date()
      },
      create: {
        id: 'referral-config',
        referralTiers: JSON.stringify(referralTiers),
        createdAt: new Date(),
        updatedAt: new Date()
      }
    });

    logger.info(`Admin ${req.user!.username} updated referral configuration`);

    // Emit real-time update to all connected users
    const { SocketService } = await import('../websocket/SocketService');
    const socketService = SocketService.getInstance();
    if (socketService) {
      await socketService.notifyAllUsers('referral_config_updated', {
        referralTiers,
        updatedBy: req.user!.username,
        updatedAt: new Date()
      });
    }

    res.json(createSuccessResponse({
      referralTiers,
      lastUpdated: config.updatedAt
    }, 'Referral configuration updated successfully'));
  } catch (error) {
    logger.error('Failed to update referral configuration:', error);
    throw new ValidationError('Failed to update referral configuration');
  }
}));

// Get referral statistics for admin
router.get('/stats', requirePermission('VIEW_ANALYTICS'), asyncHandler(async (req: AuthenticatedRequest, res) => {
  const { period = 'all' } = req.query;

  let dateFilter: any = {};
  const now = new Date();

  switch (period) {
    case 'today':
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      dateFilter = { gte: startOfDay };
      break;
    case 'week':
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - 7);
      dateFilter = { gte: startOfWeek };
      break;
    case 'month':
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      dateFilter = { gte: startOfMonth };
      break;
  }

  const [
    totalReferrals,
    validReferrals,
    totalReferralEarnings,
    topReferrers,
    recentReferrals
  ] = await Promise.all([
    prisma.referral.count({
      where: { createdAt: dateFilter }
    }),
    prisma.referral.findMany({
      where: { createdAt: dateFilter },
      include: {
        user: {
          include: {
            depositRequests: {
              where: { status: 'APPROVED' }
            }
          }
        }
      }
    }),
    prisma.referralEarning.aggregate({
      where: { createdAt: dateFilter },
      _sum: { amount: true }
    }),
    prisma.user.findMany({
      where: {
        referrals: {
          some: {}
        }
      },
      include: {
        _count: {
          select: {
            referrals: true
          }
        },
        referrals: {
          include: {
            user: {
              include: {
                depositRequests: {
                  where: { status: 'APPROVED' }
                }
              }
            }
          }
        },
        referralEarnings: true
      },
      orderBy: {
        referrals: {
          _count: 'desc'
        }
      },
      take: 10
    }),
    prisma.referral.findMany({
      where: { createdAt: dateFilter },
      include: {
        user: {
          select: {
            username: true,
            createdAt: true,
            depositRequests: {
              where: { status: 'APPROVED' }
            }
          }
        },
        parent: {
          select: {
            username: true
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: 20
    })
  ]);

  const validReferralsCount = validReferrals.filter(ref => 
    ref.user.depositRequests.length > 0
  ).length;

  const stats = {
    period,
    summary: {
      totalReferrals,
      validReferrals: validReferralsCount,
      totalReferralEarnings: totalReferralEarnings._sum.amount || 0,
      conversionRate: totalReferrals > 0 ? (validReferralsCount / totalReferrals * 100).toFixed(2) : 0
    },
    topReferrers: topReferrers.map(user => ({
      id: user.id,
      username: user.username,
      totalReferrals: user._count.referrals,
      validReferrals: user.referrals.filter(ref => 
        ref.user.depositRequests.length > 0
      ).length,
      totalEarnings: user.referralEarnings.reduce((sum: number, earning: any) => sum + earning.amount, 0)
    })),
    recentReferrals: recentReferrals.map(ref => ({
      id: ref.id,
      referredUser: ref.user.username,
      referrer: ref.parent.username,
      createdAt: ref.createdAt,
      hasDeposited: ref.user.depositRequests.length > 0
    }))
  };

  res.json(createSuccessResponse(stats));
}));

// Get all referral records with pagination
router.get('/records', requirePermission('VIEW_ANALYTICS'), asyncHandler(async (req: AuthenticatedRequest, res) => {
  const { page = 1, limit = 50, search, referrerId } = req.query;
  const skip = (Number(page) - 1) * Number(limit);

  const where: any = {};
  
  if (search) {
    where.OR = [
      { 
        user: {
          username: { contains: search, mode: 'insensitive' }
        }
      },
      {
        parent: {
          username: { contains: search, mode: 'insensitive' }
        }
      }
    ];
  }

  if (referrerId) {
    where.parentId = referrerId;
  }

  const [referrals, total] = await Promise.all([
    prisma.referral.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
            createdAt: true,
            depositRequests: {
              where: { status: 'APPROVED' },
              select: { amount: true, createdAt: true }
            }
          }
        },
        parent: {
          select: {
            id: true,
            username: true
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: Number(limit)
    }),
    prisma.referral.count({ where })
  ]);

  const totalPages = Math.ceil(total / Number(limit));

  res.json(createSuccessResponse({
    items: referrals.map(ref => ({
      id: ref.id,
      referredUser: {
        id: ref.user.id,
        username: ref.user.username,
        email: ref.user.email,
        createdAt: ref.user.createdAt,
        hasDeposited: ref.user.depositRequests.length > 0,
        totalDeposits: ref.user.depositRequests.reduce((sum, dep) => sum + dep.amount, 0)
      },
      referrer: {
        id: ref.parent.id,
        username: ref.parent.username
      },
      createdAt: ref.createdAt
    })),
    total,
    page: Number(page),
    limit: Number(limit),
    totalPages
  }));
}));

export default router;