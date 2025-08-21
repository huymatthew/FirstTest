#!/bin/bash

# Script fix Nginx configuration errors
# Usage: ./fix_nginx_config.sh [domain-name]

echo "🔧 Fixing Nginx configuration errors..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get domain or use default
DOMAIN=${1:-"your-domain.com"}
PROJECT_PATH=$(pwd)

echo -e "${YELLOW}Domain: $DOMAIN${NC}"
echo -e "${YELLOW}Project path: $PROJECT_PATH${NC}"

# Backup existing config if it exists
if [ -f /etc/nginx/sites-available/loara ]; then
    echo -e "${YELLOW}Backing up existing config...${NC}"
    sudo cp /etc/nginx/sites-available/loara /etc/nginx/sites-available/loara.backup
fi

# Create new correct nginx config
echo -e "${YELLOW}Creating new Nginx configuration...${NC}"
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
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # Client max body size
    client_max_body_size 100M;

    # Static files
    location /static/ {
        alias $PROJECT_PATH/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Media files
    location /media/ {
        alias $PROJECT_PATH/media/;
        expires 1y;
        add_header Cache-Control "public";
        access_log off;
    }

    # Health check endpoint
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
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Block access to sensitive files
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.(env|git) {
        deny all;
    }

    # Favicon and robots
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        log_not_found off;
        access_log off;
    }
}
EOF

# Remove and recreate symbolic link
echo -e "${YELLOW}Setting up symbolic link...${NC}"
sudo rm -f /etc/nginx/sites-enabled/loara
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/loara /etc/nginx/sites-enabled/

# Test nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
    
    # Reload nginx
    echo -e "${YELLOW}Reloading Nginx...${NC}"
    sudo systemctl reload nginx
    
    if sudo systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✅ Nginx reloaded successfully${NC}"
    else
        echo -e "${RED}❌ Nginx failed to reload${NC}"
        sudo systemctl status nginx
        exit 1
    fi
else
    echo -e "${RED}❌ Nginx configuration still has errors${NC}"
    sudo nginx -t
    echo -e "${YELLOW}You can restore backup with:${NC}"
    echo -e "sudo cp /etc/nginx/sites-available/loara.backup /etc/nginx/sites-available/loara"
    exit 1
fi

# Test local connection
echo -e "${YELLOW}Testing local connection...${NC}"
if curl -s --max-time 5 -H "Host: $DOMAIN" http://localhost >/dev/null; then
    echo -e "${GREEN}✅ Local HTTP test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Local HTTP test failed (check if Django is running)${NC}"
fi

echo -e "${GREEN}🎉 Nginx configuration fixed successfully!${NC}"
echo -e "${GREEN}Configuration details:${NC}"
echo -e "  - Domain: $DOMAIN"
echo -e "  - Static files: $PROJECT_PATH/staticfiles/"
echo -e "  - Media files: $PROJECT_PATH/media/"
echo -e "  - Proxy to: http://127.0.0.1:8000"
