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

# Stop all services gracefully (core + AI services + utilities)
stop:
  @echo "🛑 Stopping all services..."
  @echo "Stopping core n8n services..."
  @docker compose down 2>/dev/null || true
  @echo "Stopping combined stacks..."
  @docker compose -f docker-compose.yml -f docker-compose.langfuse.yml down 2>/dev/null || true
  @docker compose -f docker-compose.yml -f docker-compose.supabase.yml down 2>/dev/null || true
  @docker compose -f docker-compose.yml -f docker-compose.supabase-minimal.yml down 2>/dev/null || true
  @echo "Stopping individual utility platforms..."
  @docker compose -f docker-compose.supabase.yml down 2>/dev/null || true
  @docker compose -f docker-compose.supabase-minimal.yml down 2>/dev/null || true
  @docker compose -f docker-compose.langfuse.yml down 2>/dev/null || true
  @echo "Cleaning up any remaining containers..."
  @docker stop $(docker ps -q --filter "name=langfuse-*") 2>/dev/null || true
  @docker stop $(docker ps -q --filter "name=supabase-*") 2>/dev/null || true
  @docker stop $(docker ps -q --filter "name=n8n-*") 2>/dev/null || true
  @docker rm $(docker ps -aq --filter "name=langfuse-*") 2>/dev/null || true
  @docker rm $(docker ps -aq --filter "name=supabase-*") 2>/dev/null || true
  @docker rm $(docker ps -aq --filter "name=n8n-*") 2>/dev/null || true
  @echo "✅ All services stopped!"

# Stop only core n8n services (excludes utilities)
stop-core:
  @echo "🛑 Stopping core n8n services..."
  ./scripts/stop_n8n.sh

# Force stop all services without confirmation
stop-force:
  @echo "🛑 Force stopping all services..."
  @echo "Force stopping core n8n services..."
  @docker compose down --timeout 10 2>/dev/null || true
  @echo "Force stopping combined stacks..."
  @docker compose -f docker-compose.yml -f docker-compose.langfuse.yml down --timeout 10 2>/dev/null || true
  @docker compose -f docker-compose.yml -f docker-compose.supabase.yml down --timeout 10 2>/dev/null || true
  @docker compose -f docker-compose.yml -f docker-compose.supabase-minimal.yml down --timeout 10 2>/dev/null || true
  @echo "Force stopping individual utility platforms..."
  @docker compose -f docker-compose.supabase.yml down --timeout 10 2>/dev/null || true
  @docker compose -f docker-compose.supabase-minimal.yml down --timeout 10 2>/dev/null || true
  @docker compose -f docker-compose.langfuse.yml down --timeout 10 2>/dev/null || true
  @echo "Force killing any remaining containers..."
  @docker kill $(docker ps -q --filter "name=langfuse-*") 2>/dev/null || true
  @docker kill $(docker ps -q --filter "name=supabase-*") 2>/dev/null || true
  @docker kill $(docker ps -q --filter "name=n8n-*") 2>/dev/null || true
  @docker rm -f $(docker ps -aq --filter "name=langfuse-*") 2>/dev/null || true
  @docker rm -f $(docker ps -aq --filter "name=supabase-*") 2>/dev/null || true
  @docker rm -f $(docker ps -aq --filter "name=n8n-*") 2>/dev/null || true
  @echo "✅ All services force stopped!"

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

# Show logs for Qdrant
logs-qdrant:
  @echo "📋 Showing Qdrant logs..."
  docker compose logs -f qdrant

# Show logs for Flowise
logs-flowise:
  @echo "📋 Showing Flowise logs..."
  docker compose logs -f flowise

# Show logs for Neo4j
logs-neo4j:
  @echo "📋 Showing Neo4j logs..."
  docker compose logs -f neo4j

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

# Test backup functionality
backup-test:
  @echo "🧪 Testing backup functionality..."
  @echo "1. Checking backup directory permissions..."
  @ls -la ./backups 2>/dev/null || echo "Backups directory doesn't exist - will be created"
  @echo "2. Testing backup process..."
  @./scripts/backup.sh
  @echo "3. Verifying backup files..."
  @ls -lh ./backups/ | tail -5

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

# Restore only AI services from backup
restore-ai-services DATE:
  @echo "🔄 Restoring AI services from {{DATE}}..."
  ./scripts/restore.sh --ai-services-only {{DATE}}

