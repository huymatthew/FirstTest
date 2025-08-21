#!/bin/bash

# Complete domain setup script for Azure VM
# Usage: ./setup_domain.sh your-domain.com

echo "🌐 Complete domain setup for Azure VM"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Please provide your domain name${NC}"
    echo "Usage: ./setup_domain.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
echo -e "${YELLOW}Setting up domain: $DOMAIN${NC}"

# Step 1: Show current IP
echo -e "${YELLOW}Step 1: Current server IP${NC}"
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${GREEN}Server IP: $SERVER_IP${NC}"
echo -e "${YELLOW}Make sure your DNS A record points $DOMAIN to $SERVER_IP${NC}"
echo ""

# Step 2: Update Django settings
echo -e "${YELLOW}Step 2: Updating Django settings...${NC}"
if [ ! -f .env ]; then
    cp production.env .env 2>/dev/null || cp .env.example .env
fi

# Update ALLOWED_HOSTS in .env
sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1,$SERVER_IP/" .env

# Generate new secret key if needed
if ! grep -q "DJANGO_SECRET_KEY=" .env || grep -q "your-super-secret-key" .env; then
    NEW_SECRET=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())" 2>/dev/null || openssl rand -base64 32)
    sed -i "s/DJANGO_SECRET_KEY=.*/DJANGO_SECRET_KEY=$NEW_SECRET/" .env
fi

sed -i "s/DEBUG=.*/DEBUG=False/" .env
echo -e "${GREEN}✅ Django settings updated${NC}"

# Step 3: Restart Django container
echo -e "${YELLOW}Step 3: Restarting Django container...${NC}"
docker-compose down
docker-compose up -d
sleep 5

if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Django container restarted${NC}"
else
    echo -e "${RED}❌ Failed to restart Django container${NC}"
    docker-compose logs
    exit 1
fi

# Step 4: Install and configure Nginx
echo -e "${YELLOW}Step 4: Setting up Nginx...${NC}"
sudo apt update -qq
sudo apt install -y nginx

# Create nginx config
sudo tee /etc/nginx/sites-available/loara << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Static files
    location /static/ {
        alias $(pwd)/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias $(pwd)/media/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Health check
    location /health/ {
        proxy_pass http://127.0.0.1:8000/health/;
        access_log off;
    }

    # Main application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
}
EOF

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/loara /etc/nginx/sites-enabled/

if sudo nginx -t; then
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    echo -e "${GREEN}✅ Nginx configured and started${NC}"
else
    echo -e "${RED}❌ Nginx configuration error${NC}"
    exit 1
fi

# Step 5: Configure firewall
echo -e "${YELLOW}Step 5: Configuring firewall...${NC}"
sudo ufw allow 'Nginx Full' >/dev/null 2>&1
sudo ufw allow ssh >/dev/null 2>&1
echo "y" | sudo ufw enable >/dev/null 2>&1
echo -e "${GREEN}✅ Firewall configured${NC}"

# Step 6: Test setup
echo -e "${YELLOW}Step 6: Testing setup...${NC}"

# Test local
if curl -s -H "Host: $DOMAIN" http://localhost >/dev/null; then
    echo -e "${GREEN}✅ Local HTTP test passed${NC}"
else
    echo -e "${RED}❌ Local HTTP test failed${NC}"
fi

# Test DNS
echo -e "${YELLOW}Testing DNS resolution...${NC}"
DOMAIN_IP=$(dig +short $DOMAIN 2>/dev/null)
if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✅ DNS resolves correctly${NC}"
    
    # Test external access
    sleep 2
    if curl -s --max-time 10 http://$DOMAIN >/dev/null; then
        echo -e "${GREEN}✅ External HTTP access works!${NC}"
    else
        echo -e "${YELLOW}⚠️  External access not working yet (DNS may still be propagating)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  DNS not yet propagated or incorrect${NC}"
    echo -e "  Domain IP: $DOMAIN_IP"
    echo -e "  Server IP: $SERVER_IP"
fi

# Final status
echo ""
echo -e "${GREEN}🎉 Setup completed!${NC}"
echo -e "${GREEN}Your site should be available at:${NC}"
echo -e "  - ${YELLOW}http://$DOMAIN${NC}"
echo -e "  - ${YELLOW}http://www.$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Wait for DNS propagation (5-10 minutes)"
echo -e "2. Test: curl http://$DOMAIN"
echo -e "3. Setup SSL: ./setup_ssl.sh $DOMAIN"
echo ""
echo -e "${YELLOW}To check status:${NC}"
echo -e "  nginx: sudo systemctl status nginx"
echo -e "  django: docker-compose ps"
echo -e "  logs: docker-compose logs -f"
