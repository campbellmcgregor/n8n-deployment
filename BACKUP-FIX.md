# Backup Issues Fix for Remote Machine

## Issue Summary
The backup process is failing due to:
1. Permission errors on the backups directory
2. Incorrect backup script file path logic  
3. Deprecated environment variables

## Complete Fix Instructions (Run on Remote Machine)

### 1. Fix Directory Permissions
```bash
# Ensure backups directory exists and has correct permissions
mkdir -p ./backups
sudo chown 1000:1000 ./backups
chmod 755 ./backups

# Verify the directory permissions
ls -la ./backups
# Should show: drwxr-xr-x 2 1000 1000 4096 ... backups
```

### 2. Update Environment Variables
Add these lines to your `.env` file:
```bash
# Add to .env file
N8N_RUNNERS_ENABLED=true
OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
```

### 3. Fix Backup Script
Edit `scripts/backup.sh` line 18, change from:
```bash
docker compose exec -T n8n n8n export:workflow --backup --output="/home/node/.n8n/backups/n8n-backup-$DATE.tar.gz"
```
To:
```bash
docker compose exec -T n8n n8n export:workflow --backup --output="backups/n8n-backup-$DATE.tar.gz"
```

### 4. Restart and Test
```bash
# Restart services to apply environment changes
docker compose down
docker compose up -d

# Wait for services to be healthy
just health

# Test the backup with validation
just backup-test
```

## Validation Steps

After running the fixes, you should see:

1. **No permission errors** when creating backups
2. **No deprecation warnings** in the output  
3. **Backup files created** in `./backups/` directory
4. **File sizes** showing actual content (not 0 bytes)

### Example of Successful Output:
```
💾 Creating backup...
Starting backup process...
Backing up n8n workflows and credentials...
Backing up PostgreSQL database...

🔍 Validating backups...
✓ n8n backup created: 2.1M
✓ Database backup created: 15K

✅ Backup completed successfully!
  - n8n data: ./backups/n8n-backup-20250804_141257.tar.gz (2.1M)
  - Database: ./backups/postgres-backup-20250804_141257.sql.gz (15K)
```

### Troubleshooting
If you still see errors:
- Check `docker compose logs n8n` for detailed error messages
- Verify the backups directory ownership: `ls -la ./backups`
- Ensure services are healthy: `just health`

## Root Causes Explained
- **Permission Error**: Container runs as UID 1000 but mounted directory had wrong ownership
- **Path Error**: Script was using absolute path which n8n interpreted as a directory name
- **Deprecation Warnings**: Missing recommended environment variables for task runners