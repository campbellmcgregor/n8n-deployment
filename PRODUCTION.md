# Production Deployment Guide

This guide covers deploying n8n in production environments with security, performance, and reliability considerations.

## Pre-Production Checklist

### Security

- [ ] Generate strong encryption keys (32+ characters) - `just gen-key`
- [ ] Use secure database passwords - `just gen-jwt`
- [ ] Enable HTTPS with valid SSL certificates - `just start-https`
- [ ] Configure firewall rules
- [ ] Set up user authentication
- [ ] Review and customize external hooks

### Performance

- [ ] Configure Redis for production workloads
- [ ] Optimize PostgreSQL settings
- [ ] Set up dedicated worker processes
- [ ] Configure proper resource limits
- [ ] Enable monitoring and logging - `just health`

### Reliability

- [ ] Set up automated backups - `just backup`
- [ ] Configure health checks - `just health`
- [ ] Set up monitoring and alerting
- [ ] Plan disaster recovery procedures
- [ ] Test failover scenarios

## Production Configuration

### Environment Variables

```bash
# Production environment settings
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
N8N_LOG_LEVEL=warn
N8N_DIAGNOSTICS_ENABLED=false
N8N_METRICS=true

# Security
N8N_USER_MANAGEMENT_DISABLED=false
N8N_SECURE_COOKIE=true

# Performance
QUEUE_HEALTH_CHECK_ACTIVE=true
```

### HTTPS Deployment

```bash
# Enable HTTPS with Caddy
just start-https

# Or use custom SSL certificates
# Update caddy/Caddyfile with your domain and certificates
```

### Monitoring

- Enable n8n metrics endpoint
- Set up PostgreSQL monitoring - `just db-info`
- Monitor Redis performance - `just redis-info`
- Configure log aggregation - `just logs-follow`
- Set up uptime monitoring - `just health`

### Backup Strategy

```bash
# Automated daily backups
crontab -e
# Add: 0 2 * * * cd /path/to/n8n-self-hosted && just backup
```

## Scaling Considerations

### Horizontal Scaling

- Deploy multiple n8n worker instances
- Use load balancer for webhook endpoints
- Scale PostgreSQL with read replicas
- Configure Redis clustering

### Resource Requirements

- **Minimum**: 2 CPU cores, 4GB RAM
- **Recommended**: 4 CPU cores, 8GB RAM
- **Storage**: SSD with backup strategy
- **Network**: Stable connection with monitoring

## Security Hardening

### Network Security

- Use private networks for inter-service communication
- Configure firewall rules (only expose necessary ports)
- Enable fail2ban for SSH protection
- Use VPN for administrative access

### Application Security

- Enable user management and authentication
- Configure RBAC (Role-Based Access Control)
- Regular security updates - `just update`
- Audit workflow permissions
- Monitor and log access attempts - `just logs-follow`

## Maintenance

### Regular Tasks

- [ ] Update Docker images monthly - `just update`
- [ ] Review and rotate secrets quarterly
- [ ] Check backup integrity weekly - `just backup-list`
- [ ] Monitor performance metrics daily - `just stats`
- [ ] Review logs for anomalies - `just logs-follow`

### Update Procedure

1. Test updates in staging environment
2. Schedule maintenance window
3. Create full backup - `just backup`
4. Update Docker images - `just pull`
5. Verify functionality - `just health`
6. Monitor performance post-update - `just stats`

## Troubleshooting

### Common Issues

- **Service startup failures**: Check logs with `just logs-n8n`
- **Database connection issues**: Verify credentials with `just db-info`
- **Performance problems**: Monitor with `just stats`
- **SSL certificate issues**: Check with `just logs-follow`

### Diagnostic Commands

```bash
# Check service status
just status

# View logs
just logs-n8n

# Health check
just health

# Database backup
just backup

# Show all service URLs
just urls

# Check resource usage
just stats

# Database connection test
just db-connect

# Redis connection test
just redis-cli
```

## Support Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [Redis Configuration](https://redis.io/topics/config)
