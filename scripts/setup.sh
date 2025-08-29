#!/bin/sh

# Local n8n Setup Script
# This script helps you set up a local n8n deployment

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

print_error() {
    print_color $RED "✗ $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Generate secure random key
generate_key() {
    openssl rand -hex 32
}

# Generate secure random key (64 chars)
generate_key_64() {
    openssl rand -hex 64
}

# Generate secure password (16 chars)
generate_password() {
    openssl rand -base64 12 | tr -d "/+" | cut -c1-16
}

print_warning() {
    print_color $YELLOW "⚠ $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_step "Docker is installed"

    if ! command_exists docker compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_step "Docker Compose is installed"

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    print_step "Docker daemon is running"
}

# Create necessary directories
create_directories() {
    print_header "Creating Directories"

    directories=(
        "shared"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_step "Created directory: $dir"
        else
            print_step "Directory already exists: $dir"
        fi
    done
}

# Setup environment file
setup_environment() {
    print_header "Setting up Environment"

    if [ -f ".env" ]; then
        print_warning "Environment file already exists. Backing up to .env.backup"
        cp .env .env.backup
    fi

    if [ ! -f ".env.example" ]; then
        print_error ".env.example file not found!"
        exit 1
    fi

    print_step "Copying environment template"
    cp .env.example .env

    # Generate all secure keys and passwords
    print_step "Generating secure keys and passwords..."
    N8N_ENCRYPTION_KEY=$(generate_key)
    N8N_JWT_SECRET=$(generate_key)
    POSTGRES_PASSWORD=$(generate_password)
    FLOWISE_PASSWORD=$(generate_password)
    NEO4J_PASSWORD=$(generate_password)
    LANGFUSE_SALT=$(generate_key_64)
    LANGFUSE_NEXTAUTH_SECRET=$(generate_key_64)
    LANGFUSE_ENCRYPTION_KEY=$(generate_key_64)
    LANGFUSE_ADMIN_PASSWORD=$(generate_password)
    CLICKHOUSE_PASSWORD=$(generate_password)
    MINIO_PASSWORD=$(generate_password)
    SUPABASE_JWT_SECRET=$(generate_key)
    SUPABASE_DB_PASSWORD=$(generate_password)
    SUPABASE_DASHBOARD_PASSWORD=$(generate_password)

    # Replace all placeholders in .env file
    if command_exists sed; then
        sed -i.tmp "s/CHANGE_ME_32_char_hex_string/$N8N_ENCRYPTION_KEY/g" .env
        sed -i.tmp "s/CHANGE_ME_secure_password/$POSTGRES_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_password/$NEO4J_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_64_char_hex_string/$LANGFUSE_SALT/g" .env
        sed -i.tmp "s/CHANGE_ME_admin_password/$LANGFUSE_ADMIN_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_clickhouse_password/$CLICKHOUSE_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_minio_password/$MINIO_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_supabase_db_password/$SUPABASE_DB_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_dashboard_password/$SUPABASE_DASHBOARD_PASSWORD/g" .env
        sed -i.tmp "s/CHANGE_ME_supabase_anon_jwt_token/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MTc2OTIwMCwiZXhwIjoxNzk5NTM1NjAwfQ.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE/g" .env
        sed -i.tmp "s/CHANGE_ME_supabase_service_role_jwt_token/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE3OTk1MzU2MDB9.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q/g" .env
        
        # Handle the multi-line replacements separately
        sed -i.tmp "s/LANGFUSE_NEXTAUTH_SECRET=CHANGE_ME_64_char_hex_string/LANGFUSE_NEXTAUTH_SECRET=$LANGFUSE_NEXTAUTH_SECRET/g" .env
        sed -i.tmp "s/LANGFUSE_ENCRYPTION_KEY=CHANGE_ME_64_char_hex_string/LANGFUSE_ENCRYPTION_KEY=$LANGFUSE_ENCRYPTION_KEY/g" .env
        
        rm -f .env.tmp
        print_step "Updated .env file with secure keys and passwords"
    else
        print_warning "sed command not found. Please manually update the .env file with secure keys."
        print_color $YELLOW "Run 'just git-config' to set up Git identity after setup."
    fi
}

# Start services
start_services() {
    print_header "Starting Services"

    print_step "Pulling Docker images..."
    docker compose pull

    print_step "Starting services in detached mode..."
    docker compose up -d

    print_step "Waiting for services to be ready..."
    sleep 10

    # Check service health
    if docker compose ps | grep -q "Up"; then
        print_step "Services are running!"
    else
        print_warning "Some services might still be starting up. Check with: docker compose ps"
    fi
}

# Show access information
show_access_info() {
    print_header "Access Information"

    echo ""
    print_color $GREEN "🎉 n8n is now running!"
    echo ""
    print_color $BLUE "Access URLs:"
    print_color $BLUE "  • n8n Editor: http://localhost:5678"
    print_color $BLUE "  • n8n API: http://localhost:5678/api"
    print_color $BLUE "  • PostgreSQL: localhost:5432"
    print_color $BLUE "  • Redis: localhost:6379"
    echo ""
    print_color $YELLOW "Useful commands:"
    print_color $YELLOW "  • View logs: docker compose logs -f n8n"
    print_color $YELLOW "  • Stop services: docker compose down"
    print_color $YELLOW "  • Backup data: ./scripts/backup.sh"
    echo ""
    print_color $GREEN "Happy automating! 🚀"
}

# Main execution
main() {
    print_header "n8n Self-Hosted / Local Deployment Setup"

    check_prerequisites
    create_directories
    setup_environment

    echo ""
    read -p "Do you want to start the services now? (y/N): " -n 1 -r
    echo ""

    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        start_services
        show_access_info
    else
        print_color $YELLOW "Setup completed! Run 'docker compose up -d' when you're ready to start."
    fi
}

# Run main function if script is executed directly
if [ "${0##*/}" = "setup.sh" ]; then
    main "$@"
fi