# Backup utility platforms only
backup-utilities:
  @echo "💾 Backing up utility platforms..."
  ./scripts/backup.sh --utilities-only

# Backup Supabase platform only
backup-supabase:
  @echo "💾 Backing up Supabase platform..."
  ./scripts/backup.sh --supabase-only

# Backup Langfuse observability only
backup-langfuse:
  @echo "💾 Backing up Langfuse observability..."
  ./scripts/backup.sh --langfuse-only

# Restore utility platforms from backup
restore-utilities DATE:
  @echo "🔄 Restoring utility platforms from {{DATE}}..."
  ./scripts/restore.sh --utilities-only {{DATE}}

# Restore Supabase platform from backup
restore-supabase DATE:
  @echo "🔄 Restoring Supabase platform from {{DATE}}..."
  ./scripts/restore.sh --supabase-only {{DATE}}

# Restore Langfuse observability from backup
restore-langfuse DATE:
  @echo "🔄 Restoring Langfuse observability from {{DATE}}..."
  ./scripts/restore.sh --langfuse-only {{DATE}}

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

# AI Services Operations
# ======================

# Open Neo4j Browser
neo4j-browser:
  @echo "🌐 Opening Neo4j Browser..."
  @echo "  Neo4j Browser: http://localhost:7474"
  @echo "  Bolt URL: bolt://localhost:7687"

# Connect to Neo4j via Cypher Shell
neo4j-shell:
  @echo "🔌 Connecting to Neo4j Cypher Shell..."
  docker compose exec neo4j cypher-shell

# Open Flowise UI
flowise-ui:
  @echo "🌐 Opening Flowise UI..."
  @echo "  Flowise UI: http://localhost:3001"

# Check Qdrant status
qdrant-status:
  @echo "📊 Qdrant cluster status:"
  @curl -s http://localhost:6333/cluster || echo "Qdrant not accessible"

# Open Qdrant dashboard
qdrant-ui:
  @echo "🌐 Qdrant Dashboard..."
  @echo "  Qdrant API: http://localhost:6333"
  @echo "  Collections: http://localhost:6333/collections"

# Utility Platform Operations  
# ============================

# Start Supabase database platform
start-supabase:
  @echo "🚀 Starting Supabase platform (minimal)..."
  docker compose -f docker-compose.yml -f docker-compose.supabase-minimal.yml up -d

# Stop Supabase platform
stop-supabase:
  @echo "🛑 Stopping Supabase platform..."
  docker compose -f docker-compose.supabase-minimal.yml down

# Restart Supabase platform
restart-supabase: stop-supabase start-supabase

# Start Langfuse observability
start-langfuse:
  @echo "🚀 Starting Langfuse observability..."
  docker compose -f docker-compose.yml -f docker-compose.langfuse.yml up -d

# Stop Langfuse observability
stop-langfuse:
  @echo "🛑 Stopping Langfuse observability..."
  docker compose -f docker-compose.langfuse.yml down

# Restart Langfuse observability
restart-langfuse: stop-langfuse start-langfuse

# Start both utility platforms
start-utilities:
  @echo "🚀 Starting utility platforms (Supabase + Langfuse)..."
  docker compose -f docker-compose.yml -f docker-compose.supabase.yml -f docker-compose.langfuse.yml up -d

# Stop both utility platforms
stop-utilities:
  @echo "🛑 Stopping utility platforms..."
  docker compose -f docker-compose.supabase.yml down
  docker compose -f docker-compose.langfuse.yml down

# Restart both utility platforms
restart-utilities: stop-utilities start-utilities

# Show utility service status
status-utilities:
  @echo "📊 Utility Platform Status:"
  @echo ""
  @echo "Supabase Services:"
  @docker compose -f docker-compose.supabase-minimal.yml ps 2>/dev/null || echo "  No Supabase services running"
  @echo ""
  @echo "Langfuse Services:"
  @docker compose -f docker-compose.yml -f docker-compose.langfuse.yml ps langfuse-web langfuse-worker clickhouse minio 2>/dev/null || echo "  No Langfuse services running"

# View Supabase logs
logs-supabase:
  @echo "📋 Showing Supabase platform logs..."
  docker compose -f docker-compose.supabase-minimal.yml logs -f

# View Langfuse logs
logs-langfuse:
  @echo "📋 Showing Langfuse observability logs..."
  docker compose -f docker-compose.langfuse.yml logs -f

