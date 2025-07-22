# Setting up Grafana with Authentik OAuth

## 1. Create OAuth2/OpenID Provider in Authentik

1. Go to Applications → Providers → Create
2. Select "OAuth2/OpenID Provider"
3. Configure:
   - Name: `Grafana OAuth`
   - Client type: Confidential
   - Client ID: (auto-generated or custom)
   - Client Secret: (copy this for Grafana config)
   - Redirect URIs: `https://grafana.smigula.io/login/generic_oauth`
   - Signing Key: Select available key
   - Subject mode: Based on the User's hashed ID
   - Include claims in id_token: ✓ (REQUIRED)
   - Scopes: Select `openid`, `profile`, `email`
   - Under "Advanced protocol settings":
     - Include claims in id_token: ✓ (must be checked)
     - Token validity: (keep defaults or adjust as needed)

## 2. Create Application in Authentik

1. Go to Applications → Applications → Create
2. Configure:
   - Name: `Grafana`
   - Slug: `grafana`
   - Provider: Select "Grafana OAuth" (created above)
   - Launch URL: `https://grafana.smigula.io`

## 3. Configure Grafana

Add these environment variables to your Grafana container:

```yaml
environment:
  - GF_AUTH_GENERIC_OAUTH_ENABLED=true
  - GF_AUTH_GENERIC_OAUTH_NAME=Authentik
  - GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP=true
  - GF_AUTH_GENERIC_OAUTH_CLIENT_ID=<your-client-id>
  - GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=<your-client-secret>
  - GF_AUTH_GENERIC_OAUTH_SCOPES=openid profile email
  - GF_AUTH_GENERIC_OAUTH_AUTH_URL=https://auth.smigula.io/application/o/authorize/
  - GF_AUTH_GENERIC_OAUTH_TOKEN_URL=https://auth.smigula.io/application/o/token/
  - GF_AUTH_GENERIC_OAUTH_API_URL=https://auth.smigula.io/application/o/userinfo/
  - GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH=contains(groups[*], 'Grafana Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'
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