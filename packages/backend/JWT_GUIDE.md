# JWT Token Guide

This guide explains how to use JWT tokens in the Win5x project.

## 🔐 Overview

The project uses JWT (JSON Web Tokens) for authentication with the following features:

- **Access Tokens**: Short-lived tokens (default: 15 minutes) for API access
- **Refresh Tokens**: Long-lived tokens (default: 7 days) for token renewal
- **User & Admin Support**: Different token types with role-based permissions
- **Automatic Refresh**: Built-in token refresh mechanism

## 🚀 Quick Start

### 1. Test JWT Generation

Run the test script to see JWT tokens in action:

```bash
cd packages/backend
npm run test-jwt
```

### 2. Generate Custom Tokens

Use the CLI tool to generate tokens:

```bash
# Generate user token
npm run generate-jwt --userId=123 --username=john --type=user

# Generate admin token
npm run generate-jwt --userId=456 --username=admin --type=admin --role=super --permissions=read,write

# Generate custom token
npm run generate-jwt --custom --customPayload='{"customField":"value"}' --expiresIn=2h
```

## 📋 Token Types

### User Tokens
```typescript
{
  userId: string;
  username: string;
  type: 'user';
  iat: number;    // Issued at
  exp: number;    // Expiration
}
```

### Admin Tokens
```typescript
{
  userId: string;
  username: string;
  type: 'admin';
  role: string;
  permissions: string[];
  iat: number;    // Issued at
  exp: number;    // Expiration
}
```

## 🛠️ API Usage

### Generate Tokens Programmatically

```typescript
import { jwtGenerator } from './utils/jwtGenerator';

// Generate user tokens
const userTokens = jwtGenerator.generateUserTokens('user123', 'john_doe');

// Generate admin tokens
const adminTokens = jwtGenerator.generateAdminTokens(
  'admin456', 
  'admin_user', 
  'super_admin', 
  ['read', 'write', 'delete']
);

// Generate custom token
const customToken = jwtGenerator.generateCustomToken(
  { customField: 'value' }, 
  '1h'
);
```

### Verify Tokens

```typescript
// Verify access token
const payload = jwtGenerator.verifyToken(token);

// Verify refresh token
const refreshData = jwtGenerator.verifyRefreshToken(refreshToken);

// Check if token is expired
const isExpired = jwtGenerator.isTokenExpired(token);
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the backend directory:

```env
# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key"
JWT_REFRESH_SECRET="your-super-secret-refresh-key"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"
```

### Default Values

If environment variables are not set, the system uses these defaults:

- `JWT_SECRET`: `"default-jwt-secret-change-in-production"`
- `JWT_REFRESH_SECRET`: `"default-refresh-secret-change-in-production"`
- `JWT_EXPIRES_IN`: `"15m"`
- `JWT_REFRESH_EXPIRES_IN`: `"7d"`

## 🔒 Security Best Practices

### 1. Strong Secrets
- Use cryptographically strong random strings (256+ bits)
- Never commit secrets to version control
- Use different secrets for different environments

### 2. Token Expiration
- Keep access tokens short-lived (15 minutes or less)
- Use refresh tokens for longer sessions
- Implement token rotation for sensitive operations

### 3. Validation
- Always verify tokens on the server side
- Check token expiration before processing requests
- Validate user permissions for admin operations

## 📱 Frontend Integration

### Store Tokens
```typescript
// Store tokens securely (localStorage for demo, use httpOnly cookies in production)
localStorage.setItem('accessToken', tokens.accessToken);
localStorage.setItem('refreshToken', tokens.refreshToken);
```

### Use in API Calls
```typescript
// Add to request headers
const response = await fetch('/api/protected', {
  headers: {
    'Authorization': `Bearer ${accessToken}`
  }
});
```

### Handle Token Refresh
```typescript
// Automatic refresh on 401 responses
if (response.status === 401) {
  const newTokens = await refreshToken(refreshToken);
  // Retry original request with new token
}
```

## 🧪 Testing

### Unit Tests
```bash
npm test
```

### Manual Testing
```bash
# Test JWT functionality
npm run test-jwt

# Generate specific tokens
npm run generate-jwt --help
```

## 🚨 Troubleshooting

### Common Issues

1. **"Token verification failed"**
   - Check if JWT_SECRET is set correctly
   - Verify token hasn't expired
   - Ensure token format is correct

2. **"Token expired"**
   - Use refresh token to get new access token
   - Check JWT_EXPIRES_IN configuration

3. **"Invalid token"**
   - Verify token structure
   - Check if token was signed with correct secret

### Debug Mode

Enable debug logging by setting:
```env
NODE_ENV=development
DEBUG=jwt:*
```

## 📚 Additional Resources

- [JWT.io](https://jwt.io/) - JWT debugger and documentation
- [jsonwebtoken npm package](https://www.npmjs.com/package/jsonwebtoken)
- [Express JWT middleware](https://github.com/auth0/express-jwt)

## 🔄 Migration from Old System

If you're upgrading from an older authentication system:

1. Update environment variables
2. Test token generation with new system
3. Verify existing tokens still work (if using same secret)
4. Update frontend to use new token format

## 📞 Support

For issues or questions:
1. Check the test scripts first
2. Review environment configuration
3. Check server logs for detailed error messages
4. Verify token payload structure
