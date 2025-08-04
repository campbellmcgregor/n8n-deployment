# n8n Self-Hosted / Local Deployment Justfile
# Convenient commands for managing your local n8n deployment

# Load environment variables from .env file
set dotenv-load := true

# Default recipe - show available commands
default:
  @just --list

# Setup and Configuration
# ======================

# Run initial setup for n8n deployment
setup:
  @echo "🚀 Running n8n setup..."
  ./scripts/setup.sh

# Generate secure encryption key
gen-key:
  @echo "Generated encryption key:"
  @openssl rand -hex 32

# Generate secure JWT secret
gen-jwt:
  @echo "Generated JWT secret:"
  @openssl rand -hex 32

# Service Management
# ==================

# Start n8n services (normal mode)
start:
  @echo "🔄 Starting n8n services..."
  ./scripts/start_n8n.sh

# Start n8n services with HTTPS support
start-https:
  @echo "🔄 Starting n8n services with HTTPS..."
  ./scripts/start_n8n.sh --https

# Start n8n services in development mode
start-dev:
  @echo "🔄 Starting n8n services in development mode..."
  ./scripts/start_n8n.sh --dev

# Start n8n services with HTTPS and development mode
start-https-dev:
  @echo "🔄 Starting n8n services with HTTPS and development mode..."
  ./scripts/start_n8n.sh --https --dev

# Stop n8n services gracefully
stop:
  @echo "🛑 Stopping n8n services..."
  ./scripts/stop_n8n.sh

# Force stop n8n services without confirmation
stop-force:
  @echo "🛑 Force stopping n8n services..."
  ./scripts/stop_n8n.sh --force

# Stop services and remove volumes (⚠️ DELETES ALL DATA!)
stop-clean:
  @echo "🧹 Stopping and cleaning up all data..."
  ./scripts/stop_n8n.sh --clean

# Stop services and remove only volumes (⚠️ DELETES ALL DATA!)
stop-volumes:
  @echo "🗑️ Stopping and removing volumes..."
  ./scripts/stop_n8n.sh --volumes

# Stop services and remove Docker images
stop-images:
  @echo "🗑️ Stopping and removing images..."
  ./scripts/stop_n8n.sh --images

# Restart n8n services
restart: stop start

# Restart n8n services with HTTPS
restart-https: stop start-https

# Docker Compose Operations
# =========================

# Start services using docker compose up -d
up:
  @echo "🆙 Starting services with docker compose..."
  docker compose up -d

# Start services with HTTPS profile
up-https:
  @echo "🆙 Starting services with HTTPS profile..."
  docker compose --profile https up -d

# Start services in development mode
up-dev:
  @echo "🆙 Starting services in development mode..."
  docker compose -f docker compose.yml -f docker compose.dev.yml up -d

# Stop services using docker compose down
down:
  @echo "⬇️ Stopping services with docker compose..."
  docker compose down

# Pull latest Docker images
pull:
  @echo "⬇️ Pulling latest Docker images..."
  docker compose pull

# Monitoring and Logs
# ===================

# Check health of all services
health:
  @echo "🩺 Checking service health..."
  ./scripts/health-check.sh

# Show status of all containers
status:
  @echo "📊 Container status:"
  @docker compose ps

# Show logs for all services
logs:
  @echo "📋 Showing logs for all services..."
  docker compose logs

# Show logs for n8n main service
logs-n8n:
  @echo "📋 Showing n8n logs..."
  docker compose logs -f n8n

# Show logs for PostgreSQL
logs-db:
  @echo "📋 Showing PostgreSQL logs..."
  docker compose logs -f postgres

# Show logs for Redis
logs-redis:
  @echo "📋 Showing Redis logs..."
  docker compose logs -f redis

# Follow logs for all services
logs-follow:
  @echo "📋 Following logs for all services..."
  docker compose logs -f

# Show resource usage statistics
stats:
  @echo "📊 Container resource usage:"
  @docker stats --no-stream

# Backup and Restore
# ==================

# Create backup of workflows and database
backup:
  @echo "💾 Creating backup..."
  ./scripts/backup.sh

# List available backups
backup-list:
  @echo "📋 Available backups:"
  ./scripts/restore.sh --list

# Restore from backup (interactive selection)
restore:
  @echo "🔄 Starting restore process..."
  ./scripts/restore.sh

# Restore specific backup by date (format: YYYYMMDD_HHMMSS)
restore-date DATE:
  @echo "🔄 Restoring backup from {{DATE}}..."
  ./scripts/restore.sh {{DATE}}

# Restore only workflows from backup
restore-workflows DATE:
  @echo "🔄 Restoring workflows from {{DATE}}..."
  ./scripts/restore.sh --workflows-only {{DATE}}

# Restore only database from backup
restore-database DATE:
  @echo "🔄 Restoring database from {{DATE}}..."
  ./scripts/restore.sh --database-only {{DATE}}

# Force restore without confirmation
restore-force DATE:
  @echo "🔄 Force restoring backup from {{DATE}}..."
  ./scripts/restore.sh --force {{DATE}}

# Testing
# =======

# Run backup/restore tests
test:
  @echo "🧪 Running backup/restore tests..."
  ./tests/test-backup-restore.sh

