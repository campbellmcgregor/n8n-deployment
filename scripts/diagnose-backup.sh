#!/bin/bash

echo "=== n8n Backup Diagnostics ==="
echo

echo "1. Checking container status..."
docker compose ps

echo
echo "2. Checking volume mounts for n8n container..."
docker compose exec n8n ls -la /

echo
echo "3. Checking /tmp directory accessibility (used for backup creation)..."
docker compose exec n8n ls -la /tmp && echo "✓ /tmp directory accessible" || echo "❌ /tmp directory not accessible"

echo
echo "4. Testing n8n export command syntax..."
docker compose exec n8n n8n export:workflow --help || echo "❌ n8n export command failed"

echo
echo "5. Testing backup creation in /tmp..."
TEST_DATE=$(date +%Y%m%d_%H%M%S)
if docker compose exec -T n8n n8n export:workflow --backup --output="/tmp/test-backup-$TEST_DATE/" >/dev/null 2>&1; then
    echo "✓ Can create backup in /tmp"
    docker compose exec n8n rm -rf "/tmp/test-backup-$TEST_DATE" 2>/dev/null || true
else
    echo "❌ Cannot create backup in /tmp"
fi

echo
echo "6. Testing docker cp functionality..."
docker compose exec n8n touch /tmp/test-file
if docker cp n8n-main:/tmp/test-file ./test-file 2>/dev/null; then
    echo "✓ docker cp works (can extract files from container)"
    rm -f ./test-file
    docker compose exec n8n rm -f /tmp/test-file
else
    echo "❌ docker cp failed"
fi

echo
echo "7. Checking available disk space in container..."
docker compose exec n8n df -h

echo
echo "8. Checking n8n container environment..."
docker compose exec n8n env | grep -E "(N8N_|NODE_|PATH)"

echo
echo "9. Checking host backups directory..."
ls -la ./backups/ 2>/dev/null || echo "ℹ️  Backups directory will be created automatically"

echo
echo "=== Diagnostics Complete ==="