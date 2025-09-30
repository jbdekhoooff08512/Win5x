import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function createTestUser() {
  console.log('🚀 Creating test user with username "4" and 1 lakh rupees...');

  try {
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { username: '4' },
    });

    if (existingUser) {
      console.log('⚠️  User with username "4" already exists');
      
      // Update the existing user's balance to 1 lakh
      const updatedUser = await prisma.user.update({
        where: { username: '4' },
        data: {
          walletBetting: 100000, // 1 lakh rupees
        },
        select: {
          id: true,
          username: true,
          email: true,
          walletBetting: true,
          walletGaming: true,
        },
      });

      console.log('✅ Updated existing user balance:');
      console.log(`   Username: ${updatedUser.username}`);
      console.log(`   Email: ${updatedUser.email}`);
      console.log(`   Betting Wallet: ₹${updatedUser.walletBetting.toLocaleString()}`);
      console.log(`   Gaming Wallet: ₹${updatedUser.walletGaming.toLocaleString()}`);

      // Create transaction record for the balance update
      await prisma.transaction.create({
        data: {
          userId: updatedUser.id,
                    type: 'BONUS_CREDIT',
          amount: 100000 - Number(existingUser.walletBetting || 0),
          status: 'COMPLETED',
          description: 'Test user balance setup - 1 lakh rupees',
        },
      });

      console.log('✅ Transaction record created');
    } else {
      // Create new user
      const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12');
      const hashedPassword = await bcrypt.hash('password123', saltRounds);

      const newUser = await prisma.user.create({
        data: {
          username: '4',
          email: 'testuser4@example.com',
          password: hashedPassword,
          walletBetting: 100000, // 1 lakh rupees
          walletGaming: 0,
        },
        select: {
          id: true,
          username: true,
          email: true,
          walletBetting: true,
          walletGaming: true,
        },
      });

      console.log('✅ Created new test user:');
      console.log(`   Username: ${newUser.username}`);
      console.log(`   Email: ${newUser.email}`);
      console.log(`   Betting Wallet: ₹${newUser.walletBetting.toLocaleString()}`);
      console.log(`   Gaming Wallet: ₹${newUser.walletGaming.toLocaleString()}`);
      console.log(`   Password: password123`);

      // Create transaction record for the initial balance
      await prisma.transaction.create({
        data: {
          userId: newUser.id,
                    type: 'BONUS_CREDIT',
          amount: 100000,
          status: 'COMPLETED',
          description: 'Test user creation - Initial 1 lakh rupees',
        },
      });

      console.log('✅ Transaction record created');
    }

    console.log('🎉 Test user setup completed successfully!');
    console.log('📝 Login credentials:');
    console.log('   Username: 4');
    console.log('   Password: password123');
    console.log('   Betting Wallet: ₹100,000');

  } catch (error) {
    console.error('❌ Error creating test user:', error);
    throw error;
  }
}

// Run the script
createTestUser()
  .catch((e) => {
    console.error('❌ Script failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

