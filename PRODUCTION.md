# Production Deployment Guide

This guide covers deploying n8n in production environments with security, performance, and reliability considerations.

## Pre-Production Checklist

### Security

- [ ] Generate strong encryption keys (32+ characters)
- [ ] Use secure database passwords
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Configure firewall rules
- [ ] Set up user authentication
- [ ] Review and customize external hooks

### Performance

- [ ] Configure Redis for production workloads
- [ ] Optimize PostgreSQL settings
- [ ] Set up dedicated worker processes
- [ ] Configure proper resource limits
- [ ] Enable monitoring and logging

### Reliability

- [ ] Set up automated backups
- [ ] Configure health checks
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
docker-compose --profile https up -d

# Or use custom SSL certificates
# Update caddy/Caddyfile with your domain and certificates
```

### Monitoring

- Enable n8n metrics endpoint
- Set up PostgreSQL monitoring
- Monitor Redis performance
- Configure log aggregation
- Set up uptime monitoring

### Backup Strategy

```bash
# Automated daily backups
crontab -e
# Add: 0 2 * * * /path/to/local-n8n/scripts/backup.sh
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
- Regular security updates
- Audit workflow permissions
- Monitor and log access attempts

## Maintenance

### Regular Tasks

- [ ] Update Docker images monthly
- [ ] Review and rotate secrets quarterly
- [ ] Check backup integrity weekly
- [ ] Monitor performance metrics daily
- [ ] Review logs for anomalies

### Update Procedure

1. Test updates in staging environment
2. Schedule maintenance window
3. Create full backup
4. Update Docker images
5. Verify functionality
6. Monitor performance post-update

## Troubleshooting

### Common Issues

- **Service startup failures**: Check logs with `docker-compose logs`
- **Database connection issues**: Verify credentials and network
- **Performance problems**: Monitor resource usage and optimize
- **SSL certificate issues**: Check Caddy configuration and DNS

### Diagnostic Commands

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f n8n

# Health check
./scripts/health-check.sh

# Database backup
./scripts/backup.sh
```

## Support Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [Redis Configuration](https://redis.io/topics/config)
