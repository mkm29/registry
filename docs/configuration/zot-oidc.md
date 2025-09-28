# Zot Registry OIDC Authentication with Authentik

## Overview

This document describes how Zot registry is configured to use OpenID Connect (OIDC) authentication with Authentik.

## Configuration

### Zot Configuration

The Zot registry is configured with both htpasswd and OIDC authentication in `config/config.yaml`:

```yaml
auth:
  htpasswd:
    path: /etc/zot/htpasswd
  failDelay: 5
  openid:
    providers:
      oidc:
        name: "authentik"
        issuer: https://auth.smigula.io/application/o/registry/
        clientid: CCQHiOCoO3922YxXn4zCKADuJPYafy5u8EAw34gg
        clientsecret: <your-client-secret>
        scopes:
          - openid
          - profile
          - email
          - groups
```

### Important URLs

- **OIDC Discovery**: https://auth.smigula.io/application/o/registry/.well-known/openid-configuration
- **Authorization**: https://auth.smigula.io/application/o/authorize/
- **Token**: https://auth.smigula.io/application/o/token/
- **UserInfo**: https://auth.smigula.io/application/o/userinfo/
- **JWKS**: https://auth.smigula.io/application/o/registry/jwks/

## Authentication Flow

1. **Web UI Access**: When accessing the Zot web UI at https://registry.smigula.io/home, users will be redirected to Authentik for authentication
1. **API Access**: The registry API supports both:
   - Basic auth using htpasswd (for backward compatibility)
   - OIDC tokens from Authentik

## Docker Client Authentication

### Using OIDC Token

1. First, obtain an access token from Authentik
1. Use the token with docker login:
   ```bash
   docker login registry.smigula.io -u <username> -p <access-token>
   ```

### Using Basic Auth (Fallback)

The htpasswd authentication remains available:

```bash
docker login registry.smigula.io -u smigula -p <password>
```

## Troubleshooting

### Common Issues

1. **404 on OIDC Discovery**

   - Ensure the issuer URL includes the trailing slash: `https://auth.smigula.io/application/o/registry/`
   - Verify the application slug in Authentik matches "registry"

1. **Invalid Client Credentials**

   - Double-check the client ID and secret in Authentik
   - Ensure the client secret hasn't been rotated

1. **Scope Issues**

   - Zot requires: openid, profile, email, groups
   - Verify these scopes are enabled in the Authentik application

### Logs

Check Zot logs for OIDC errors:

```bash
docker logs registry | grep -i "oidc\|openid\|auth"
```

## Security Considerations

1. **Client Secret**: The OIDC client secret is stored in plain text in the config. Consider:

   - Using environment variable substitution
   - Implementing secret management
   - Restricting file permissions

1. **Dual Authentication**: Both htpasswd and OIDC are active, providing:

   - Fallback authentication method
   - Gradual migration path
   - Emergency access if OIDC fails

## Future Enhancements

1. **Remove htpasswd**: Once OIDC is proven stable, consider removing htpasswd authentication
1. **Group-based Access**: Implement authorization based on Authentik groups
1. **Token Refresh**: Implement automatic token refresh for long-running operations

## Related Documentation

- **[Registry Stack Architecture](../stacks/registry.md)** - Complete registry setup guide
- **[Authentik Setup Guide](../guides/authentik-setup.md)** - Identity provider configuration
- **[Zot Registry Configuration](zot-registry.md)** - Complete registry configuration reference