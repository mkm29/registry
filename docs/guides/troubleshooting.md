# Troubleshooting

## Common Issues

- **Registry connection**: Test with `curl -sk https://127.0.0.1:5000/v2/`
- **Docker images**: Use registry prefixes (e.g., `localhost:5000/docker/nginx`)
- **Metrics**: Check Alloy status at `http://localhost:12345`
- **Logs**: View with `task logs SERVICE=<name>` or `podman logs <container>`
- **Permissions**: Restart services with `podman restart <container>`

For detailed troubleshooting, check the individual service logs and documentation.

## Detailed Troubleshooting

### Registry Connection Issues

```bash
# Check if Zot is responding
curl -sk https://127.0.0.1:5000/v2/

# Test Zot Web UI
curl -sk https://127.0.0.1:5000/home

# View detailed logs
task logs SERVICE=zot
# or: podman logs zot-registry

# Check specific registry sync
podman logs zot-registry 2>&1 | grep -i "docker\|ghcr\|gcr"

# Test image pull with specific prefix
docker pull localhost:5000/docker/alpine:latest
```

### Authentication Issues

```bash
# Test authentication through external URL (handled by Traefik/Authentik)
curl https://registry.smigula.io/v2/

# For local access (no authentication required)
curl -sk https://127.0.0.1:5000/v2/

# Verify Zot configuration
podman exec zot-registry cat /etc/zot/config.json
```

### Metrics Not Appearing

```bash
# Check Mimir health
curl http://localhost:9009/ready

# Check Alloy is pushing metrics to Mimir
task logs SERVICE=alloy
# or: podman logs alloy 2>&1 | grep -i "remote_write\|mimir"

# Registry metrics should be accessible
curl -sk https://127.0.0.1:5000/metrics

# Check Mimir logs
task logs SERVICE=mimir
# or: podman logs mimir

# Check MinIO connectivity (Mimir storage backend)
curl http://localhost:9000/minio/health/live
```

### TLS / Certificate Trust Issues

Zot now runs with TLS using cfssl-generated certificates. If you see certificate errors when pulling images or hitting the API, install the local CA:

```bash
# Install the CA cert so containers and clients trust the registry
task trust-ca

# This copies ca.pem to ~/.config/containers/certs.d/ so that
# Podman and Docker trust the self-signed registry certificate.

# Verify TLS is working
curl -sk https://127.0.0.1:5000/v2/
```
