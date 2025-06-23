# 🚀 Quick Start Guide

Get n8n running locally in under 5 minutes!

## Prerequisites ✅

- Docker & Docker Compose installed
- Just task runner installed ([installation guide](https://github.com/casey/just#installation))
- 2GB+ RAM available
- Port 5678 available

## Quick Setup

### Option 1: Using Just (Recommended)

```bash
# Install just if not already installed
brew install just  # macOS
# or: cargo install just

# Run the setup and start
just setup
just start
```

The `just setup` command will:

- ✅ Check prerequisites
- ✅ Create necessary directories
- ✅ Generate secure keys
- ✅ Configure environment
- ✅ Start all services

### Option 2: Automated Setup Script

```bash
# Run the setup script
just setup
# or directly: ./scripts/setup.sh
```

### Option 3: Manual Setup

```bash
# 1. Copy environment template
cp env.template .env

# 2. Generate secure keys
just gen-key    # Copy this to N8N_ENCRYPTION_KEY in .env
just gen-jwt    # Copy this to N8N_JWT_SECRET in .env

# 3. Start services
just start
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
just status

# View logs
just logs-n8n

# Stop services
just stop

# Restart services
just restart

# Health check
just health

# Backup data
just backup

# Show all commands
just --list
```

## Alternative Commands

If you prefer direct docker-compose commands:

```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f n8n

# Stop services
docker-compose down

# Restart services
docker-compose restart
```

## Troubleshooting 🔧

### Services won't start?

```bash
# Check Docker is running
just check-deps

# Check port availability
lsof -i :5678
```

### Can't access n8n?

```bash
# Wait for services to be ready
just logs-n8n

# Check service status
just status
```

### Database connection issues?

```bash
# Check PostgreSQL
just db-info

# Reset database (⚠️ destroys data)
just stop-clean
just start
```

## What's Next? 📚

- ✅ Run `just --list` to see all available commands
- ✅ Read the full [README.md](README.md) for advanced configuration
- ✅ Explore [n8n documentation](https://docs.n8n.io/)
- ✅ Join the [n8n community](https://community.n8n.io/)
- ✅ Check out [workflow templates](https://n8n.io/workflows/)

---

**Need help?** Check the [troubleshooting section](README.md#troubleshooting) in the main README.
