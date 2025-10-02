const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function fixWageringRequirements() {
  try {
    console.log('🔧 Fixing wagering requirements for existing users...\n');
    
    // Get all users who have deposits but no wagering requirement
    const users = await prisma.user.findMany({
      where: {
        walletBetting: { gt: 0 },
        wageringRequired: 0
      },
      select: {
        id: true,
        username: true,
        walletBetting: true,
        wageringRequired: true,
        wageringProgress: true,
      }
    });

    console.log(`Found ${users.length} users with deposits but no wagering requirement:\n`);

    for (const user of users) {
      const bettingBalance = Number(user.walletBetting);
      
      // Calculate wagering requirement based on current balance
      // Assuming the balance is from deposits, set 5x requirement
      const newWageringRequired = bettingBalance * 5;
      
      console.log(`👤 ${user.username}:`);
      console.log(`   Current Balance: ₹${bettingBalance}`);
      console.log(`   Current Wagering Required: ₹${user.wageringRequired || 0}`);
      console.log(`   New Wagering Required: ₹${newWageringRequired}`);
      console.log(`   Current Wagering Progress: ₹${user.wageringProgress || 0}`);
      
      // Update the user's wagering requirement
      await prisma.user.update({
        where: { id: user.id },
        data: {
          wageringRequired: newWageringRequired
        }
      });
      
      console.log(`   ✅ Updated successfully!\n`);
    }

    console.log('🎯 All wagering requirements have been fixed!');
    
    // Show updated status
    console.log('\n📊 Updated User Status:');
    console.log('=' .repeat(60));
    
    const updatedUsers = await prisma.user.findMany({
      where: { walletBetting: { gt: 0 } },
      select: {
        username: true,
        walletBetting: true,
        wageringRequired: true,
        wageringProgress: true,
      }
    });

    updatedUsers.forEach((user, index) => {
      const bettingBalance = Number(user.walletBetting);
      const wageringRequired = user.wageringRequired || 0;
      const wageringProgress = user.wageringProgress || 0;
      const remaining = Math.max(0, wageringRequired - wageringProgress);
      
      console.log(`${index + 1}. ${user.username}`);
      console.log(`   Balance: ₹${bettingBalance}`);
      console.log(`   Wagering Required: ₹${wageringRequired}`);
      console.log(`   Wagering Progress: ₹${wageringProgress}`);
      console.log(`   Remaining: ₹${remaining}`);
      console.log(`   Can Withdraw: ${wageringRequired === 0 || wageringProgress >= wageringRequired ? '✅ YES' : '❌ NO'}`);
      console.log('-'.repeat(40));
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixWageringRequirements();

