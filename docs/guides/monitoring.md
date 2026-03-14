# Monitoring and Observability

## Grafana Dashboard

1. Access at <http://localhost:3000>
1. Login with configured credentials
1. Navigate to **Dashboards → Docker Registry**
1. Monitor:
   - HTTP request rates and latencies
   - Cache hit ratios
   - Response code distribution
   - Storage metrics
1. For log exploration:
   - Navigate to **Explore → Loki**
   - Query registry logs using LogQL

## Mimir Queries

Access Mimir through Grafana at <http://localhost:3000> (Explore → Mimir datasource) and try these PromQL queries:

```bash
# Request rate by method
rate(zot_http_requests_total[5m])

# 99th percentile latency
histogram_quantile(0.99, rate(zot_http_request_duration_seconds_bucket[5m]))

# Cache hit ratio
rate(zot_storage_cache_hits_total[5m]) / rate(zot_storage_cache_requests_total[5m])

# Container CPU usage
rate(container_cpu_usage_seconds_total{container_name="zot-registry"}[5m])

# Container memory usage
container_memory_usage_bytes{container_name="zot-registry"}
```

## Tempo Traces

1. Access through Grafana at <http://localhost:3000>
1. Navigate to Explore → Select Tempo datasource
1. View traces for:
   - Registry operations (image pulls/pushes)
   - OTLP trace collection
   - Service dependencies and latencies
1. Use trace-to-logs correlation to see related log entries

## Loki Log Queries

Access Loki through Grafana's Explore interface or use these example LogQL queries:

```bash
# View all Docker container logs
{job="docker_logs"}

# View logs from the registry container
{container="zot-registry"}

# Filter by compose service
{service="zot-registry"}

# Filter registry logs by level
{container="zot-registry"} |= "level=error"

# Search for sync operations in Zot
{container="zot-registry"} |= "sync" |= "syncing image"

# View logs from all monitoring stack containers
{compose_project="registry"} |~ "zot-registry|prometheus|grafana|loki"

# Filter Zot logs by specific registry
{container="zot-registry"} |= "remote" |~ "docker|ghcr|gcr"

# Show logs for specific image pulls
{container="zot-registry"} |= "docker/nginx"

# Monitor authentication errors
{container="zot-registry"} |= "error" |= "auth"

# Rate of errors over time
rate({container="zot-registry"} |= "error" [5m])
```

## Management Commands

### Zot Registry Operations

```bash
task up                              # Start all services
task logs SERVICE=zot-registry       # View Zot logs

# Check registry health
curl -sk https://127.0.0.1:5000/v2/

# List repositories
curl -sk https://127.0.0.1:5000/v2/_catalog

# Get repository tags
curl -sk https://127.0.0.1:5000/v2/docker/nginx/tags/list

# Access Web UI
open https://127.0.0.1:5000/home
```

### Monitoring Stack Operations

```bash
task up                              # Start all services

# View logs for specific services
task logs SERVICE=mimir-1
task logs SERVICE=grafana
task logs SERVICE=loki
task logs SERVICE=tempo
task logs SERVICE=alloy
```

### Alloy Management

```bash
task logs SERVICE=alloy              # View Alloy logs

# Access Alloy UI
curl http://localhost:12345
# Or open http://localhost:12345 in browser
```
