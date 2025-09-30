import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';

const prisma = new PrismaClient();

// Generate secure random password
function generateSecurePassword(length: number = 12): string {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length));
  }
  return password;
}

// Generate simple password for easier testing
function generateSimplePassword(): string {
  return 'password123';
}

async function resetAdminCredentials() {
  console.log('🔐 Resetting admin credentials...');
  
  const adminUsername = 'admin';
  const adminEmail = 'admin@win5x.com';
  const newPassword = generateSimplePassword(); // Using simple password for testing
  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);
  const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

  try {
    // Check if admin exists
    const existingAdmin = await prisma.admin.findUnique({
      where: { username: adminUsername }
    });

    if (existingAdmin) {
      // Update existing admin
      await prisma.admin.update({
        where: { id: existingAdmin.id },
        data: {
          password: hashedPassword,
          isActive: true,
          updatedAt: new Date()
        }
      });
      console.log('✅ Updated existing admin account');
    } else {
      // Create new admin
      await prisma.admin.create({
        data: {
          username: adminUsername,
          email: adminEmail,
          password: hashedPassword,
          role: 'SUPER_ADMIN',
          permissions: [
            'MANAGE_BETS',
            'MANAGE_USERS', 
            'MANAGE_WITHDRAWALS',
            'MANAGE_DEPOSITS',
            'VIEW_ANALYTICS',
            'EMERGENCY_CONTROLS',
            'MANAGE_TIMERS'
          ],
          isActive: true
        }
      });
      console.log('✅ Created new admin account');
    }

    console.log('📝 Admin Login Credentials:');
    console.log(`   Username: ${adminUsername}`);
    console.log(`   Email: ${adminEmail}`);
    console.log(`   Password: ${newPassword}`);
    console.log('');

  } catch (error) {
    console.error('❌ Error resetting admin credentials:', error);
    throw error;
  }
}

async function resetUserCredentials() {
  console.log('👤 Resetting user credentials...');
  
  const testUsers = [
    { username: 'testuser', email: 'testuser@win5x.com' },
    { username: 'user1', email: 'user1@win5x.com' },
    { username: 'demo', email: 'demo@win5x.com' }
  ];

  const newPassword = generateSimplePassword(); // Using simple password for testing
  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);
  const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

  try {
    for (const userData of testUsers) {
      const existingUser = await prisma.user.findUnique({
        where: { username: userData.username }
      });

      if (existingUser) {
        // Update existing user
        await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            password: hashedPassword,
            isActive: true,
            mustChangePassword: false,
            updatedAt: new Date()
          }
        });
        console.log(`✅ Updated existing user: ${userData.username}`);
      } else {
        // Create new user
        const referralCode = userData.username.toUpperCase() + Math.random().toString(36).substr(2, 4).toUpperCase();
        
        await prisma.user.create({
          data: {
            username: userData.username,
            email: userData.email,
            password: hashedPassword,
            referralCode: referralCode,
            walletBetting: 10000, // ₹10,000 initial balance
            walletGaming: 0,
            isActive: true,
            mustChangePassword: false
          }
        });
        console.log(`✅ Created new user: ${userData.username}`);
      }
    }

    console.log('📝 User Login Credentials:');
    testUsers.forEach(user => {
      console.log(`   Username: ${user.username} | Email: ${user.email}`);
    });
    console.log(`   Password: ${newPassword} (for all users)`);
    console.log('');

  } catch (error) {
    console.error('❌ Error resetting user credentials:', error);
    throw error;
  }
}

async function main() {
  console.log('🚀 Starting credential reset process...\n');
  
  try {
    await resetAdminCredentials();
    await resetUserCredentials();
    
    console.log('🎉 Credential reset completed successfully!');
    console.log('\n📋 Summary:');
    console.log('   ✅ Admin credentials reset');
    console.log('   ✅ User credentials reset');
    console.log('   ✅ All accounts are active and ready to use');
    console.log('\n🔗 You can now login with the credentials shown above.');
    
  } catch (error) {
    console.error('❌ Credential reset failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the script
main();


