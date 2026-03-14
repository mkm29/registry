# Quick Start Guide

## Prerequisites

- **Hardware**: Minimum 8GB RAM, 50GB free disk space
- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **Container Runtime**: Podman 5.0+ (default) or Docker CE 28.3+
- **Task**: [Task](https://taskfile.dev/) runner (preferred over Make)
- **SOPS**: [Mozilla SOPS](https://github.com/getsops/sops) for secret management
- **Age**: [Age](https://github.com/FiloSottile/age) encryption tool, with key at `~/.config/sops/age/keys.txt`
- **cfssl**: [Cloudflare CFSSL](https://github.com/cloudflare/cfssl) for PKI certificate generation
- **Network**: Internet connectivity for image pulls

## Installation Steps

### 1. Clone the repository

```bash
git clone https://github.com/mkm29/registry.git
cd registry
```

### 2. Initialize the environment

This creates required data directories, generates the full PKI certificate chain (CA, intermediate, and server certificates), and decrypts and aggregates all SOPS-encrypted secrets.

```bash
task init
```

### 3. Deploy the infrastructure

This starts all services in the correct dependency order: Zot registry first (with a health-check gate), then MinIO (with a health-check gate and bucket initialization), and finally the remaining services.

```bash
task up
```

### 4. Configure your container runtime to use the registry

```bash
# For external HTTPS access (authentication handled by Traefik/Authentik)
podman login registry.smigula.io

# For local TLS access (CA is trusted during `task init`)
podman pull 127.0.0.1:5000/docker/nginx:latest
```

### 5. Access services

```bash
# Check all running services
podman ps
```

## Service URLs

- **Zot Registry API (local)**: <https://127.0.0.1:5000/v2/> (TLS-enabled)
- **Zot Registry API (external)**: <https://registry.smigula.io/v2/> (auth via Traefik/Authentik)
- **Zot Web UI**: <https://127.0.0.1:5000/home>
- **Grafana**: <http://localhost:3000>
- **Mimir**: <http://localhost:9009> (metrics storage)
- **Tempo**: <http://localhost:3200> (tracing)
- **MinIO Console**: <http://localhost:9001> (object storage)
- **Loki**: <http://localhost:3100> (logs)
- **Alloy**: <http://localhost:12345> (Grafana Alloy UI)

### 6. View logs in Grafana

- Navigate to <http://localhost:3000>
- Go to Explore and select the Loki datasource
- Try queries like `{container="zot-registry"}` or `{job="docker_logs"}`

## Teardown

To stop all services and purge decrypted secrets:

```bash
task down
```

## Next Steps

- [Test the registry](testing.md) with sample images
- [Configure monitoring](monitoring.md) dashboards
- [Set up authentication](../stacks/authentik.md) for external access
- Review [troubleshooting guide](troubleshooting.md) for common issues
