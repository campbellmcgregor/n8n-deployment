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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_step "Docker is installed"

    if ! command_exists docker-compose; then
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

# Main execution
main() {
    print_header "n8n Local Deployment Setup"

    check_prerequisites
    create_directories

    print_color $GREEN "Basic setup completed! 🚀"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
