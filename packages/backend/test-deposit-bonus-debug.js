const https = require('https');
const http = require('http');

const BASE_URL = 'http://localhost:3001';

function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const client = isHttps ? https : http;
    
    const requestOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    };

    if (options.body) {
      requestOptions.headers['Content-Length'] = Buffer.byteLength(options.body);
    }

    const req = client.request(requestOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve({ status: res.statusCode, data: jsonData });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on('error', (err) => reject(err));
    
    if (options.body) {
      req.write(options.body);
    }
    
    req.end();
  });
}

async function testDepositBonusDebug() {
  console.log('🔍 Debugging Deposit Bonus Issue');
  console.log('=' .repeat(50));
  
  // Step 1: Login as admin
  console.log('\n=== Step 1: Login as Admin ===');
  let adminToken = '';
  try {
    const response = await makeRequest(`${BASE_URL}/api/auth/admin/login`, {
      method: 'POST',
      body: JSON.stringify({
        username: 'superadmin',
        password: 'superadmin123'
      })
    });
    
    if (response.data.success) {
      adminToken = response.data.data.accessToken;
      console.log('✅ Admin logged in successfully');
    } else {
      console.log('❌ Admin login failed:', response.data.message);
      return;
    }
  } catch (error) {
    console.log('❌ Admin login error:', error.message);
    return;
  }

  // Step 2: Check promotions config
  console.log('\n=== Step 2: Check Promotions Config ===');
  try {
    const response = await makeRequest(`${BASE_URL}/api/user/promotions/config`);
    
    if (response.status === 200 && response.data.success) {
      const config = response.data.data;
      console.log(`✅ Deposit Bonus Percentage: ${config.depositBonusPct}%`);
    } else {
      console.log('❌ Promotions config failed:', response.data.message);
    }
  } catch (error) {
    console.log('❌ Promotions config error:', error.message);
  }

  // Step 3: Check recent deposits
  console.log('\n=== Step 3: Check Recent Deposits ===');
  try {
    const response = await makeRequest(`${BASE_URL}/api/payment/admin/deposits?pageSize=10`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    if (response.status === 200 && response.data.success) {
      const deposits = response.data.data.deposits;
      console.log(`✅ Found ${deposits.length} recent deposits`);
      
      deposits.forEach((deposit, index) => {
        console.log(`\n   Deposit ${index + 1}:`);
        console.log(`   - ID: ${deposit.id}`);
        console.log(`   - Amount: ₹${deposit.amount}`);
        console.log(`   - Status: ${deposit.status}`);
        console.log(`   - Payment Method: ${deposit.paymentMethod?.displayName || 'Unknown'}`);
        console.log(`   - User: ${deposit.user?.username || 'Unknown'}`);
        console.log(`   - Created: ${deposit.createdAt}`);
        console.log(`   - Approved: ${deposit.approvedAt || 'Not approved'}`);
      });
    } else {
      console.log('❌ Failed to fetch deposits:', response.data.message);
    }
  } catch (error) {
    console.log('❌ Deposits fetch error:', error.message);
  }

  // Step 4: Check user's bonus wallet balance
  console.log('\n=== Step 4: Check User Bonus Wallet ===');
  try {
    const response = await makeRequest(`${BASE_URL}/api/user/wallet`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    if (response.status === 200 && response.data.success) {
      const wallet = response.data.data;
      console.log('✅ User wallet info:');
      console.log(`   - Betting Wallet: ₹${wallet.betting}`);
      console.log(`   - Bonus Wallet: ₹${wallet.bonus}`);
      console.log(`   - Gaming Wallet: ₹${wallet.gaming}`);
    } else {
      console.log('❌ Failed to fetch wallet:', response.data.message);
    }
  } catch (error) {
    console.log('❌ Wallet fetch error:', error.message);
  }

  // Step 5: Check recent transactions for bonus credits
  console.log('\n=== Step 5: Check Recent Transactions ===');
  try {
    const response = await makeRequest(`${BASE_URL}/api/user/transactions?pageSize=20`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    if (response.status === 200 && response.data.success) {
      const transactions = response.data.data.transactions;
      console.log(`✅ Found ${transactions.length} recent transactions`);
      
      const bonusTransactions = transactions.filter(t => t.type === 'BONUS_CREDIT');
      console.log(`\n   Bonus Credit Transactions: ${bonusTransactions.length}`);
      
      bonusTransactions.forEach((tx, index) => {
        console.log(`\n   Bonus ${index + 1}:`);
        console.log(`   - Amount: ₹${tx.amount}`);
        console.log(`   - Description: ${tx.description}`);
        console.log(`   - Status: ${tx.status}`);
        console.log(`   - Date: ${tx.createdAt}`);
      });
      
      if (bonusTransactions.length === 0) {
        console.log('   ❌ No bonus credit transactions found!');
        console.log('   This confirms the bonus is not being credited.');
      }
    } else {
      console.log('❌ Failed to fetch transactions:', response.data.message);
    }
  } catch (error) {
    console.log('❌ Transactions fetch error:', error.message);
  }

  console.log('\n🎯 Debug Summary:');
  console.log('If no bonus transactions are found, the issue is in the PaymentService');
  console.log('Check the server logs for any errors during deposit approval');
  console.log('=' .repeat(50));
}

// Run the test
testDepositBonusDebug().catch(console.error);
