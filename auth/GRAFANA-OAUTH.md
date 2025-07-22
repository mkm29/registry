# Setting up Grafana with Authentik OAuth

## 1. Create OAuth2/OpenID Provider in Authentik

1. Go to Applications → Providers → Create
2. Select "OAuth2/OpenID Provider"
3. Configure:
   - Name: `Grafana OAuth`
   - Client type: Confidential
   - Client ID: `lxEIE09Ya7A8m2PSAIMpLVLMpFBtHQMwxLPC2KlE` (or auto-generated)
   - Client Secret: (copy this for Grafana config)
   - Redirect URIs: `https://grafana.smigula.io/login/generic_oauth`
   - Signing Key: Select available key
   - Subject mode: Based on the User's hashed ID
   - Include claims in id_token: ✓ (REQUIRED)
   - Scopes: Select `openid`, `profile`, `email`
   - Under "Advanced protocol settings":
     - Include claims in id_token: ✓ (must be checked)
     - Token validity: (keep defaults or adjust as needed)
     - **IMPORTANT**: Ensure "Include User claims from scopes in id_token" is checked
     - Sub Mode: Based on the User's hashed ID

## 2. Create Application in Authentik

1. Go to Applications → Applications → Create
2. Configure:
   - Name: `Grafana`
   - Slug: `grafana`
   - Provider: Select "Grafana OAuth" (created above)
   - Launch URL: `https://grafana.smigula.io`

## 3. Configure Grafana

Grafana is configured via `grafana.ini` with the following OAuth settings:

```ini
[auth.generic_oauth]
enabled = true
name = Authentik
icon = signin
client_id = lxEIE09Ya7A8m2PSAIMpLVLMpFBtHQMwxLPC2KlE
# client_secret is set via environment variable
scopes = openid email profile
empty_scopes = false
email_claim = email
login_claim = preferred_username
name_claim = name
auth_url = https://auth.smigula.io/application/o/authorize/
token_url = https://auth.smigula.io/application/o/token/
api_url = https://auth.smigula.io/application/o/userinfo/
signout_redirect_url = https://auth.smigula.io/application/o/grafana/end-session/
# Role mapping
role_attribute_path = contains(groups[*], 'Grafana Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'
groups_attribute_path = groups
# Settings
allow_sign_up = true
use_pkce = true
use_refresh_token = true
```

The client secret is stored in `.grafana-secrets.env`:
```
GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=<your-client-secret>
```

## 4. Create Groups in Authentik (Optional)

For role mapping:
1. Go to Directory → Groups → Create
2. Create groups:
   - `Grafana Admins` - Members get Admin role
   - `Grafana Editors` - Members get Editor role
   - Others get Viewer role by default

## 5. Remove Traefik Auth Middleware for Grafana

Since Grafana will handle its own OAuth, remove the auth middleware from Traefik:

```yaml
grafana:
  rule: "Host(`grafana.smigula.io`)"
  service: grafana
  entryPoints:
    - websecure
  tls:
    certResolver: letsencrypt
  middlewares:
    - security-headers
    - grafana-headers
    # Remove: - authentik
```

## Testing

1. Restart Grafana with new environment variables
2. Visit https://grafana.smigula.io
3. Click "Sign in with Authentik"
4. Authenticate in Authentik
5. You should be redirected back to Grafana and logged in