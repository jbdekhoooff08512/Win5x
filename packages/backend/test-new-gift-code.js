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

async function testNewGiftCode() {
  console.log('🎁 Testing New Gift Code Creation and Redemption');
  console.log('=' .repeat(60));
  
  try {
    // Step 1: Admin login
    console.log('\n=== Step 1: Admin Login ===');
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
    
    // Step 2: Create new gift code
    console.log('\n=== Step 2: Create New Gift Code ===');
    const timestamp = Date.now();
    const giftCodeData = {
      code: `TEST${timestamp}`,
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
      
      // Step 3: Atharv login
      console.log('\n=== Step 3: Atharv Login ===');
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
      
      // Step 4: Get current wallet balance
      console.log('\n=== Step 4: Current Wallet Balance ===');
      const walletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      });
      
      if (walletResponse.status === 200) {
        console.log('Current wallet balance:', JSON.stringify(walletResponse.data.data, null, 2));
      }
      
      // Step 5: Redeem new gift code
      console.log('\n=== Step 5: Redeem New Gift Code ===');
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
      
      // Step 6: Check updated wallet balance
      console.log('\n=== Step 6: Updated Wallet Balance ===');
      const updatedWalletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${userToken}`
        }
      });
      
      if (updatedWalletResponse.status === 200) {
        console.log('Updated wallet balance:', JSON.stringify(updatedWalletResponse.data.data, null, 2));
      }
      
    } else {
      console.log('❌ Gift code creation failed');
      console.log('Response:', JSON.stringify(createResponse.data, null, 2));
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testNewGiftCode();
