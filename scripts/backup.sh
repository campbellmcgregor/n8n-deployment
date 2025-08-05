#!/bin/bash

# n8n Backup Script
# This script creates backups of your n8n workflows and database
# 
# PERMISSION STRATEGY:
# - Creates backups inside container (/tmp) to avoid host permission issues
# - Uses 'docker cp' to transfer files from container to host
# - This approach works consistently across all deployments regardless of host user ownership

set -e

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

echo "Starting backup process..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup n8n workflows and credentials (create in /tmp inside container to avoid permission issues)
echo "Backing up n8n workflows and credentials..."
export_result=$(docker compose exec -T n8n n8n export:workflow --backup --output="/tmp/n8n-backup-$DATE/" 2>&1 || true)

# Check if export failed due to no workflows (this is OK for new installations)
if echo "$export_result" | grep -q "No workflows found"; then
    echo "ℹ️ No workflows found - creating empty backup for new installation"
    # Create empty backup directory structure
    docker compose exec -T n8n mkdir -p "/tmp/n8n-backup-$DATE"
    docker compose exec -T n8n touch "/tmp/n8n-backup-$DATE/.empty"
elif ! docker compose exec -T n8n test -d "/tmp/n8n-backup-$DATE"; then
    echo "❌ n8n backup directory not created and unknown error occurred"
    echo "Export output: $export_result"
    exit 1
fi

# Create tar.gz archive from the exported directory (inside container)
echo "Creating archive from exported workflows..."
if ! docker compose exec -T n8n tar -czf "/tmp/n8n-backup-$DATE.tar.gz" -C "/tmp" "n8n-backup-$DATE"; then
    echo "❌ Failed to create n8n backup archive"
    docker compose exec -T n8n rm -rf "/tmp/n8n-backup-$DATE" 2>/dev/null || true
    exit 1
fi

# Copy the archive from container to host using docker cp (avoids all permission issues)
echo "Copying backup archive to host..."
if ! docker cp n8n-main:/tmp/n8n-backup-$DATE.tar.gz "$BACKUP_DIR/n8n-backup-$DATE.tar.gz"; then
    echo "❌ Failed to copy n8n backup to host"
    docker compose exec -T n8n rm -rf "/tmp/n8n-backup-$DATE" "/tmp/n8n-backup-$DATE.tar.gz" 2>/dev/null || true
    exit 1
fi

# Clean up temporary files inside container
echo "Cleaning up temporary files in container..."
docker compose exec -T n8n rm -rf "/tmp/n8n-backup-$DATE" "/tmp/n8n-backup-$DATE.tar.gz" 2>/dev/null || true

# Backup database
echo "Backing up PostgreSQL database..."
docker compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/postgres-backup-$DATE.sql"

# Compress database backup
gzip "$BACKUP_DIR/postgres-backup-$DATE.sql"

# Backup AI Services (if running)
# ================================

# Backup Qdrant vector database
if docker compose ps | grep -q "n8n-qdrant.*running"; then
    echo "Backing up Qdrant vector database..."
    # Create Qdrant snapshot via API
    docker compose exec -T qdrant curl -X POST "http://localhost:6333/snapshots" \
        -H "Content-Type: application/json" \
        -d "{}" > /dev/null 2>&1 || true
    
    # Wait for snapshot creation
    sleep 2
    
    # Copy snapshot directory from container
    docker cp n8n-qdrant:/qdrant/storage/snapshots "$BACKUP_DIR/qdrant-snapshots-$DATE" 2>/dev/null || true
    
    # Compress Qdrant backup
    if [ -d "$BACKUP_DIR/qdrant-snapshots-$DATE" ]; then
        tar -czf "$BACKUP_DIR/qdrant-backup-$DATE.tar.gz" -C "$BACKUP_DIR" "qdrant-snapshots-$DATE"
        rm -rf "$BACKUP_DIR/qdrant-snapshots-$DATE"
        echo "✓ Qdrant backup created"
    fi
fi

# Backup Flowise data
if docker compose ps | grep -q "n8n-flowise.*running"; then
    echo "Backing up Flowise data..."
    # Create temporary directory in container
    docker compose exec -T flowise mkdir -p /tmp/flowise-backup 2>/dev/null || true
    
    # Copy Flowise data to temp directory
    docker compose exec -T flowise cp -r /root/.flowise /tmp/flowise-backup/ 2>/dev/null || true
    
    # Create tar archive in container
    docker compose exec -T flowise tar -czf /tmp/flowise-backup-$DATE.tar.gz -C /tmp/flowise-backup .flowise 2>/dev/null || true
    
    # Copy backup to host
    docker cp n8n-flowise:/tmp/flowise-backup-$DATE.tar.gz "$BACKUP_DIR/flowise-backup-$DATE.tar.gz" 2>/dev/null || true
    
    # Clean up temp files in container
    docker compose exec -T flowise rm -rf /tmp/flowise-backup /tmp/flowise-backup-$DATE.tar.gz 2>/dev/null || true
    
    if [ -f "$BACKUP_DIR/flowise-backup-$DATE.tar.gz" ]; then
        echo "✓ Flowise backup created"
    fi
fi

# Backup Neo4j graph database
if docker compose ps | grep -q "n8n-neo4j.*running"; then
    echo "Backing up Neo4j database..."
    # Stop Neo4j for consistent backup (optional, comment out if you prefer online backup)
    # docker compose stop neo4j
    
    # Create Neo4j dump
    docker compose exec -T neo4j neo4j-admin database dump neo4j --to-path=/tmp --verbose 2>/dev/null || true
    
    # Copy dump to host
    if docker compose exec -T neo4j test -f /tmp/neo4j.dump; then
        docker cp n8n-neo4j:/tmp/neo4j.dump "$BACKUP_DIR/neo4j-backup-$DATE.dump" 2>/dev/null || true
        
        # Clean up temp file in container
        docker compose exec -T neo4j rm -f /tmp/neo4j.dump 2>/dev/null || true
        
        # Compress Neo4j backup
        if [ -f "$BACKUP_DIR/neo4j-backup-$DATE.dump" ]; then
            gzip "$BACKUP_DIR/neo4j-backup-$DATE.dump"
            echo "✓ Neo4j backup created"
        fi
    fi
    
    # Restart Neo4j if it was stopped
    # docker compose start neo4j
fi

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
