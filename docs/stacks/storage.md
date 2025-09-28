# Storage Stack - MinIO S3

**Purpose**: S3-compatible object storage for monitoring backends

```mermaid
graph TB
    subgraph "MinIO Stack"
        MinIO[MinIO Server<br/>:9000 S3 API<br/>:9001 Console]
        Console[MinIO Console<br/>Web Management]

        subgraph "Storage"
            Data[MinIO Data<br/>S3 Buckets]
        end

        subgraph "Configuration"
            Credentials[Admin Credentials<br/>Access/Secret Keys]
            Policies[Bucket Policies<br/>Access Control]
        end
    end

    subgraph "S3 Clients"
        Mimir[Mimir Cluster<br/>Metrics Storage]
        Loki[Loki<br/>Log Storage]
        Tempo[Tempo<br/>Trace Storage]
        Apps[Other Applications<br/>S3 SDK]
    end

    MinIO --> Data
    MinIO --> Credentials
    MinIO --> Policies
    Console --> MinIO

    Mimir --> MinIO
    Loki --> MinIO
    Tempo --> MinIO
    Apps --> MinIO

    classDef storage fill:#fff3e0,stroke:#ef6c00,stroke-width:3px,color:#424242
    classDef config fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#424242
    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#424242
    classDef clients fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#424242

    class MinIO,Console storage
    class Credentials,Policies config
    class Data data
    class Mimir,Loki,Tempo,Apps clients
```

## Key Features

- S3-compatible API for broad compatibility
- Web-based management console
- Automated bucket creation and policies
- Service user management

## Services

- `minio`: Main storage server
- `mc`: MinIO client for setup and administration

## Configuration

See [`storage/docker-compose.yaml`](../../storage/docker-compose.yaml) for the complete configuration.

## Management

```bash
# From the storage/ directory
docker-compose up -d        # Start MinIO
docker-compose down         # Stop MinIO
docker-compose logs -f      # View logs
```

## Access Points

- **S3 API**: http://localhost:9000
- **Console**: http://localhost:9001
- **Default Credentials**: Check environment variables in docker-compose.yaml