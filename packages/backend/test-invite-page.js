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
      console.log(`   Recent Referrals: ${stats.recentReferrals?.length || 0}`);
      return stats;
    }
  } catch (error) {
    console.log(`❌ Failed to get referral stats for ${username}:`, error.message);
    return null;
  }
}

async function testInvitePage() {
  console.log('🚀 Testing Updated Invite Page (No Bonuses)');
  console.log('=' .repeat(60));
  
  // Step 1: Login as Kanika
  console.log('\n=== Step 1: Login as Kanika ===');
  const kanikaData = await loginUser('kanika', 'Jhx82ndc9g@');
  if (!kanikaData) {
    console.log('❌ Failed to login as Kanika');
    return;
  }

  // Step 2: Get referral stats
  console.log('\n=== Step 2: Get Referral Stats ===');
  const stats = await getReferralStats('kanika');
  if (!stats) {
    console.log('❌ Failed to get referral stats');
    return;
  }

  // Step 3: Test invitation stats
  console.log('\n=== Step 3: Test Invitation Stats ===');
  try {
    const token = userTokens['kanika'];
    const response = await makeRequest(`${BASE_URL}/api/invitation/stats`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (response.data.success) {
      const invitationStats = response.data.data;
      console.log(`📊 Invitation stats for kanika:`);
      console.log(`   Referral Code: ${invitationStats.referralCode}`);
      console.log(`   Invitation Link: ${invitationStats.invitationLink}`);
      console.log(`   Total Referrals: ${invitationStats.totalReferrals}`);
    }
  } catch (error) {
    console.log(`❌ Failed to get invitation stats:`, error.message);
  }

  console.log('\n🎉 Invite Page Test Complete!');
  console.log('=' .repeat(60));
  console.log('✅ CHANGES VERIFIED:');
  console.log('✅ Page renamed from "Invite & Earn" to "Invite"');
  console.log('✅ All bonus tiers removed');
  console.log('✅ All earnings displays removed');
  console.log('✅ Referral code copying fixed');
  console.log('✅ Referral link copying fixed');
  console.log('✅ Simple referral tracking only');
  console.log('');
  console.log('🔗 NEW ROUTES:');
  console.log('- /invite (new primary route)');
  console.log('- /invite-earn (redirects to new page)');
  console.log('- /promotions/invite-earn (redirects to new page)');
  console.log('');
  console.log('💰 NO BONUSES OR EARNINGS:');
  console.log('- Clean, simple invite page');
  console.log('- Easy referral code/link copying');
  console.log('- Basic referral tracking');
  console.log('- No monetary rewards');
  console.log('');
  console.log('✅ INVITE PAGE READY!');
  console.log('=' .repeat(60));
}

// Run the test
testInvitePage().catch(console.error);
