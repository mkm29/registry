# Grafana 12.0.2 OAuth /emails Endpoint Workaround

## The Problem

Grafana 12.0.2 has a hardcoded bug where it:

1. Always appends `/emails` to the userinfo endpoint
1. Ignores the `email_claim` configuration
1. Uses hardcoded `user:email` scope instead of configured scopes

## Solution: Custom OIDC Provider Configuration

Since we can't fix Grafana's behavior, we need to configure Authentik to handle the `/emails` endpoint.

### Option 1: Use a Custom Scope Mapping (Recommended)

1. In Authentik, create a custom Property Mapping:

   - Go to Customization → Property Mappings → Create
   - Name: `Grafana Email Endpoint`
   - Object field: `email`
   - Expression:

   ```python
   # Return email in the format Grafana expects for /emails endpoint
   return [{"email": request.user.email, "primary": True, "verified": True}]
   ```

1. Create a custom Scope:

   - Go to System → Scopes → Create
   - Name: `grafana-email`
   - Description: `Grafana email endpoint compatibility`
   - Property mappings: Select "Grafana Email Endpoint"

1. Update your OAuth provider:

   - Add the `grafana-email` scope to your provider
   - Ensure it's included in the available scopes

### Option 2: Use Expression Policy

Create an Expression Policy that handles the `/emails` path:

1. Go to System → Policies → Create → Expression Policy
1. Name: `Grafana Emails Handler`
1. Expression:

```python
import re
if re.match(r'.*/emails$', request.http_request.path):
    return True
return False
```

### Option 3: Nginx/Traefik Rewrite

Add a rewrite rule in your reverse proxy to redirect `/emails` requests:

For Traefik:

```yaml
middlewares:
  grafana-oauth-fix:
    replacePathRegex:
      regex: "^(.*)/emails$"
      replacement: "$1"
```

### Option 4: Wait for Future Grafana Release

Since Grafana 12.0.2 is the latest release, we must use one of the workarounds above until Grafana releases a fix for this bug in a future version.

## Current Status

Currently using standard OAuth configuration but hitting the /emails bug. The recommended solution is Option 1 (custom scope mapping) as it works within Authentik's framework.
