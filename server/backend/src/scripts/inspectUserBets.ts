import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(username: string) {
  const user = await prisma.user.findUnique({ where: { username } });
  if (!user) {
    console.log('User not found');
    return;
  }
  console.log('User:', { id: user.id, walletBetting: user.walletBetting, walletGaming: user.walletGaming });

  const bets = await prisma.bet.findMany({
    where: { userId: user.id },
    orderBy: { placedAt: 'desc' },
    take: 10,
    include: { round: { select: { roundNumber: true, winningNumber: true } } },
  });

  for (const b of bets) {
    console.log({
      id: b.id,
      amount: b.amount,
      status: b.status,
      actualPayout: (b as any).actualPayout,
      walletType: (b as any).walletType,
      placedAt: b.placedAt,
      round: b.round?.roundNumber,
    });
  }
}

const [,, username] = process.argv;
if (!username) {
  console.error('Usage: ts-node inspectUserBets.ts <username>');
  process.exit(1);
}

main(username)
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });



