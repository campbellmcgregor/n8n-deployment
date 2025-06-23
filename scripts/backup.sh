#!/bin/bash

# n8n Backup Script
# This script creates backups of your n8n workflows and database

set -e

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

echo "Starting backup process..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup n8n workflows and credentials
echo "Backing up n8n workflows and credentials..."
docker-compose exec -T n8n n8n export:workflow --backup --output="/home/node/.n8n/backups/n8n-backup-$DATE.tar.gz"

# Backup database
echo "Backing up PostgreSQL database..."
docker-compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/postgres-backup-$DATE.sql"

# Compress database backup
gzip "$BACKUP_DIR/postgres-backup-$DATE.sql"

echo "✓ Backup completed successfully!"
echo "  - n8n data: ./backups/n8n-backup-$DATE.tar.gz"
echo "  - Database: ./backups/postgres-backup-$DATE.sql.gz"

# Optional: Clean up old backups (keep only last 7 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete 2>/dev/null || true

echo "✓ Old backups cleaned up (kept last 7 days)"
