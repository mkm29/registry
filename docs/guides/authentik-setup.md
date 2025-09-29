# Authentik Setup Guide

This guide covers the complete setup and configuration of Authentik authentication server integrated with Traefik.

## Prerequisites

- Traefik stack running and accessible
- Domain name configured (e.g., `auth.yourdomain.com`)
- Docker networks created

## Initial Setup

### 1. Create the auth network

```bash
docker network create auth
```

### 2. Start Authentik

```bash
cd auth/
docker compose up -d
```

### 3. Complete initial setup

- Navigate to <https://auth.yourdomain.com/if/flow/initial-setup/>
- Create the admin user (username: akadmin)
- Set a secure password

## Configuration in Authentik

After initial setup, you need to configure Authentik for Traefik integration:

### 1. Create a Provider

- Go to Applications → Providers
- Click "Create" and select "Proxy Provider"
- Name: `traefik-forward-auth`
- Authorization flow: `default-provider-authorization-explicit-consent`
- Mode: Forward auth (single application)
- External host: `https://auth.yourdomain.com`

### 2. Create an Application

- Go to Applications → Applications
- Click "Create"
- Name: `Traefik Forward Auth`
- Slug: `traefik-forward-auth`
- Provider: Select the provider created above

### 3. Create an Outpost

- Go to Applications → Outposts
- Click "Create"
- Name: `traefik`
- Type: Proxy
- Applications: Select `Traefik Forward Auth`

## Protecting Services with Authentik

To protect a service with Authentik authentication, modify its router configuration in Traefik:

### Example: Protecting Grafana

Edit `/traefik/config/dynamic/monitoring.yml`:

```yaml
http:
  routers:
    grafana:
      rule: "Host(`grafana.yourdomain.com`)"
      service: grafana
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers
        - authentik  # Add this instead of auth-basic
        - grafana-headers
```

### Example: Protecting a new service

```yaml
http:
  routers:
    my-service:
      rule: "Host(`service.yourdomain.com`)"
      service: my-service
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers
        - authentik  # This enables Authentik authentication
```

## Managing Access

In Authentik, you can:

### 1. Create Groups

- Admin group for full access
- Viewer group for read-only access
- Service-specific groups

### 2. Create Policies

- Time-based access
- IP-based restrictions
- Group membership requirements

### 3. Bind Policies to Applications

- Different services can have different access requirements
- Users can have different permissions per service

## Secret Management with SOPS

This project uses SOPS for secret management. See the [SOPS Configuration Guide](../configuration/sops.md) for details on:

- Encrypting/decrypting `.secrets.env` files
- AGE key management
- Best practices for secret handling

## Environment Variables

Key variables in `.secrets.env`:

- `PG_PASS`: PostgreSQL password (auto-generated)
- `AUTHENTIK_SECRET_KEY`: Secret key for Authentik (auto-generated)
- `AUTHENTIK_EMAIL__*`: Email configuration for notifications
- `COMPOSE_PORT_HTTP/HTTPS`: Ports for direct access (we use Traefik instead)

## Troubleshooting

### 1. Check Authentik logs

```bash
docker logs authentik-server
docker logs authentik-worker
```

### 2. Verify network connectivity

- Ensure Traefik and Authentik are on the same `auth` network
- Check that services can reach `authentik-server:9000`

### 3. Common issues

- Clear browser cookies if experiencing redirect loops
- Ensure the external host in the provider matches your domain
- Check that all required headers are being passed through

### 4. SOPS-related issues

- Verify AGE keys are properly configured
- Check file format specifications for `.env` files
- Ensure encrypted files are properly decrypted before starting services

## Architecture

For detailed architecture information including Mermaid diagrams and service relationships, see the [Authentication Stack](../stacks/authentik.md) documentation.

## Related Documentation

- [Authentication Stack Architecture](../stacks/authentik.md)
- [SOPS Configuration Guide](../configuration/sops.md)
- [Traefik Stack Setup](../stacks/traefik.md)
