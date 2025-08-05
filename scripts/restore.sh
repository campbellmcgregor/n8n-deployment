#!/bin/bash

# n8n Restore Script
# This script restores n8n workflows and database from backups

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    print_color $BLUE "================================"
    print_color $BLUE "$1"
    print_color $BLUE "================================"
}

print_step() {
    print_color $GREEN "✓ $1"
}

print_warning() {
    print_color $YELLOW "⚠ $1"
}

print_error() {
    print_color $RED "✗ $1"
}

# Default values
BACKUP_DIR="./backups"
RESTORE_TYPE="full"
FORCE_RESTORE=false
BACKUP_DATE=""

# Show usage
show_usage() {
    echo "n8n Restore Script"
    echo ""
    echo "Usage: $0 [OPTIONS] [BACKUP_DATE]"
    echo ""
    echo "Options:"
    echo "  --workflows-only    Restore only workflows and credentials"
    echo "  --database-only     Restore only the PostgreSQL database"
    echo "  --ai-services-only  Restore only AI services (Qdrant, Flowise, Neo4j)"
    echo "  --list             List available backups"
    echo "  --force            Force restore without confirmation"
    echo "  --help             Show this help message"
    echo ""
    echo "Arguments:"
    echo "  BACKUP_DATE        Date/time of backup to restore (format: YYYYMMDD_HHMMSS)"
    echo "                     If not provided, will show available backups to choose from"
    echo ""
    echo "Examples:"
    echo "  $0 --list                              # List all available backups"
    echo "  $0 20250622_143000                     # Restore specific backup"
    echo "  $0 --workflows-only 20250622_143000    # Restore only workflows"
    echo "  $0 --database-only 20250622_143000     # Restore only database"
    echo "  $0 --force 20250622_143000             # Force restore without prompts"
    echo ""
    echo "WARNING: Restoration will overwrite existing data!"
}

# List available backups
list_backups() {
    print_header "Available Backups"

    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi

    echo ""
    print_color $BLUE "Database Backups:"
    if ls "$BACKUP_DIR"/postgres-backup-*.sql.gz >/dev/null 2>&1; then
        for backup in "$BACKUP_DIR"/postgres-backup-*.sql.gz; do
            basename=$(basename "$backup")
            date_part=$(echo "$basename" | sed 's/postgres-backup-\(.*\)\.sql\.gz/\1/')
            size=$(du -h "$backup" | cut -f1)
            print_color $YELLOW "  • $date_part ($size)"
        done
    else
        print_warning "  No database backups found"
    fi

    echo ""
    print_color $BLUE "n8n Data Backups:"
    if ls "$BACKUP_DIR"/n8n-backup-*.tar.gz >/dev/null 2>&1; then
        for backup in "$BACKUP_DIR"/n8n-backup-*.tar.gz; do
            basename=$(basename "$backup")
            date_part=$(echo "$basename" | sed 's/n8n-backup-\(.*\)\.tar\.gz/\1/')
            size=$(du -h "$backup" | cut -f1)
            print_color $YELLOW "  • $date_part ($size)"
        done
    else
        print_warning "  No n8n data backups found"
    fi
    echo ""
}

# Validate backup files exist
validate_backup() {
    local date_part="$1"
    local db_backup="$BACKUP_DIR/postgres-backup-$date_part.sql.gz"
    local n8n_backup="$BACKUP_DIR/n8n-backup-$date_part.tar.gz"

    if [ "$RESTORE_TYPE" = "full" ] || [ "$RESTORE_TYPE" = "database" ]; then
        if [ ! -f "$db_backup" ]; then
            print_error "Database backup not found: $db_backup"
            return 1
        fi
    fi

    if [ "$RESTORE_TYPE" = "full" ] || [ "$RESTORE_TYPE" = "workflows" ]; then
        if [ ! -f "$n8n_backup" ]; then
            print_error "n8n backup not found: $n8n_backup"
            return 1
        fi
    fi

    return 0
}

# Check if services are running
check_services() {
    if docker compose ps | grep -q "Up"; then
        print_warning "n8n services are currently running."
        return 0
    fi
    return 1
}

