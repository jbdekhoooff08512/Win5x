const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function resetAdminPassword() {
  try {
    console.log('Resetting admin password...');
    
    const newPassword = 'superadmin123';
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    
    // Update admin password
    const admin = await prisma.admin.update({
      where: { username: 'superadmin' },
      data: { password: hashedPassword }
    });
    
    console.log('✅ Admin password reset successfully');
    console.log('Username: superadmin');
    console.log('Password: superadmin123');
    
    // Also create a test user
    const testUserPassword = 'password123';
    const testUserHashedPassword = await bcrypt.hash(testUserPassword, saltRounds);
    
    const testUser = await prisma.user.upsert({
      where: { username: 'testuser' },
      update: { password: testUserHashedPassword },
      create: {
        username: 'testuser',
        email: 'testuser@example.com',
        password: testUserHashedPassword,
        referralCode: 'TESTUSER123'
      }
    });
    
    console.log('✅ Test user created/updated');
    console.log('Username: testuser');
    console.log('Password: password123');
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

resetAdminPassword();
