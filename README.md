# n8n Local Deployment

A comprehensive Docker-based local deployment setup for n8n workflow automation platform with advanced features, monitoring, and production-ready configurations.

## Features

- **Production-Ready**: Full PostgreSQL + Redis + n8n stack
- **HTTPS Support**: Optional Caddy reverse proxy with automatic TLS
- **Queue Management**: Redis-powered background job processing
- **Monitoring**: Health checks and comprehensive logging
- **Backup System**: Automated backup and restore functionality
- **Security**: Secure key generation and environment management
- **External Hooks**: Custom workflow and credential event handling
- **Worker Processes**: Dedicated worker and webhook processes

## Quick Start

1. **Clone and Setup**:

   ```bash
   git clone <repository-url>
   cd local-n8n
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

2. **Access n8n**: Open <http://localhost:5678> in your browser

3. **Optional HTTPS**: Enable with `docker-compose --profile https up -d`

## Architecture

- **n8n Main**: Workflow editor and API (port 5678)
- **n8n Worker**: Background task processing
- **n8n Webhook**: High-throughput webhook handling (port 5679)
- **PostgreSQL**: Persistent data storage (port 5432)
- **Redis**: Queue and cache management (port 6379)
- **Caddy**: Optional HTTPS termination (ports 80/443)

# Local n8n Deployment

A robust, production-ready local deployment of n8n using Docker Compose. This setup includes PostgreSQL database, Redis queue management, and optional HTTPS support via Caddy reverse proxy.

![n8n Workflow Editor](https://docs.n8n.io/_images/n8n-docs-icon.svg)

## 🚀 Features

- **Self-hosted n8n** - Full-featured workflow automation platform
- **PostgreSQL Database** - Reliable data persistence
- **Redis Queue Management** - Scalable workflow execution
- **Worker Process** - Dedicated background job processing
- **Webhook Process** - High-performance webhook handling
- **HTTPS Support** - Optional SSL termination with Caddy
- **Custom Nodes** - Support for custom node development
- **External Hooks** - Extensible backend hooks
- **Backup Management** - Automated backup solutions
- **Monitoring Ready** - Built-in health checks and logging

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM available
- 10GB free disk space (recommended)

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url> local-n8n
cd local-n8n
```

### 2. Configure Environment

```bash
# Copy the environment template
cp env.template .env

# Edit the environment variables
nano .env
```

**Important**: Update these critical environment variables in your `.env` file:

- `N8N_ENCRYPTION_KEY` - Generate a secure 32+ character key
- `N8N_JWT_SECRET` - Generate a secure 32+ character secret
- `POSTGRES_PASSWORD` - Set a strong database password

### 3. Generate Secure Keys

```bash
# Generate encryption key
openssl rand -hex 32

# Generate JWT secret
openssl rand -hex 32
```

### 4. Start the Services

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f n8n
```

### 5. Access n8n

Open your browser and navigate to: <http://localhost:5678>

## 📁 Directory Structure

```
local-n8n/
├── README.md                 # This file
├── docker-compose.yml        # Main Docker Compose configuration
├── env.template             # Environment variables template
├── .env                     # Your environment variables (create from template)
├── backups/                 # n8n backups storage
├── custom-nodes/           # Custom node development
├── external-hooks/         # Backend hooks and extensions
├── init-scripts/           # Database initialization scripts
├── logs/                   # Application logs
├── scripts/                # Utility scripts
├── shared/                 # Shared files between host and containers
└── caddy/                  # Caddy configuration (for HTTPS)
    ├── Caddyfile
    ├── data/
    └── config/
```

## 🔧 Configuration

### Environment Variables

Key environment variables you should configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_ENCRYPTION_KEY` | Encryption key for credentials | **Required** |
| `N8N_JWT_SECRET` | JWT secret for user sessions | **Required** |
| `POSTGRES_PASSWORD` | Database password | **Required** |
| `N8N_HOST` | n8n host | `localhost` |
| `N8N_PORT` | n8n port | `5678` |
| `WEBHOOK_URL` | Webhook base URL | `http://localhost:5678/` |
| `TIMEZONE` | System timezone | `UTC` |

### Custom Nodes

Place your custom nodes in the `custom-nodes/` directory:

```bash
# Install a custom node
cd custom-nodes/
npm install n8n-nodes-your-custom-node
```

### External Hooks

