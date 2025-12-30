# 🚀 RescueVN - Local Development & Production Deployment Guide

## 📋 Thay đổi được thực hiện

### Backend (Django)
1. **settings.py** - Thêm environment-based configuration
   - `ENV` variable: `development` hoặc `production`
   - `DEBUG` tự động tuỳ thuộc `ENV`
   - `ALLOWED_HOSTS` tuỳ thuộc `ENV`
   - `CORS` configuration tuỳ thuộc `ENV`
   - Database config với default values cho local

2. **api.py** - Thêm health check endpoint
   - `GET /api/health` - Return status, env, debug info

3. **.env.example** - Template cho environment variables

### Frontend (Nuxt)
1. **nuxt.config.ts** - Thêm runtimeConfig
   - `apiBase`: API URL (default: `http://127.0.0.1:8000/api`)
   - `wsBase`: WebSocket URL (default: `ws://127.0.0.1:8000`)
   - `env`: Node environment

2. **useRealtimeMap.ts** - Dynamic WebSocket connection
   - Tự động detect environment (local vs production)
   - Sử dụng `wsBase` config từ environment variables
   - Fallback tới `127.0.0.1:8000` cho development

3. **.env.example** - Template cho frontend environment variables

---

## ✅ Chạy Local Development

### 1️⃣ Backend Setup

```bash
cd backend

# Copy .env từ .env.example (nếu chưa có)
cp .env.example .env

# Cập nhật .env với credentials của bạn
# ENV=development          (mặc định)
# DB_*                     (điều chỉnh nếu cần)

# Cài đặt dependencies
pip install -r requirements.txt

# Chạy migrations
python manage.py migrate

# Khởi động server
python manage.py runserver 0.0.0.0:8000
```

✅ Backend chạy tại: `http://127.0.0.1:8000`
✅ API docs: `http://127.0.0.1:8000/api/docs`
✅ Health check: `http://127.0.0.1:8000/api/health`

### 2️⃣ Frontend Setup

```bash
cd frontend/rescue-web

# Copy .env từ .env.example (nếu chưa có)
cp .env.example .env

# Cài đặt dependencies
npm install

# Chạy dev server
npm run dev
```

✅ Frontend chạy tại: `http://localhost:3000`
✅ Tự động kết nối tới backend `http://127.0.0.1:8000`

---

## 🌍 Production Deployment

### 1️⃣ Backend Deployment

```bash
# Cập nhật .env cho production
export ENV=production
export ALLOWED_HOSTS=api.example.com,example.com
export CORS_ALLOWED_ORIGINS=https://example.com,https://www.example.com
export SECRET_KEY=your-secret-key-here    # Đổi khác với dev
export DB_HOST=your-production-db-host
export DB_NAME=rescue_prod
export DB_USER=rescue_user
export DB_PASSWORD=strong-password

# Chạy migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Khởi động với gunicorn/daphne
# Daphne (for WebSocket + HTTP/2)
daphne -b 0.0.0.0 -p 8000 app.asgi:application

# Hoặc Gunicorn (HTTP only)
# gunicorn app.wsgi:application --bind 0.0.0.0:8000
```

### 2️⃣ Frontend Deployment

```bash
cd frontend/rescue-web

# Cập nhật .env cho production
export NUXT_PUBLIC_API_BASE=https://api.example.com/api
export NUXT_PUBLIC_WS_BASE=wss://api.example.com

# Build
npm run build

# Deploy dist/
npm run preview   # để test trước
```

### 3️⃣ Nginx Reverse Proxy Configuration

```nginx
# Backend
upstream backend {
    server 127.0.0.1:8000;
}

# Frontend
upstream frontend {
    server 127.0.0.1:3000;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🔐 Environment Variables Reference

### Backend `.env`
```dotenv
# Environment
ENV=development|production

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=rescue_db
DB_USER=postgres
DB_PASSWORD=****
DB_HOST=localhost
DB_PORT=5432

# Security
SECRET_KEY=****
JWT_SECRET=****

# CORS (Production only)
ALLOWED_HOSTS=api.example.com
CORS_ALLOWED_ORIGINS=https://example.com

# Storage
USE_CLOUD=False|True
AWS_ACCESS_KEY_ID=****
AWS_SECRET_ACCESS_KEY=****
AWS_STORAGE_BUCKET_NAME=****

# OAuth
GOOGLE_CLIENT_ID=****
```

### Frontend `.env`
```dotenv
# Local Development
NUXT_PUBLIC_API_BASE=http://127.0.0.1:8000/api
NUXT_PUBLIC_WS_BASE=ws://127.0.0.1:8000

# Production
NUXT_PUBLIC_API_BASE=https://api.example.com/api
NUXT_PUBLIC_WS_BASE=wss://api.example.com
```

---

## 🧪 Testing Configuration

### Local (Development)
- ✅ CORS: Allow All Origins
- ✅ DEBUG: True
- ✅ Database: Local PostgreSQL
- ✅ Storage: Local Filesystem
- ✅ WebSocket: `ws://127.0.0.1:8000`

### Production
- ✅ CORS: Specific Origins Only
- ✅ DEBUG: False
- ✅ Database: Production DB
- ✅ Storage: AWS S3 (if enabled)
- ✅ WebSocket: `wss://api.example.com`

---

## 📊 Health Check

```bash
# Local
curl http://127.0.0.1:8000/api/health

# Production
curl https://api.example.com/api/health

# Response
{
  "status": "ok",
  "env": "development|production",
  "debug": true|false
}
```

---

## 🛠️ Troubleshooting

### WebSocket Connection Failed
- **Local**: Ensure backend running at `127.0.0.1:8000`
- **Production**: Check `NUXT_PUBLIC_WS_BASE` is `wss://` (secure)
- **CORS**: Verify `CORS_ALLOWED_ORIGINS` includes frontend domain

### API 401/403 Errors
- Check JWT token expiration
- Verify `JWT_SECRET` matches between local and production
- Ensure token is sent in Authorization header

### Database Connection Failed
- Verify PostgreSQL running
- Check DB credentials in `.env`
- Run `python manage.py migrate`

---

## 📝 Checklist trước Deploy

- [ ] `.env` updated cho production
- [ ] `ENV=production` set
- [ ] `SECRET_KEY` changed (khác với dev)
- [ ] `ALLOWED_HOSTS` configured đúng
- [ ] `CORS_ALLOWED_ORIGINS` configured đúng
- [ ] Database migrations chạy
- [ ] `python manage.py collectstatic` chạy
- [ ] Frontend `.env` updated với production URLs
- [ ] SSL certificates configured
- [ ] WebSocket proxy configured (Nginx/Apache)
- [ ] Health check endpoint responding
- [ ] Logs monitoring setup

---

**Ready to deploy! 🚀**
