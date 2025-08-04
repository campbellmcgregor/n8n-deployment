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
docker compose exec -T n8n n8n export:workflow --backup --output=".n8n/backups/n8n-backup-$DATE/"

# Create tar.gz archive from the exported directory
echo "Creating archive from exported workflows..."
docker compose exec -T n8n tar -czf ".n8n/backups/n8n-backup-$DATE.tar.gz" -C ".n8n/backups" "n8n-backup-$DATE"

# Clean up temporary directory
docker compose exec -T n8n rm -rf ".n8n/backups/n8n-backup-$DATE"

# Backup database
echo "Backing up PostgreSQL database..."
docker compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/postgres-backup-$DATE.sql"

# Compress database backup
gzip "$BACKUP_DIR/postgres-backup-$DATE.sql"

# Validate backups were created successfully  
N8N_BACKUP="$BACKUP_DIR/n8n-backup-$DATE.tar.gz"
DB_BACKUP="$BACKUP_DIR/postgres-backup-$DATE.sql.gz"

echo ""
echo "🔍 Validating backups..."

# Check if files exist and have content
if [ -f "$N8N_BACKUP" ] && [ -s "$N8N_BACKUP" ]; then
    N8N_SIZE=$(du -h "$N8N_BACKUP" | cut -f1)
    echo "✓ n8n backup created: $N8N_SIZE"
else
    echo "❌ n8n backup failed or empty"
    exit 1
fi

if [ -f "$DB_BACKUP" ] && [ -s "$DB_BACKUP" ]; then
    DB_SIZE=$(du -h "$DB_BACKUP" | cut -f1)
    echo "✓ Database backup created: $DB_SIZE"
else
    echo "❌ Database backup failed or empty"
    exit 1
fi

echo ""
echo "✅ Backup completed successfully!"
echo "  - n8n data: ./backups/n8n-backup-$DATE.tar.gz ($N8N_SIZE)"
echo "  - Database: ./backups/postgres-backup-$DATE.sql.gz ($DB_SIZE)"

# Optional: Clean up old backups (keep only last 7 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete 2>/dev/null || true

echo "✓ Old backups cleaned up (kept last 7 days)"
