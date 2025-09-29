# Quick Start Guide

## Prerequisites

- **Hardware**: Minimum 8GB RAM, 50GB free disk space
- **Operating System**: Linux (Ubuntu 20.04+ recommended) or macOS with Docker support
- **Docker**: Docker Engine 24.0+ with Docker Compose v2
- **Network**: Internet connectivity for image pulls and certificate generation

## Installation Steps

### 1. Set up credentials (optional)

```bash
# Create credentials file for upstream registries (optional)
cat <<EOF > zot/config/credentials.yaml
registry-1.docker.io:
  username: <your_docker_hub_username>
  password: <your_docker_hub_password>
ghcr.io:
  username: <your_github_username>
  password: <your_github_token>
EOF

# Set up Grafana credentials in monitoring directory
cat <<EOF > monitoring/.env
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
EOF
```

### 2. Setup rootless Docker (if not already done)

Follow the [Rootless Docker Setup](../configuration/rootless-docker.md) guide.

### 3. Start all services

```bash
# Start Zot registry
cd zot
docker-compose up -d

# Start Traefik reverse proxy
cd ../traefik
docker-compose up -d

# Start monitoring stack
cd ../monitoring
docker-compose up -d

# Start authentication stack (optional)
cd ../auth
docker-compose up -d

# Start storage stack
cd ../storage
docker-compose up -d

# Start media stack (optional)
cd ../mediaserver
docker-compose up -d
```

### 4. Configure Docker to use the registry

```bash
# For external HTTPS access (authentication handled by Traefik/Authentik)
docker login registry.yourdomain.com

# For local HTTP access (no authentication required)
# First add to insecure registries - see "Configure Docker for Insecure Registry" section
docker pull localhost:5000/docker/nginx:latest
```

### 5. Access services

```bash
# Check all running services
docker ps
```

## Service URLs

- **Zot Registry API (local)**: <http://localhost:5000/v2/> (no auth)
- **Zot Registry API (external)**: <https://registry.yourdomain.com/v2/> (auth via Traefik/Authentik)
- **Zot Web UI**: <http://localhost:5000/home>
- **Grafana**: <http://localhost:3000> (admin/admin)
- **Mimir**: <http://localhost:9009> (metrics storage)
- **Tempo**: <http://localhost:3200> (tracing)
- **MinIO Console**: <http://localhost:9001> (object storage)
- **Loki**: <http://localhost:3100> (logs)
- **Alloy**: <http://localhost:12345> (Grafana Alloy UI)

### 6. View logs in Grafana

- Navigate to <http://localhost:3000>
- Login with admin/admin
- Go to Explore → Select Loki datasource
- Try queries like `{container="registry"}` or `{job="docker_logs"}`

## Next Steps

- [Test the registry](testing.md) with sample images
- [Configure monitoring](monitoring.md) dashboards
- [Set up authentication](../stacks/authentik.md) for external access
- Review [troubleshooting guide](troubleshooting.md) for common issues
