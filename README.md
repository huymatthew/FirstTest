# Loara Django Project

Dự án Django cơ bản được thiết kế để deploy dễ dàng trên Linux server.

## 🚀 Tính năng

- Django 5.2.5 với Python 3.12
- Cấu hình sẵn sàng cho production
- Support Docker và Docker Compose
- Gunicorn WSGI server
- WhiteNoise cho static files
- Cấu hình environment variables
- Health check endpoint

## 📋 Yêu cầu hệ thống

- Python 3.12+
- pip
- virtualenv (tùy chọn)
- Docker (tùy chọn)

## 🛠️ Cài đặt và chạy local

### Phương pháp 1: Python Virtual Environment

```bash
# Clone project (nếu sử dụng Git)
git clone <repository-url>
cd Loara

# Tạo virtual environment
python3.12 -m venv venv
source venv/bin/activate  # Linux/Mac
# hoặc
venv\Scripts\activate  # Windows

# Cài đặt dependencies
pip install -r requirements.txt

# Chạy migrations
python manage.py migrate

# Tạo superuser (tùy chọn)
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic

# Chạy development server
python manage.py runserver
```

### Phương pháp 2: Docker

```bash
# Build và chạy với Docker Compose
docker-compose up -d

# Hoặc build Docker image thủ công
docker build -t loara-django .
docker run -p 8000:8000 loara-django
```

## 🚀 Deployment trên Linux Server

### Automatic Deployment Script

```bash
chmod +x deploy.sh
./deploy.sh
```

### Manual Deployment

1. **Cập nhật hệ thống:**
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Cài đặt Python 3.12:**
```bash
sudo apt install python3.12 python3.12-venv python3.12-dev
```

3. **Clone và setup project:**
```bash
git clone <repository-url>
cd Loara
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

4. **Cấu hình environment variables:**
```bash
cp .env.example .env
# Chỉnh sửa file .env với các giá trị thực tế
nano .env
```

5. **Chạy migrations và collect static:**
```bash
python manage.py migrate
python manage.py collectstatic --noinput
```

6. **Chạy với Gunicorn:**
```bash
gunicorn --bind 0.0.0.0:8000 Loara.wsgi:application
```

### Setup SystemD Service (Production)

Tạo file `/etc/systemd/system/loara.service`:

```ini
[Unit]
Description=Loara Django App
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/Loara
Environment="PATH=/path/to/Loara/venv/bin"
EnvironmentFile=/path/to/Loara/.env
ExecStart=/path/to/Loara/venv/bin/gunicorn --bind 0.0.0.0:8000 Loara.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
```

Khởi động service:
```bash
sudo systemctl daemon-reload
sudo systemctl start loara
sudo systemctl enable loara
```

### Setup Nginx (Reverse Proxy)

Tạo file `/etc/nginx/sites-available/loara`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/Loara/staticfiles/;
    }

    location /media/ {
        alias /path/to/Loara/media/;
    }
}
```

Kích hoạt site:
```bash
sudo ln -s /etc/nginx/sites-available/loara /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🔗 API Endpoints

- `/` - Trang chủ
- `/health/` - Health check endpoint
- `/admin/` - Django admin interface

## 🛡️ Security Notes

- Thay đổi `DJANGO_SECRET_KEY` trong production
- Set `DEBUG=False` trong production
- Cấu hình HTTPS khi deploy
- Sử dụng database mạnh hơn (PostgreSQL) thay vì SQLite
- Backup database định kỳ

## 📝 Logs

Logs có thể được xem qua:
```bash
# SystemD logs
sudo journalctl -u loara -f

# Docker logs
docker-compose logs -f
```

## 🤝 Contributing

1. Fork project
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

This project is licensed under the MIT License.
"# FirstTest" 
