# Registry Stack - Zot OCI Registry

**Purpose**: OCI-compliant container registry with pull-through caching

```mermaid
graph TB
    subgraph "Registry Stack"
        Zot[Zot OCI Registry<br/>:5000 Registry API<br/>:5001 Metrics]
        ZotUI[Zot UI<br/>:3000<br/>Web Interface]

        subgraph "Configuration"
            Config[Registry Config<br/>config.yaml]
            Auth[Registry Auth<br/>htpasswd]
        end

        subgraph "Storage"
            RegData[Registry Data<br/>OCI Artifacts]
            Cache[Pull-through Cache<br/>Docker Hub Mirror]
        end
    end

    subgraph "External Dependencies"
        DockerHub[Docker Hub<br/>Upstream Registry]
        Clients[Docker Clients<br/>Podman/Docker]
    end

    Zot --> Config
    Zot --> Auth
    Zot --> RegData
    Zot --> Cache
    ZotUI --> Zot

    Cache --> DockerHub
    Clients --> Zot

    classDef registry fill:#fce4ec,stroke:#c2185b,stroke-width:3px,color:#424242
    classDef config fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#424242
    classDef storage fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#424242
    classDef external fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#424242

    class Zot,ZotUI registry
    class Config,Auth config
    class RegData,Cache storage
    class DockerHub,Clients external
```

## Key Features

- OCI Distribution Specification compliance
- Pull-through caching for improved performance
- Web UI for registry management
- Vulnerability scanning and image signing support

## Services

- `registry`: Main Zot registry server

## Configuration

See [`zot/docker-compose.yaml`](../../zot/docker-compose.yaml) for the complete configuration.

For OIDC authentication setup with Authentik, see the [Zot OIDC Configuration Guide](../configuration/zot-oidc.md).

## Registry Prefixes

Zot uses prefix-based routing for different registries:

- `/docker/` - Docker Hub images
- `/ghcr/` - GitHub Container Registry images
- `/gcr/` - Google Container Registry images
- `/quay/` - Quay.io images
- `/k8s/` - Kubernetes registry images

## Usage Examples

```bash
# Docker Hub images
docker pull localhost:5000/docker/nginx:latest

# GitHub Container Registry
docker pull localhost:5000/ghcr/project-zot/zot-linux-amd64:v2.1.5

# Google Container Registry
docker pull localhost:5000/gcr/cadvisor/cadvisor:v0.52.0
```

## Management

```bash
# From the zot/ directory
docker-compose up -d        # Start Zot registry
docker-compose down         # Stop Zot registry
docker-compose logs -f      # View Zot logs

# Registry API commands
curl http://localhost:5000/v2/_catalog                    # List all repositories
curl http://localhost:5000/v2/docker/nginx/tags/list      # List tags for a repository
```

## Access Points

- **Registry API (local)**: http://localhost:5000/v2/ (no auth)
- **Registry API (external)**: https://registry.yourdomain.com/v2/ (auth via Traefik/Authentik)
- **Web UI**: http://localhost:5000/home
- **Metrics**: http://localhost:5000/metrics