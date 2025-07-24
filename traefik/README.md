# Traefik Configuration

This directory contains the Traefik configuration that replaces the Caddy reverse proxy setup.

## Key Features

- **Automatic HTTPS**: Uses Let's Encrypt for SSL certificates
- **OpenTelemetry Tracing**: Sends traces to Grafana Tempo via Alloy
- **Prometheus Metrics**: Exposes metrics at `/metrics` endpoint
- **Dynamic Configuration**: Supports hot-reloading of route configurations
- **Security Headers**: Implements comprehensive security headers
- **Basic Authentication**: Protects sensitive services

## Migration from Caddy

### Key Differences

1. **Configuration Structure**:

   - Caddy: Single `Caddyfile`
   - Traefik: Split into static (`traefik.yml`) and dynamic configurations

1. **Service Discovery**:

   - Caddy: Manual proxy configuration
   - Traefik: Can use Docker labels OR file-based configuration

1. **Logging**:

   - Caddy: Per-domain log files
   - Traefik: Centralized access and error logs (can be filtered by service)

1. **OpenTelemetry Support**:

   - Caddy: Limited native support
   - Traefik: Full OTLP support with configurable sampling

### File Structure

```
traefik/
├── docker-compose.yaml     # Main compose file
├── config/
│   ├── traefik.yml        # Static configuration
│   └── dynamic/           # Dynamic route configurations
│       ├── monitoring.yml # Monitoring services
│       ├── registry.yml   # Registry configuration
│       ├── media.yml      # Media services
│       ├── middleware.yml # Reusable middlewares
│       └── metrics.yml    # Metrics endpoint
└── logs/                  # Log files directory
```

## Usage

1. **Start Traefik**:

   ```bash
   cd traefik
   docker compose up -d
   ```

1. **View Logs**:

   ```bash
   docker logs traefik
   # Or view log files
   tail -f logs/access.log
   ```

1. **Access Dashboard**:

   - URL: https://traefik.smigula.io
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
1. **Basic Authentication**: For sensitive services (using same credentials as Caddy)
1. **Rate Limiting**: Available as middleware (not enabled by default)

## Differences in Behavior

1. **Path Matching**: Traefik uses different syntax for path matching

   - Caddy: `/path*`
   - Traefik: `PathPrefix(\`/path\`)\`

1. **Header Handling**: Traefik automatically adds X-Forwarded-\* headers

1. **WebSocket Support**: Automatically detected and handled

## Troubleshooting

1. **Certificate Issues**: Check `/letsencrypt/acme.json` permissions (should be 600)
1. **Service Discovery**: Ensure services are on the correct Docker network
1. **Configuration Errors**: Check `docker logs traefik` for validation errors

## Adding New Services

To add a new service, create a new file in `config/dynamic/` or add to existing file:

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
