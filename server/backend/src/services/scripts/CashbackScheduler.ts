import { PrismaClient } from '@prisma/client';
import { logger } from '../../utils/logger';

const prisma = new PrismaClient();

/**
 * Daily cashback scheduler
 * - Releases 10% of current gaming wallet balance into betting wallet
 * - Intended to be run once per day via cron/PM2
 */
export async function runDailyCashbackRelease(): Promise<void> {
  try {
    const users = await prisma.user.findMany({ select: { id: true, walletGaming: true } });
    for (const u of users) {
      const gc = Number(u.walletGaming || 0);
      if (gc <= 0.5) continue; // skip tiny balances
      const release = Math.floor(gc * 0.10); // 10% rounded down to avoid float drift
      if (release <= 0) continue;

      await prisma.$transaction([
        prisma.user.update({ where: { id: u.id }, data: { walletGaming: { decrement: release }, walletBetting: { increment: release } } }),
        prisma.transaction.create({
          data: {
            userId: u.id,
            type: 'CASHBACK',
            amount: release,
            status: 'COMPLETED',
            description: 'Daily cashback release (10% of gaming wallet)',
          },
        }),
      ]);
    }
    logger.info('Daily cashback release completed');
  } catch (e) {
    logger.error('Daily cashback release failed', e);
  }
}










