# Troubleshooting

## Common Issues

- **Registry connection**: Test with `curl http://localhost:5000/v2/`
- **Docker images**: Use registry prefixes (e.g., `localhost:5000/docker/nginx`)
- **Metrics**: Check Alloy status at `http://localhost:12345`
- **Logs**: View with `docker-compose logs -f [service-name]`
- **Permissions**: Restart services with `docker-compose restart`

For detailed troubleshooting, check the individual service logs and documentation.

## Detailed Troubleshooting

### Registry Connection Issues

```bash
# Check if Zot is responding
curl http://localhost:5000/v2/

# Test Zot Web UI
curl http://localhost:5000/home

# View detailed logs
docker logs registry

# Check specific registry sync
docker logs registry 2>&1 | grep -i "docker\|ghcr\|gcr"

# Test image pull with specific prefix
docker pull localhost:5000/docker/alpine:latest
```

### Authentication Issues

```bash
# Test authentication through external URL (handled by Traefik/Authentik)
curl https://registry.yourdomain.com/v2/

# For local access (no authentication required)
curl http://localhost:5000/v2/

# Verify Zot configuration
docker exec registry cat /etc/zot/config.yaml
```

### Metrics Not Appearing

```bash
# Check Mimir health
curl http://localhost:9009/ready

# Check Alloy is pushing metrics to Mimir
docker-compose logs -f alloy | grep -i "remote_write\|mimir"

# Registry metrics should be accessible
curl http://localhost:5000/metrics

# Check Mimir logs
docker-compose logs -f mimir

# Check MinIO connectivity (Mimir storage backend)
curl http://localhost:9000/minio/health/live
```

### Docker Configuration Issues

Remember to configure Docker for insecure registries when using HTTP:

```bash
# For rootless Docker
nano ~/.config/docker/daemon.json

# For regular Docker
sudo nano /etc/docker/daemon.json

# Add insecure registry configuration:
{
  "insecure-registries": ["localhost:5000"]
}
```
