# MinIO Object Storage Stack

This document covers the MinIO object storage configuration that provides S3-compatible storage for various services in the infrastructure.

## Overview

MinIO is configured as a single-node deployment with:

- S3-compatible API endpoint accessible at `https://api.minio.smigula.io`
- Web console accessible at `https://minio.smigula.io`
- Storage persisted at `/mnt/data/minio` on the host
- Integration with Traefik for TLS termination and routing
- Prometheus metrics enabled for monitoring

## Architecture

```mermaid
graph TB
    subgraph "MinIO Stack"
        MinIO[MinIO Server<br/>:9000 S3 API<br/>:9001 Console]
        Console[MinIO Console<br/>Web Management]

        subgraph "Storage"
            Data[MinIO Data<br/>S3 Buckets]
            Loki[loki/ bucket<br/>Log chunks & indexes]
            Mimir[mimir/ bucket<br/>TSDB blocks]
            Tempo[tempo/ bucket<br/>Trace data]
            Registry[registry/ bucket<br/>Container layers]
        end

        subgraph "Configuration"
            Credentials[Admin Credentials<br/>Access/Secret Keys]
            Policies[Bucket Policies<br/>Access Control]
            Users[Service Users<br/>lokiuser, mimiruser]
        end
    end

    subgraph "S3 Clients"
        LokiSvc[Loki<br/>Log Storage]
        MimirSvc[Mimir<br/>Metrics Storage]
        TempoSvc[Tempo<br/>Trace Storage]
        RegistrySvc[Registry<br/>Image Storage]
    end

    MinIO --> Data
    MinIO --> Credentials
    MinIO --> Policies
    Console --> MinIO

    LokiSvc --> Loki
    MimirSvc --> Mimir
    TempoSvc --> Tempo
    RegistrySvc --> Registry

    classDef storage fill:#fff3e0,stroke:#ef6c00,stroke-width:3px,color:#424242
    classDef config fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#424242
    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#424242
    classDef clients fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#424242

    class MinIO,Console storage
    class Credentials,Policies,Users config
    class Data,Loki,Mimir,Tempo,Registry data
    class LokiSvc,MimirSvc,TempoSvc,RegistrySvc clients
```

## Services Using MinIO

Currently configured to provide object storage for:

- **Loki**: Log aggregation and storage
- **Mimir**: Prometheus long-term metrics storage
- **Tempo**: Distributed tracing backend
- **Registry**: Docker registry storage backend (future)

## Quick Start

1. **Start MinIO**:

   ```bash
   task up                             # Start all services (includes MinIO)
   podman compose up -d minio          # Start MinIO only
   ```

1. **Verify MinIO is running**:

   ```bash
   podman compose ps
   podman logs minio
   ```

1. **Initial Setup** (automated via `task up`):

   The `scripts/setup-minio.sh` script automatically handles MinIO bucket and user setup as part of the `task up` deployment.

## Docker Compose Configuration

The [`services/storage.yaml`](../../services/storage.yaml) defines the MinIO service:

1. **minio**: The MinIO server

   - Runs on ports 9000 (API) and 9001 (Console)
   - Connected to the `monitoring` network for service integration
   - Health checks via `/minio/health/live` endpoint

## Network Configuration

MinIO is attached to the `monitoring` external network to allow communication with:

- Loki for log storage
- Grafana for data source queries
- Mimir for metrics storage
- Tempo for trace storage

## Storage Layout

```bash
/mnt/data/minio/
├── loki/          # Loki log chunks and indexes
├── mimir/         # Prometheus TSDB blocks
├── tempo/         # Trace data
├── registry/      # Docker registry layers (future)
└── backups/       # General backup storage
```

## Credentials and Access

### Root Credentials

- Username: `minioadmin`
- Password: Configured via environment variables (see `.env` files)

### Service Users

Each service has its own user with bucket-specific permissions:

| Service | Username | Bucket | Policy | Purpose |
| ------- | --------- | ------ | ------------ | ------------------------- |
| Loki | lokiuser | loki | loki-policy | Log chunk storage |
| Mimir | mimiruser | mimir | mimir-policy | Metrics TSDB blocks |
| Tempo | tempouser | tempo | tempo-policy | Distributed trace storage |

## External Access

MinIO is accessible through Traefik with automatic TLS certificates:

- **API Endpoint**: <https://api.minio.smigula.io>

  - Used by S3-compatible clients
  - CORS headers configured for browser access

- **Console**: <https://minio.smigula.io>

  - Web-based management interface
  - File browser and bucket management

## Monitoring

MinIO exposes Prometheus metrics on the API port at `/minio/v2/metrics/cluster`.

Integration with the monitoring stack:

```yaml
- job_name: 'minio'
  static_configs:
    - targets: ['minio:9000']
  metrics_path: '/minio/v2/metrics/cluster'
```

## Manual Administration

### Using mc (MinIO Client)

The `mc` command is available on the host system. Common operations:

```bash
# List buckets
mc ls local/

# List objects in a bucket
mc ls local/loki/

# Check disk usage
mc du local/

# Add a new user
mc admin user add local newuser newsecret

# Create and attach a policy
mc admin policy create local policy-name policy.json
mc admin policy attach local policy-name --user username

# Check server info
mc admin info local
```

### Policy Examples

Each service has a policy granting full access to its specific bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::bucketname",
        "arn:aws:s3:::bucketname/*"
      ]
    }
  ]
}
```

## Backup and Recovery

### Backup MinIO Data

```bash
# Using mc mirror
mc mirror --overwrite local/loki /backup/minio/loki

# Using rsync
rsync -av /mnt/data/minio/ /backup/minio/
```

### Restore from Backup

```bash
# Stop MinIO
podman compose down minio

# Restore data
rsync -av /backup/minio/ /mnt/data/minio/

# Start MinIO
podman compose up -d minio
```

## Troubleshooting

### Check MinIO Health

```bash
curl -f http://localhost:9000/minio/health/live
```

### View Logs

```bash
task logs SERVICE=minio
podman logs minio
```

### Common Issues

1. **Access Denied Errors**

   - Verify user has correct policy attached: `mc admin user info local username`
   - Check policy permissions: `mc admin policy info local policy-name`

1. **Connection Refused**

   - Ensure MinIO is on correct network: `podman inspect minio`
   - Verify service is healthy: `podman compose ps`

1. **DNS Resolution Issues**

   - Services must be on same Docker network
   - Use container name (minio) not localhost for inter-container communication

## Security Considerations

1. **Change default credentials** in production using environment variables or `.env` file
1. **Enable TLS** for MinIO API (currently handled by Traefik)
1. **Implement bucket lifecycle policies** for data retention
1. **Regular backups** of critical data
1. **Monitor access logs** for unauthorized access attempts

## Management Commands

```bash
# Start/stop MinIO
task up                             # Start all services (includes MinIO)
podman compose up -d minio          # Start MinIO only
podman compose down minio           # Stop MinIO

# View logs
task logs SERVICE=minio             # Follow MinIO logs
podman logs minio                   # View MinIO container logs

# Check status
podman compose ps
```

## Access Points

- **S3 API**: <http://localhost:9000> (local), <https://api.minio.smigula.io> (external)
- **Console**: <http://localhost:9001> (local), <https://minio.smigula.io> (external)
- **Health Check**: <http://localhost:9000/minio/health/live>
- **Metrics**: <http://localhost:9000/minio/v2/metrics/cluster>
