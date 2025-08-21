#!/bin/bash

# Script fix Docker permission issues
# Chạy với: chmod +x fix_docker_permissions.sh && ./fix_docker_permissions.sh

echo "🔧 Fixing Docker permission issues..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if user is already in docker group
if groups $USER | grep -q '\bdocker\b'; then
    echo -e "${GREEN}✅ User is already in docker group${NC}"
else
    echo -e "${YELLOW}Adding user to docker group...${NC}"
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ User added to docker group${NC}"
fi

# Fix Docker socket permissions
echo -e "${YELLOW}Fixing Docker socket permissions...${NC}"
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

# Restart Docker service
echo -e "${YELLOW}Restarting Docker service...${NC}"
sudo systemctl restart docker

# Wait for Docker to start
sleep 3

# Apply new group membership
echo -e "${YELLOW}Applying new group membership...${NC}"
newgrp docker << 'EOF'
# Test Docker access
echo -e "${YELLOW}Testing Docker access...${NC}"
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker is working properly!${NC}"
    echo -e "${GREEN}You can now run: docker-compose up -d${NC}"
else
    echo -e "${RED}❌ Docker still has permission issues${NC}"
    echo -e "${YELLOW}Please logout and login again, then try:${NC}"
    echo -e "  docker-compose up -d"
fi
EOF

echo -e "${YELLOW}⚠️  If Docker still doesn't work, please:${NC}"
echo -e "1. Logout and login again"
echo -e "2. Or reboot the system"
echo -e "3. Then try: docker-compose up -d"
