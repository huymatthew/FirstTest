from django.shortcuts import render
from django.http import HttpResponse

# Create your views here.

def home(request):
    """Trang chủ"""
    return HttpResponse("""
    <html>
        <head>
            <title>Loara - Django Server</title>
            <style>
                body { 
                    font-family: Arial, sans-serif; 
                    margin: 40px; 
                    background-color: #f5f5f5; 
                }
                .container { 
                    background: white; 
                    padding: 30px; 
                    border-radius: 10px; 
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    max-width: 600px;
                    margin: 0 auto;
                }
                h1 { 
                    color: #2c3e50; 
                    text-align: center;
                }
                .info {
                    background: #e8f5e8;
                    padding: 15px;
                    border-left: 4px solid #4caf50;
                    margin: 20px 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 Loara Django Server</h1>
                <div class="info">
                    <p><strong>Chúc mừng!</strong> Django server đã được cấu hình thành công.</p>
                    <p>Dự án này đã sẵn sàng để deploy lên Linux server.</p>
                </div>
                <p><strong>Thông tin dự án:</strong></p>
                <ul>
                    <li>Framework: Django 5.2.5</li>
                    <li>Python Version: 3.12</li>
                    <li>Status: Ready for Production</li>
                </ul>
            </div>
        </body>
    </html>
    """)

def api_health(request):
    """API kiểm tra health của server"""
    return HttpResponse('{"status": "healthy", "message": "Server is running"}', 
                       content_type='application/json')
