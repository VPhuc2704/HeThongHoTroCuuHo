# Dùng Python bản nhẹ (slim) để tiết kiệm dung lượng
FROM python:3.10-slim

# Cài đặt các thư viện hệ thống CẦN THIẾT cho GeoDjango/PostGIS
# Nếu thiếu mấy cái này, Django sẽ báo lỗi gdal library not found
RUN apt-get update && apt-get install -y \
    binutils \
    libproj-dev \
    gdal-bin \
    libgdal-dev \
    && rm -rf /var/lib/apt/lists/*

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy file cài đặt trước để tận dụng cache của Docker
COPY requirements.txt .

# Cài đặt các thư viện Python
RUN pip install --no-cache-dir -r requirements.txt
# Cài thêm Gunicorn và Uvicorn để chạy server production
RUN pip install gunicorn uvicorn

# Copy toàn bộ code vào trong container
COPY . .

# Mở cổng 8000 (nội bộ container)
EXPOSE 8000

# Lệnh chạy server: Dùng Gunicorn quản lý Uvicorn worker (tốt nhất cho Django Ninja)
# Thay 'rescue_project' bằng tên thư mục chứa file wsgi.py/asgi.py của bạn
CMD ["gunicorn", "-w", "2", "-k", "uvicorn.workers.UvicornWorker", "app.asgi:application", "--bind", "0.0.0.0:8000"]