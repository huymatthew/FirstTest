#!/bin/bash

# Script cập nhật .env với tên miền
# Usage: ./update_env.sh your-domain.com

echo "📝 Updating .env file with domain configuration"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if domain provided
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: ./update_env.sh your-domain.com${NC}"
    echo -e "${YELLOW}This will update ALLOWED_HOSTS in .env file${NC}"
    exit 1
fi

DOMAIN=$1

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from template...${NC}"
    cp .env.example .env
fi

# Update ALLOWED_HOSTS
echo -e "${YELLOW}Updating ALLOWED_HOSTS with domain: $DOMAIN${NC}"
sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1/" .env

# Enable SSL settings if HTTPS
echo -e "${YELLOW}Do you want to enable HTTPS settings? (y/n)${NC}"
read -r enable_https

if [ "$enable_https" = "y" ] || [ "$enable_https" = "Y" ]; then
    sed -i "s/SESSION_COOKIE_SECURE=False/SESSION_COOKIE_SECURE=True/" .env
    sed -i "s/CSRF_COOKIE_SECURE=False/CSRF_COOKIE_SECURE=True/" .env
    sed -i "s/SECURE_SSL_REDIRECT=False/SECURE_SSL_REDIRECT=True/" .env
    echo -e "${GREEN}✅ HTTPS settings enabled${NC}"
else
    echo -e "${YELLOW}Keeping HTTP settings (you can enable HTTPS later)${NC}"
fi

echo -e "${GREEN}✅ .env file updated successfully!${NC}"
echo -e "${GREEN}Current ALLOWED_HOSTS: $DOMAIN,www.$DOMAIN,localhost,127.0.0.1${NC}"
