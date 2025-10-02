#!/bin/bash

# Database Setup Script for Win5x
echo "========================================="
echo "    Win5x Database Setup Script"
echo "========================================="
echo

echo "🗄️ Step 1: Checking PostgreSQL installation..."
if ! command -v psql &> /dev/null; then
    echo "⚠️ PostgreSQL is not installed. Installing..."
    apt update
    apt install -y postgresql postgresql-contrib
    echo "✅ PostgreSQL installed!"
else
    echo "✅ PostgreSQL is already installed"
fi

echo
echo "🔄 Step 2: Starting PostgreSQL service..."
systemctl start postgresql
systemctl enable postgresql
echo "✅ PostgreSQL service started and enabled!"

echo
echo "🔧 Step 3: Configuring PostgreSQL..."
# Switch to postgres user and configure database
sudo -u postgres psql << 'EOF'
-- Create database if it doesn't exist
SELECT 'CREATE DATABASE win5x'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'win5x')\gexec

-- Create user if it doesn't exist
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'win5x') THEN

      CREATE ROLE win5x LOGIN PASSWORD 'win5x_password';
   END IF;
END
$do$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE win5x TO win5x;
ALTER USER win5x CREATEDB;

\q
EOF

echo "✅ Database and user configured!"

echo
echo "🔧 Step 4: Configuring PostgreSQL to accept connections..."
# Update postgresql.conf to listen on all addresses
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Update pg_hba.conf to allow connections
echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/*/main/pg_hba.conf

echo "✅ PostgreSQL configuration updated!"

echo
echo "🔄 Step 5: Restarting PostgreSQL..."
systemctl restart postgresql
echo "✅ PostgreSQL restarted!"

echo
echo "🧪 Step 6: Testing database connection..."
cd /var/www/kart/packages/backend
if pnpm prisma migrate deploy; then
    echo "✅ Database connection successful!"
else
    echo "⚠️ Database connection failed. Please check your .env file"
    echo "Make sure DATABASE_URL is set correctly:"
    echo "DATABASE_URL=\"postgresql://win5x:win5x_password@localhost:5432/win5x?schema=public\""
fi

echo
echo "========================================="
echo "✅ Database setup completed!"
echo "========================================="
echo
echo "📝 Database connection details:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: win5x"
echo "   Username: win5x"
echo "   Password: win5x_password"
echo
echo "🔗 Connection URL:"
echo "   postgresql://win5x:win5x_password@localhost:5432/win5x?schema=public"
echo
