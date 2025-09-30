import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const totalUsers = 15;
  const baseUsername = 'testuser';
  const passwordPlain = 'password123';
  const balanceAmount = 200000; // ₹2,00,000

  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12');
  const hashedPassword = await bcrypt.hash(passwordPlain, saltRounds);

  console.log(`Creating ${totalUsers} users with ₹${balanceAmount.toLocaleString()} each...`);

  for (let i = 1; i <= totalUsers; i++) {
    const suffix = String(i).padStart(2, '0');
    const username = `${baseUsername}${suffix}`;
    const email = `${username}@example.com`;

    const existing = await prisma.user.findUnique({ where: { username } });
    if (existing) {
      await prisma.user.update({
        where: { id: existing.id },
        data: { walletBetting: balanceAmount, walletGaming: 0 },
      });
      await prisma.transaction.create({
        data: {
          userId: existing.id,
          type: 'BONUS_CREDIT',
          amount: balanceAmount - Number(existing.walletBetting || 0),
          status: 'COMPLETED',
          description: 'Seed adjust to ₹2,00,000',
        },
      });
      console.log(`Updated ${username}`);
      continue;
    }

    const created = await prisma.user.create({
      data: {
        username,
        email,
        password: hashedPassword,
        walletBetting: balanceAmount,
        walletGaming: 0,
      },
    });
    await prisma.transaction.create({
      data: {
        userId: created.id,
        type: 'BONUS_CREDIT',
        amount: balanceAmount,
        status: 'COMPLETED',
        description: 'Seed initial ₹2,00,000',
      },
    });
    console.log(`Created ${username}`);
  }

  console.log('Done.');
}

main().finally(async () => {
  await prisma.$disconnect();
});


