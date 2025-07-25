# Migrating Services from Basic Auth to Authentik

## Example: Migrating Monitoring Services

Here's how to update your monitoring services to use Authentik instead of basic auth:

### Before (using basic auth):

```yaml
prometheus:
  rule: "Host(`prometheus.smigula.io`)"
  service: prometheus
  entryPoints:
    - websecure
  tls:
    certResolver: letsencrypt
  middlewares:
    - security-headers
    - auth-basic  # Old basic auth
```

### After (using Authentik):

```yaml
prometheus:
  rule: "Host(`prometheus.smigula.io`)"
  service: prometheus
  entryPoints:
    - websecure
  tls:
    certResolver: letsencrypt
  middlewares:
    - security-headers
    - authentik  # New Authentik auth
```

## Step-by-Step Migration Process

1. **Start Authentik and complete initial setup**
1. **Create the provider and outpost in Authentik** (see README.md)
1. **Update service configurations** one by one:
   - Replace `auth-basic` with `authentik` in middleware lists
   - Test each service after updating
1. **Configure access policies** in Authentik for each service

## Services to Migrate

- [ ] Traefik Dashboard (traefik.smigula.io)
- [ ] Grafana (grafana.smigula.io)
- [ ] Prometheus (prometheus.smigula.io)
- [ ] Tempo (tempo.smigula.io)
- [ ] Dozzle (dozzle.smigula.io)
- [ ] Alloy (alloy.smigula.io)

## Advanced Configuration

### Per-Service Access Control

You can create different applications in Authentik for different access levels:

1. **Admin Services** (full infrastructure access):

   - Create an "Infrastructure Admin" application
   - Bind to admin group only
   - Use for: Traefik dashboard, Prometheus, Dozzle

1. **Monitoring Services** (read-only access):

   - Create a "Monitoring" application
   - Allow broader access
   - Use for: Grafana, Tempo

1. **Media Services** (entertainment access):

   - Create separate application with different policies
   - Can have different authentication flows

### Example: Service-Specific Middleware

Create service-specific auth middleware in `/traefik/config/dynamic/authentik.yaml`:

```yaml
middlewares:
  # Standard authentik middleware
  authentik:
    forwardAuth:
      address: "http://authentik-server:9000/outpost.goauthentik.io/auth/traefik"
      trustForwardHeader: true
      authResponseHeaders:
        - X-authentik-username
        - X-authentik-groups
        - X-authentik-email
        - X-authentik-name
        - X-authentik-uid

  # Admin-only middleware (requires additional Authentik configuration)
  authentik-admin:
    forwardAuth:
      address: "http://authentik-server:9000/outpost.goauthentik.io/auth/traefik"
      trustForwardHeader: true
      authResponseHeaders:
        - X-authentik-username
        - X-authentik-groups
      # Additional headers or parameters can be added
```

## Testing the Migration

1. **Keep basic auth as fallback** initially:

   ```yaml
   middlewares:
     - security-headers
     - authentik
     # - auth-basic  # Commented out but available
   ```

1. **Test with different user accounts**:

   - Admin user
   - Regular user
   - Unauthenticated access

1. **Monitor logs** during testing:

   ```bash
   docker logs authentik-server -f
   docker logs traefik -f
   ```
