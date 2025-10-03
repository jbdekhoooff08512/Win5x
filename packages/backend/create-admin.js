const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function createAdmin() {
  try {
    console.log('Creating admin user...');
    
    const password = 'superadmin123';
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    
    // Create admin user
    const admin = await prisma.admin.create({
      data: {
        username: 'superadmin',
        email: 'superadmin@win5x.com',
        password: hashedPassword,
        role: 'SUPER_ADMIN',
        permissions: ['MANAGE_BETS', 'MANAGE_USERS', 'MANAGE_WITHDRAWALS', 'MANAGE_DEPOSITS', 'VIEW_ANALYTICS', 'EMERGENCY_CONTROLS', 'MANAGE_TIMERS', 'GIFT_CODES']
      }
    });
    
    console.log('✅ Admin user created successfully');
    console.log('Username: superadmin');
    console.log('Password: superadmin123');
    console.log('Email: superadmin@win5x.com');
    
  } catch (error) {
    if (error.code === 'P2002') {
      console.log('Admin user already exists');
    } else {
      console.error('Error:', error.message);
    }
  } finally {
    await prisma.$disconnect();
  }
}

createAdmin();
