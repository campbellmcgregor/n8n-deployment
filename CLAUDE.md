# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive Docker-based self-hosted n8n workflow automation platform deployment. The repository provides production-ready infrastructure with advanced features including queue management, monitoring, backup/restore systems, and extensibility through custom nodes and hooks.

## Architecture

### Core Components
- **n8n Main Instance**: Workflow editor and API (port 5678) - handles UI, webhooks, and timers
- **n8n Worker**: Background task processor in queue mode - executes workflows asynchronously  
- **PostgreSQL**: Primary database for workflows, credentials, and execution data (port 5432)
- **Redis**: Queue management and caching for distributed execution (port 6379)
- **Caddy** (optional): HTTPS termination and reverse proxy (ports 80/443)

### Queue Mode Architecture
The deployment uses n8n's queue mode for scalability:
- Main instance generates execution jobs and handles webhooks/timers
- Redis acts as message broker between main instance and workers
- Workers consume jobs from Redis queue and execute workflows
- All containers share the same encryption key and database connection
- `EXECUTIONS_MODE=queue` must be set on all n8n containers

### Docker Compose Structure
- Uses `x-n8n-common` anchor for shared configuration across n8n containers
- Shared volumes for persistent data, custom nodes, external hooks, logs, and backups
- Health checks for PostgreSQL and Redis with proper dependency management
- Container networking via dedicated `n8n-network` bridge

## Key Commands

### Just Task Runner (Recommended)
```bash
# Setup and start
just setup                    # Initial setup with environment generation
just start                    # Start all services
just start-https              # Start with HTTPS support  
just stop                     # Stop services gracefully

# Monitoring and logs
just health                   # Comprehensive health check
just status                   # Container status
just logs-n8n                 # n8n logs
just logs-db                  # PostgreSQL logs

# Backup and restore
just backup                   # Create complete backup
just backup-list              # List available backups
just restore                  # Interactive restore
just restore-date DATE        # Restore specific backup

# Database operations
just db-connect               # Connect to PostgreSQL
just db-info                  # Database size and table info
just redis-cli                # Connect to Redis CLI

# Development
just shell                    # Shell in n8n container
just version                  # Show n8n version
just urls                     # Show all service URLs
```

### Docker Compose (Manual)
```bash
# Basic operations
docker compose up -d          # Start all services
docker compose down           # Stop services
docker compose ps             # Check container status
docker compose logs -f n8n    # Follow n8n logs

# HTTPS profile
docker compose --profile https up -d

# Scaling workers
docker compose up -d --scale n8n-worker=3
```

### Environment Setup
```bash
# Generate secure keys
openssl rand -hex 32          # For N8N_ENCRYPTION_KEY and N8N_JWT_SECRET

# Copy and configure environment
cp env.template .env
# Edit .env with proper values

# Required environment variables:
# - N8N_ENCRYPTION_KEY (32+ chars)
# - N8N_JWT_SECRET (32+ chars)  
# - POSTGRES_PASSWORD
# - EXECUTIONS_MODE=queue
```

## Critical Configuration Notes

### Environment Variables
- All n8n containers must share the same `N8N_ENCRYPTION_KEY` for credential access
- `EXECUTIONS_MODE=queue` is required for worker functionality
- Database credentials must match between PostgreSQL container and n8n containers
- Redis connection settings (`QUEUE_BULL_REDIS_HOST=redis`) enable queue communication

### Worker Command Syntax
- Use `command: worker` (not `command: n8n worker`) 
- Use `command: webhook` (not `command: n8n webhook`) if webhook processor is used
- Modern n8n Docker images expect this simplified syntax

### Webhook Container (Optional)
- The webhook container is optional and can be removed for simpler deployments
- Main n8n instance can handle webhooks directly in most cases
- Only needed for high-throughput webhook scenarios with load balancing

## Development Workflows

### Custom Node Development
1. Place custom nodes in `custom-nodes/` directory
2. Install dependencies: `cd custom-nodes/ && npm install n8n-nodes-package`
3. Restart n8n: `just restart`
4. Custom nodes are mounted as volume to container

### External Hooks Development  
1. Edit `external-hooks/external-hooks.js` for custom backend logic
2. Hooks execute at workflow lifecycle events (activate, deactivate, before/after execution)
3. Restart n8n to apply changes: `just restart`
4. Use for custom logging, analytics, integrations, or business logic

### Backup/Restore System
- Automated backup script creates PostgreSQL dumps and workflow exports
- Comprehensive restore with validation and rollback capabilities
- Test suite verifies backup/restore functionality
- Supports partial restores (workflows-only or database-only)

## Security Considerations

- Generate strong encryption keys (32+ character hex strings)
- Keep `.env` file out of version control (included in .gitignore)
- Database passwords should be changed from defaults
- External hooks have full access to n8n internals - validate custom code carefully
- HTTPS setup recommended for production via Caddy configuration

## Common Issues

### Container Startup Problems
- Ensure `.env` file exists with proper values
- Check `EXECUTIONS_MODE=queue` is set in both Docker Compose and .env
- Verify PostgreSQL and Redis are healthy before n8n containers start
- Review container logs: `just logs-n8n` or `docker compose logs n8n`

### Queue Mode Issues
- All n8n containers need same encryption key and database access
- Redis must be accessible to all n8n containers
- Worker containers need proper Redis queue configuration
- Check Redis connectivity: `just redis-cli` then `PING`

### Performance Tuning
- Scale workers: `docker compose up -d --scale n8n-worker=3`
- Monitor resource usage: `just stats`
- Adjust worker concurrency via environment variables
- PostgreSQL connection pool limits may need tuning for multiple workers