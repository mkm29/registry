# Setting Up Applications in Authentik

## For Each Service You Want to Protect

### 1. Create a Proxy Provider
- Go to Applications → Providers → Create
- Select "Proxy Provider"
- Configure:
  - Name: `<Service> Proxy` (e.g., "Alloy Proxy")
  - Authorization flow: Use default or create custom
  - External host: `https://<service>.smigula.io`
  - Internal host: Leave empty (Traefik handles routing)

### 2. Create an Application
- Go to Applications → Applications → Create
- Configure:
  - Name: `<Service>` (e.g., "Alloy")
  - Slug: `<service>` (must match subdomain, e.g., "alloy")
  - Provider: Select the proxy provider created above
  - Launch URL: `https://<service>.smigula.io`

### 3. Configure the Outpost
- Go to Applications → Outposts
- Edit existing or create new proxy outpost
- Add your application to the outpost

### 4. Update Traefik Configuration
In your service's Traefik configuration, use the `authentik` middleware:

```yaml
middlewares:
  - security-headers
  - authentik
```

## Services to Configure

- [ ] Alloy (alloy.smigula.io)
- [ ] Prometheus (prometheus.smigula.io)
- [ ] Dozzle (dozzle.smigula.io)

## Testing
After configuration, accessing the service should redirect to Authentik for login.