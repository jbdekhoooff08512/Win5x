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

async function testAtharvCurrentState() {
  console.log('🔍 Testing Atharv Current State');
  console.log('=' .repeat(50));
  
  try {
    // Step 1: Login as atharv
    console.log('\n=== Step 1: Atharv Login ===');
    const loginResponse = await makeRequest(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      body: JSON.stringify({
        username: 'atharv',
        password: 'Jhx82ndc9g@'
      })
    });
    
    console.log('Login Status:', loginResponse.status);
    if (loginResponse.status !== 200) {
      console.log('❌ Atharv login failed');
      console.log('Response:', JSON.stringify(loginResponse.data, null, 2));
      return;
    }
    
    const userToken = loginResponse.data.data.accessToken;
    const userId = loginResponse.data.data.user.id;
    console.log('✅ Atharv login successful');
    console.log('User ID:', userId);
    
    // Step 2: Get current wallet balance
    console.log('\n=== Step 2: Current Wallet Balance ===');
    const walletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (walletResponse.status === 200) {
      console.log('Current wallet balance:', JSON.stringify(walletResponse.data.data, null, 2));
    } else {
      console.log('❌ Failed to get wallet balance');
    }
    
    // Step 3: Get referral stats
    console.log('\n=== Step 3: Current Referral Stats ===');
    const referralResponse = await makeRequest(`${BASE_URL}/api/invitation/stats`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (referralResponse.status === 200) {
      console.log('Referral stats:', JSON.stringify(referralResponse.data.data, null, 2));
    } else {
      console.log('❌ Failed to get referral stats');
    }
    
    // Step 4: Admin login
    console.log('\n=== Step 4: Admin Login ===');
    const adminResponse = await makeRequest(`${BASE_URL}/api/auth/admin/login`, {
      method: 'POST',
      body: JSON.stringify({
        username: 'superadmin',
        password: 'superadmin123'
      })
    });
    
    if (adminResponse.status === 200) {
      console.log('✅ Admin login successful');
      const adminToken = adminResponse.data.data.accessToken;
      
      // Step 5: Check gift codes
      console.log('\n=== Step 5: Current Gift Codes ===');
      const giftCodesResponse = await makeRequest(`${BASE_URL}/api/gift-code/admin/gift-codes`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      
      if (giftCodesResponse.status === 200) {
        console.log('Gift codes:', JSON.stringify(giftCodesResponse.data.data, null, 2));
      } else {
        console.log('❌ Failed to get gift codes');
      }
    } else {
      console.log('❌ Admin login failed');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testAtharvCurrentState();
