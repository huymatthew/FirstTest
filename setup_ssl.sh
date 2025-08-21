#!/bin/bash

# Script setup SSL certificate với Let's Encrypt
# Chạy sau khi setup_nginx.sh: ./setup_ssl.sh your-domain.com

echo "🔒 Setting up SSL certificate with Let's Encrypt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if domain parameter is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Please provide your domain name${NC}"
    echo "Usage: ./setup_ssl.sh your-domain.com"
    exit 1
fi

DOMAIN=$1
echo -e "${YELLOW}Setting up SSL for domain: $DOMAIN${NC}"

# Install Certbot
echo -e "${YELLOW}Installing Certbot...${NC}"
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Test if domain resolves to this server
echo -e "${YELLOW}Testing domain resolution...${NC}"
DOMAIN_IP=$(dig +short $DOMAIN)
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✅ Domain resolves correctly to this server${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Domain IP ($DOMAIN_IP) != Server IP ($SERVER_IP)${NC}"
    echo -e "${YELLOW}SSL setup may fail if DNS hasn't propagated yet${NC}"
    echo -e "${YELLOW}Continue anyway? (y/n)${NC}"
    read -r continue_setup
    if [ "$continue_setup" != "y" ] && [ "$continue_setup" != "Y" ]; then
        echo -e "${RED}Exiting...${NC}"
        exit 1
    fi
fi

# Get SSL certificate
echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Check if certificate was obtained successfully
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
    
    # Test SSL
    echo -e "${YELLOW}Testing SSL configuration...${NC}"
    if sudo nginx -t; then
        echo -e "${GREEN}✅ Nginx configuration with SSL is valid${NC}"
        sudo systemctl reload nginx
    else
        echo -e "${RED}❌ Nginx configuration has errors${NC}"
        exit 1
    fi
    
    # Setup auto-renewal
    echo -e "${YELLOW}Setting up certificate auto-renewal...${NC}"
    (sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
    
    echo -e "${GREEN}🎉 SSL setup completed!${NC}"
    echo -e "${GREEN}Your site is now available at:${NC}"
    echo -e "  - ${YELLOW}https://$DOMAIN${NC}"
    echo -e "  - ${YELLOW}https://www.$DOMAIN${NC}"
    echo -e "  - ${YELLOW}http://$DOMAIN${NC} (redirects to HTTPS)"
    echo ""
    echo -e "${GREEN}Certificate auto-renewal is configured.${NC}"
    
else
    echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
    echo -e "${YELLOW}Common issues:${NC}"
    echo -e "1. Domain not pointing to this server"
    echo -e "2. DNS not propagated yet (wait 5-10 minutes)"
    echo -e "3. Firewall blocking port 80/443"
    echo -e "4. Nginx not running"
    echo ""
    echo -e "${YELLOW}You can try again later with:${NC}"
    echo -e "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi
