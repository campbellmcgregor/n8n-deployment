#!/bin/bash

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

    if [ ! -f "env.template" ]; then
        print_error "env.template file not found!"
        exit 1
    fi

    print_step "Copying environment template"
    cp env.template .env

    # Generate secure keys
    print_step "Generating secure keys..."
    ENCRYPTION_KEY=$(generate_key)
    JWT_SECRET=$(generate_key)
    DB_PASSWORD=$(generate_key | cut -c1-16) # Shorter for DB password

    # Replace placeholders in .env file
    if command_exists sed; then
        sed -i.tmp "s/your_encryption_key_here_32_chars_min/$ENCRYPTION_KEY/g" .env
        sed -i.tmp "s/your_jwt_secret_here_32_chars_minimum/$JWT_SECRET/g" .env
        sed -i.tmp "s/n8n_secure_password/$DB_PASSWORD/g" .env
        rm -f .env.tmp
        print_step "Updated .env file with secure keys"
    else
        print_warning "sed command not found. Please manually update the .env file with secure keys."
        print_color $YELLOW "Encryption Key: $ENCRYPTION_KEY"
        print_color $YELLOW "JWT Secret: $JWT_SECRET"
        print_color $YELLOW "DB Password: $DB_PASSWORD"
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

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_services
        show_access_info
    else
        print_color $YELLOW "Setup completed! Run 'docker compose up -d' when you're ready to start."
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
