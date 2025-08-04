#!/bin/bash

# n8n Health Check Script
# This script checks the health of all n8n services

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    echo ""
    print_color $BLUE "================================"
    print_color $BLUE "$1"
    print_color $BLUE "================================"
}

check_service() {
    local service=$1
    local url=$2
    local expected_status=${3:-200}

    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        print_color $GREEN "✓ $service is healthy"
        return 0
    else
        print_color $RED "✗ $service is not responding"
        return 1
    fi
}

check_docker_service() {
    local service=$1
    local container_name=$2

    if docker compose ps "$service" | grep -q "Up.*healthy\|Up.*running"; then
        print_color $GREEN "✓ $service container is running"
        return 0
    else
        print_color $RED "✗ $service container is not healthy"
        return 1
    fi
}

print_header "n8n Deployment Health Check"

# Check if Docker Compose is running
if ! docker compose ps >/dev/null 2>&1; then
    print_color $RED "✗ Docker Compose services not found. Are they running?"
    exit 1
fi

print_color $BLUE "Checking Docker containers..."

# Check individual services
services_ok=true

# PostgreSQL
if check_docker_service "postgres" "n8n-postgres"; then
    # Test database connection
    if docker compose exec -T postgres pg_isready -U n8n -d n8n >/dev/null 2>&1; then
        print_color $GREEN "  └─ Database connection OK"
    else
        print_color $RED "  └─ Database connection failed"
        services_ok=false
    fi
else
    services_ok=false
fi

# Redis
if check_docker_service "redis" "n8n-redis"; then
    # Test Redis connection
    if docker compose exec -T redis redis-cli ping | grep -q "PONG"; then
        print_color $GREEN "  └─ Redis connection OK"
    else
        print_color $RED "  └─ Redis connection failed"
        services_ok=false
    fi
else
    services_ok=false
fi

# n8n main service
if check_docker_service "n8n" "n8n-main"; then
    # Test n8n web interface
    sleep 2 # Give n8n a moment to respond
    if check_service "n8n Web Interface" "http://localhost:5678/healthz" 200; then
        print_color $GREEN "  └─ n8n web interface OK"
    else
        print_color $YELLOW "  └─ n8n web interface not responding (might still be starting)"
    fi
else
    services_ok=false
fi

# n8n worker (optional)
if docker compose ps | grep -q "n8n-worker"; then
    check_docker_service "n8n-worker" "n8n-worker"
fi

# n8n webhook (optional)
if docker compose ps | grep -q "n8n-webhook"; then
    if check_docker_service "n8n-webhook" "n8n-webhook"; then
        if check_service "n8n Webhook Service" "http://localhost:5679/healthz" 200; then
            print_color $GREEN "  └─ n8n webhook service OK"
        else
            print_color $YELLOW "  └─ n8n webhook service not responding"
        fi
    fi
fi

print_header "Service URLs"
print_color $BLUE "• n8n Editor: http://localhost:5678"
print_color $BLUE "• n8n API: http://localhost:5678/api"

if docker compose ps | grep -q "n8n-webhook"; then
    print_color $BLUE "• n8n Webhooks: http://localhost:5679"
fi

if docker compose ps | grep -q "caddy"; then
    print_color $BLUE "• HTTPS (Caddy): https://localhost"
fi

print_header "Resource Usage"

# Show resource usage
echo "Container resource usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "n8n|postgres|redis" || echo "No containers found"

print_header "Recent Logs"
echo "Last 10 log entries from n8n:"
docker compose logs --tail=10 n8n | tail -10

if $services_ok; then
    print_color $GREEN "\n🎉 All core services are healthy!"
    exit 0
else
    print_color $RED "\n⚠️  Some services have issues. Check the output above."
    print_color $YELLOW "Try running: docker compose logs [service-name] for more details"
    exit 1
fi
