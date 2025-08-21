#!/bin/bash

# Complete setup for lumora.io.vn domain
# Run this script on your Azure VM

echo "🌐 Setting up lumora.io.vn on Azure VM"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="lumora.io.vn"
PROJECT_PATH=$(pwd)

echo -e "${YELLOW}Setting up domain: $DOMAIN${NC}"
echo -e "${YELLOW}Project path: $PROJECT_PATH${NC}"

# Step 1: Show current server IP for DNS setup
echo -e "${YELLOW}=== STEP 1: DNS SETUP ===${NC}"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "Unable to get IP")
echo -e "${GREEN}Your Azure VM IP: $SERVER_IP${NC}"
echo -e "${YELLOW}Please create these DNS records:${NC}"
echo -e "  A Record: @ → $SERVER_IP"
echo -e "  A Record: www → $SERVER_IP"
echo -e "  TTL: 300 (5 minutes)"
echo ""

# Step 2: Update Django settings
echo -e "${YELLOW}=== STEP 2: UPDATING DJANGO SETTINGS ===${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << EOF
# Django settings for lumora.io.vn
DEBUG=False
DJANGO_SECRET_KEY=wu=xhbj4x!wx)9v+gbg9))mof041yu7ytjdq^@yi\$#r\$j)^ay_
ALLOWED_HOSTS=lumora.io.vn,www.lumora.io.vn,localhost,127.0.0.1,$SERVER_IP

# Security settings
SECURE_BROWSER_XSS_FILTER=True
SECURE_CONTENT_TYPE_NOSNIFF=True
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False
SECURE_SSL_REDIRECT=False

# Static files
STATIC_URL=/static/
MEDIA_URL=/media/
EOF
else
    # Update existing .env
    sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=lumora.io.vn,www.lumora.io.vn,localhost,127.0.0.1,$SERVER_IP/" .env
fi
echo -e "${GREEN}✅ Django settings updated${NC}"

# Step 3: Restart Django container
echo -e "${YELLOW}=== STEP 3: RESTARTING DJANGO ===${NC}"
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
    docker-compose up -d
    sleep 5
    
    if docker-compose ps | grep -q "Up"; then
        echo -e "${GREEN}✅ Django container restarted${NC}"
    else
        echo -e "${RED}❌ Django container failed to start${NC}"
        docker-compose logs
    fi
else
    echo -e "${YELLOW}⚠️  Docker Compose not found, skipping container restart${NC}"
fi

# Step 4: Install and configure Nginx
echo -e "${YELLOW}=== STEP 4: SETTING UP NGINX ===${NC}"
sudo apt update -qq
sudo apt install -y nginx

# Create nginx config for lumora.io.vn
sudo tee /etc/nginx/sites-available/loara << EOF
server {
    listen 80;
    server_name lumora.io.vn www.lumora.io.vn;

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

    # Client settings
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

    # Health check
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

    # Security
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.(env|git) {
        deny all;
    }

    # Static assets
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

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/loara
sudo ln -s /etc/nginx/sites-available/loara /etc/nginx/sites-enabled/

# Test and start nginx
if sudo nginx -t; then
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    echo -e "${GREEN}✅ Nginx configured successfully${NC}"
else
    echo -e "${RED}❌ Nginx configuration error${NC}"
    sudo nginx -t
    exit 1
fi

# Step 5: Configure firewall
echo -e "${YELLOW}=== STEP 5: CONFIGURING FIREWALL ===${NC}"
sudo ufw allow 'Nginx Full' >/dev/null 2>&1
sudo ufw allow ssh >/dev/null 2>&1
echo "y" | sudo ufw enable >/dev/null 2>&1
echo -e "${GREEN}✅ Firewall configured${NC}"

# Step 6: Test setup
echo -e "${YELLOW}=== STEP 6: TESTING SETUP ===${NC}"

# Test local
if curl -s --max-time 5 -H "Host: lumora.io.vn" http://localhost >/dev/null; then
    echo -e "${GREEN}✅ Local HTTP test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Local HTTP test failed${NC}"
fi

# Test DNS
DOMAIN_IP=$(dig +short lumora.io.vn 2>/dev/null | head -1)
if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✅ DNS resolves correctly${NC}"
    
    # Test external access
    if curl -s --max-time 10 http://lumora.io.vn >/dev/null; then
        echo -e "${GREEN}✅ External HTTP access works!${NC}"
    else
        echo -e "${YELLOW}⚠️  External access not working yet${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  DNS not propagated yet${NC}"
    echo -e "  Expected: $SERVER_IP"
    echo -e "  Current:  $DOMAIN_IP"
fi

# Final summary
echo ""
echo -e "${GREEN}🎉 Setup completed for lumora.io.vn!${NC}"
echo -e "${GREEN}Your site will be available at:${NC}"
echo -e "  - ${YELLOW}http://lumora.io.vn${NC}"
echo -e "  - ${YELLOW}http://www.lumora.io.vn${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Create DNS A records pointing to: $SERVER_IP"
echo -e "2. Wait 5-10 minutes for DNS propagation"
echo -e "3. Test: curl http://lumora.io.vn"
echo -e "4. Setup SSL: ./setup_ssl_lumora.sh"
echo ""
echo -e "${YELLOW}To monitor:${NC}"
echo -e "  Django: docker-compose logs -f"
echo -e "  Nginx:  sudo tail -f /var/log/nginx/error.log"
EOF
