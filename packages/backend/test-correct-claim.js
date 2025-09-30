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

async function testCorrectClaim() {
  console.log('🎯 Testing Correct Referral Claim for Atharv');
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
    }
    
    // Step 3: Claim tier 3 bonus (10 referrals = ₹388)
    console.log('\n=== Step 3: Claim Tier 3 Bonus (₹388) ===');
    const claimResponse = await makeRequest(`${BASE_URL}/api/invitation/claim/3`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    console.log('Claim Status:', claimResponse.status);
    if (claimResponse.status === 200) {
      console.log('✅ Referral bonus claimed successfully');
      console.log('Response:', JSON.stringify(claimResponse.data, null, 2));
    } else {
      console.log('❌ Referral bonus claim failed');
      console.log('Response:', JSON.stringify(claimResponse.data, null, 2));
    }
    
    // Step 4: Check updated wallet balance
    console.log('\n=== Step 4: Updated Wallet Balance ===');
    const updatedWalletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (updatedWalletResponse.status === 200) {
      console.log('Updated wallet balance:', JSON.stringify(updatedWalletResponse.data.data, null, 2));
    }
    
    // Step 5: Test admin panel view
    console.log('\n=== Step 5: Admin Panel View ===');
    const adminResponse = await makeRequest(`${BASE_URL}/api/auth/admin/login`, {
      method: 'POST',
      body: JSON.stringify({
        username: 'superadmin',
        password: 'superadmin123'
      })
    });
    
    if (adminResponse.status === 200) {
      const adminToken = adminResponse.data.data.accessToken;
      const userId = '469c6cf9-e638-460f-9b40-c56f35f83d0c'; // atharv's ID
      
      const adminStatsResponse = await makeRequest(`${BASE_URL}/api/admin/invitation/${userId}/stats`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      
      if (adminStatsResponse.status === 200) {
        console.log('Admin panel referral stats:', JSON.stringify(adminStatsResponse.data.data, null, 2));
      }
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testCorrectClaim();
