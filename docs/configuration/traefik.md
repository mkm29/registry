# Traefik Configuration Guide

This guide covers the Traefik v3.6.9 reverse proxy configuration that provides automatic HTTPS, service discovery, and observability features.

## Key Features

- **Automatic HTTPS**: Uses Let's Encrypt for SSL certificates
- **OpenTelemetry Tracing**: Sends traces to Grafana Tempo via Alloy
- **Prometheus Metrics**: Exposes metrics at `/metrics` endpoint
- **Dynamic Configuration**: Supports hot-reloading of route configurations
- **Security Headers**: Implements comprehensive security headers
- **Basic Authentication**: Protects sensitive services

## File Structure

```bash
services/traefik.yaml          # Service definition
config/traefik/
├── traefik.yml                # Static configuration
└── dynamic/                   # Dynamic route configurations
    ├── monitoring.yml
    ├── registry.yml
    ├── media.yml
    ├── middleware.yml
    ├── metrics.yml
    ├── authentik.yaml
    ├── geoblock.yml
    └── minio.yml
```

## Usage

1. **Start Traefik** (along with all services):

   ```bash
   task up
   ```

   Or start Traefik individually from the project root:

   ```bash
   podman compose up -d traefik
   ```

1. **View Logs**:

   ```bash
   task logs SERVICE=traefik
   ```

   Log files are stored at `/mnt/media/logs/traefik/` (mounted as a volume).

1. **Access Dashboard**:

   - URL: <https://traefik.smigula.io>
   - Credentials: Same as configured in basic auth

## OpenTelemetry Configuration

Traefik is configured to send traces to Alloy on port 4317 (OTLP gRPC). The configuration includes:

- Service name: Automatically set based on router name
- Span attributes: HTTP method, status code, path, etc.
- Sampling: Configurable via `samplingServerURL`

## Monitoring

- **Metrics**: Available at internal port 8082 or via `/metrics` endpoint
- **Traces**: Sent to Tempo via Alloy
- **Logs**: JSON formatted for easy parsing by Loki

## Security Features

1. **Automatic HTTPS redirect**: All HTTP traffic redirected to HTTPS
1. **Security Headers**: HSTS, XSS Protection, Content-Type sniffing prevention
1. **Basic Authentication**: For sensitive services
1. **Rate Limiting**: Available as middleware (not enabled by default)

## Troubleshooting

1. **Certificate Issues**: Check `/letsencrypt/acme.json` permissions (should be 600)
1. **Service Discovery**: Ensure services are on the correct Docker network
1. **Configuration Errors**: Check logs with `task logs SERVICE=traefik` for validation errors

## Adding New Services

To add a new service, create a new file in `config/traefik/dynamic/` or add to an existing file:

```yaml
http:
  routers:
    myservice:
      rule: "Host(`myservice.smigula.io`)"
      service: myservice
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers

  services:
    myservice:
      loadBalancer:
        servers:
          - url: "http://myservice:8080"
```

The configuration will be automatically reloaded.

## Related Documentation

- **[Traefik Stack Architecture](../stacks/traefik.md)** - Complete stack overview and architecture
- **[CFSSL Configuration](cfssl.md)** - TLS certificate generation
- **[Monitoring Guide](../guides/monitoring.md)** - Observability setup and queries