# Stop services if running
stop_services() {
    if check_services; then
        print_step "Stopping n8n services for restoration..."
        docker compose down
        sleep 3
    fi
}

# Start services
start_services() {
    print_step "Starting n8n services..."
    docker compose up -d
    sleep 10

    if docker compose ps | grep -q "Up"; then
        print_step "Services started successfully!"
    else
        print_warning "Some services may still be starting up."
    fi
}

# Restore database
restore_database() {
    local date_part="$1"
    local db_backup="$BACKUP_DIR/postgres-backup-$date_part.sql.gz"

    print_step "Restoring PostgreSQL database..."

    # Start only postgres and redis (needed for n8n to connect later)
    docker compose up -d postgres redis
    sleep 5

    # Drop and recreate database
    docker compose exec -T postgres psql -U n8n -d postgres -c "DROP DATABASE IF EXISTS n8n;"
    docker compose exec -T postgres psql -U n8n -d postgres -c "CREATE DATABASE n8n;"

    # Restore database
    gunzip -c "$db_backup" | docker compose exec -T postgres psql -U n8n -d n8n

    print_step "Database restored successfully"
}

# Restore n8n workflows and credentials
restore_workflows() {
    local date_part="$1"
    local n8n_backup="$BACKUP_DIR/n8n-backup-$date_part.tar.gz"

    print_step "Restoring n8n workflows and credentials..."

    # Start n8n service to access the import functionality
    docker compose up -d n8n
    sleep 10

    # Copy backup file to container and restore
    docker cp "$n8n_backup" n8n-main:/tmp/restore-backup.tar.gz
    docker compose exec -T n8n n8n import:workflow --input="/tmp/restore-backup.tar.gz"

    # Clean up
    docker compose exec -T n8n rm -f /tmp/restore-backup.tar.gz

    print_step "Workflows and credentials restored successfully"
}

# Restore Qdrant vector database
restore_qdrant() {
    local date_part="$1"
    local backup_file="$BACKUP_DIR/qdrant-backup-$date_part.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        print_warning "Qdrant backup not found, skipping..."
        return
    fi
    
    echo "Restoring Qdrant vector database..."
    
    # Extract backup
    tar -xzf "$backup_file" -C "$BACKUP_DIR"
    
    # Stop Qdrant to restore data
    docker compose stop qdrant 2>/dev/null || true
    
    # Clear existing Qdrant data
    docker compose exec -T qdrant rm -rf /qdrant/storage/snapshots 2>/dev/null || true
    
    # Copy snapshots to container
    docker cp "$BACKUP_DIR/qdrant-snapshots-$date_part" n8n-qdrant:/qdrant/storage/snapshots 2>/dev/null || true
    
    # Start Qdrant
    docker compose start qdrant 2>/dev/null || true
    
    # Clean up extracted files
    rm -rf "$BACKUP_DIR/qdrant-snapshots-$date_part"
    
    print_step "Qdrant database restored successfully"
}

# Restore Flowise data
restore_flowise() {
    local date_part="$1"
    local backup_file="$BACKUP_DIR/flowise-backup-$date_part.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        print_warning "Flowise backup not found, skipping..."
        return
    fi
    
    echo "Restoring Flowise data..."
    
    # Copy backup to container
    docker cp "$backup_file" n8n-flowise:/tmp/flowise-restore.tar.gz 2>/dev/null || true
    
    # Stop Flowise
    docker compose stop flowise 2>/dev/null || true
    
    # Clear existing data and restore
    docker compose exec -T flowise bash -c "rm -rf /root/.flowise && tar -xzf /tmp/flowise-restore.tar.gz -C /root/ && rm /tmp/flowise-restore.tar.gz" 2>/dev/null || true
    
    # Start Flowise
    docker compose start flowise 2>/dev/null || true
    
    print_step "Flowise data restored successfully"
}

