#!/bin/bash

# Deploy script for Loara Django project on Linux server

echo "🚀 Starting deployment of Loara Django project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Python 3.12 is installed
if ! command -v python3.12 &> /dev/null; then
    echo -e "${RED}Python 3.12 is not installed. Please install it first.${NC}"
    exit 1
fi

# Create virtual environment
echo -e "${YELLOW}Creating virtual environment...${NC}"
python3.12 -m venv venv
source venv/bin/activate

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
python manage.py makemigrations
python manage.py migrate

# Create superuser (optional)
echo -e "${YELLOW}Do you want to create a superuser? (y/n)${NC}"
read -r create_superuser
if [ "$create_superuser" = "y" ] || [ "$create_superuser" = "Y" ]; then
    python manage.py createsuperuser
fi

# Collect static files
echo -e "${YELLOW}Collecting static files...${NC}"
python manage.py collectstatic --noinput

# Set environment variables for production
echo -e "${YELLOW}Setting up environment variables...${NC}"
export DEBUG=False
export DJANGO_SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}To start the server, run:${NC}"
echo -e "${YELLOW}source venv/bin/activate${NC}"
echo -e "${YELLOW}gunicorn --bind 0.0.0.0:8000 Loara.wsgi:application${NC}"
echo ""
echo -e "${GREEN}Or use Docker:${NC}"
echo -e "${YELLOW}docker-compose up -d${NC}"
