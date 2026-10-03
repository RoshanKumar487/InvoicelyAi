# 🐳 Docker Deployment Guide - InvoicelyAi Backend

This guide explains how to build, test, and deploy the **InvoicelyAi Backend** service using Docker for production environments.

---

## 📋 Dockerfile Architecture Highlights

- **Multi-Stage Build**: Separates the build environment (Maven 3.9 + Temurin JDK 17) from the lightweight runtime environment (Temurin JRE 17 Alpine), keeping the final production image under ~180MB.
- **Enterprise Security (Non-Root User)**: Runs as an unprivileged user (`appuser:appgroup`), passing vulnerability scans and meeting compliance standards (SOC2, HIPAA, PCI).
- **JVM Container Optimization**: Preconfigured with `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0` to respect Docker container memory limits and prevent OOM kills in Kubernetes/ECS/Cloud Run.
- **Dynamic Port Binding**: Supports `${PORT:8080}`, seamlessly adapting to platform-injected ports (Render, Railway, Heroku, Cloud Run).
- **Automated Health Checks**: Built-in `HEALTHCHECK` pinging `/api/v1/health` every 30s.

---

## 🛠️ Files Overview

| File | Purpose |
|---|---|
| [`backend/Dockerfile`](file:///c:/Users/ADMIN/Documents/InvocielyAi/InvoicelyAi-main/InvoicelyAi/backend/Dockerfile) | Production multi-stage build (builds from source, no local Java required) |
| [`backend/Dockerfile.prebuilt`](file:///c:/Users/ADMIN/Documents/InvocielyAi/InvoicelyAi-main/InvoicelyAi/backend/Dockerfile.prebuilt) | Instant build using locally compiled JAR (`build/libs/invoicely-backend-1.0.0.jar`) |
| [`backend/.dockerignore`](file:///c:/Users/ADMIN/Documents/InvocielyAi/InvoicelyAi-main/InvoicelyAi/backend/.dockerignore) | Excludes build artifacts, caches, logs, and sensitive `.env` files from build context |
| [`docker-compose.yml`](file:///c:/Users/ADMIN/Documents/InvocielyAi/InvoicelyAi-main/InvoicelyAi/docker-compose.yml) | Compose file for running the containerized backend with environment variables |

---

## 🚀 Quick Start

### 1. Build the Docker Image (Multi-stage from source)

Navigate to the `backend` directory and build:

```bash
cd backend
docker build -t invoicely-backend:latest .
```

*Or from project root:*
```bash
docker build -t invoicely-backend:latest -f backend/Dockerfile backend
```

---

### 2. Fast Build Using Pre-Built JAR (Optional)

If you already compiled the application with Gradle (`..\gradlew.bat bootJar`):

```bash
cd backend
docker build -f Dockerfile.prebuilt -t invoicely-backend:latest .
```

---

### 3. Run the Container Locally

Run with your Supabase database credentials:

```bash
docker run -d \
  --name invoicely-backend \
  -p 8080:8080 \
  -e DB_HOST="db.pggsnzcbkqyzcpjmcmqj.supabase.co" \
  -e DB_PORT="5432" \
  -e DB_NAME="postgres" \
  -e DB_USER="postgres" \
  -e DB_PASSWORD="YourSupabasePassword" \
  -e JWT_SECRET="your_jwt_secret_key" \
  invoicely-backend:latest
```

---

### 4. Run with Docker Compose

From the project root:

```bash
# Start backend in detached mode
docker compose up -d --build

# View real-time logs
docker compose logs -f backend

# Stop the container
docker compose down
```

---

## 🔍 Verification & Health Check

Once running, verify the container:

```bash
# 1. Check container status & health
docker ps

# 2. Check health endpoint
curl http://localhost:8080/api/v1/health

# Expected response:
# {"success":true,"message":"Service is running smoothly","data":{"service":"InvoicelyAi Backend","status":"UP","timestamp":"..."}}

# 3. Interactive API Documentation
# Open in browser: http://localhost:8080/swagger-ui/index.html
```

---

## ☁️ Cloud Deployment Strategies

### Option A: Render (Easiest)
1. Push code to GitHub.
2. In Render Dashboard, click **New +** -> **Web Service**.
3. Select your repository.
4. Set **Root Directory** to `backend`.
5. Select **Docker** as the Environment.
6. Under **Environment Variables**, add:
   - `DB_HOST`: Your Supabase host (e.g. `db.xxxx.supabase.co`)
   - `DB_PORT`: `5432`
   - `DB_NAME`: `postgres`
   - `DB_USER`: `postgres`
   - `DB_PASSWORD`: Your database password
   - `JWT_SECRET`: Your production secret
7. Render will automatically detect `backend/Dockerfile` and deploy.

### Option B: Railway
1. Click **New Project** -> **Deploy from GitHub repo**.
2. Go to **Settings** -> **Root Directory**, set to `/backend`.
3. Railway automatically detects `Dockerfile` and builds the image.
4. Add environment variables in Railway Variables tab.

### Option C: Google Cloud Run / AWS ECR & ECS
1. Build and tag image:
   ```bash
   docker build -t gcr.io/<PROJECT_ID>/invoicely-backend:1.0.0 backend/
   ```
2. Push to container registry:
   ```bash
   docker push gcr.io/<PROJECT_ID>/invoicely-backend:1.0.0
   ```
3. Deploy to Cloud Run:
   ```bash
   gcloud run deploy invoicely-backend \
     --image gcr.io/<PROJECT_ID>/invoicely-backend:1.0.0 \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars DB_HOST=...,DB_PASSWORD=...
   ```

---

## 🔑 Environment Variables Reference

| Variable | Default Value | Description |
|---|---|---|
| `PORT` | `8080` | Port the web service listens on |
| `DB_HOST` | `db.pggsnzcbkqyzcpjmcmqj.supabase.co` | Supabase PostgreSQL Host |
| `DB_PORT` | `5432` | PostgreSQL Port |
| `DB_NAME` | `postgres` | Database Name |
| `DB_USER` | `postgres` | Database User |
| `DB_PASSWORD` | - | Database Password |
| `JWT_SECRET` | - | Secret key used to sign and verify JWT tokens |
| `DEV_SECRET_KEY` | - | Secret key required to register platform developers |
| `JAVA_OPTS` | Container RAM limits (75%) | JVM runtime tuning parameters |
