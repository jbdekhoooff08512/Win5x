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

async function testFinalBalance() {
  console.log('🎯 Testing Final Balance Calculation');
  console.log('=' .repeat(50));
  
  try {
    // Step 1: Atharv login
    console.log('\n=== Step 1: Atharv Login ===');
    const userResponse = await makeRequest(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      body: JSON.stringify({
        username: 'atharv',
        password: 'Jhx82ndc9g@'
      })
    });
    
    if (userResponse.status !== 200) {
      console.log('❌ Atharv login failed');
      return;
    }
    
    const userToken = userResponse.data.data.accessToken;
    console.log('✅ Atharv login successful');
    
    // Step 2: Admin login
    console.log('\n=== Step 2: Admin Login ===');
    const adminResponse = await makeRequest(`${BASE_URL}/api/auth/admin/login`, {
      method: 'POST',
      body: JSON.stringify({
        username: 'superadmin',
        password: 'superadmin123'
      })
    });
    
    if (adminResponse.status !== 200) {
      console.log('❌ Admin login failed');
      return;
    }
    
    const adminToken = adminResponse.data.data.accessToken;
    console.log('✅ Admin login successful');
    
    // Step 3: Create new gift code
    console.log('\n=== Step 3: Create New Gift Code ===');
    const timestamp = Date.now();
    const giftCodeData = {
      code: `FINAL${timestamp}`,
      amount: 490,
      usageLimit: 1,
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    };
    
    const createResponse = await makeRequest(`${BASE_URL}/api/gift-code/admin/gift-codes`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify(giftCodeData)
    });
    
    console.log('Create Status:', createResponse.status);
    if (createResponse.status === 201) {
      console.log('✅ Gift code created successfully');
      console.log('Code:', createResponse.data.data.code);
      console.log('Amount:', createResponse.data.data.amount);
      
      const giftCode = createResponse.data.data.code;
      
      // Step 4: Get current wallet balance
      console.log('\n=== Step 4: Current Wallet Balance ===');
      const walletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      });
      
      if (walletResponse.status === 200) {
        const wallet = walletResponse.data.data;
        console.log('💰 Current Wallet Balance:');
        console.log(`   Betting Wallet: ₹${wallet.betting}`);
        console.log(`   Gaming Wallet: ₹${wallet.gaming}`);
        console.log(`   Bonus Balance: ₹${wallet.bonus}`);
        console.log(`   Total: ₹${Number(wallet.betting) + Number(wallet.gaming) + Number(wallet.bonus)}`);
      }
      
      // Step 5: Redeem gift code
      console.log('\n=== Step 5: Redeem Gift Code ===');
      const redeemResponse = await makeRequest(`${BASE_URL}/api/gift-code/user/redeem-code`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${userToken}`
        },
        body: JSON.stringify({ code: giftCode })
      });
      
      console.log('Redeem Status:', redeemResponse.status);
      if (redeemResponse.status === 200) {
        console.log('✅ Gift code redeemed successfully');
        console.log('Response:', JSON.stringify(redeemResponse.data, null, 2));
      } else {
        console.log('❌ Gift code redemption failed');
        console.log('Response:', JSON.stringify(redeemResponse.data, null, 2));
      }
      
      // Step 6: Check final wallet balance
      console.log('\n=== Step 6: Final Wallet Balance ===');
      const finalWalletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      });
      
      if (finalWalletResponse.status === 200) {
        const wallet = finalWalletResponse.data.data;
        console.log('💰 Final Wallet Balance:');
        console.log(`   Betting Wallet: ₹${wallet.betting}`);
        console.log(`   Gaming Wallet: ₹${wallet.gaming}`);
        console.log(`   Bonus Balance: ₹${wallet.bonus}`);
        console.log(`   Total: ₹${Number(wallet.betting) + Number(wallet.gaming) + Number(wallet.bonus)}`);
        
        // Calculate expected balance
        const expectedGaming = 1038 + 490; // Previous gaming + gift code
        const expectedBonus = 2096; // Previous bonus (including ₹338 referral)
        const expectedTotal = 4550 + expectedGaming + expectedBonus;
        
        console.log('\n=== Step 7: Expected vs Actual ===');
        console.log(`Expected Gaming Wallet: ₹${expectedGaming}`);
        console.log(`Actual Gaming Wallet: ₹${wallet.gaming}`);
        console.log(`Expected Bonus Balance: ₹${expectedBonus}`);
        console.log(`Actual Bonus Balance: ₹${wallet.bonus}`);
        console.log(`Expected Total: ₹${expectedTotal}`);
        console.log(`Actual Total: ₹${Number(wallet.betting) + Number(wallet.gaming) + Number(wallet.bonus)}`);
        
        if (Number(wallet.gaming) === expectedGaming && Number(wallet.bonus) === expectedBonus) {
          console.log('\n🎉 SUCCESS: Final balance matches expected calculation!');
        } else {
          console.log('\n❌ Mismatch: Final balance does not match expected calculation');
        }
      }
    } else {
      console.log('❌ Gift code creation failed');
      console.log('Response:', JSON.stringify(createResponse.data, null, 2));
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Stack:', error.stack);
  }
}

testFinalBalance();
