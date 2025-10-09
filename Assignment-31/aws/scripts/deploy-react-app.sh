#!/bin/bash

# React App Deployment Script for AWS
set -e

# Log everything
exec > >(tee /var/log/react-app-deployment.log) 2>&1
echo "=== Starting React App Deployment on AWS ==="
echo "Environment: ${environment}"
echo "Timestamp: $(date)"
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"
echo "Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"

# Update system
echo "Updating system packages..."
apt-get update -y

# Install Node.js 18.x
echo "Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Nginx and Git
echo "Installing Nginx and Git..."
apt-get install -y nginx git

# Verify installations
echo "Node.js version: $(node -v)"
echo "NPM version: $(npm -v)"
echo "Git version: $(git --version)"

# Start and enable Nginx
echo "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Create application directory
APP_DIR="/opt/react-app"
echo "Setting up application in $APP_DIR..."
mkdir -p $APP_DIR
cd $APP_DIR

# Clone React app
REACT_APP_REPO="https://github.com/pravinmishraaws/my-react-app.git"
echo "Cloning React app from $REACT_APP_REPO..."
git clone $REACT_APP_REPO . || echo "Repository already exists, pulling latest..." && git pull

# Check and modify App.js if specific lines exist
echo "Checking and modifying App.js..."
cd src

# Create a backup of original App.js
cp App.js App.js.backup

# Check if the deployment lines already exist and modify them
if grep -q "Deployed by:" App.js; then
    echo "Found existing deployment lines, modifying them..."
    # Replace existing lines
    sed -i 's/Deployed by: <strong>.*<\/strong>/Deployed by: <strong>Santhosh Kumar Raju<\/strong>/g' App.js
    sed -i 's/Date: <strong>.*<\/strong>/Date: <strong>09\/10\/2025<\/strong>/g' App.js
else
    echo "Adding deployment lines to App.js..."
    # Add the lines after the logo image
    sed -i '/<img src={logo} className="App-logo" alt="logo" \/>/a \
        <h2>Deployed by: <strong>Santhosh Kumar Raju<\/strong><\/h2>\
        <p>Date: <strong>09\/10\/2025<\/strong><\/p>' App.js
fi

echo "App.js modification completed"
echo "Modified content:"
grep -A 2 "Deployed by:" App.js

# Go back to root directory
cd /opt/react-app

# Install dependencies
echo "Installing dependencies..."
npm install

# Build React app
echo "Building React application..."
CI=false npm run build

# Check if build was successful
if [ ! -d "build" ]; then
    echo "ERROR: Build directory not created!"
    echo "Trying alternative build approach..."
    npm run build
fi

echo "Build completed successfully. Build directory contents:"
ls -la build/

# Deploy to Nginx
echo "Deploying to Nginx..."
rm -rf /var/www/html/*
cp -r build/* /var/www/html/

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configure Nginx for React Router
echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/default << 'NGINX_CONFIG'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html index.htm;
    
    # React Router support
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
NGINX_CONFIG

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Restart Nginx
echo "Restarting Nginx..."
systemctl restart nginx

# Wait for Nginx to start
sleep 10

# Check if Nginx is running
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running successfully"
else
    echo "❌ Nginx failed to start"
    systemctl status nginx
    exit 1
fi

# Test the application
echo "Testing application..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost/ > /dev/null 2>&1; then
        echo "✅ React application is serving correctly"
        break
    else
        echo "⚠️  Application not ready yet (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
        RETRY_COUNT=$((RETRY_COUNT+1))
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Application test failed after $MAX_RETRIES attempts"
    echo "Nginx status:"
    systemctl status nginx
    echo "Last 20 lines of Nginx error log:"
    tail -20 /var/log/nginx/error.log
    exit 1
fi

# Create a comprehensive test page
cat > /var/www/html/deployment-info.html << HTML
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Info - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        .success { color: green; font-weight: bold; }
        .aws-info { background: #ff9900; color: white; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="aws-info">
        <h2>🚀 AWS Deployment</h2>
    </div>
    <h1>React App Deployment Information</h1>
    <div class="info">
        <p><strong>Environment:</strong> <span class="success">${environment}</span></p>
        <p><strong>Deployed by:</strong> <span class="success">Santhosh Kumar Raju</span></p>
        <p><strong>Deployment Date:</strong> <span class="success">09/10/2025</span></p>
        <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
        <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
        <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
        <p><strong>Server Time:</strong> $(date)</p>
    </div>
    <p><a href="/">Go to React Application</a></p>
</body>
</html>
HTML

echo "=== Deployment Completed Successfully ==="
echo "Environment: ${environment}"
echo "Timestamp: $(date)"
echo "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Deployment log: /var/log/react-app-deployment.log"
echo "App.js modified with: Deployed by Santhosh Kumar Raju on 09/10/2025"