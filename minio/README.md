# MinIO Object Storage Setup

This directory contains the configuration for a self-hosted MinIO object storage server, which provides S3-compatible storage for various services in the stack.

## Overview

MinIO is configured as a single-node deployment with:

- S3-compatible API endpoint accessible at `https://api.minio.smigula.io`
- Web console accessible at `https://minio.smigula.io`
- Storage persisted at `/mnt/data/minio` on the host
- Integration with Traefik for TLS termination and routing
- Prometheus metrics enabled for monitoring

## Services Using MinIO

Currently configured to provide object storage for:

- **Loki**: Log aggregation and storage
- **Mimir**: (Future) Prometheus long-term metrics storage
- **Tempo**: (Future) Distributed tracing backend
- **Registry**: (Future) Docker registry storage backend

## Quick Start

1. **Start MinIO**:

   ```bash
   docker compose up -d
   ```

1. **Verify MinIO is running**:

   ```bash
   docker compose ps
   docker logs minio
   ```

1. **Initial Setup** (if needed):

   ```bash
   ./setup.sh
   ```

## Architecture

### Docker Compose Configuration

The `docker-compose.yaml` defines two services:

1. **minio**: The MinIO server

   - Runs on ports 9000 (API) and 9001 (Console)
   - Connected to the `monitoring` network for service integration
   - Health checks via `/minio/health/live` endpoint
   - Resource limits: 2 CPUs, 2GB memory

1. **mc**: MinIO Client (initialization container)

   - Automatically creates buckets and users on startup
   - Configures policies for service-specific access
   - Exits after initialization

### Network Configuration

MinIO is attached to the `monitoring` external network to allow communication with:

- Loki for log storage
- Grafana for data source queries
- Future services (Mimir, Tempo)

### Storage Layout

```
/mnt/data/minio/
├── loki/          # Loki log chunks and indexes
├── mimir/         # Prometheus TSDB blocks (future)
├── tempo/         # Trace data (future)
├── registry/      # Docker registry layers (future)
└── backups/       # General backup storage
```

## Credentials and Access

### Root Credentials

- Username: `minioadmin`
- Password: `minioadmin123` (change in production via `.env` file)

### Service Users

Each service has its own user with bucket-specific permissions:

| Service | Username  | Password     | Bucket | Policy       |
| ------- | --------- | ------------ | ------ | ------------ |
| Loki    | lokiuser  | SuperSecret1 | loki   | loki-policy  |
| Mimir   | mimiruser | SuperSecret1 | mimir  | mimir-policy |
| Tempo   | tempouser | SuperSecret1 | tempo  | tempo-policy |

## External Access

MinIO is accessible through Traefik with automatic TLS certificates:

- **API Endpoint**: https://api.minio.smigula.io

  - Used by S3-compatible clients
  - CORS headers configured for browser access

- **Console**: https://minio.smigula.io

  - Web-based management interface
  - File browser and bucket management

## Monitoring

MinIO exposes Prometheus metrics on the API port at `/minio/v2/metrics/cluster`.

To add MinIO to Prometheus:

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
docker compose down

# Restore data
rsync -av /backup/minio/ /mnt/data/minio/

# Start MinIO
docker compose up -d
```

## Troubleshooting

### Check MinIO Health

```bash
curl -f http://localhost:9000/minio/health/live
```

### View Logs

```bash
docker logs minio
docker logs minio-mc
```

### Common Issues

1. **Access Denied Errors**

   - Verify user has correct policy attached: `mc admin user info local username`
   - Check policy permissions: `mc admin policy info local policy-name`

1. **Connection Refused**

   - Ensure MinIO is on correct network: `docker inspect minio`
   - Verify service is healthy: `docker ps`

1. **DNS Resolution Issues**

   - Services must be on same Docker network
   - Use container name (minio) not localhost for inter-container communication

## Security Considerations

1. **Change default credentials** in production using environment variables or `.env` file
1. **Enable TLS** for MinIO API (currently handled by Traefik)
1. **Implement bucket lifecycle policies** for data retention
1. **Regular backups** of critical data
1. **Monitor access logs** for unauthorized access attempts

## Future Enhancements

- [ ] Multi-node deployment for high availability
- [ ] Bucket replication for disaster recovery
- [ ] Integration with external identity providers
- [ ] Automated backup jobs
- [ ] Storage tiering with lifecycle policies
