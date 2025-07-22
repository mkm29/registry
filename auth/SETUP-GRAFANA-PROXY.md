# Setting up Grafana with Authentik Proxy Authentication

Since Grafana 12.0.2 has a bug with OAuth /emails endpoint, we're using proxy authentication through Traefik.

## 1. Create Proxy Provider in Authentik

1. Go to Applications → Providers → Create
2. Select "Proxy Provider"
3. Configure:
   - Name: `Grafana Proxy`
   - Authorization flow: Select default authorization flow
   - Type: Forward auth (single application)
   - External host: `https://grafana.smigula.io`

## 2. Create Application in Authentik

1. Go to Applications → Applications → Create
2. Configure:
   - Name: `Grafana`
   - Slug: `grafana`
   - Provider: Select "Grafana Proxy" (created above)
   - Launch URL: `https://grafana.smigula.io`

## 3. Create/Update Outpost

1. Go to Applications → Outposts
2. Either create new or edit existing outpost
3. Ensure the outpost includes:
   - The "Grafana" application
   - Type: Proxy
   - Configuration: Use default

## 4. How it Works

1. User visits https://grafana.smigula.io
2. Traefik's authentik middleware intercepts the request
3. If not authenticated, redirects to Authentik login
4. After login, Authentik passes headers to Grafana:
   - X-authentik-username
   - X-authentik-email
   - X-authentik-name
   - X-authentik-groups
5. Grafana creates/updates user based on headers

## 5. Verify Setup

Test with curl:
```bash
curl -I https://grafana.smigula.io
# Should redirect to auth.smigula.io if not authenticated
```

## 6. Role Mapping (Optional)

To map Authentik groups to Grafana roles, create groups in Authentik:
- `Grafana Admins` → Admin role
- `Grafana Editors` → Editor role
- Others → Viewer role

Then configure Grafana to parse the groups header.