# Run quick backup/restore tests
test-quick:
  @echo "🧪 Running quick tests..."
  ./tests/test-backup-restore.sh --quick

# Database Operations
# ===================

# Connect to PostgreSQL database
db-connect:
  @echo "🔌 Connecting to PostgreSQL..."
  docker compose exec postgres psql -U n8n -d n8n

# Show database size and table info
db-info:
  @echo "📊 Database information:"
  @docker compose exec postgres psql -U n8n -d n8n -c "\l+ n8n"
  @docker compose exec postgres psql -U n8n -d n8n -c "\dt+"

# Backup database only
db-backup:
  @echo "💾 Backing up database..."
  @mkdir -p backups
  @docker compose exec -T postgres pg_dump -U n8n n8n > backups/manual-db-backup-$(date +%Y%m%d_%H%M%S).sql
  @echo "✅ Database backup completed"

# Redis Operations
# ================

# Connect to Redis CLI
redis-cli:
  @echo "🔌 Connecting to Redis..."
  docker compose exec redis redis-cli

# Show Redis info
redis-info:
  @echo "📊 Redis information:"
  @docker compose exec redis redis-cli INFO

# Flush all Redis data
redis-flush:
  @echo "🧹 Flushing Redis data..."
  docker compose exec redis redis-cli FLUSHALL

# Development and Debugging
# =========================

# Show n8n version
version:
  @echo "📋 n8n version:"
  @docker compose exec n8n n8n --version

# Show container environment variables
env:
  @echo "🔧 Container environment:"
  @docker compose exec n8n env | grep N8N_

# Execute bash shell in n8n container
shell:
  @echo "🐚 Opening shell in n8n container..."
  docker compose exec n8n bash

# Execute bash shell in PostgreSQL container
shell-db:
  @echo "🐚 Opening shell in PostgreSQL container..."
  docker compose exec postgres bash

# Execute bash shell in Redis container
shell-redis:
  @echo "🐚 Opening shell in Redis container..."
  docker compose exec redis bash

# Cleanup Operations
# ==================

# Remove all stopped containers
clean-containers:
  @echo "🧹 Removing stopped containers..."
  @docker container prune -f

# Remove unused images
clean-images:
  @echo "🧹 Removing unused images..."
  @docker image prune -f

# Remove unused volumes (⚠️ May delete data!)
clean-volumes:
  @echo "🧹 Removing unused volumes..."
  @docker volume prune -f

# Full Docker cleanup (⚠️ DESTRUCTIVE!)
clean-all:
  @echo "🧹 Performing full Docker cleanup..."
  @docker system prune -a -f --volumes

# Utility Commands
# ================

# Show all n8n URLs
urls:
  @echo "🌐 n8n Service URLs:"
  @echo "  • n8n Editor: http://localhost:5678"
  @echo "  • n8n API: http://localhost:5678/api"
  @echo "  • PostgreSQL: localhost:5432"
  @echo "  • Redis: localhost:6379"
  @if docker compose ps | grep -q "caddy"; then echo "  • HTTPS (Caddy): https://localhost"; fi

# Check if required tools are installed
check-deps:
  #!/usr/bin/env bash
  echo "🔍 Checking dependencies..."
  for tool in docker docker compose openssl curl; do
    if command -v $tool >/dev/null 2>&1; then
      echo "✅ $tool is installed"
    else
      echo "❌ $tool is NOT installed"
    fi
  done

# Update to latest n8n version
update:
  @echo "⬆️ Updating to latest n8n version..."
  @just pull
  @just restart

# Reset everything (⚠️ DESTRUCTIVE! Removes all data and containers)
reset:
  @echo "🔄 Resetting entire deployment..."
  @echo "⚠️  This will delete ALL data and containers!"
  @read -p "Are you sure? Type 'yes' to confirm: " confirm && [ "$confirm" = "yes" ] || exit 1
  docker compose down -v --remove-orphans
  docker system prune -f
  @echo "✅ Reset complete. Run 'just setup' to reinitialize."

# Show detailed help for specific operations
help-start:
  @echo "🚀 Start Commands:"
  @echo "  just start          - Start n8n normally"
  @echo "  just start-https    - Start with HTTPS support"
  @echo "  just start-dev      - Start in development mode"
  @echo "  just start-https-dev - Start with HTTPS + dev mode"

help-stop:
  @echo "🛑 Stop Commands:"
  @echo "  just stop           - Stop services gracefully"
  @echo "  just stop-force     - Force stop without confirmation"
  @echo "  just stop-clean     - Stop and remove all data (⚠️ DESTRUCTIVE!)"
  @echo "  just stop-volumes   - Stop and remove volumes (⚠️ DESTRUCTIVE!)"
  @echo "  just stop-images    - Stop and remove Docker images"

help-backup:
  @echo "💾 Backup & Restore Commands:"
  @echo "  just backup                    - Create backup"
  @echo "  just backup-list               - List available backups"
  @echo "  just restore                   - Interactive restore"
  @echo "  just restore-date DATE         - Restore specific backup"
  @echo "  just restore-workflows DATE    - Restore only workflows"
  @echo "  just restore-database DATE     - Restore only database"
  @echo "  just restore-force DATE        - Force restore without confirmation" 