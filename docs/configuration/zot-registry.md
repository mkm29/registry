# Zot Registry Configuration

Zot is configured via `zot/config/zot-config.yaml`. For detailed configuration options, see the [Zot documentation](https://zotregistry.dev).

## Key Configuration Settings

Our configuration (`zot/config/zot-config.yaml`) includes:

### Storage Configuration

```yaml
storage:
  rootDirectory: /var/lib/zot
  gc: true                               # Enable garbage collection
```

### HTTP Configuration

```yaml
http:
  address: 0.0.0.0
  port: '5000'                           # Main API port
  externalUrl: https://registry.smigula.io  # External URL for reverse proxy
  # Authentication is now handled externally by Authentik through Traefik
  # No local authentication is configured
log:
  level: info
```

### Multi-Registry Sync Configuration

```yaml
extensions:
  sync:
    enable: true
    credentialsFile: /etc/zot/credentials.yaml
    registries:
      - urls: ['https://registry-1.docker.io']
        onDemand: true                   # Pull images only when requested
        content:
          - prefix: '**'
            destination: /docker         # Access via localhost:5000/docker/<image>
      - urls: ['https://ghcr.io']
        onDemand: true
        content:
          - prefix: '**'
            destination: /ghcr           # Access via localhost:5000/ghcr/<image>
      - urls: ['https://gcr.io']
        onDemand: true
        content:
          - prefix: '**'
            destination: /gcr            # Access via localhost:5000/gcr/<image>
      # Additional registries: quay.io, registry.k8s.io
```

### Extensions

```yaml
extensions:
  search:
    enable: true                         # Enable search functionality
  ui:
    enable: true                         # Enable web UI
  metrics:
    enable: true                         # Prometheus metrics
    prometheus:
      path: /metrics
  scrub:
    enable: true                         # Enable image vulnerability scanning
    interval: "24h"
```

## Configuration Files

- **Main Config**: [`zot/config/config.yaml`](../../zot/config/config.yaml)
- **Credentials**: [`zot/config/credentials.yaml`](../../zot/config/credentials.yaml) (git ignored)
- **Docker Compose**: [`zot/docker-compose.yaml`](../../zot/docker-compose.yaml)