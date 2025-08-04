#!/bin/bash

echo "=== n8n Backup Diagnostics ==="
echo

echo "1. Checking container status..."
docker compose ps

echo
echo "2. Checking volume mounts for n8n container..."
docker compose exec n8n ls -la /

echo
echo "3. Checking if backups directory exists in container..."
docker compose exec n8n ls -la /backups || echo "❌ /backups directory not found in container"

echo
echo "4. Checking current working directory in container..."
docker compose exec n8n pwd

echo
echo "5. Testing n8n export command syntax..."
docker compose exec n8n n8n export:workflow --help || echo "❌ n8n export command failed"

echo
echo "6. Checking available disk space in container..."
docker compose exec n8n df -h

echo
echo "7. Checking n8n container environment..."
docker compose exec n8n env | grep -E "(N8N_|NODE_|PATH)"

echo
echo "8. Testing simple file creation in container..."
docker compose exec n8n touch /tmp/test-file && echo "✓ Can create files in /tmp" || echo "❌ Cannot create files"

echo
echo "9. Checking host backups directory permissions..."
ls -la ./backups/

echo
echo "=== Diagnostics Complete ==="