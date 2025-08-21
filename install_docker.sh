#!/bin/bash

# Script cài đặt Docker và Docker Compose cho Ubuntu/Debian
# Chạy với: chmod +x install_docker.sh && ./install_docker.sh

echo "🐳 Installing Docker and Docker Compose..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo -e "${YELLOW}Adding Docker GPG key...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo -e "${YELLOW}Adding Docker repository...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine
echo -e "${YELLOW}Installing Docker Engine...${NC}"
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
echo -e "${YELLOW}Adding user to docker group...${NC}"
sudo usermod -aG docker $USER

# Start and enable Docker service
echo -e "${YELLOW}Starting Docker service...${NC}"
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose V1 (fallback)
echo -e "${YELLOW}Installing Docker Compose V1 as fallback...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for easier access
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo -e "${GREEN}✅ Docker installation completed!${NC}"
echo -e "${GREEN}You can now use:${NC}"
echo -e "  - ${YELLOW}docker compose up -d${NC} (V2 - recommended)"
echo -e "  - ${YELLOW}docker-compose up -d${NC} (V1 - legacy)"

# Test installation
echo -e "${YELLOW}Testing Docker installation...${NC}"
if docker --version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
else
    echo -e "${RED}❌ Docker installation failed${NC}"
fi

if docker compose version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose V2: $(docker compose version)${NC}"
elif docker-compose --version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose V1: $(docker-compose --version)${NC}"
else
    echo -e "${RED}❌ Docker Compose installation failed${NC}"
fi

echo -e "${YELLOW}⚠️  Please logout and login again (or run 'newgrp docker') to use Docker without sudo${NC}"
echo -e "${GREEN}🎉 Installation completed! You can now deploy your Django project.${NC}"
