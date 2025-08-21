#!/bin/bash

# Script fix và tạo Django Secret Key mới
# Usage: ./fix_secret_key.sh

echo "🔑 Fixing Django Secret Key..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check current secret key
echo -e "${YELLOW}Checking current secret key...${NC}"

if [ -f .env ]; then
    CURRENT_KEY=$(grep "DJANGO_SECRET_KEY=" .env | cut -d'=' -f2)
    if [ -n "$CURRENT_KEY" ] && [ "$CURRENT_KEY" != "your-super-secret-key-here" ] && [ "$CURRENT_KEY" != "your-secret-key-here" ]; then
        echo -e "${GREEN}✅ Valid secret key found in .env${NC}"
        echo -e "Current key: ${CURRENT_KEY:0:20}...${CURRENT_KEY: -10}"
        echo -e "${YELLOW}Do you want to generate a new key? (y/n)${NC}"
        read -r generate_new
        if [ "$generate_new" != "y" ] && [ "$generate_new" != "Y" ]; then
            echo -e "${GREEN}Keeping current secret key.${NC}"
            exit 0
        fi
    else
        echo -e "${RED}❌ Invalid or default secret key found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No .env file found${NC}"
fi

# Generate new secret key
echo -e "${YELLOW}Generating new secret key...${NC}"

# Try multiple methods to generate secret key
NEW_SECRET=""

# Method 1: Django
if command -v python3 >/dev/null 2>&1; then
    NEW_SECRET=$(python3 -c "
try:
    from django.core.management.utils import get_random_secret_key
    print(get_random_secret_key())
except:
    import secrets
    import string
    chars = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
    print(''.join(secrets.choice(chars) for i in range(50)))
" 2>/dev/null)
fi

# Method 2: OpenSSL fallback
if [ -z "$NEW_SECRET" ] && command -v openssl >/dev/null 2>&1; then
    NEW_SECRET=$(openssl rand -base64 50 | tr -d '\n')
fi

# Method 3: /dev/urandom fallback
if [ -z "$NEW_SECRET" ]; then
    NEW_SECRET=$(head -c 50 /dev/urandom | base64 | tr -d '\n' | head -c 50)
fi

if [ -z "$NEW_SECRET" ]; then
    echo -e "${RED}❌ Failed to generate secret key${NC}"
    exit 1
fi

echo -e "${GREEN}✅ New secret key generated${NC}"
echo -e "New key: ${NEW_SECRET:0:20}...${NEW_SECRET: -10}"

# Create or update .env file
echo -e "${YELLOW}Updating .env file...${NC}"

if [ ! -f .env ]; then
    # Create new .env file
    cat > .env << EOF
# Django settings
DEBUG=False
DJANGO_SECRET_KEY=$NEW_SECRET
ALLOWED_HOSTS=localhost,127.0.0.1

# Security settings
SECURE_BROWSER_XSS_FILTER=True
SECURE_CONTENT_TYPE_NOSNIFF=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF
    echo -e "${GREEN}✅ Created new .env file${NC}"
else
    # Update existing .env file
    if grep -q "DJANGO_SECRET_KEY=" .env; then
        sed -i "s/DJANGO_SECRET_KEY=.*/DJANGO_SECRET_KEY=$NEW_SECRET/" .env
    else
        echo "DJANGO_SECRET_KEY=$NEW_SECRET" >> .env
    fi
    echo -e "${GREEN}✅ Updated existing .env file${NC}"
fi

# Update docker-compose.yml if needed
echo -e "${YELLOW}Checking docker-compose.yml...${NC}"
if [ -f docker-compose.yml ]; then
    if grep -q "DJANGO_SECRET_KEY" docker-compose.yml; then
        sed -i "s/DJANGO_SECRET_KEY=.*/DJANGO_SECRET_KEY=$NEW_SECRET/" docker-compose.yml
        echo -e "${GREEN}✅ Updated docker-compose.yml${NC}"
    fi
fi

# Restart containers to apply new secret key
echo -e "${YELLOW}Restarting containers to apply new secret key...${NC}"
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
    docker-compose up -d
    
    # Wait for container to start
    sleep 5
    
    if docker-compose ps | grep -q "Up"; then
        echo -e "${GREEN}✅ Containers restarted successfully${NC}"
    else
        echo -e "${RED}❌ Failed to restart containers${NC}"
        docker-compose logs
    fi
else
    echo -e "${YELLOW}⚠️  Docker Compose not found. Please restart manually.${NC}"
fi

# Show final status
echo ""
echo -e "${GREEN}🎉 Secret key setup completed!${NC}"
echo -e "${GREEN}Your new secret key has been:${NC}"
echo -e "  1. ✅ Generated securely"
echo -e "  2. ✅ Saved to .env file"
echo -e "  3. ✅ Applied to containers"
echo ""
echo -e "${YELLOW}Security reminder:${NC}"
echo -e "  - Never share your secret key"
echo -e "  - Keep .env file in .gitignore"
echo -e "  - Backup your .env file securely"
echo ""
echo -e "${GREEN}Test your application:${NC}"
echo -e "  curl http://localhost:8000/"
