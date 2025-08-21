#!/bin/bash

# Script setup Nginx reverse proxy cho Azure VM
# Chạy với: chmod +x setup_nginx.sh && ./setup_nginx.sh your-domain.com

echo "🌐 Setting up Nginx reverse proxy for Django on Azure VM"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if domain parameter is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Please provide your domain name${NC}"
    echo "Usage: ./setup_nginx.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
echo -e "${YELLOW}Setting up for domain: $DOMAIN${NC}"

# Install Nginx
echo -e "${YELLOW}Installing Nginx...${NC}"
sudo apt update
sudo apt install -y nginx

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Create Nginx config for Django
echo -e "${YELLOW}Creating Nginx configuration...${NC}"
sudo tee /etc/nginx/sites-available/loara << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # Static files (update path as needed)
    location /static/ {
        alias /home/\$USER/Loara/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Media files
    location /media/ {
        alias /home/\$USER/Loara/media/;
        expires 1y;
        add_header Cache-Control "public";
        access_log off;
    }

    # Health check endpoint (for load balancers)
    location /health/ {
        proxy_pass http://127.0.0.1:8000/health/;
        access_log off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Main application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Timeout settings
        proxy_connect_timeout       60s;
        proxy_send_timeout          60s;
        proxy_read_timeout          60s;
    }

    # Block access to sensitive files
    location ~ /\\.ht {
        deny all;
    }
    
    location ~ /\\.(env|git) {
        deny all;
    }
}
EOF

# Enable site
echo -e "${YELLOW}Enabling Nginx site...${NC}"
sudo ln -sf /etc/nginx/sites-available/loara /etc/nginx/sites-enabled/

# Test Nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration has errors${NC}"
    exit 1
fi

# Start and enable Nginx
echo -e "${YELLOW}Starting Nginx...${NC}"
sudo systemctl start nginx
sudo systemctl enable nginx

# Check if Django container is running
echo -e "${YELLOW}Checking Django container...${NC}"
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Django container is running${NC}"
else
    echo -e "${YELLOW}⚠️  Django container is not running. Starting...${NC}"
    docker-compose up -d
fi

# Show status
echo -e "${GREEN}🎉 Setup completed!${NC}"
echo -e "${GREEN}Your site should be available at:${NC}"
echo -e "  - ${YELLOW}http://$DOMAIN${NC}"
echo -e "  - ${YELLOW}http://www.$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Test your site: curl -H 'Host: $DOMAIN' http://localhost"
echo -e "2. Setup SSL certificate: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo -e "${GREEN}Nginx status:${NC}"
sudo systemctl status nginx --no-pager -l
EOF
