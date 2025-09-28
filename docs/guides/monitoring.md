# Monitoring and Observability

## Grafana Dashboard

1. Access at <http://localhost:3000>
2. Login with configured credentials
3. Navigate to **Dashboards → Docker Registry**
4. Monitor:
   - HTTP request rates and latencies
   - Cache hit ratios
   - Response code distribution
   - Storage metrics
5. For log exploration:
   - Navigate to **Explore → Loki**
   - Query registry logs using LogQL

## Mimir Queries

Access Mimir through Grafana at <http://localhost:3000> (Explore → Mimir datasource) and try these PromQL queries:

```promql
# Request rate by method
rate(zot_http_requests_total[5m])

# 99th percentile latency
histogram_quantile(0.99, rate(zot_http_request_duration_seconds_bucket[5m]))

# Cache hit ratio
rate(zot_storage_cache_hits_total[5m]) / rate(zot_storage_cache_requests_total[5m])

# Container CPU usage
rate(container_cpu_usage_seconds_total{container_name="registry"}[5m])

# Container memory usage
container_memory_usage_bytes{container_name="registry"}
```

## Tempo Traces

1. Access through Grafana at <http://localhost:3000>
2. Navigate to Explore → Select Tempo datasource
3. View traces for:
   - Registry operations (image pulls/pushes)
   - OTLP trace collection
   - Service dependencies and latencies
4. Use trace-to-logs correlation to see related log entries

## Loki Log Queries

Access Loki through Grafana's Explore interface or use these example LogQL queries:

```logql
# View all Docker container logs
{job="docker_logs"}

# View logs from the registry container
{container="registry"}

# Filter by compose service
{service="registry"}

# Filter registry logs by level
{container="registry"} |= "level=error"

# Search for sync operations in Zot
{container="registry"} |= "sync" |= "syncing image"

# View logs from all monitoring stack containers
{compose_project="registry"} |~ "registry|prometheus|grafana|loki"

# Filter Zot logs by specific registry
{container="registry"} |= "remote" |~ "docker|ghcr|gcr"

# Show logs for specific image pulls
{container="registry"} |= "docker/nginx"

# Monitor authentication errors
{container="registry"} |= "error" |= "auth"

# Rate of errors over time
rate({container="registry"} |= "error" [5m])
```

## Management Commands

### Zot Registry Operations

```bash
# From the zot/ directory
docker-compose up -d            # Start Zot
docker-compose down             # Stop Zot
docker-compose restart          # Restart Zot
docker-compose logs -f          # View Zot logs

# Check registry health
curl http://localhost:5000/v2/

# List repositories
curl http://localhost:5000/v2/_catalog

# Get repository tags
curl http://localhost:5000/v2/docker/nginx/tags/list

# Access Web UI
open http://localhost:5000/home
```

### Monitoring Stack Operations

```bash
# From the monitoring/ directory
docker-compose up -d            # Start monitoring
docker-compose down             # Stop monitoring
docker-compose restart          # Restart services

# View logs for specific services
docker-compose logs -f mimir
docker-compose logs -f grafana
docker-compose logs -f loki
docker-compose logs -f tempo
docker-compose logs -f alloy

# Clean up (including volumes)
docker-compose down -v
```

### Alloy Management

```bash
# Alloy is managed as part of the monitoring stack
cd monitoring/
docker-compose logs -f alloy      # View Alloy logs
docker-compose restart alloy      # Restart Alloy container

# Access Alloy UI
curl http://localhost:12345
# Or open http://localhost:12345 in browser
```