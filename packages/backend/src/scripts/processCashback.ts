import { PrismaClient } from '@prisma/client';
import { CashbackService } from '../services/CashbackService';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();
const cashbackService = new CashbackService(prisma);

async function processDailyCashback() {
  try {
    logger.info('Starting daily cashback processing...');
    
    await cashbackService.processDailyCashback();
    
    logger.info('Daily cashback processing completed successfully');
  } catch (error) {
    logger.error('Failed to process daily cashback:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  processDailyCashback();
}

export { processDailyCashback };
