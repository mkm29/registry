# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Multi-stack container infrastructure providing six integrated Docker Compose stacks: identity management (Authentik), reverse proxy (Traefik), observability (Grafana LGTM), storage (MinIO), container registry (Zot), and media automation (Plex). The architecture uses external Docker networks for service isolation and SOPS/AGE for secret management.

## Essential Commands

### Infrastructure Deployment

```bash
./run.sh                    # Deploy complete infrastructure (secrets → networks → stacks)
./sops-helper.sh decrypt secrets  # Decrypt all .enc files in secrets/
./sops-helper.sh encrypt secrets  # Encrypt all .dec files in secrets/
./sops-helper.sh collect          # Collect all .env.dec files into single file
```

### Task Runner (preferred over Make)

```bash
task help                      # Show all available tasks
task infra:deploy              # Deploy complete infrastructure
task infra:status              # Show service status
task quickstart                # Generate certs and start registry
task certs:all                 # Generate all certificates (CA → intermediate → registry)
task registry:start            # Start Zot registry
task registry:list-repos       # List all repositories
task secrets:decrypt DIR=secrets  # Decrypt all secrets
task logs SERVICE=grafana      # Follow service logs
```

### Per-Stack Docker Compose

```bash
# Each stack has its own docker-compose.yaml
cd zot && docker compose up -d
cd traefik && docker compose up -d
cd auth && docker compose up -d
cd minio && docker compose up -d
cd monitoring && docker compose up -d
cd mediaserver && docker compose up -d
```

### Certificate Management

```bash
task certs:clean          # Remove all generated certificates
task certs:all            # Generate full chain (CA → intermediate → registry certs)
task tls:configure-docker # Configure Docker daemon to trust registry certs
task tls:test             # Test TLS connection to registry
```

## Architecture

### Stack Startup Order

The `run.sh` script starts stacks in dependency order:
1. **zot** (registry) - Container registry with pull-through caching
2. **traefik** - Reverse proxy with automatic HTTPS
3. **auth** - Authentik identity provider (PostgreSQL, Redis, server, worker)
4. **minio** - S3-compatible object storage
5. **monitoring** - Grafana LGTM stack (Mimir cluster, Loki, Tempo, Alloy, Grafana)
6. **mediaserver** - Plex and content management apps

### Network Architecture

External Docker networks isolate stacks: `traefik`, `registry`, `mediaserver`, `monitoring`, `auth`. Traefik connects to all networks as the central ingress point.

### Directory Structure

```
auth/               # Authentik stack (PostgreSQL, Redis, server, worker)
cfssl/              # Certificate configuration files
certs/              # Generated certificates (gitignored)
mediaserver/        # Plex, Radarr, Sonarr, etc.
minio/              # MinIO object storage
monitoring/         # Grafana LGTM stack (Mimir, Loki, Tempo, Alloy)
secrets/            # SOPS-encrypted secrets (.enc files committed, .dec ignored)
shared/             # Shared configuration files
traefik/            # Traefik reverse proxy
zot/                # Zot container registry
```

### Secret Management

- Secrets stored in `secrets/` with SOPS/AGE encryption
- `.enc` files (encrypted) are committed to git
- `.dec` files (decrypted) are gitignored and for local use
- `run.sh` automatically decrypts secrets before starting stacks
- AGE public key configured in `.sops.yaml`

### Data Directories

Infrastructure creates directories under `/mnt/data/`:
- `postgres/`, `redis/` - Auth stack databases
- `mimir-{1,2,3}/` - Mimir cluster data
- `grafana/` - Dashboards, plugins, exports
- `zot/` - Registry storage
- `minio/` - Object storage
- `logs/traefik/` - Access logs

Media server uses configurable paths via `DATA_ROOT` and `CONFIG_ROOT` environment variables (default: `/mnt/filestore/`).

## Key Configuration Files

- `Taskfile.yml` - Task runner definitions (preferred over Makefile)
- `run.sh` - Orchestrated startup script
- `sops-helper.sh` - SOPS encryption/decryption helper
- `.sops.yaml` - SOPS encryption rules with AGE key
- `cfssl/*.json` - Certificate authority configuration

## Service Ports

| Port | Service |
|------|---------|
| 80/443 | Traefik ingress |
| 3000 | Grafana |
| 3100 | Loki |
| 3200 | Tempo |
| 5000 | Zot registry |
| 9000/9001 | MinIO (API/Console) |
| 9008/9443 | Authentik |
| 9009 | Mimir |
| 32400 | Plex |
