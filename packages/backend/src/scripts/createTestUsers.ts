import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function createTestUsers() {
  console.log('🚀 Creating 10 test users with ₹1,00,000 betting wallet balance...');

  const testUsers = [
    { username: 'testuser01', email: 'testuser01@example.com' },
    { username: 'testuser02', email: 'testuser02@example.com' },
    { username: 'testuser03', email: 'testuser03@example.com' },
    { username: 'testuser04', email: 'testuser04@example.com' },
    { username: 'testuser05', email: 'testuser05@example.com' },
    { username: 'testuser06', email: 'testuser06@example.com' },
    { username: 'testuser07', email: 'testuser07@example.com' },
    { username: 'testuser08', email: 'testuser08@example.com' },
    { username: 'testuser09', email: 'testuser09@example.com' },
    { username: 'testuser10', email: 'testuser10@example.com' },
  ];

  const password = 'password123';
  const balance = 100000; // ₹1,00,000
  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12');
  const hashedPassword = await bcrypt.hash(password, saltRounds);

  let createdCount = 0;
  let updatedCount = 0;
  let skippedCount = 0;

  try {
    for (const userData of testUsers) {
      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { username: userData.username },
      });

      if (existingUser) {
        console.log(`⚠️  User ${userData.username} already exists, updating balance...`);
        
        // Update the existing user's balance to ₹1,00,000
        const updatedUser = await prisma.user.update({
          where: { username: userData.username },
          data: {
            walletBetting: balance, // Set betting wallet to ₹1,00,000
            walletGaming: 0,    // Reset gaming wallet to 0
          },
          select: {
            id: true,
            username: true,
            email: true,
            walletBetting: true,
            walletGaming: true,
          },
        });

        console.log(`✅ Updated ${updatedUser.username}: Betting Wallet ₹${updatedUser.walletBetting.toLocaleString()}, Gaming Wallet ₹${updatedUser.walletGaming.toLocaleString()}`);

        // Create transaction record for the balance update
        await prisma.transaction.create({
          data: {
            userId: updatedUser.id,
            type: 'BONUS_CREDIT',
            amount: balance - Number(existingUser.walletBetting || 0),
            status: 'COMPLETED',
            description: 'Test user balance setup - ₹1,00,000 betting wallet',
          },
        });

        updatedCount++;
      } else {
        // Create new user
        const newUser = await prisma.user.create({
          data: {
            username: userData.username,
            email: userData.email,
            password: hashedPassword,
            walletBetting: balance, // Set betting wallet to ₹1,00,000
            walletGaming: 0,    // Set gaming wallet to 0
          },
          select: {
            id: true,
            username: true,
            email: true,
            walletBetting: true,
            walletGaming: true,
          },
        });

        console.log(`✅ Created ${newUser.username}: Betting Wallet ₹${newUser.walletBetting.toLocaleString()}, Gaming Wallet ₹${newUser.walletGaming.toLocaleString()}`);

        // Create transaction record for the initial balance
        await prisma.transaction.create({
          data: {
            userId: newUser.id,
            type: 'BONUS_CREDIT',
            amount: balance,
            status: 'COMPLETED',
            description: 'Test user creation - Initial ₹1,00,000 betting wallet',
          },
        });

        createdCount++;
      }
    }

    console.log('\n🎉 Test users setup completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   Created: ${createdCount} new users`);
    console.log(`   Updated: ${updatedCount} existing users`);
    console.log(`   Skipped: ${skippedCount} users`);
    console.log(`\n📝 Login credentials for all test users:`);
    console.log(`   Username: testuser01 - testuser10`);
    console.log(`   Password: password123`);
    console.log(`   Betting Wallet: ₹1,00,000 each`);
    console.log(`   Gaming Wallet: ₹0 each`);

  } catch (error) {
    console.error('❌ Error creating test users:', error);
    throw error;
  }
}

// Run the script
createTestUsers()
  .catch((e) => {
    console.error('❌ Script failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

