#!/bin/bash

# React App Deployment Script
set -e

# Log everything
exec > >(tee /var/log/react-app-deployment.log) 2>&1
echo "=== Starting React App Deployment ==="
echo "Environment: ${environment}"
echo "Timestamp: $(date)"

# Update system
echo "Updating system packages..."
apt-get update -y

# Install Node.js
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Nginx and Git
echo "Installing Nginx and Git..."
apt-get install -y nginx git

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Create app directory
mkdir -p /opt/react-app
cd /opt/react-app

# Clone React app
echo "Cloning React application..."
git clone https://github.com/pravinmishraaws/my-react-app.git .

# Modify specific lines in App.js
echo "Modifying specific lines in App.js..."
cd src

# Create a backup of original App.js
cp App.js App.js.backup

# Replace "Your Full Name" with "Santhosh Kumar Raju"
sed -i 's/Your Full Name/Santhosh Kumar Raju/g' App.js

# Replace "DD\/MM\/YYYY" with "09\/10\/2025"
sed -i 's/DD\/MM\/YYYY/09\/10\/2025/g' App.js

echo "App.js modified successfully"
echo "Modified lines in App.js:"
grep -n "Deployed by:\|Date:" App.js

# Go back to root directory
cd /opt/react-app

# Install dependencies
echo "Installing dependencies..."
npm install

# Build React app
echo "Building React application..."
CI=false npm run build

# Deploy to Nginx
echo "Deploying to Nginx..."
rm -rf /var/www/html/*
cp -r build/* /var/www/html/

# Set permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configure Nginx for React Router
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

# Restart Nginx
systemctl restart nginx

# Create test page
cat > /var/www/html/test.html << HTML
<!DOCTYPE html>
<html>
<head>
    <title>Test Page - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .success { color: green; }
    </style>
</head>
<body>
    <h1>React App Deployment Test</h1>
    <p class="success">✅ Nginx is working</p>
    <p class="success">✅ Static files are serving</p>
    <p><strong>Environment:</strong> ${environment}</p>
    <p><strong>Deployed at:</strong> $(date)</p>
    <p><a href="/">Go to React App</a></p>
</body>
</html>
HTML

echo "=== Deployment Completed Successfully ==="
echo "Environment: ${environment}"
echo "Timestamp: $(date)"
echo "App.js modified: 'Your Full Name' → 'Santhosh Kumar Raju'"
echo "App.js modified: 'DD/MM/YYYY' → '09/10/2025'"