# Open Supabase Studio
supabase-studio:
  @echo "🌐 Opening Supabase Studio..."
  @echo "  Supabase Studio: http://localhost:3000"
  @echo "  Supabase API: http://localhost:8000"

# Connect to Supabase PostgreSQL
supabase-db:
  @echo "🔌 Connecting to Supabase PostgreSQL..."
  docker compose -f docker-compose.supabase-minimal.yml exec supabase-db psql -U postgres

# Open Langfuse dashboard
langfuse-ui:
  @echo "🌐 Opening Langfuse dashboard..."
  @echo "  Langfuse Dashboard: http://localhost:3002"

# Connect to ClickHouse client
clickhouse-client:
  @echo "🔌 Connecting to ClickHouse..."
  docker compose -f docker-compose.yml -f docker-compose.langfuse.yml exec clickhouse clickhouse-client

# Open MinIO console
minio-console:
  @echo "🌐 Opening MinIO console..."
  @echo "  MinIO Console: http://localhost:9001"
  @echo "  MinIO API: http://localhost:9000"

# View Supabase auth service logs
supabase-logs-auth:
  @echo "📋 Showing Supabase auth logs..."
  docker compose -f docker-compose.supabase.yml logs -f supabase-auth

# View Supabase API logs
supabase-logs-api:
  @echo "📋 Showing Supabase API logs..."
  docker compose -f docker-compose.supabase.yml logs -f supabase-kong

# View Langfuse web service logs
langfuse-logs-web:
  @echo "📋 Showing Langfuse web logs..."
  docker compose -f docker-compose.langfuse.yml logs -f langfuse-web

# View Langfuse worker logs
langfuse-logs-worker:
  @echo "📋 Showing Langfuse worker logs..."
  docker compose -f docker-compose.langfuse.yml logs -f langfuse-worker

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

# Show all service URLs
urls:
  @echo "🌐 Core Services:"
  @echo "  • n8n Editor: http://localhost:5678"
  @echo "  • n8n API: http://localhost:5678/api"
  @echo "  • PostgreSQL: localhost:5432"
  @echo "  • Redis: localhost:6379"
  @echo ""
  @echo "🤖 AI Services:"
  @echo "  • Flowise: http://localhost:3001"
  @echo "  • Neo4j Browser: http://localhost:7474"
  @echo "  • Qdrant API: http://localhost:6333"
  @echo ""
  @echo "🗄️ Database Platform:"
  @if docker compose -f docker-compose.supabase.yml ps 2>/dev/null | grep -q "Up"; then echo "  • Supabase Studio: http://localhost:3000"; echo "  • Supabase API: http://localhost:8000"; else echo "  • Supabase: Not running"; fi
  @echo ""
  @echo "📊 LLM Observability:"
  @if docker compose -f docker-compose.langfuse.yml ps 2>/dev/null | grep -q "Up"; then echo "  • Langfuse Dashboard: http://localhost:3002"; echo "  • ClickHouse: http://localhost:8123"; echo "  • MinIO Console: http://localhost:9001"; else echo "  • Langfuse: Not running"; fi

# Show utility service URLs only
urls-utilities:
  @echo "🗄️ Database Platform:"
  @if docker compose -f docker-compose.supabase.yml ps 2>/dev/null | grep -q "Up"; then echo "  • Supabase Studio: http://localhost:3000"; echo "  • Supabase API: http://localhost:8000"; else echo "  • Supabase: Not running"; fi
  @echo ""
  @echo "📊 LLM Observability:"
  @if docker compose -f docker-compose.langfuse.yml ps 2>/dev/null | grep -q "Up"; then echo "  • Langfuse Dashboard: http://localhost:3002"; echo "  • ClickHouse: http://localhost:8123"; echo "  • MinIO Console: http://localhost:9001"; else echo "  • Langfuse: Not running"; fi

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
  @echo "  just start              - Start core n8n services"
  @echo "  just start-https        - Start with HTTPS support"
  @echo "  just start-dev          - Start in development mode"
  @echo "  just start-supabase     - Start Supabase database platform"
  @echo "  just start-langfuse     - Start Langfuse LLM observability"
  @echo "  just start-utilities    - Start both utility platforms"

