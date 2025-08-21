#!/bin/bash

# Quick deploy script without Docker
# Chạy với: chmod +x quick_deploy.sh && ./quick_deploy.sh

echo "⚡ Quick Deploy Loara Django Project (No Docker)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Python 3.12
if ! command -v python3.12 &> /dev/null; then
    echo -e "${YELLOW}Installing Python 3.12...${NC}"
    sudo apt update
    sudo apt install -y python3.12 python3.12-venv python3.12-dev python3-pip
fi

# Create virtual environment
echo -e "${YELLOW}Setting up virtual environment...${NC}"
python3.12 -m venv venv
source venv/bin/activate

# Install dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Setup environment
echo -e "${YELLOW}Setting up environment variables...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo "DEBUG=False" >> .env
    echo "DJANGO_SECRET_KEY=$(python3.12 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')" >> .env
    echo "ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0" >> .env
fi

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
python manage.py migrate

# Collect static files
echo -e "${YELLOW}Collecting static files...${NC}"
python manage.py collectstatic --noinput

# Ask for superuser creation
echo -e "${YELLOW}Do you want to create a superuser? (y/n)${NC}"
read -r create_superuser
if [ "$create_superuser" = "y" ] || [ "$create_superuser" = "Y" ]; then
    python manage.py createsuperuser
fi

# Start server
echo -e "${GREEN}✅ Setup completed!${NC}"
echo -e "${GREEN}Starting Django server...${NC}"
echo -e "${YELLOW}Access your application at: http://localhost:8000${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Run with gunicorn if available, otherwise use development server
if command -v gunicorn &> /dev/null; then
    echo -e "${GREEN}Running with Gunicorn (Production)...${NC}"
    gunicorn --bind 0.0.0.0:8000 --workers 3 Loara.wsgi:application
else
    echo -e "${YELLOW}Running with Django development server...${NC}"
    python manage.py runserver 0.0.0.0:8000
fi
