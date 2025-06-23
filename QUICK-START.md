# 🚀 Quick Start Guide

Get n8n running locally in under 5 minutes!

## Prerequisites ✅

- Docker & Docker Compose installed
- 2GB+ RAM available
- Port 5678 available

## Quick Setup

### Option 1: Automated Setup (Recommended)

```bash
# Run the setup script
./scripts/setup.sh
```

The script will:

- ✅ Check prerequisites
- ✅ Create necessary directories
- ✅ Generate secure keys
- ✅ Configure environment
- ✅ Start all services

### Option 2: Manual Setup

```bash
# 1. Copy environment template
cp env.template .env

# 2. Generate secure keys (Linux/Mac)
export N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
export N8N_JWT_SECRET=$(openssl rand -hex 32)
export POSTGRES_PASSWORD=$(openssl rand -hex 16)

# 3. Update .env file
sed -i "s/your_encryption_key_here_32_chars_min/$N8N_ENCRYPTION_KEY/g" .env
sed -i "s/your_jwt_secret_here_32_chars_minimum/$N8N_JWT_SECRET/g" .env
sed -i "s/n8n_secure_password/$POSTGRES_PASSWORD/g" .env

# 4. Start services
docker-compose up -d
```

## Access n8n 🌐

Once running, open: **<http://localhost:5678>**

## First Time Setup 👤

1. Open <http://localhost:5678>
2. Create your admin account
3. Start building workflows!

## Quick Commands 🛠️

```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f n8n

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Health check
./scripts/health-check.sh

# Backup data
./scripts/backup.sh
```

## Troubleshooting 🔧

### Services won't start?

```bash
# Check Docker is running
docker info

# Check port availability
lsof -i :5678
```

### Can't access n8n?

```bash
# Wait for services to be ready
docker-compose logs n8n

# Check if port is bound
docker-compose port n8n 5678
```

### Database connection issues?

```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready -U n8n

# Reset database (⚠️ destroys data)
docker-compose down -v
docker-compose up -d
```

## What's Next? 📚

- ✅ Read the full [README.md](README.md) for advanced configuration
- ✅ Explore [n8n documentation](https://docs.n8n.io/)
- ✅ Join the [n8n community](https://community.n8n.io/)
- ✅ Check out [workflow templates](https://n8n.io/workflows/)

---

**Need help?** Check the [troubleshooting section](README.md#troubleshooting) in the main README.