help-stop:
  @echo "🛑 Stop Commands:"
  @echo "  just stop               - Stop ALL services (core + AI + utilities)"
  @echo "  just stop-core          - Stop only core n8n services"
  @echo "  just stop-force         - Force stop ALL services without confirmation"
  @echo "  just stop-supabase      - Stop Supabase platform"
  @echo "  just stop-langfuse      - Stop Langfuse observability"
  @echo "  just stop-utilities     - Stop both utility platforms"
  @echo "  just stop-clean         - Stop and remove all data (⚠️ DESTRUCTIVE!)"

help-backup:
  @echo "💾 Backup & Restore Commands:"
  @echo "  just backup                     - Create backup of all services"
  @echo "  just backup-utilities           - Backup utility platforms only"
  @echo "  just backup-supabase            - Backup Supabase platform only"
  @echo "  just backup-langfuse            - Backup Langfuse observability only"
  @echo "  just restore DATE               - Interactive restore"
  @echo "  just restore-utilities DATE     - Restore utility platforms"
  @echo "  just restore-supabase DATE      - Restore Supabase platform"
  @echo "  just restore-langfuse DATE      - Restore Langfuse observability"

help-utilities:
  @echo "🔧 Utility Platform Commands:"
  @echo ""
  @echo "Database Platform (Supabase):"
  @echo "  just start-supabase             - Start Supabase platform"
  @echo "  just supabase-studio            - Open Supabase Studio UI"
  @echo "  just supabase-db                - Connect to Supabase PostgreSQL"
  @echo "  just logs-supabase              - View Supabase platform logs"
  @echo "  just supabase-logs-auth         - View authentication service logs"
  @echo "  just supabase-logs-api          - View API gateway logs"
  @echo ""
  @echo "LLM Observability (Langfuse):"
  @echo "  just start-langfuse             - Start Langfuse observability"
  @echo "  just langfuse-ui                - Open Langfuse dashboard"
  @echo "  just clickhouse-client          - Connect to ClickHouse analytics"
  @echo "  just minio-console              - Open MinIO storage console"
  @echo "  just logs-langfuse              - View Langfuse platform logs"
  @echo "  just langfuse-logs-web          - View Langfuse web service logs"
  @echo "  just langfuse-logs-worker       - View Langfuse worker logs"

help-supabase:
  @echo "🗄️ Supabase Database Platform:"
  @echo "  just start-supabase             - Start complete Supabase platform"
  @echo "  just stop-supabase              - Stop Supabase services"
  @echo "  just restart-supabase           - Restart Supabase platform"
  @echo "  just supabase-studio            - Open Supabase Studio (http://localhost:3000)"
  @echo "  just supabase-db                - Connect to Supabase PostgreSQL"
  @echo "  just logs-supabase              - View all Supabase logs"
  @echo "  just supabase-logs-auth         - View authentication service logs"
  @echo "  just supabase-logs-api          - View API gateway logs"
  @echo "  just backup-supabase            - Backup Supabase platform"
  @echo "  just restore-supabase DATE      - Restore Supabase from backup"

help-langfuse:
  @echo "📊 Langfuse LLM Observability:"
  @echo "  just start-langfuse             - Start Langfuse observability stack"
  @echo "  just stop-langfuse              - Stop Langfuse services"
  @echo "  just restart-langfuse           - Restart Langfuse platform"
  @echo "  just langfuse-ui                - Open Langfuse dashboard (http://localhost:3002)"
  @echo "  just clickhouse-client          - Connect to ClickHouse analytics DB"
  @echo "  just minio-console              - Open MinIO console (http://localhost:9001)"
  @echo "  just logs-langfuse              - View all Langfuse logs"
  @echo "  just langfuse-logs-web          - View Langfuse web service logs"
  @echo "  just langfuse-logs-worker       - View Langfuse worker logs"
  @echo "  just backup-langfuse            - Backup Langfuse observability"
  @echo "  just restore-langfuse DATE      - Restore Langfuse from backup"

help-backup-utils:
  @echo "💾 Utility Backup & Restore:"
  @echo "  just backup-utilities           - Backup both Supabase + Langfuse"
  @echo "  just backup-supabase            - Backup Supabase platform only"
  @echo "  just backup-langfuse            - Backup Langfuse observability only"
  @echo "  just restore-utilities DATE     - Restore both platforms"
  @echo "  just restore-supabase DATE      - Restore Supabase platform"
  @echo "  just restore-langfuse DATE      - Restore Langfuse observability"
  @echo ""
  @echo "Examples:"
  @echo "  just backup-utilities           # Backup both platforms"
  @echo "  just restore-supabase 20250805_120000  # Restore specific Supabase backup" 