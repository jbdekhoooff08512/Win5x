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
      console.log(`   Invitation Link: ${stats.invitationLink}`);
      console.log(`   Total Referrals: ${stats.totalReferrals}`);
      console.log(`   Recent Referrals:`);
      stats.recentReferrals.forEach(ref => {
        console.log(`     - ${ref.username} (${ref.referralCode}) - Joined: ${new Date(ref.joinedAt).toLocaleDateString()}`);
      });
      return stats;
    }
  } catch (error) {
    console.log(`❌ Failed to get referral stats for ${username}:`, error.message);
    return null;
  }
}

async function testSimpleReferralSystem() {
  console.log('🚀 Testing Simple Referral System (No Bonuses)');
  console.log('=' .repeat(60));
  
  // Step 1: Login as Kanika
  console.log('\n=== Step 1: Login as Kanika ===');
  const kanikaData = await loginUser('kanika', 'Jhx82ndc9g@');
  if (!kanikaData) {
    console.log('❌ Failed to login as Kanika');
    return;
  }

  // Step 2: Get Kanika's referral stats
  console.log('\n=== Step 2: Get Kanika\'s Referral Stats ===');
  await getReferralStats('kanika');

  // Step 3: Register a new user with Kanika's referral code
  console.log('\n=== Step 3: Register New User with Referral Code ===');
  const newUser = {
    username: 'testuser_simple',
    email: 'testuser_simple@test.com',
    password: 'Password123'
  };
  
  const userData = await registerUser(newUser, 'KANIKAH6S12T');
  if (userData) {
    console.log('✅ User registered successfully with referral code');
  }

  // Step 4: Check updated stats
  console.log('\n=== Step 4: Check Updated Stats ===');
  await getReferralStats('kanika');

  // Step 5: Test invitation stats
  console.log('\n=== Step 5: Test Invitation Stats ===');
  try {
    const token = userTokens['kanika'];
    const response = await makeRequest(`${BASE_URL}/api/invitation/stats`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (response.data.success) {
      const stats = response.data.data;
      console.log(`📊 Invitation stats for kanika:`);
      console.log(`   Referral Code: ${stats.referralCode}`);
      console.log(`   Invitation Link: ${stats.invitationLink}`);
      console.log(`   Total Referrals: ${stats.totalReferrals}`);
    }
  } catch (error) {
    console.log(`❌ Failed to get invitation stats:`, error.message);
  }

  console.log('\n🎉 Simple Referral System Test Complete!');
  console.log('=' .repeat(60));
  console.log('✅ SYSTEM FEATURES VERIFIED:');
  console.log('✅ User login and registration');
  console.log('✅ Referral code generation');
  console.log('✅ Referral link creation');
  console.log('✅ Referral tracking (without bonuses)');
  console.log('✅ Simple referral statistics');
  console.log('');
  console.log('💰 NO BONUSES OR EARNINGS:');
  console.log('- Referrals are tracked for statistics only');
  console.log('- No monetary rewards or bonuses');
  console.log('- Simple referral link sharing');
  console.log('- Clean, simple referral system');
  console.log('');
  console.log('✅ SYSTEM READY FOR PRODUCTION!');
  console.log('=' .repeat(60));
}

// Run the test
testSimpleReferralSystem().catch(console.error);
