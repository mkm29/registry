# Fixing Grafana 12.0.2 OAuth /emails Endpoint Issue

## Problem

Grafana 12.0.2 has a bug where it automatically appends `/emails` to the OAuth userinfo endpoint, resulting in 404 errors when using Authentik.

## Solution Options

### Option 1: Use Forward Auth Instead (Recommended)

Instead of using OAuth, use Authentik's forward auth with Traefik:

1. In Traefik monitoring.yml, add authentik middleware to Grafana:

```yaml
grafana:
  middlewares:
    - security-headers
    - grafana-headers
    - authentik  # Add this
```

2. Update grafana.ini to disable OAuth:

```ini
[auth.generic_oauth]
enabled = false

[auth.proxy]
enabled = true
header_name = X-authentik-username
header_property = username
auto_sign_up = true
sync_ttl = 60
whitelist = 172.24.0.0/16
headers = "Email:X-authentik-email Name:X-authentik-name"
enable_login_token = false
```

### Option 2: Upgrade Grafana

The /emails endpoint bug is fixed in Grafana 12.1+. Update your docker-compose.yaml:

```yaml
grafana:
  image: registry.smigula.io/docker/grafana/grafana:12.1-latest
```

### Option 3: Use Grafana Enterprise (if available)

Grafana Enterprise has better OAuth implementation that doesn't have this bug.

### Option 4: Custom OAuth Proxy

Deploy an OAuth proxy (like oauth2-proxy) between Grafana and Authentik to handle the authentication flow properly.

## Current Workaround Status

The following approaches do NOT work in Grafana 12.0.2:

- Setting `api_url` to empty
- Using `use_id_token = true`
- Setting email attribute paths
- Disabling teams_url

This is because the /emails endpoint call is hardcoded in this specific version.

## Recommendation

Use Option 1 (Forward Auth) as it's the most reliable and doesn't require upgrading Grafana.
