import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const envContent = `VITE_API_URL=http://localhost:3001
VITE_PROXY_TARGET=http://localhost:3001`;

const envPath = path.join(__dirname, '.env');

fs.writeFileSync(envPath, envContent);
console.log('✅ Updated user .env file with localhost configuration');
console.log('📝 API URL: http://localhost:3001');
console.log('🔄 Proxy Target: http://localhost:3001');
