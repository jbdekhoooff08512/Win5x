import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main(username: string, newPassword: string) {
  const user = await prisma.user.findUnique({ where: { username } });
  if (!user) {
    console.log(`User ${username} not found`);
    return;
  }
  console.log(`Found ${username}. isActive=${(user as any).isActive}`);
  const match = await bcrypt.compare(newPassword, (user as any).password);
  console.log(`Password match: ${match}`);
  if (!match) {
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12');
    const hashed = await bcrypt.hash(newPassword, saltRounds);
    await prisma.user.update({ where: { id: user.id }, data: { password: hashed } });
    console.log('Password reset to provided value.');
  }
}

const [,, u, p] = process.argv;
if (!u || !p) {
  console.error('Usage: ts-node verifyAndFixUser.ts <username> <password>');
  process.exit(1);
}

main(u, p)
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });


