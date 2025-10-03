const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkPaymentMethods() {
  try {
    console.log('🔍 Checking Payment Methods');
    console.log('=' .repeat(30));
    
    const paymentMethods = await prisma.paymentMethod.findMany({
      select: { id: true, name: true, isActive: true }
    });
    
    console.log('Available payment methods:');
    paymentMethods.forEach(pm => {
      console.log(`- ${pm.id}: ${pm.name} (Active: ${pm.isActive})`);
    });
    
    if (paymentMethods.length === 0) {
      console.log('No payment methods found. Creating a default one...');
      
      const defaultMethod = await prisma.paymentMethod.create({
        data: {
          name: 'Default Payment',
          type: 'BANK_TRANSFER',
          isActive: true,
          config: {}
        }
      });
      
      console.log('✅ Created default payment method:', defaultMethod.id);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkPaymentMethods();