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

let userTokens = {};
let referralCodes = {};
let adminToken = '';

async function loginAdmin() {
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
      return true;
    } else {
      console.log('❌ Admin login failed:', response.data.message);
      return false;
    }
  } catch (error) {
    console.log('❌ Admin login error:', error.message);
    return false;
  }
}

async function loginUser(username, password) {
  try {
    const response = await makeRequest(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      body: JSON.stringify({
        username,
        password
      })
    });
    
    if (response.data.success) {
      userTokens[username] = response.data.data.accessToken;
      console.log(`✅ Logged in: ${username}`);
      return response.data.data;
    } else {
      console.log(`❌ Login failed for ${username}:`, response.data.message);
      return null;
    }
  } catch (error) {
    console.log(`❌ Login error for ${username}:`, error.message);
    return null;
  }
}

async function registerUser(userData, referralCode = null) {
  try {
    const requestBody = { ...userData };
    if (referralCode) {
      requestBody.referralCode = referralCode;
    }
    
    const response = await makeRequest(`${BASE_URL}/api/auth/register`, {
      method: 'POST',
      body: JSON.stringify(requestBody)
    });
    
    if (response.data.success) {
      userTokens[userData.username] = response.data.data.accessToken;
      console.log(`✅ Registered: ${userData.username}`);
      return response.data.data;
    } else {
      console.log(`❌ Registration failed for ${userData.username}:`, response.data.message);
      return null;
    }
  } catch (error) {
    console.log(`❌ Registration error for ${userData.username}:`, error.message);
    return null;
  }
}

async function getReferralStats(username) {
  try {
    const token = userTokens[username];
    if (!token) {
      console.log(`❌ No token for ${username}`);
      return null;
    }

    const response = await makeRequest(`${BASE_URL}/api/referral/stats`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (response.data.success) {
      const stats = response.data.data;
      console.log(`📊 Referral stats for ${username}:`);
      console.log(`   Referral Code: ${stats.referralCode}`);
      console.log(`   Total Referrals: ${stats.totalReferrals}`);
      console.log(`   Valid Referrals: ${stats.validReferrals}`);
      console.log(`   Total Earnings: ₹${stats.totalEarnings}`);
      console.log(`   Tiers Status:`);
      stats.tiers.forEach(tier => {
        console.log(`     Tier ${tier.id}: ${tier.progress}/${tier.invitees} referrals - ${tier.status} - ₹${tier.reward}`);
      });
      return stats;
    }
  } catch (error) {
    console.log(`❌ Failed to get referral stats for ${username}:`, error.message);
    return null;
  }
}

async function createDepositRequest(username, amount) {
  try {
    const token = userTokens[username];
    if (!token) {
      console.log(`❌ No token for ${username}`);
      return null;
    }

    const response = await makeRequest(`${BASE_URL}/api/payment/deposit`, {
      method: 'POST',
      body: JSON.stringify({
        amount,
        paymentMethod: 'upi',
        reference: `KANIKA_TEST_${Date.now()}_${username}`
      }),
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (response.data.success) {
      console.log(`💰 Deposit request created for ${username}: ₹${amount}`);
      return response.data.data;
    }
  } catch (error) {
    console.log(`❌ Failed to create deposit request for ${username}:`, error.message);
    return null;
  }
}

async function approveDepositRequest(depositId) {
  try {
    const response = await makeRequest(`${BASE_URL}/api/payment/admin/deposits/${depositId}`, {
      method: 'PUT',
      body: JSON.stringify({
        action: 'approve',
        notes: 'Kanika 3-Tier Test Deposit'
      }),
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });
    
    if (response.data.success) {
      console.log(`✅ Deposit approved: ${depositId}`);
      return response.data.data;
    }
  } catch (error) {
    console.log(`❌ Failed to approve deposit ${depositId}:`, error.message);
    return null;
  }
}

async function claimReferralBonus(username, tierId) {
  try {
    const token = userTokens[username];
    if (!token) {
      console.log(`❌ No token for ${username}`);
      return null;
    }

    const response = await makeRequest(`${BASE_URL}/api/referral/claim/${tierId}`, {
      method: 'POST',
      body: JSON.stringify({}),
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (response.data.success) {
      console.log(`🎁 Tier ${tierId} bonus claimed for ${username}: ₹${response.data.data.amount}`);
      return response.data.data;
    } else {
      console.log(`❌ Failed to claim tier ${tierId} bonus for ${username}:`, response.data.message);
      return null;
    }
  } catch (error) {
    console.log(`❌ Failed to claim tier ${tierId} bonus for ${username}:`, error.message);
    return null;
  }
}

async function getWalletBalance(username) {
  try {
    const token = userTokens[username];
    if (!token) {
      console.log(`❌ No token for ${username}`);
      return null;
    }

    const response = await makeRequest(`${BASE_URL}/api/user/wallets`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (response.data.success) {
      const wallet = response.data.data;
      console.log(`💰 Wallet balance for ${username}:`);
      console.log(`   Betting: ₹${wallet.betting}`);
      console.log(`   Gaming: ₹${wallet.gaming}`);
      console.log(`   Bonus: ₹${wallet.bonus}`);
      console.log(`   Total: ₹${Number(wallet.betting) + Number(wallet.gaming) + Number(wallet.bonus)}`);
      return wallet;
    }
  } catch (error) {
    console.log(`❌ Failed to get wallet balance for ${username}:`, error.message);
    return null;
  }
}

async function testKanika3Tier() {
  console.log('🚀 Starting Kanika 3-Tier Referral System Test');
  console.log('=' .repeat(60));
  
  // Step 1: Login as admin
  console.log('\n=== Step 1: Admin Login ===');
  const adminLoggedIn = await loginAdmin();
  if (!adminLoggedIn) {
    console.log('❌ Cannot proceed without admin access');
    return;
  }

  // Step 2: Login as Kanika
  console.log('\n=== Step 2: Login as Kanika ===');
  const kanikaData = await loginUser('kanika', 'Jhx82ndc9g@');
  if (!kanikaData) {
    console.log('❌ Failed to login as Kanika');
    return;
  }

  // Step 3: Get initial stats
  console.log('\n=== Step 3: Initial Referral Stats ===');
  await getReferralStats('kanika');
  await getWalletBalance('kanika');

  // Step 4: Register 2 users for Tier 1
  console.log('\n=== Step 4: Registering 2 Users for Tier 1 ===');
  const tier1Users = [
    { username: 'kanika_tier1_1', email: 'kanika_tier1_1@test.com', password: 'Password123' },
    { username: 'kanika_tier1_2', email: 'kanika_tier1_2@test.com', password: 'Password123' }
  ];
  
  const depositRequests = [];
  for (const user of tier1Users) {
    const userData = await registerUser(user, 'KANIKAH6S12T');
    if (userData) {
      // Create deposit request for each user
      const deposit = await createDepositRequest(user.username, 200); // Tier 1 requires ₹200 deposit
      if (deposit) {
        depositRequests.push({ username: user.username, depositId: deposit.id });
      }
    }
  }

  // Step 5: Approve Tier 1 deposits
  console.log('\n=== Step 5: Approving Tier 1 Deposits ===');
  for (const req of depositRequests) {
    await approveDepositRequest(req.depositId);
  }

  // Step 6: Check Tier 1 completion and claim
  console.log('\n=== Step 6: Checking Tier 1 Completion ===');
  await getReferralStats('kanika');
  await getWalletBalance('kanika');
  
  console.log('\n=== Step 7: Claiming Tier 1 Bonus (₹58) ===');
  await claimReferralBonus('kanika', 1);

  // Step 8: Register 8 more users for Tier 2 (10 total)
  console.log('\n=== Step 8: Registering 8 More Users for Tier 2 (10 total) ===');
  const tier2Users = [
    { username: 'kanika_tier2_1', email: 'kanika_tier2_1@test.com', password: 'Password123' },
    { username: 'kanika_tier2_2', email: 'kanika_tier2_2@test.com', password: 'Password123' },
    { username: 'kanika_tier2_3', email: 'kanika_tier2_3@test.com', password: 'Password123' },
    { username: 'kanika_tier2_4', email: 'kanika_tier2_4@test.com', password: 'Password123' },
    { username: 'kanika_tier2_5', email: 'kanika_tier2_5@test.com', password: 'Password123' },
    { username: 'kanika_tier2_6', email: 'kanika_tier2_6@test.com', password: 'Password123' },
    { username: 'kanika_tier2_7', email: 'kanika_tier2_7@test.com', password: 'Password123' },
    { username: 'kanika_tier2_8', email: 'kanika_tier2_8@test.com', password: 'Password123' }
  ];
  
  const tier2DepositRequests = [];
  for (const user of tier2Users) {
    const userData = await registerUser(user, 'KANIKAH6S12T');
    if (userData) {
      // Create deposit request for each user
      const deposit = await createDepositRequest(user.username, 500); // Tier 2 requires ₹500 deposit
      if (deposit) {
        tier2DepositRequests.push({ username: user.username, depositId: deposit.id });
      }
    }
  }

  // Step 9: Approve Tier 2 deposits
  console.log('\n=== Step 9: Approving Tier 2 Deposits ===');
  for (const req of tier2DepositRequests) {
    await approveDepositRequest(req.depositId);
  }

  // Step 10: Check Tier 2 completion and claim
  console.log('\n=== Step 10: Checking Tier 2 Completion ===');
  await getReferralStats('kanika');
  await getWalletBalance('kanika');
  
  console.log('\n=== Step 11: Claiming Tier 2 Bonus (₹338) ===');
  await claimReferralBonus('kanika', 2);

  // Step 12: Register 90 more users for Tier 3 (100 total)
  console.log('\n=== Step 12: Registering 90 More Users for Tier 3 (100 total) ===');
  const tier3Users = [];
  for (let i = 1; i <= 90; i++) {
    tier3Users.push({
      username: `kanika_tier3_${i}`,
      email: `kanika_tier3_${i}@test.com`,
      password: 'Password123'
    });
  }
  
  const tier3DepositRequests = [];
  for (const user of tier3Users) {
    const userData = await registerUser(user, 'KANIKAH6S12T');
    if (userData) {
      // Create deposit request for each user
      const deposit = await createDepositRequest(user.username, 1200); // Tier 3 requires ₹1200 deposit
      if (deposit) {
        tier3DepositRequests.push({ username: user.username, depositId: deposit.id });
      }
    }
  }

  // Step 13: Approve Tier 3 deposits
  console.log('\n=== Step 13: Approving Tier 3 Deposits ===');
  for (const req of tier3DepositRequests) {
    await approveDepositRequest(req.depositId);
  }

  // Step 14: Check Tier 3 completion and claim
  console.log('\n=== Step 14: Checking Tier 3 Completion ===');
  await getReferralStats('kanika');
  await getWalletBalance('kanika');
  
  console.log('\n=== Step 15: Claiming Tier 3 Bonus (₹11,678) ===');
  await claimReferralBonus('kanika', 3);

  // Step 16: Final verification
  console.log('\n=== Step 16: Final Verification ===');
  await getReferralStats('kanika');
  await getWalletBalance('kanika');

  console.log('\n🎉 Kanika 3-Tier Referral System Test Complete!');
  console.log('=' .repeat(60));
  console.log('Summary:');
  console.log('- Tier 1: 2 referrals with ₹200 deposits each → ₹58 bonus');
  console.log('- Tier 2: 10 referrals with ₹500 deposits each → ₹338 bonus');
  console.log('- Tier 3: 100 referrals with ₹1200 deposits each → ₹11,678 bonus');
  console.log('- Total potential earnings: ₹12,074');
  console.log('- Kanika Referral Code: KANIKAH6S12T');
}

// Run the test
testKanika3Tier().catch(console.error);
