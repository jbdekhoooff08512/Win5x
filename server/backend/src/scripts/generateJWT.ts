#!/usr/bin/env ts-node

import { jwtGenerator } from '../utils/jwtGenerator';
import { config } from 'dotenv';

// Load environment variables
config();

interface GenerateTokenOptions {
  userId: string;
  username: string;
  type: 'user' | 'admin';
  role?: string;
  permissions?: string[];
  expiresIn?: string;
  custom?: boolean;
  customPayload?: any;
}

function printUsage() {
  console.log(`
JWT Token Generator

Usage:
  npm run generate-jwt [options]

Options:
  --userId <id>           User ID (required)
  --username <name>       Username (required)
  --type <type>           Token type: user or admin (required)
  --role <role>           Admin role (optional, for admin tokens)
  --permissions <perms>   Comma-separated permissions (optional, for admin tokens)
  --expiresIn <time>      Custom expiration time (e.g., 1h, 7d, 30m)
  --custom                Generate custom token with custom payload
  --customPayload <json>  Custom payload as JSON string

Examples:
  # Generate user token
  npm run generate-jwt --userId=123 --username=john --type=user

  # Generate admin token
  npm run generate-jwt --userId=456 --username=admin --type=admin --role=super --permissions=read,write

  # Generate custom token
  npm run generate-jwt --custom --customPayload='{"customField":"value"}' --expiresIn=2h

Environment Variables:
  JWT_SECRET              JWT signing secret (defaults to development secret)
  JWT_REFRESH_SECRET      JWT refresh secret (defaults to development secret)
  JWT_EXPIRES_IN          Default access token expiration (defaults to 15m)
  JWT_REFRESH_EXPIRES_IN  Default refresh token expiration (defaults to 7d)
`);
}

function parseArgs(): GenerateTokenOptions | null {
  const args = process.argv.slice(2);
  console.log('Debug: Raw arguments:', args);
  const options: Partial<GenerateTokenOptions> = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    console.log(`Debug: Processing arg ${i}: ${arg}`);
    
    if (arg === '--help' || arg === '-h') {
      printUsage();
      return null;
    }
    
    if (arg.startsWith('--')) {
      // Handle both --key=value and --key value formats
      if (arg.includes('=')) {
        // Format: --key=value
        const [keyPart, value] = arg.split('=', 2);
        const key = keyPart.slice(2) as keyof GenerateTokenOptions;
        console.log(`Debug: Found key=value format: ${key} = ${value}`);
        
        if (key === 'custom') {
          options[key] = true;
        } else if (key === 'permissions') {
          options[key] = value.split(',').map(p => p.trim());
        } else if (key === 'customPayload') {
          try {
            options[key] = JSON.parse(value);
          } catch {
            console.error('Invalid JSON payload');
            return null;
          }
        } else {
          (options as any)[key] = value;
        }
        console.log(`Debug: Set ${key} = ${(options as any)[key]}`);
      } else {
        // Format: --key value
        const key = arg.slice(2) as keyof GenerateTokenOptions;
        console.log(`Debug: Found key format: ${key}`);
        
        if (key === 'custom') {
          options[key] = true;
          continue;
        }
        
        const value = args[i + 1];
        console.log(`Debug: Key ${key} has value: ${value}`);
        
        if (value && !value.startsWith('--')) {
          if (key === 'permissions') {
            options[key] = value.split(',').map(p => p.trim());
          } else if (key === 'customPayload') {
            try {
              options[key] = JSON.parse(value);
            } catch {
              console.error('Invalid JSON payload');
              return null;
            }
          } else {
            (options as any)[key] = value;
          }
          console.log(`Debug: Set ${key} = ${(options as any)[key]}`);
          i++; // Skip next argument
        }
      }
    }
  }

  console.log('Debug: Final options:', options);

  // Validate required fields
  if (!options.userId || !options.username || !options.type) {
    console.error('Missing required fields: userId, username, and type are required');
    console.error('Found:', { userId: options.userId, username: options.username, type: options.type });
    printUsage();
    return null;
  }

  if (options.type === 'admin' && !options.role) {
    console.warn('Warning: Admin token without role specified');
  }

  return options as GenerateTokenOptions;
}

function generateToken(options: GenerateTokenOptions) {
  try {
    let tokens: { accessToken: string; refreshToken: string } | string;

    if (options.custom) {
      // Generate custom token
      const payload = options.customPayload || {};
      const expiresIn = options.expiresIn || '1h';
      tokens = jwtGenerator.generateCustomToken(payload, expiresIn);
      
      console.log('\n🔐 Custom JWT Token Generated');
      console.log('=' .repeat(50));
      console.log(`Token: ${tokens}`);
      console.log(`Expires In: ${expiresIn}`);
      
      // Decode and show payload
      const decoded = jwtGenerator.decodeToken(tokens);
      console.log('\n📋 Decoded Payload:');
      console.log(JSON.stringify(decoded, null, 2));
      
    } else {
      // Generate standard tokens
      if (options.type === 'admin') {
        tokens = jwtGenerator.generateAdminTokens(
          options.userId,
          options.username,
          options.role || 'admin',
          options.permissions || []
        );
      } else {
        tokens = jwtGenerator.generateUserTokens(
          options.userId,
          options.username
        );
      }

      console.log('\n🔐 JWT Tokens Generated');
      console.log('=' .repeat(50));
      console.log(`User ID: ${options.userId}`);
      console.log(`Username: ${options.username}`);
      console.log(`Type: ${options.type}`);
      if (options.role) console.log(`Role: ${options.role}`);
      if (options.permissions) console.log(`Permissions: ${options.permissions.join(', ')}`);
      
      console.log('\n📱 Access Token:');
      console.log(tokens.accessToken);
      
      console.log('\n🔄 Refresh Token:');
      console.log(tokens.refreshToken);
      
      // Decode and show access token payload
      const decoded = jwtGenerator.decodeToken(tokens.accessToken);
      console.log('\n📋 Decoded Access Token Payload:');
      console.log(JSON.stringify(decoded, null, 2));
      
      // Show expiration info
      const expiration = jwtGenerator.getTokenExpiration(tokens.accessToken);
      if (expiration) {
        console.log(`\n⏰ Access Token Expires: ${expiration.toISOString()}`);
        console.log(`⏰ Refresh Token Expires: ${jwtGenerator.getTokenExpiration(tokens.refreshToken)?.toISOString()}`);
      }
    }

    console.log('\n✅ Token generation successful!');
    
  } catch (error) {
    console.error('❌ Error generating token:', error);
    process.exit(1);
  }
}

function main() {
  const options = parseArgs();
  if (!options) {
    process.exit(1);
  }

  generateToken(options);
}

if (require.main === module) {
  main();
}
