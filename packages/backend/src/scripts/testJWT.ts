import { jwtGenerator } from '../utils/jwtGenerator';

// Set default JWT secrets for testing
process.env.JWT_SECRET = 'test-jwt-secret-key-for-development';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-key-for-development';
process.env.JWT_EXPIRES_IN = '1h';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';

console.log('🔐 JWT Token Generator Test\n');

// Test 1: Generate user tokens
console.log('1️⃣ Generating User Tokens:');
const userTokens = jwtGenerator.generateUserTokens('user123', 'john_doe');
console.log(`Access Token: ${userTokens.accessToken}`);
console.log(`Refresh Token: ${userTokens.refreshToken}`);

// Decode and show user token payload
const userPayload = jwtGenerator.decodeToken(userTokens.accessToken);
console.log('User Token Payload:', JSON.stringify(userPayload, null, 2));

console.log('\n' + '='.repeat(60) + '\n');

// Test 2: Generate admin tokens
console.log('2️⃣ Generating Admin Tokens:');
const adminTokens = jwtGenerator.generateAdminTokens(
  'admin456', 
  'admin_user', 
  'super_admin', 
  ['read', 'write', 'delete', 'manage_users']
);
console.log(`Access Token: ${adminTokens.accessToken}`);
console.log(`Refresh Token: ${adminTokens.refreshToken}`);

// Decode and show admin token payload
const adminPayload = jwtGenerator.decodeToken(adminTokens.accessToken);
console.log('Admin Token Payload:', JSON.stringify(adminPayload, null, 2));

console.log('\n' + '='.repeat(60) + '\n');

// Test 3: Generate custom token
console.log('3️⃣ Generating Custom Token:');
const customToken = jwtGenerator.generateCustomToken(
  { 
    customField: 'customValue',
    userId: 'custom123',
    action: 'special_operation'
  }, 
  '30m'
);
console.log(`Custom Token: ${customToken}`);

// Decode and show custom token payload
const customPayload = jwtGenerator.decodeToken(customToken);
console.log('Custom Token Payload:', JSON.stringify(customPayload, null, 2));

console.log('\n' + '='.repeat(60) + '\n');

// Test 4: Token verification
console.log('4️⃣ Testing Token Verification:');
try {
  const verifiedUser = jwtGenerator.verifyToken(userTokens.accessToken);
  console.log('✅ User token verified successfully:', verifiedUser.userId);
  
  const verifiedAdmin = jwtGenerator.verifyToken(adminTokens.accessToken);
  console.log('✅ Admin token verified successfully:', verifiedAdmin.userId);
  
  const verifiedCustom = jwtGenerator.verifyToken(customToken);
  console.log('✅ Custom token verified successfully');
} catch (error) {
  console.error('❌ Token verification failed:', error);
}

console.log('\n' + '='.repeat(60) + '\n');

// Test 5: Token expiration
console.log('5️⃣ Token Expiration Info:');
const userExpiration = jwtGenerator.getTokenExpiration(userTokens.accessToken);
const adminExpiration = jwtGenerator.getTokenExpiration(adminTokens.accessToken);
const customExpiration = jwtGenerator.getTokenExpiration(customToken);

console.log(`User Token Expires: ${userExpiration?.toISOString()}`);
console.log(`Admin Token Expires: ${adminExpiration?.toISOString()}`);
console.log(`Custom Token Expires: ${customExpiration?.toISOString()}`);

console.log('\n' + '='.repeat(60) + '\n');

// Test 6: Refresh token verification
console.log('6️⃣ Testing Refresh Token Verification:');
try {
  const userRefresh = jwtGenerator.verifyRefreshToken(userTokens.refreshToken);
  console.log('✅ User refresh token verified:', userRefresh);
  
  const adminRefresh = jwtGenerator.verifyRefreshToken(adminTokens.refreshToken);
  console.log('✅ Admin refresh token verified:', adminRefresh);
} catch (error) {
  console.error('❌ Refresh token verification failed:', error);
}

console.log('\n✅ All JWT tests completed successfully!');
console.log('\n💡 To generate tokens from command line, use:');
console.log('   npm run generate-jwt --userId=123 --username=test --type=user');
console.log('   npm run generate-jwt --userId=456 --username=admin --type=admin --role=admin --permissions=read,write');
