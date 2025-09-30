const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function cleanupAndSimulate() {
  try {
    console.log('🧹 Cleaning up previous simulation and creating fresh referrals');
    console.log('=' .repeat(60));
    
    // Get atharv's user ID
    const atharv = await prisma.user.findUnique({
      where: { username: 'atharv' },
      select: { id: true, username: true, referralCode: true }
    });
    
    if (!atharv) {
      console.log('❌ Atharv not found');
      return;
    }
    
    console.log('Atharv found:', atharv.username, 'ID:', atharv.id, 'Referral Code:', atharv.referralCode);
    
    // Clean up previous simulation users
    console.log('\n=== Cleaning up previous simulation ===');
    const existingRefUsers = await prisma.user.findMany({
      where: {
        username: {
          startsWith: 'refuser'
        }
      },
      select: { id: true, username: true }
    });
    
    for (const user of existingRefUsers) {
      // Delete related records first
      await prisma.depositRequest.deleteMany({ where: { userId: user.id } });
      await prisma.referral.deleteMany({ where: { userId: user.id } });
      await prisma.referral.deleteMany({ where: { parentId: user.id } });
      await prisma.user.delete({ where: { id: user.id } });
      console.log(`🗑️ Deleted user: ${user.username}`);
    }
    
    // Create 10 new referred users
    console.log('\n=== Creating 10 new referred users ===');
    const referredUsers = [];
    for (let i = 1; i <= 10; i++) {
      const username = `refuser${i}`;
      const email = `refuser${i}@example.com`;
      const password = await bcrypt.hash('password123', 12);
      
      const user = await prisma.user.create({
        data: {
          username,
          email,
          password,
          referredById: atharv.id,
          referralCode: `${username.toUpperCase()}${Math.random().toString(36).substring(2, 8).toUpperCase()}`
        }
      });
      
      referredUsers.push(user);
      console.log(`✅ Created referred user ${i}: ${username} (${user.id})`);
    }
    
    // Create referral relationships
    console.log('\n=== Creating referral relationships ===');
    for (const user of referredUsers) {
      await prisma.referral.create({
        data: {
          userId: user.id,
          parentId: atharv.id,
          level: 1
        }
      });
      console.log(`✅ Created referral relationship for ${user.username}`);
    }
    
    // Create deposit requests for all referred users (to make them "valid" referrals)
    console.log('\n=== Creating approved deposits ===');
    for (const user of referredUsers) {
      await prisma.depositRequest.create({
        data: {
          userId: user.id,
          paymentMethodId: '7e7f8f6e-f034-4efa-86a7-02d131c81a4f', // win5x-coin payment method
          amount: 200, // Minimum deposit amount
          status: 'APPROVED',
          approvedBy: 'bcdd0cba-8b4d-4135-9b80-fe22d76747eb', // superadmin ID
          approvedAt: new Date()
        }
      });
      console.log(`✅ Created approved deposit for ${user.username}`);
    }
    
    // Check referral stats
    console.log('\n=== Final Referral Stats ===');
    const referralStats = await prisma.referral.count({
      where: { parentId: atharv.id }
    });
    
    const validReferrals = await prisma.referral.findMany({
      where: { parentId: atharv.id },
      include: {
        user: {
          include: {
            depositRequests: {
              where: { status: 'APPROVED' }
            }
          }
        }
      }
    });
    
    const validReferralsCount = validReferrals.filter(ref => 
      ref.user.depositRequests.length > 0
    ).length;
    
    console.log('Total referrals:', referralStats);
    console.log('Valid referrals:', validReferralsCount);
    
    // Calculate expected bonus (tier 3: 10 referrals = ₹388)
    const expectedBonus = 388;
    console.log('Expected bonus for 10 referrals:', expectedBonus);
    
    console.log('\n✅ Referral simulation completed successfully!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

cleanupAndSimulate();
