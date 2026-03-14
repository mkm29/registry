# Zot Registry Configuration

Zot v2.1.15 is configured via `config/zot/config.json`. For detailed configuration options, see the [Zot documentation](https://zotregistry.dev).

## Key Configuration Settings

Our configuration (`config/zot/config.json`) includes:

### Storage Configuration

Registry blobs are stored at `~/.config/containers/storage` (local SSD), mounted into the container:

```json
{
  "storage": {
    "rootDirectory": "/var/lib/zot",
    "gc": true
  }
}
```

### HTTP Configuration

Zot binds to `127.0.0.1:5000` (loopback only) and uses TLS with cfssl-generated certificates mounted from `services/certs/`:

```json
{
  "http": {
    "address": "127.0.0.1",
    "port": "5000",
    "externalUrl": "https://registry.smigula.io",
    "tls": {
      "cert": "/certs/server.pem",
      "key": "/certs/server-key.pem",
      "cacert": "/certs/ca.pem"
    }
  },
  "log": {
    "level": "info"
  }
}
```

### Multi-Registry Sync Configuration

Upstream registry credentials are sourced from `secrets/all.env.dec` (aggregated env). Images are pulled through the local registry cache using paths like `registry.smigula.io/docker/...`, `registry.smigula.io/ghcr/...`:

```json
{
  "extensions": {
    "sync": {
      "enable": true,
      "registries": [
        {
          "urls": ["https://registry-1.docker.io"],
          "onDemand": true,
          "content": [
            { "prefix": "**", "destination": "/docker" }
          ]
        },
        {
          "urls": ["https://ghcr.io"],
          "onDemand": true,
          "content": [
            { "prefix": "**", "destination": "/ghcr" }
          ]
        },
        {
          "urls": ["https://gcr.io"],
          "onDemand": true,
          "content": [
            { "prefix": "**", "destination": "/gcr" }
          ]
        }
      ]
    }
  }
}
```

### Extensions

```json
{
  "extensions": {
    "search": { "enable": true },
    "ui": { "enable": true },
    "metrics": {
      "enable": true,
      "prometheus": { "path": "/metrics" }
    },
    "scrub": {
      "enable": true,
      "interval": "24h"
    }
  }
}
```

## Management

- List repositories: `task registry:list`
- View logs: `task logs SERVICE=zot` or `podman logs zot-registry`
- Container name: `zot-registry`
- Default runtime: Podman

## Configuration Files

- **Main Config**: [`config/zot/config.json`](../../config/zot/config.json)
- **Credentials**: [`secrets/all.env.dec`](../../secrets/all.env.dec) (aggregated env, git ignored)
- **Compose Service**: [`services/registry.yaml`](../../services/registry.yaml)