# Restore Neo4j graph database
restore_neo4j() {
    local date_part="$1"
    local backup_file="$BACKUP_DIR/neo4j-backup-$date_part.dump.gz"
    
    if [ ! -f "$backup_file" ]; then
        print_warning "Neo4j backup not found, skipping..."
        return
    fi
    
    echo "Restoring Neo4j database..."
    
    # Decompress backup
    gunzip -c "$backup_file" > "$BACKUP_DIR/neo4j-restore.dump"
    
    # Copy dump to container
    docker cp "$BACKUP_DIR/neo4j-restore.dump" n8n-neo4j:/tmp/neo4j-restore.dump 2>/dev/null || true
    
    # Stop Neo4j
    docker compose stop neo4j 2>/dev/null || true
    
    # Restore database
    docker compose exec -T neo4j neo4j-admin database load neo4j --from-path=/tmp --overwrite-destination=true 2>/dev/null || true
    
    # Clean up temp files
    docker compose exec -T neo4j rm -f /tmp/neo4j-restore.dump 2>/dev/null || true
    rm -f "$BACKUP_DIR/neo4j-restore.dump"
    
    # Start Neo4j
    docker compose start neo4j 2>/dev/null || true
    
    print_step "Neo4j database restored successfully"
}

# Main restore function
perform_restore() {
    local date_part="$1"

    print_header "Restoring from backup: $date_part"

    # Validate backup files
    if ! validate_backup "$date_part"; then
        exit 1
    fi

    # Confirm destructive operation
    if [ "$FORCE_RESTORE" = false ]; then
        echo ""
        print_color $RED "⚠️  WARNING: This will overwrite existing data!"
        print_color $YELLOW "Restore type: $RESTORE_TYPE"
        print_color $YELLOW "Backup date: $date_part"
        echo ""
        read -p "Are you sure you want to continue? Type 'yes' to confirm: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
            print_step "Restore cancelled."
            exit 0
        fi
    fi

    # Stop services
    stop_services

    # Perform restoration based on type
    case "$RESTORE_TYPE" in
    "full")
        restore_database "$date_part"
        restore_workflows "$date_part"
        # Restore AI services if available
        restore_qdrant "$date_part"
        restore_flowise "$date_part"
        restore_neo4j "$date_part"
        ;;
    "database")
        restore_database "$date_part"
        ;;
    "workflows")
        restore_workflows "$date_part"
        ;;
    "ai-services")
        restore_qdrant "$date_part"
        restore_flowise "$date_part"
        restore_neo4j "$date_part"
        ;;
    esac

    # Start all services
    start_services

    echo ""
    print_header "Restore Completed"
    print_color $GREEN "🎉 Restoration completed successfully!"
    echo ""
    print_color $BLUE "Access URLs:"
    print_color $BLUE "  • n8n Editor: http://localhost:5678"
    print_color $BLUE "  • n8n API: http://localhost:5678/api"
    echo ""
    print_color $YELLOW "Note: It may take a few moments for all services to be fully ready."
}

# Interactive backup selection
select_backup() {
    list_backups

    echo ""
    print_color $BLUE "Enter the backup date/time to restore (YYYYMMDD_HHMMSS):"
    read -p "Backup date: " selected_date

    if [ -z "$selected_date" ]; then
        print_error "No backup date provided."
        exit 1
    fi

    BACKUP_DATE="$selected_date"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --workflows-only)
        RESTORE_TYPE="workflows"
        shift
        ;;
    --database-only)
        RESTORE_TYPE="database"
        shift
        ;;
    --ai-services-only)
        RESTORE_TYPE="ai-services"
        shift
        ;;
    --list)
        list_backups
        exit 0
        ;;
    --force)
        FORCE_RESTORE=true
        shift
        ;;
    --help | -h)
        show_usage
        exit 0
        ;;
    *)
        if [ -z "$BACKUP_DATE" ]; then
            BACKUP_DATE="$1"
        else
            print_error "Unknown option: $1"
            show_usage
            exit 1
        fi
        shift
        ;;
    esac
done

# Main execution
main() {
    print_header "n8n Restore Utility"

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi

    # If no backup date provided, show selection
    if [ -z "$BACKUP_DATE" ]; then
        select_backup
    fi

    # Perform the restore
    perform_restore "$BACKUP_DATE"
}

# Run main function
main "$@"
