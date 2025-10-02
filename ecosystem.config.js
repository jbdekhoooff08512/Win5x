module.exports = {
  apps: [
    {
      name: 'win5x-backend',
      script: './packages/backend/dist/index.js',
      cwd: '/var/www/kart',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      max_memory_restart: '1G',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-admin',
      script: 'serve',
      args: '-s packages/admin/dist -l 8081',
      cwd: '/var/www/kart',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/admin-error.log',
      out_file: './logs/admin-out.log',
      log_file: './logs/admin-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'win5x-user',
      script: 'serve',
      args: '-s packages/user/dist -l 8080',
      cwd: '/var/www/kart',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/user-error.log',
      out_file: './logs/user-out.log',
      log_file: './logs/user-combined.log',
      time: true,
      max_memory_restart: '500M',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ]
};
