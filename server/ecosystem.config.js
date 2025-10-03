module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './backend/dist/server.js',
      cwd: '/var/www/win5x/server',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 82,
        DATABASE_URL: 'postgresql://win5x_user:Jhx82ndc9g@j@127.0.0.1:5432/win5x_game',
        REDIS_URL: 'redis://localhost:6379',
        JWT_SECRET: 'your_jwt_secret_key',
        JWT_REFRESH_SECRET: 'your_refresh_secret_key',
        ADMIN_EMAIL: 'admin@win5x.com',
        ADMIN_PASSWORD: 'admin123'
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      max_memory_restart: '1G',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
