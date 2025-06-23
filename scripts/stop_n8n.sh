#!/bin/bash

# n8n Stop Script
# Convenient script to stop the n8n local deployment

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
        print_error "Docker daemon is not running."
        exit 1
    fi
}

# Check if services are running
check_running_services() {
    if ! docker-compose ps | grep -q "Up"; then
        print_warning "No n8n services appear to be running."
        echo ""
        print_color $YELLOW "Current status:"
        docker-compose ps
        echo ""
        if docker-compose ps | grep -q "Exit"; then
            print_color $YELLOW "Found stopped containers. Would you like to remove them?"
            read -p "Remove stopped containers? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_step "Removing stopped containers..."
                docker-compose down
                print_step "Cleanup completed!"
            fi
        else
            print_color $BLUE "Nothing to stop."
        fi
        exit 0
    fi
}

# Parse command line arguments
REMOVE_VOLUMES=false
REMOVE_IMAGES=false
FORCE_STOP=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --volumes | -v)
        REMOVE_VOLUMES=true
        shift
        ;;
    --images | -i)
        REMOVE_IMAGES=true
        shift
        ;;
    --force | -f)
        FORCE_STOP=true
        shift
        ;;
    --clean | -c)
        REMOVE_VOLUMES=true
        REMOVE_IMAGES=true
        shift
        ;;
    --help | -h)
        echo "n8n Stop Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --volumes, -v    Remove volumes (WARNING: This deletes all data!)"
        echo "  --images, -i     Remove downloaded Docker images"
        echo "  --force, -f      Force stop without confirmation"
        echo "  --clean, -c      Complete cleanup (volumes + images)"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0              # Stop services normally"
        echo "  $0 --force      # Stop without confirmation"
        echo "  $0 --volumes    # Stop and remove volumes (deletes data!)"
        echo "  $0 --clean      # Complete cleanup"
        echo ""
        echo "WARNING: Using --volumes or --clean will permanently delete all n8n data!"
        exit 0
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information."
        exit 1
        ;;
    esac
done

# Confirm destructive operations
confirm_destructive_action() {
    if [ "$REMOVE_VOLUMES" = true ] && [ "$FORCE_STOP" = false ]; then
        echo ""
        print_color $RED "⚠️  WARNING: This will permanently delete all n8n data!"
        print_color $YELLOW "This includes:"
        print_color $YELLOW "  • All workflows and credentials"
        print_color $YELLOW "  • Database content"
        print_color $YELLOW "  • Redis cache"
        print_color $YELLOW "  • Custom configurations"
        echo ""
        read -p "Are you absolutely sure you want to continue? Type 'yes' to confirm: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
            print_step "Operation cancelled."
            exit 0
        fi
    fi
}

# Main execution
main() {
    print_header "Stopping n8n Local Deployment"

    # Pre-flight checks
    check_docker
    check_running_services

    # Show current status
    echo ""
    print_color $YELLOW "Current service status:"
    docker-compose ps
    echo ""

    # Confirm destructive actions
    confirm_destructive_action

    # Ask for confirmation unless force flag is used
    if [ "$FORCE_STOP" = false ]; then
        read -p "Stop all n8n services? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_step "Operation cancelled."
            exit 0
        fi
    fi

    # Stop services
    print_step "Stopping n8n services..."
    if [ "$REMOVE_VOLUMES" = true ]; then
        docker-compose down -v
        print_step "Services stopped and volumes removed!"
        print_color $RED "All n8n data has been permanently deleted."
    else
        docker-compose down
        print_step "Services stopped!"
    fi

    # Remove images if requested
    if [ "$REMOVE_IMAGES" = true ]; then
        print_step "Removing Docker images..."

        # Get image IDs for n8n-related images
        IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(n8nio/n8n|postgres|redis|caddy)" | head -10)

        if [ -n "$IMAGES" ]; then
            echo "$IMAGES" | while read image; do
                if docker rmi "$image" >/dev/null 2>&1; then
                    print_step "Removed image: $image"
                else
                    print_warning "Could not remove image: $image (may be in use)"
                fi
            done
        else
            print_warning "No n8n-related images found to remove."
        fi
    fi

    # Show final status
    echo ""
    print_header "Final Status"

    if docker-compose ps | grep -q "Up"; then
        print_warning "Some services are still running:"
        docker-compose ps
    else
        print_step "All n8n services have been stopped."
    fi

    echo ""
    print_color $GREEN "🛑 n8n deployment stopped!"
    echo ""
    print_color $BLUE "To start n8n again:"
    print_color $BLUE "  ./scripts/start_n8n.sh"
    echo ""

    if [ "$REMOVE_VOLUMES" = true ]; then
        print_color $YELLOW "Since volumes were removed, you'll need to reconfigure n8n on next start."
    else
        print_color $YELLOW "Your data is preserved and will be available when you restart."
    fi

    echo ""
    print_color $BLUE "Other useful commands:"
    print_color $BLUE "  • Health check: ./scripts/health-check.sh"
    print_color $BLUE "  • View logs: docker-compose logs"
    print_color $BLUE "  • Complete setup: ./scripts/setup.sh"
}

# Run main function
main "$@"
