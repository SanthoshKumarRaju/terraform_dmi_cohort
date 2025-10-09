#!/bin/bash

# Set environment variables from Terraform templatefile
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"
DB_PASSWORD="${db_password}"
GITHUB_REPO="${github_repo}"
BRANCH="${branch}"
APP_VERSION="${app_version}"
INSTANCE_INDEX="${instance_index}"

# Log setup process
exec > >(tee /var/log/epicbook-setup.log) 2>&1
echo "Starting EpicBook setup on instance $INSTANCE_INDEX at $(date)"

# Update system and install basic packages
echo "Updating system packages..."
apt-get update
apt-get upgrade -y
apt-get install -y curl wget gnupg software-properties-common

# Install Node.js 18.x
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install MySQL client, Nginx, and other dependencies
echo "Installing dependencies..."
apt-get install -y mysql-client nginx git build-essential

# Install PM2 for process management
echo "Installing PM2..."
npm install -g pm2

# Create application directory
echo "Setting up application directory..."
mkdir -p /opt/epicbook
cd /opt/epicbook

# Clone the EpicBook application repository
echo "Cloning EpicBook repository from $GITHUB_REPO..."
git clone $GITHUB_REPO .
git checkout $BRANCH

# Install backend dependencies
echo "Installing backend dependencies..."
cd backend
npm install

# Create backend environment file for EpicBook
echo "Configuring EpicBook environment..."
cat > .env << EOC
# Database Configuration
DB_HOST=$DB_HOST
DB_USER=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME

# Application Configuration
NODE_ENV=production
PORT=3000
JWT_SECRET=epicbook-super-secret-jwt-key-change-in-production-$(date +%s)
EOC

# Install frontend dependencies and build
echo "Building EpicBook frontend..."
cd ../frontend
npm install
npm run build

# Create Nginx configuration for EpicBook
echo "Configuring Nginx for EpicBook..."
cat > /etc/nginx/sites-available/epicbook << EOC
server {
    listen 80;
    server_name _;
    root /opt/epicbook/frontend/build;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Serve static files
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy API requests to EpicBook backend
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Health check endpoint for EpicBook
    location /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 "healthy\n";
    }
}
EOC

# Enable EpicBook nginx site
echo "Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/epicbook /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Start EpicBook backend with PM2
echo "Starting EpicBook backend..."
cd /opt/epicbook/backend
pm2 start server.js --name "epicbook-backend"
pm2 startup
pm2 save

# Configure nginx to start on boot and restart it
echo "Starting Nginx..."
systemctl enable nginx
systemctl restart nginx

# Wait for database to be ready
echo "Waiting for database connection..."
for i in {1..30}; do
    if mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
        echo "Database connection successful!"
        break
    else
        echo "Attempt $i: Database not ready yet..."
        sleep 10
    fi
done

# Initialize EpicBook database schema if needed
echo "Initializing EpicBook database..."
if mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "USE $DB_NAME;" 2>/dev/null; then
    echo "Database $DB_NAME exists."
    
    # Create a simple books table if it doesn't exist
    mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" << EOSQL 2>/dev/null || true
CREATE TABLE IF NOT EXISTS books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO books (title, author) VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald'),
('To Kill a Mockingbird', 'Harper Lee'),
('1984', 'George Orwell');
EOSQL
    echo "Database initialized with sample data!"
else
    echo "Database $DB_NAME does not exist or cannot be accessed."
fi

# Create health check script for EpicBook
echo "Creating health check script..."
cat > /opt/epicbook/health-check.sh << 'EOC'
#!/bin/bash

# Check if Nginx is running
if ! systemctl is-active --quiet nginx; then
    echo "Nginx is not running"
    exit 1
fi

# Check if EpicBook backend is running
if ! pm2 describe epicbook-backend > /dev/null 2>&1; then
    echo "EpicBook backend is not running"
    exit 1
fi

# Check if application responds
if ! curl -f http://localhost/health > /dev/null 2>&1; then
    echo "Health check endpoint failed"
    exit 1
fi

echo "All services healthy"
exit 0
EOC

chmod +x /opt/epicbook/health-check.sh

# Create application version file
echo "Creating version file..."
cat > /opt/epicbook/version.txt << EOC
Application: EpicBook
Version: $APP_VERSION
Deployed: $(date)
Instance: $INSTANCE_INDEX
Database: $DB_HOST
Git Repository: $GITHUB_REPO
Branch: $BRANCH
EOC

echo "================================================"
echo "EpicBook setup completed successfully!"
echo "Instance: $INSTANCE_INDEX"
echo "Application version: $APP_VERSION"
echo "Database host: $DB_HOST"
echo "Application URL: http://\$(curl -s ifconfig.me)"
echo "Health check: http://localhost/health"
echo "================================================"

# Run initial health check
echo "Running initial health check..."
bash /opt/epicbook/health-check.sh

if [ $? -eq 0 ]; then
    echo "🎉 EpicBook is ready and healthy!"
else
    echo "⚠️  EpicBook setup completed with warnings. Check /var/log/epicbook-setup.log for details."
fi