import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const username = process.env.ADMIN_USERNAME || 'admin2';
  const email = process.env.ADMIN_EMAIL || 'admin2@example.com';
  const password = process.env.ADMIN_PASSWORD || 'Admin@123';
  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);

  const existing = await prisma.admin.findUnique({ where: { username } });
  if (existing) {
    console.log(`⚠️  Admin '${username}' already exists (email: ${existing.email})`);
    process.exit(0);
  }

  const hashed = await bcrypt.hash(password, saltRounds);

  const admin = await prisma.admin.create({
    data: {
      username,
      email,
      password: hashed,
      role: 'ADMIN',
      permissions: ['MANAGE_BETS', 'MANAGE_USERS', 'MANAGE_WITHDRAWALS', 'MANAGE_DEPOSITS', 'VIEW_ANALYTICS', 'EMERGENCY_CONTROLS', 'MANAGE_TIMERS'],
    },
  });

  console.log('✅ Admin created');
  console.log('   Username:', username);
  console.log('   Email   :', email);
  console.log('   Password:', password);
}

main().catch((e) => {
  console.error('❌ Failed to create admin:', e);
  process.exit(1);
}).finally(async () => {
  await prisma.$disconnect();
});


