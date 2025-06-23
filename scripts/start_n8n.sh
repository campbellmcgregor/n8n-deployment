s#!/bin/bash

# n8n Start Script
# Convenient script to start the n8n local deployment

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

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
}

# Check if environment file exists
check_environment() {
    if [ ! -f ".env" ]; then
        print_warning "Environment file (.env) not found!"
        print_color $YELLOW "Run './scripts/setup.sh' first to create the environment configuration."
        exit 1
    fi
}

# Check if services are already running
check_running_services() {
    if docker-compose ps | grep -q "Up"; then
        print_warning "Some n8n services are already running."
        echo ""
        print_color $YELLOW "Current status:"
        docker-compose ps
        echo ""
        read -p "Do you want to restart the services? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "Stopping existing services..."
            docker-compose down
        else
            print_color $BLUE "Services are already running. Access n8n at: http://localhost:5678"
            exit 0
        fi
    fi
}

# Parse command line arguments
PROFILE=""
DEV_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --https)
        PROFILE="--profile https"
        shift
        ;;
    --dev)
        DEV_MODE=true
        shift
        ;;
    --help | -h)
        echo "n8n Start Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --https    Start with HTTPS support (Caddy reverse proxy)"
        echo "  --dev      Start in development mode with debug logging"
        echo "  --help     Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                 # Start n8n normally"
        echo "  $0 --https         # Start with HTTPS"
        echo "  $0 --dev           # Start in development mode"
        echo "  $0 --https --dev   # Start with HTTPS and development mode"
        exit 0
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information."
        exit 1
        ;;
    esac
done

# Main execution
main() {
    print_header "Starting n8n Local Deployment"

    # Pre-flight checks
    check_docker
    check_environment
    check_running_services

    # Determine compose command
    COMPOSE_CMD="docker-compose"

    if [ "$DEV_MODE" = true ]; then
        COMPOSE_CMD="$COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml"
        print_step "Development mode enabled"
    fi

    if [ -n "$PROFILE" ]; then
        COMPOSE_CMD="$COMPOSE_CMD $PROFILE"
        print_step "HTTPS profile enabled"
    fi

    # Pull latest images
    print_step "Pulling latest Docker images..."
    eval "$COMPOSE_CMD pull"

    # Start services
    print_step "Starting services..."
    eval "$COMPOSE_CMD up -d"

    # Wait for services to be ready
    print_step "Waiting for services to start..."
    sleep 15

    # Check service health
    print_step "Checking service status..."
    if docker-compose ps | grep -q "Up"; then
        print_step "Services started successfully!"
    else
        print_warning "Some services might still be starting up."
    fi

    # Show status and access information
    echo ""
    print_header "Service Status"
    docker-compose ps

    echo ""
    print_header "Access Information"
    echo ""
    print_color $GREEN "🎉 n8n is starting up!"
    echo ""

    if [ -n "$PROFILE" ]; then
        print_color $BLUE "Access URLs (HTTPS):"
        print_color $BLUE "  • n8n Editor: https://localhost"
        print_color $BLUE "  • n8n API: https://localhost/api"
    else
        print_color $BLUE "Access URLs:"
        print_color $BLUE "  • n8n Editor: http://localhost:5678"
        print_color $BLUE "  • n8n API: http://localhost:5678/api"
    fi

    if [ "$DEV_MODE" = true ]; then
        print_color $BLUE "  • Debug port: 9229 (for development)"
    fi

    print_color $BLUE "  • PostgreSQL: localhost:5432"
    print_color $BLUE "  • Redis: localhost:6379"
    echo ""
    print_color $YELLOW "Useful commands:"
    print_color $YELLOW "  • View logs: docker-compose logs -f n8n"
    print_color $YELLOW "  • Stop services: ./scripts/stop_n8n.sh"
    print_color $YELLOW "  • Health check: ./scripts/health-check.sh"
    print_color $YELLOW "  • Backup data: ./scripts/backup.sh"
    echo ""
    print_color $GREEN "Happy automating! 🚀"
}

# Run main function
main "$@"
