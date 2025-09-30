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

async function testReferralClaim() {
  console.log('🎯 Testing Referral Bonus Claim');
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
      const wallet = walletResponse.data.data;
      console.log('💰 Current Wallet Balance:');
      console.log(`   Betting Wallet: ₹${wallet.betting}`);
      console.log(`   Gaming Wallet: ₹${wallet.gaming}`);
      console.log(`   Bonus Balance: ₹${wallet.bonus}`);
    }
    
    // Step 3: Get referral stats
    console.log('\n=== Step 3: Referral Stats ===');
    const referralResponse = await makeRequest(`${BASE_URL}/api/referral/stats`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (referralResponse.status === 200) {
      const stats = referralResponse.data.data;
      console.log('📊 Referral Statistics:');
      console.log(`   Referral Code: ${stats.referralCode}`);
      console.log(`   Total Referrals: ${stats.totalReferrals}`);
      console.log(`   Valid Referrals: ${stats.validReferrals}`);
      console.log(`   Total Earnings: ₹${stats.totalEarnings}`);
      console.log(`   Completed Tiers: ${stats.tiers.filter(t => t.status === 'completed').length}`);
    }
    
    // Step 4: Claim tier 3 bonus (10 referrals = ₹338)
    console.log('\n=== Step 4: Claim Tier 3 Bonus (₹338) ===');
    const claimResponse = await makeRequest(`${BASE_URL}/api/referral/claim/3`, {
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
    
    // Step 5: Check updated wallet balance
    console.log('\n=== Step 5: Updated Wallet Balance ===');
    const updatedWalletResponse = await makeRequest(`${BASE_URL}/api/user/wallets`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (updatedWalletResponse.status === 200) {
      const wallet = updatedWalletResponse.data.data;
      console.log('💰 Updated Wallet Balance:');
      console.log(`   Betting Wallet: ₹${wallet.betting}`);
      console.log(`   Gaming Wallet: ₹${wallet.gaming}`);
      console.log(`   Bonus Balance: ₹${wallet.bonus}`);
      console.log(`   Total: ₹${Number(wallet.betting) + Number(wallet.gaming) + Number(wallet.bonus)}`);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testReferralClaim();