import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const methods = [
    {
      name: 'phonepe',
      displayName: 'PhonePe',
      isActive: true,
      upiId: '9999999999@ybl',
      qrCodeUrl: 'https://via.placeholder.com/256x256/4CAF50/FFFFFF?text=PhonePe+QR',
      qrCodeData: 'upi://pay?pa=9999999999@ybl&pn=Win5x&am=100&cu=INR',
      minAmount: 100,
      maxAmount: 100000,
      instructions: 'Pay using UPI. After payment, enter UTR to verify.'
    },
    {
      name: 'googlepay',
      displayName: 'Google Pay',
      isActive: true,
      upiId: '9999999999@okaxis',
      qrCodeUrl: 'https://via.placeholder.com/256x256/4285F4/FFFFFF?text=Google+Pay+QR',
      qrCodeData: 'upi://pay?pa=9999999999@okaxis&pn=Win5x&am=100&cu=INR',
      minAmount: 100,
      maxAmount: 100000,
      instructions: 'Pay using UPI. After payment, enter UTR to verify.'
    },
    {
      name: 'paytm',
      displayName: 'Paytm',
      isActive: true,
      upiId: '9999999999@paytm',
      qrCodeUrl: 'https://via.placeholder.com/256x256/00BAF2/FFFFFF?text=Paytm+QR',
      qrCodeData: 'upi://pay?pa=9999999999@paytm&pn=Win5x&am=100&cu=INR',
      minAmount: 100,
      maxAmount: 100000,
      instructions: 'Pay using UPI. After payment, enter UTR to verify.'
    },
    {
      name: 'usdt',
      displayName: 'USDT (TRC20)',
      isActive: false,
      walletAddress: 'TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE',
      qrCodeUrl: 'https://via.placeholder.com/256x256/FF6B35/FFFFFF?text=USDT+QR',
      qrCodeData: 'TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE',
      minAmount: 1000,
      maxAmount: 500000,
      instructions: 'Send USDT to the above address and provide TXID.'
    }
  ];

  for (const m of methods) {
    const existing = await prisma.paymentMethod.findUnique({ where: { name: m.name } });
    if (existing) {
      await prisma.paymentMethod.update({ where: { id: existing.id }, data: m });
      console.log(`Updated payment method: ${m.displayName}`);
    } else {
      await prisma.paymentMethod.create({ data: m });
      console.log(`Created payment method: ${m.displayName}`);
    }
  }
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });


