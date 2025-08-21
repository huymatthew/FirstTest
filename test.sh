#!/bin/bash

# Test script for Loara Django project

echo "🧪 Testing Loara Django Project..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test health endpoint
echo -e "${YELLOW}Testing health endpoint...${NC}"
health_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health/)

if [ "$health_response" = "200" ]; then
    echo -e "${GREEN}✅ Health endpoint is working${NC}"
else
    echo -e "${RED}❌ Health endpoint failed (HTTP $health_response)${NC}"
fi

# Test home page
echo -e "${YELLOW}Testing home page...${NC}"
home_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)

if [ "$home_response" = "200" ]; then
    echo -e "${GREEN}✅ Home page is working${NC}"
else
    echo -e "${RED}❌ Home page failed (HTTP $home_response)${NC}"
fi

# Test admin page
echo -e "${YELLOW}Testing admin page...${NC}"
admin_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/admin/)

if [ "$admin_response" = "200" ] || [ "$admin_response" = "302" ]; then
    echo -e "${GREEN}✅ Admin page is accessible${NC}"
else
    echo -e "${RED}❌ Admin page failed (HTTP $admin_response)${NC}"
fi

echo -e "${GREEN}🎉 Testing completed!${NC}"
