import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(username: string) {
  const user = await prisma.user.findUnique({ where: { username } });
  if (!user) { console.log('User not found'); return; }

  const lost = await prisma.bet.findMany({
    where: { userId: user.id, status: 'LOST' },
    select: { amount: true },
  });
  const totalLost = lost.reduce((s, b) => s + (b.amount || 0), 0);
  const expectedReversal = totalLost * 0.1;

  console.log({ walletBetting: user.walletBetting, walletGaming: user.walletGaming, totalLost, expectedReversal });
}

const [,, username] = process.argv;
if (!username) { console.error('Usage: ts-node auditGamingWallet.ts <username>'); process.exit(1); }

main(username).finally(async () => { await prisma.$disconnect(); });



