import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  base: '/admin/',  // Important for serving under /admin/
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@win5x/common': resolve(__dirname, '../common/src'),
    },
  },
  server: {
    host: true,
    port: 8081,
    proxy: {
      '/api': {
        target: process.env.VITE_PROXY_TARGET || 'https://nymex.store',
        changeOrigin: true,
      },
      '/socket.io': {
        target: process.env.VITE_PROXY_TARGET || 'https://nymex.store',
        changeOrigin: true,
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});