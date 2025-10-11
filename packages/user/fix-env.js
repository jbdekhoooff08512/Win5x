import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const envContent = `VITE_API_URL=https://nymex.store
VITE_PROXY_TARGET=https://nymex.store`;

const envPath = path.join(__dirname, '.env');

fs.writeFileSync(envPath, envContent);
console.log('✅ Updated user .env file with production configuration');
console.log('📝 API URL: https://nymex.store');
console.log('🔄 Proxy Target: https://nymex.store');
