import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

async function cleanupDatabase() {
  try {
    logger.info('Starting database cleanup...');

    // Get all rounds ordered by creation time
    const allRounds = await prisma.gameRound.findMany({
      orderBy: { createdAt: 'asc' },
    });

    logger.info(`Found ${allRounds.length} rounds in database`);

    // Delete all rounds
    await prisma.gameRound.deleteMany({});
    logger.info('Deleted all existing rounds');

    // Reset the round counter
    logger.info('Database cleanup completed successfully');
  } catch (error) {
    logger.error('Failed to cleanup database:', error);
  } finally {
    await prisma.$disconnect();
  }
}

cleanupDatabase();