Create backend hooks in `external-hooks/external-hooks.js`:

```javascript
module.exports = {
  workflow: {
    activate: [
      async function(workflowData) {
        console.log('Workflow activated:', workflowData.name);
      }
    ]
  }
};
```

## 🚦 Service Management

### Basic Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart n8n

# View logs
docker-compose logs -f [service-name]

# Scale workers
docker-compose up -d --scale n8n-worker=3
```

### Health Checks

```bash
# Check service health
docker-compose ps

# PostgreSQL health
docker-compose exec postgres pg_isready -U n8n

# Redis health
docker-compose exec redis redis-cli ping

# n8n health
curl http://localhost:5678/healthz
```

## 🔐 HTTPS Setup

To enable HTTPS with automatic SSL certificates:

### 1. Configure Caddy

Create `caddy/Caddyfile`:

```caddyfile
your-domain.com {
    reverse_proxy n8n:5678
    
    # Optional: Basic auth
    # basicauth {
    #     admin $2a$14$...your-bcrypt-hash
    # }
}
```

### 2. Update Environment

```bash
# Update your .env file
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-domain.com/
```

### 3. Start with HTTPS Profile

```bash
docker-compose --profile https up -d
```

## 📊 Monitoring and Logging

### Log Locations

- **n8n logs**: `./logs/`
- **Container logs**: `docker-compose logs [service]`
- **PostgreSQL logs**: Within container at `/var/lib/postgresql/data/log/`

### Log Levels

Set log level in `.env`:

```bash
N8N_LOG_LEVEL=debug  # error, warn, info, debug
```

### Metrics (Optional)

Enable metrics collection:

```bash
N8N_METRICS=true
N8N_METRICS_PREFIX=n8n_
```

## 💾 Backup and Restore

### Manual Backup

```bash
# Backup workflows and credentials
docker-compose exec n8n n8n export:workflow --backup --output=/home/node/.n8n/backups/

# Backup database
docker-compose exec postgres pg_dump -U n8n n8n > ./backups/postgres-backup-$(date +%Y%m%d).sql
```

### Automated Backup Script

Create `scripts/backup.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)

# Backup n8n data
docker-compose exec n8n n8n export:workflow --backup --output=/home/node/.n8n/backups/n8n-backup-$DATE.tar.gz

# Backup database
docker-compose exec postgres pg_dump -U n8n n8n > ./backups/postgres-backup-$DATE.sql

echo "Backup completed: $DATE"
```

## 🔧 Troubleshooting

### Common Issues

#### Service Won't Start

```bash
# Check service logs
docker-compose logs [service-name]

# Verify environment variables
docker-compose config
```

#### Database Connection Issues

```bash
# Test database connection
docker-compose exec postgres pg_isready -U n8n -d n8n

# Reset database (⚠️ DESTRUCTIVE)
docker-compose down -v
docker-compose up -d
```

#### Permission Issues

```bash
# Fix ownership issues
sudo chown -R $USER:$USER ./logs ./backups ./custom-nodes
```

#### Memory Issues

```bash
# Check container memory usage
docker stats

# Increase memory limits in docker-compose.yml
```

### Debug Mode

Enable debug logging:

```bash
# In .env file
N8N_LOG_LEVEL=debug

# Restart services
docker-compose restart n8n
```

## 🔄 Updates

### Update n8n

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Update PostgreSQL

```bash
# Backup first!
docker-compose exec postgres pg_dump -U n8n n8n > ./backups/pre-update-backup.sql

# Update image version in docker-compose.yml
# Then restart
docker-compose up -d postgres
```

## 🧪 Development

### Custom Node Development

1. Create your node in `custom-nodes/`
2. Install dependencies
3. Restart n8n to load new nodes

```bash
cd custom-nodes/
npm init -y
npm install n8n
# Develop your custom node
docker-compose restart n8n
```

### External Hook Development

1. Edit `external-hooks/external-hooks.js`
2. Restart n8n to apply changes

## 📚 Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Security Notes

- Always use strong passwords and secrets
- Keep your n8n instance updated
- Use HTTPS in production
- Regularly backup your data
- Monitor access logs
- Consider using VPN for remote access

## 🆘 Support

- [GitHub Issues](https://github.com/your-repo/issues)
- [n8n Community Forum](https://community.n8n.io/)
- [Discord Server](https://discord.gg/n8n)
