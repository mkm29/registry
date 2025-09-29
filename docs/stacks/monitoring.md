# Monitoring Stack - Observability Platform

**Purpose**: Complete observability with metrics, logs, and traces

```mermaid
graph TB
    subgraph "Data Sources"
        Apps[Application Services<br/>All Stacks]
        Containers[Docker Containers<br/>cAdvisor]
        Logs[Application Logs<br/>Docker Logs]
        Traces[Application Traces<br/>OpenTelemetry]
        Metrics[System Metrics<br/>Node Exporter]
    end

    subgraph "Collection Layer"
        Alloy[Grafana Alloy<br/>Unified Collector<br/>:12345]
        cAdvisor[cAdvisor<br/>Container Metrics<br/>:8080]
        Dozzle[Dozzle<br/>Real-time Log Viewer<br/>:8080]
    end

    subgraph "Load Balancing"
        NginxLB[Nginx Load Balancer<br/>:80 → Mimir Cluster<br/>Round Robin]
    end

    subgraph "Storage Backends - Mimir Cluster"
        Mimir1[Mimir Node 1<br/>:8080]
        Mimir2[Mimir Node 2<br/>:8080]
        Mimir3[Mimir Node 3<br/>:8080]
    end

    subgraph "Log & Trace Storage"
        Loki[Loki<br/>Log Aggregation<br/>:3100]
        Tempo[Tempo<br/>Distributed Tracing<br/>:3200]
    end

    subgraph "Visualization"
        Grafana[Grafana<br/>Dashboards & Alerts<br/>:3000]
    end

    subgraph "Object Storage"
        MinIO[MinIO S3 Storage<br/>Persistent Backend<br/>:9000]
    end

    Apps --> Alloy
    Containers --> cAdvisor
    Logs --> Alloy
    Traces --> Alloy
    Metrics --> Alloy
    Apps --> Dozzle

    Alloy -->|Metrics| NginxLB
    Alloy -->|Logs| Loki
    Alloy -->|Traces| Tempo
    cAdvisor --> Alloy

    NginxLB --> Mimir1
    NginxLB --> Mimir2
    NginxLB --> Mimir3

    Mimir1 --> MinIO
    Mimir2 --> MinIO
    Mimir3 --> MinIO
    Loki --> MinIO
    Tempo --> MinIO

    Grafana --> NginxLB
    Grafana --> Loki
    Grafana --> Tempo

    classDef source fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#424242
    classDef collector fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#424242
    classDef storage fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#424242
    classDef visualization fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#424242
    classDef loadbalancer fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#424242
    classDef backend fill:#fff8e1,stroke:#ffa000,stroke-width:2px,color:#424242

    class Apps,Containers,Logs,Traces,Metrics source
    class Alloy,cAdvisor,Dozzle collector
    class Mimir1,Mimir2,Mimir3,Loki,Tempo storage
    class Grafana visualization
    class NginxLB loadbalancer
    class MinIO backend
```

## Key Features

- Grafana LGTM stack (Loki, Grafana, Tempo, Mimir)
- High-availability Mimir cluster with load balancing
- Unified data collection via Alloy
- Container metrics collection with cAdvisor
- Real-time log viewing with Dozzle

## Services

- `mimir-1/2/3`: 3-node Mimir cluster for metrics
- `mimir-lb`: Nginx load balancer for cluster
- `grafana`: Visualization and dashboards
- `loki`: Log aggregation and querying
- `tempo`: Distributed tracing
- `alloy`: Unified observability collector
- `cadvisor`: Container metrics collection
- `dozzle`: Real-time log viewer

## Configuration

See [`monitoring/docker-compose.yaml`](../../monitoring/docker-compose.yaml) for the complete configuration.

## Management

```bash
# From the monitoring/ directory
docker-compose up -d        # Start monitoring stack
docker-compose down         # Stop monitoring stack
docker-compose logs -f      # View all monitoring logs

# View specific service logs
docker-compose logs -f mimir
docker-compose logs -f grafana
docker-compose logs -f loki
docker-compose logs -f tempo
```

## Access Points

- **Grafana**: <http://localhost:3000> (admin/admin)
- **Mimir**: <http://localhost:9009> (metrics storage)
- **Tempo**: <http://localhost:3200> (tracing)
- **Loki**: <http://localhost:3100> (logs)
- **Alloy**: <http://localhost:12345> (Grafana Alloy UI)

## Sample Queries

### Mimir (PromQL)

```bash
# Request rate by method
rate(zot_http_requests_total[5m])

# 99th percentile latency
histogram_quantile(0.99, rate(zot_http_request_duration_seconds_bucket[5m]))

# Container CPU usage
rate(container_cpu_usage_seconds_total{container_name="registry"}[5m])
```

### Loki (LogQL)

```bash
# View all Docker container logs
{job="docker_logs"}

# View logs from the registry container
{container="registry"}

# Filter registry logs by level
{container="registry"} |= "level=error"
```
