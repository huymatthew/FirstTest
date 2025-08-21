#!/bin/bash

# Script fix Nginx symbolic link issues
# Usage: ./fix_nginx_link.sh

echo "🔧 Fixing Nginx symbolic link..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if loara config exists in sites-available
if [ ! -f /etc/nginx/sites-available/loara ]; then
    echo -e "${RED}❌ /etc/nginx/sites-available/loara not found${NC}"
    echo -e "${YELLOW}Please create the nginx config first${NC}"
    exit 1
fi

# Remove existing link if exists
if [ -L /etc/nginx/sites-enabled/loara ] || [ -f /etc/nginx/sites-enabled/loara ]; then
    echo -e "${YELLOW}Removing existing link/file...${NC}"
    sudo rm -f /etc/nginx/sites-enabled/loara
fi

# Remove default site if exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo -e "${YELLOW}Removing default site...${NC}"
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# Create new symbolic link
echo -e "${YELLOW}Creating new symbolic link...${NC}"
sudo ln -s /etc/nginx/sites-available/loara /etc/nginx/sites-enabled/

# Verify link was created
if [ -L /etc/nginx/sites-enabled/loara ]; then
    echo -e "${GREEN}✅ Symbolic link created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create symbolic link${NC}"
    exit 1
fi

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
    echo -e "${RED}❌ Nginx configuration has errors${NC}"
    sudo nginx -t
    exit 1
fi

# Show current enabled sites
echo -e "${YELLOW}Current enabled sites:${NC}"
ls -la /etc/nginx/sites-enabled/

# Test local connection
echo -e "${YELLOW}Testing local connection...${NC}"
if curl -s --max-time 5 http://localhost >/dev/null; then
    echo -e "${GREEN}✅ Local HTTP test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Local HTTP test failed (this might be normal if domain not configured)${NC}"
fi

echo -e "${GREEN}🎉 Nginx link fixed successfully!${NC}"
echo -e "${GREEN}You can now test your domain or continue with SSL setup${NC}"
