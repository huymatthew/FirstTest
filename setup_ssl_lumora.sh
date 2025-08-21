#!/bin/bash

# SSL setup script for lumora.io.vn
# Run after DNS is propagated

echo "🔒 Setting up SSL certificate for lumora.io.vn"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="lumora.io.vn"

# Check if domain resolves correctly
echo -e "${YELLOW}Checking DNS resolution...${NC}"
DOMAIN_IP=$(dig +short $DOMAIN 2>/dev/null | head -1)
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✅ DNS resolves correctly${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: DNS may not be fully propagated${NC}"
    echo -e "  Domain IP: $DOMAIN_IP"
    echo -e "  Server IP: $SERVER_IP"
    echo -e "${YELLOW}Continue anyway? (y/n)${NC}"
    read -r continue_setup
    if [ "$continue_setup" != "y" ] && [ "$continue_setup" != "Y" ]; then
        echo -e "${RED}Exiting...${NC}"
        exit 1
    fi
fi

# Install Certbot
echo -e "${YELLOW}Installing Certbot...${NC}"
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
echo -e "${YELLOW}Obtaining SSL certificate for lumora.io.vn...${NC}"
sudo certbot --nginx -d lumora.io.vn -d www.lumora.io.vn --non-interactive --agree-tos --email admin@lumora.io.vn

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
    
    # Update Django settings for HTTPS
    echo -e "${YELLOW}Updating Django settings for HTTPS...${NC}"
    sed -i "s/SESSION_COOKIE_SECURE=False/SESSION_COOKIE_SECURE=True/" .env
    sed -i "s/CSRF_COOKIE_SECURE=False/CSRF_COOKIE_SECURE=True/" .env
    sed -i "s/SECURE_SSL_REDIRECT=False/SECURE_SSL_REDIRECT=True/" .env
    
    # Restart Django container
    docker-compose restart
    
    # Test HTTPS
    echo -e "${YELLOW}Testing HTTPS...${NC}"
    if curl -s --max-time 10 https://lumora.io.vn >/dev/null; then
        echo -e "${GREEN}✅ HTTPS working perfectly!${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTPS test failed, but certificate might still be valid${NC}"
    fi
    
    # Setup auto-renewal
    (sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
    
    echo -e "${GREEN}🎉 SSL setup completed!${NC}"
    echo -e "${GREEN}Your site is now available at:${NC}"
    echo -e "  - ${YELLOW}https://lumora.io.vn${NC} 🔒"
    echo -e "  - ${YELLOW}https://www.lumora.io.vn${NC} 🔒"
    echo -e "  - ${YELLOW}http://lumora.io.vn${NC} (redirects to HTTPS)"
    
else
    echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
    echo -e "${YELLOW}Common issues:${NC}"
    echo -e "1. DNS not pointing to this server"
    echo -e "2. Domain not accessible from internet"
    echo -e "3. Firewall blocking port 80/443"
    echo -e ""
    echo -e "${YELLOW}You can try again later with:${NC}"
    echo -e "sudo certbot --nginx -d lumora.io.vn -d www.lumora.io.vn"
fi
