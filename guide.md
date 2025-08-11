# 🚀 **Universal Dockerization Guide for Open Source Projects**

*Deploy ANY open source project on Coolify with zero manual configuration*

---

## 🎯 **The Goal**

Create a **"one-click deployment"** system where:
- ✅ Import project from Git → Deploy instantly
- ✅ All environment variables pre-configured
- ✅ External databases (Neon, Upstash, etc.) auto-connected
- ✅ No manual setup required
- ✅ Works for any tech stack

---

## 📋 **Step-by-Step Process**

### **Step 1: Analyze the Project**

**Before dockerizing ANY project, understand:**

1. **What technology stack?**
   - Frontend: React, Vue, Angular, Next.js?
   - Backend: Node.js, Python, PHP, Go?
   - Database: PostgreSQL, MySQL, MongoDB?
   - Cache: Redis, Memcached?

2. **How does it normally run?**
   - `npm start`, `yarn dev`, `python manage.py runserver`?
   - Separate frontend/backend or monorepo?
   - Build process required?

3. **What external services needed?**
   - Database, Redis, Email service, File storage?

---

### **Step 2: Choose External Services**

**Use these FREE managed services:**

| **Service Type** | **Provider** | **Free Tier** |
|------------------|--------------|---------------|
| **PostgreSQL** | [Neon](https://neon.tech) | 512MB, 3 DBs |
| **Redis** | [Upstash](https://upstash.com) | 10K commands/day |
| **Email** | [Resend](https://resend.com) | 100 emails/day |
| **File Storage** | [Cloudinary](https://cloudinary.com) | 25K images |
| **Analytics** | [PostHog](https://posthog.com) | 1M events/month |

---

### **Step 3: Create the Universal Dockerfile**

**Template for most projects:**

```dockerfile
# Universal Dockerfile Template
FROM node:20-alpine as base

# Install system dependencies
RUN apk add --no-cache \
    curl \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY yarn.lock* ./

# Install dependencies
RUN if [ -f "yarn.lock" ]; then yarn install --frozen-lockfile; \
    else npm ci --only=production; fi

# Copy source code
COPY . .

# Build the application
RUN if [ -f "package.json" ]; then \
      if grep -q "build" package.json; then \
        if [ -f "yarn.lock" ]; then yarn build; else npm run build; fi \
      fi \
    fi

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl --fail http://localhost:3000/health || curl --fail http://localhost:3000/ || exit 1

# Start command
CMD ["npm", "start"]
```

---

### **Step 4: Create docker-compose.coolify.yml**

**Universal template:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      # App Configuration
      NODE_ENV: "production"
      PORT: "3000"
      HOST: "0.0.0.0"
      
      # URLs - Auto-populated by Coolify
      APP_URL: "https://${COOLIFY_FQDN}"
      SERVER_URL: "https://${COOLIFY_FQDN}"
      FRONTEND_URL: "https://${COOLIFY_FQDN}"
      
      # Database - Replace with your Neon URL
      DATABASE_URL: "postgresql://username:password@host/database?sslmode=require"
      
      # Redis - Replace with your Upstash URL
      REDIS_URL: "rediss://default:password@host:6379"
      
      # Email - Replace with your service
      SMTP_HOST: "smtp.resend.com"
      SMTP_PORT: "587"
      SMTP_USER: "resend"
      SMTP_PASS: "your-api-key"
      EMAIL_FROM: "noreply@yourdomain.com"
      
      # File Storage
      STORAGE_TYPE: "local"
      STORAGE_LOCAL_PATH: "/app/uploads"
      FILE_UPLOAD_SIZE_LIMIT: "10MB"
      
      # Security
      JWT_SECRET: "your-super-secret-jwt-key-change-this"
      SESSION_SECRET: "your-session-secret-change-this"
      
      # Feature Flags
      ENABLE_SIGNUP: "true"
      ENABLE_MULTI_TENANT: "true"
      
    volumes:
      - ./uploads:/app/uploads
    labels:
      - "coolify.port=3000"
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

### **Step 5: Project-Specific Adaptations**

#### **For Node.js/React Projects (like Twenty)**

```yaml
environment:
  # Node.js specific
  NODE_OPTIONS: "--max-old-space-size=1500"
  NPM_CONFIG_CACHE: "/tmp/.npm"
  
  # React build variables
  REACT_APP_SERVER_BASE_URL: "https://${COOLIFY_FQDN}"
  REACT_APP_API_URL: "https://${COOLIFY_FQDN}/api"
```

#### **For Python/Django Projects**

```dockerfile
FROM python:3.11-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN python manage.py collectstatic --noinput
EXPOSE 8000
CMD ["gunicorn", "project.wsgi:application", "--bind", "0.0.0.0:8000"]
```

```yaml
environment:
  DJANGO_SETTINGS_MODULE: "project.settings.production"
  DEBUG: "False"
  ALLOWED_HOSTS: "${COOLIFY_FQDN}"
```

#### **For PHP/Laravel Projects**

```dockerfile
FROM php:8.2-apache
RUN docker-php-ext-install pdo pdo_mysql
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
```

---

### **Step 6: Database Setup Automation**

**Add to Dockerfile for auto-migrations:**

```dockerfile
# Add migration script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
```

**docker-entrypoint.sh:**

```bash
#!/bin/bash
set -e

echo "🚀 Starting application setup..."

# Wait for database
echo "⏳ Waiting for database..."
until nc -z ${DB_HOST:-localhost} ${DB_PORT:-5432}; do
  sleep 1
done

# Run migrations based on project type
if [ -f "package.json" ]; then
  echo "📦 Node.js project detected"
  if grep -q "migrate" package.json; then
    npm run migrate || yarn migrate
  fi
elif [ -f "manage.py" ]; then
  echo "🐍 Django project detected"
  python manage.py migrate
elif [ -f "artisan" ]; then
  echo "🎨 Laravel project detected"
  php artisan migrate --force
fi

echo "✅ Setup complete, starting application..."
exec "$@"
```

---

### **Step 7: Environment Variables Strategy**

**Create `.env.example` with all required variables:**

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Redis
REDIS_URL=redis://host:6379

# Email
SMTP_HOST=smtp.example.com
SMTP_USER=user
SMTP_PASS=pass

# App
APP_NAME=MyApp
APP_URL=https://myapp.com
JWT_SECRET=change-this
```

**In docker-compose.coolify.yml, reference these with defaults:**

```yaml
environment:
  DATABASE_URL: "${DATABASE_URL:-postgresql://localhost:5432/app}"
  REDIS_URL: "${REDIS_URL:-redis://localhost:6379}"
  APP_URL: "https://${COOLIFY_FQDN}"
```

---

### **Step 8: Create Deployment Template**

**For each new project, copy this template:**

```
my-project/
├── Dockerfile
├── docker-compose.coolify.yml
├── docker-entrypoint.sh
├── .env.example
├── .dockerignore
└── README-DEPLOY.md
```

**.dockerignore:**
```
node_modules
.git
.env
*.log
coverage
.nyc_output
```

**README-DEPLOY.md:**
```markdown
# 🚀 One-Click Deployment

## Setup External Services:
1. **Database**: Create at [Neon](https://neon.tech)
2. **Redis**: Create at [Upstash](https://upstash.com)
3. **Email**: Setup at [Resend](https://resend.com)

## Deploy to Coolify:
1. Import this repo
2. It will auto-detect docker-compose.coolify.yml
3. Update environment variables in Coolify dashboard
4. Deploy!

## Required Environment Variables:
- DATABASE_URL
- REDIS_URL
- SMTP_* variables
- JWT_SECRET
```

---

### **Step 9: Testing Checklist**

**Before deploying any project:**

✅ **Local Docker test:**
```bash
docker build -t myapp .
docker run -p 3000:3000 myapp
```

✅ **Environment variables work:**
```bash
docker run -e DATABASE_URL=test myapp
```

✅ **Health check responds:**
```bash
curl http://localhost:3000/health
```

✅ **Database connection works**
✅ **Static files serve correctly**
✅ **API endpoints respond**

---

### **Step 10: Automation Scripts**

**Create a script to dockerize any project:**

**dockerize.sh:**
```bash
#!/bin/bash

PROJECT_NAME=$1
TECH_STACK=$2

echo "🚀 Dockerizing $PROJECT_NAME ($TECH_STACK)"

# Copy template files
cp templates/Dockerfile .
cp templates/docker-compose.coolify.yml .
cp templates/docker-entrypoint.sh .

# Customize based on tech stack
case $TECH_STACK in
  "nodejs")
    sed -i 's/PORT/3000/g' docker-compose.coolify.yml
    ;;
  "python")
    sed -i 's/PORT/8000/g' docker-compose.coolify.yml
    ;;
  "php")
    sed -i 's/PORT/80/g' docker-compose.coolify.yml
    ;;
esac

echo "✅ Project dockerized! Update environment variables and deploy."
```

---

## 🎯 **Quick Start for Any Project**

1. **Clone the project**
2. **Run:** `./dockerize.sh myproject nodejs`
3. **Update environment variables** in docker-compose.coolify.yml
4. **Setup external services** (Neon, Upstash, etc.)
5. **Import to Coolify**
6. **Deploy!**

---

## 📚 **Common Patterns by Tech Stack**

### **Node.js Projects**
- Port: Usually 3000
- Build: `npm run build`
- Start: `npm start`
- Common envs: `NODE_ENV`, `PORT`, `DATABASE_URL`

### **Python Projects**
- Port: Usually 8000
- Build: `pip install -r requirements.txt`
- Start: `gunicorn` or `python manage.py runserver`
- Common envs: `DEBUG`, `SECRET_KEY`, `DATABASE_URL`

### **PHP Projects**
- Port: Usually 80
- Build: `composer install`
- Start: Apache/Nginx
- Common envs: `DB_HOST`, `DB_PASSWORD`, `APP_KEY`

---

**This guide gives you a repeatable process to dockerize and deploy ANY open source project with minimal manual work!** 🎉

The key is having good templates and understanding the common patterns for each technology stack.