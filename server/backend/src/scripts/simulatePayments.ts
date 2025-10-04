import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function simulate() {
  const username = process.argv[2] || '4';
  const adminUsername = process.argv[3] || 'admin';
  const amount = Number(process.argv[4] || 500);

  console.log(`🔎 Using user=${username}, admin=${adminUsername}, amount=₹${amount}`);

  const user = await prisma.user.findUnique({ where: { username } });
  if (!user) throw new Error(`User ${username} not found`);
  const admin = await prisma.admin.findUnique({ where: { username: adminUsername } });
  if (!admin) throw new Error(`Admin ${adminUsername} not found`);

  // Ensure a payment method exists
  const pm = await prisma.paymentMethod.findFirst({ where: { isActive: true } });
  if (!pm) throw new Error('No active payment method found. Run seedPaymentMethods.ts');

  console.log('➡️  Creating deposit request...');
  const depositReq = await prisma.depositRequest.create({
    data: {
      userId: user.id,
      paymentMethodId: pm.id,
      amount,
      utrCode: `UTR-${Date.now()}`,
      status: 'PENDING',
    },
  });
  console.log('✅ Deposit request created:', depositReq.id);

  console.log('➡️  Approving deposit...');
  const beforeDep = await prisma.user.findUnique({ where: { id: user.id }, select: { walletBetting: true } });
  const approvedDep = await prisma.depositRequest.update({
    where: { id: depositReq.id },
    data: { status: 'APPROVED', approvedBy: admin.id, approvedAt: new Date() },
  });
  const txDep = await prisma.transaction.create({
    data: { userId: user.id, type: 'DEPOSIT', amount, status: 'COMPLETED', description: `Simulated deposit ${approvedDep.id}`, approvedBy: admin.id },
  });
  await prisma.user.update({ where: { id: user.id }, data: { walletBetting: { increment: amount } } });
  const afterDep = await prisma.user.findUnique({ where: { id: user.id }, select: { walletBetting: true } });
  console.log('💰 Deposit approved', { txId: txDep.id, before: beforeDep?.walletBetting, after: afterDep?.walletBetting });

  console.log('➡️  Creating withdrawal request...');
  const wdReq = await prisma.withdrawalRequest.create({
    data: {
      userId: user.id,
      amount: Math.min(amount / 2, Number(afterDep?.walletBetting || 0) || amount),
      paymentMethod: 'UPI',
      accountDetails: JSON.stringify({ upiId: 'test@upi' }),
      status: 'PENDING',
    },
  });
  console.log('✅ Withdrawal request created:', wdReq.id);

  console.log('➡️  Approving withdrawal...');
  const approvedWd = await prisma.withdrawalRequest.update({
    where: { id: wdReq.id },
    data: { status: 'APPROVED', approvedBy: admin.id, approvedAt: new Date() },
  });
  const txWd = await prisma.transaction.create({
    data: { userId: user.id, type: 'WITHDRAWAL', amount: -approvedWd.amount, status: 'COMPLETED', description: `Simulated withdrawal ${approvedWd.id}`, approvedBy: admin.id },
  });
  const afterWd = await prisma.user.findUnique({ where: { id: user.id }, select: { walletBetting: true } });
  console.log('🏦 Withdrawal approved', { txId: txWd.id, amount: approvedWd.amount, balanceAfter: afterWd?.walletBetting });

  console.log('➡️  Creating another withdrawal to reject...');
  const wdReq2 = await prisma.withdrawalRequest.create({
    data: {
      userId: user.id,
      amount: Math.min(approvedWd.amount / 2, Number(afterWd?.walletBetting || 0) || approvedWd.amount),
      paymentMethod: 'UPI',
      accountDetails: JSON.stringify({ upiId: 'test@upi' }),
      status: 'PENDING',
    },
  });
  console.log('✅ Withdrawal request created (to reject):', wdReq2.id);

  console.log('🚫 Rejecting withdrawal...');
  const beforeRej = await prisma.user.findUnique({ where: { id: user.id }, select: { walletBetting: true } });
  const rejected = await prisma.withdrawalRequest.update({
    where: { id: wdReq2.id },
    data: { status: 'REJECTED', approvedBy: admin.id, approvedAt: new Date(), rejectionReason: 'Diagnostics test' },
  });
  const afterRej = await prisma.user.findUnique({ where: { id: user.id }, select: { walletBetting: true } });
  console.log('↩️  Withdrawal rejected', { id: rejected.id, before: beforeRej?.walletBetting, after: afterRej?.walletBetting });

  console.log('📊 Totals check:');
  const depSum = await prisma.depositRequest.aggregate({ where: { status: 'APPROVED' }, _sum: { amount: true } });
  const wdSum = await prisma.withdrawalRequest.aggregate({ where: { status: 'APPROVED' }, _sum: { amount: true } });
  console.log('   Approved Deposits:', depSum._sum.amount || 0);
  console.log('   Approved Withdrawals:', wdSum._sum.amount || 0);
}

simulate()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });


