# Grafana OAuth with Authentik - Complete Implementation Guide

## Overview

This guide provides the complete solution for implementing OAuth authentication between Grafana 12.0.2 and Authentik, including the workaround for Grafana's /emails endpoint bug.

## The Problem

Grafana 12.0.2 has a hardcoded bug where it:

- Appends `/emails` to the configured OAuth userinfo endpoint
- Expects a specific JSON array response format
- This causes "Login failed InternalError" when using standard OAuth providers

## Solution Overview

We need to:

1. Configure Authentik to handle the /emails endpoint
1. Set up proper OAuth provider and application in Authentik
1. Configure Grafana with correct OAuth settings
1. Ensure proper group mappings for role-based access

## Step-by-Step Implementation

### Part 1: Create OAuth Provider in Authentik

1. **Login to Authentik** at https://auth.smigula.io

1. **Create OAuth2/OpenID Provider**:

   - Go to **Applications** → **Providers** → **Create**
   - Select **OAuth2/OpenID Provider**
   - Configure:
     ```
     Name: Grafana OAuth
     Client type: Confidential
     Client ID: lxEIE09Ya7A8m2PSAIMpLVLMpFBtHQMwxLPC2KlE
     Client Secret: [Generated - save this for later]
     Redirect URIs: https://grafana.smigula.io/login/generic_oauth
     Signing Key: authentik Self-signed Certificate
     ```
   - Under **Advanced protocol settings**:
     ```
     Subject mode: Based on the User's hashed ID
     Include claims in id_token: ✓ (checked)
     Token validity: 86400
     Scopes: openid, profile, email
     ```

### Part 2: Handle the /emails Endpoint Bug

1. **Create Custom Property Mapping**:

   - Go to **Customization** → **Property Mappings** → **Create**
   - Select **Scope Mapping**
   - Configure:
     ```
     Name: Grafana Emails Handler
     Scope name: grafana_emails
     Description: Handle Grafana /emails endpoint requests
     ```
   - Expression:
     ```python
     # Handle Grafana's /emails endpoint bug
     if 'request' in locals() and hasattr(request, 'context'):
         # This mapping handles the email data for Grafana
         return [{
             "email": user.email,
             "primary": True,
             "verified": True
         }]
     return user.email
     ```

1. **Create Custom Scope**:

   - Go to **System** → **Scopes** → **Create**
   - Configure:
     ```
     Name: grafana-emails
     Display name: Grafana Email Endpoint
     Description: Provides email data for Grafana /emails endpoint
     ```
   - Property mappings: Select **Grafana Emails Handler**

1. **Update OAuth Provider**:

   - Edit the **Grafana OAuth** provider
   - Add `grafana-emails` to the selected scopes
   - Ensure these scopes are selected: `openid`, `profile`, `email`, `grafana-emails`

### Part 3: Create Authentik Application

1. **Create Application**:
   - Go to **Applications** → **Applications** → **Create**
   - Configure:
     ```
     Name: Grafana
     Slug: grafana
     Provider: Grafana OAuth (select from dropdown)
     Launch URL: https://grafana.smigula.io
     ```

### Part 4: Configure Groups for Role Mapping

1. **Create Groups** (if not already existing):
   - Go to **Directory** → **Groups** → **Create**
   - Create:
     - `Grafana Admins` - Members get Admin role in Grafana
     - `Grafana Editors` - Members get Editor role in Grafana
     - Default users get Viewer role

### Part 5: Configure Grafana

1. **Update Grafana Configuration** (`/monitoring/grafana/grafana.ini`):

   ```ini
   [auth.generic_oauth]
   enabled = true
   name = Authentik
   icon = signin
   client_id = lxEIE09Ya7A8m2PSAIMpLVLMpFBtHQMwxLPC2KlE
   scopes = openid email profile grafana-emails
   empty_scopes = false
   email_claim = email
   login_claim = preferred_username
   name_claim = name
   auth_url = https://auth.smigula.io/application/o/authorize/
   token_url = https://auth.smigula.io/application/o/token/
   api_url = https://auth.smigula.io/application/o/userinfo/
   signout_redirect_url = https://auth.smigula.io/application/o/grafana/end-session/
   role_attribute_path = contains(groups[*], 'Grafana Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'
   groups_attribute_path = groups
   allow_sign_up = true
   auto_login = false
   use_pkce = true
   use_refresh_token = true
   ```

1. **Set Client Secret** in `.grafana-secrets.env`:

   ```
   GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=YOUR_CLIENT_SECRET_FROM_AUTHENTIK
   ```

1. **Ensure Traefik Configuration** allows direct access to Grafana (no auth middleware)

### Part 6: Test the Configuration

1. **Restart Grafana**:

   ```bash
   docker-compose restart grafana
   ```

1. **Test OAuth Flow**:

   - Navigate to https://grafana.smigula.io
   - Click "Sign in with Authentik"
   - Authenticate in Authentik
   - Should redirect back to Grafana and be logged in

1. **Verify Role Mapping**:

   - Users in `Grafana Admins` group should have Admin role
   - Users in `Grafana Editors` group should have Editor role
   - Other users should have Viewer role

## Alternative Solutions

### If the Property Mapping doesn't work:

1. **Traefik Path Rewrite** (add to Authentik's router):

   ```yaml
   middlewares:
     - grafana-emails-rewrite

   # In middlewares section:
   grafana-emails-rewrite:
     replacePathRegex:
       regex: "^(.*)/emails$"
       replacement: "$1"
   ```

1. **Wait for Grafana Fix**:

   - Since 12.0.2 is the latest release, we must use workarounds
   - Monitor Grafana releases for a fix to this bug

1. **Custom Authentik Flow**:

   - Create a custom flow to handle /emails endpoint
   - More complex but provides full control

## Troubleshooting

### Common Issues:

1. **"Login failed InternalError"**:

   - Check Grafana logs for the exact error
   - Verify the /emails endpoint is being handled
   - Ensure all scopes are properly configured

1. **"Invalid redirect_uri"**:

   - Verify the redirect URI in Authentik matches exactly
   - Should be: `https://grafana.smigula.io/login/generic_oauth`

1. **Role mapping not working**:

   - Ensure users are members of the appropriate groups
   - Check that `groups` claim is included in the token
   - Verify the role_attribute_path expression

### Debug Commands:

```bash
# Check Grafana logs
docker logs grafana -f

# Test OAuth endpoints directly
curl -H "Authorization: Bearer TOKEN" https://auth.smigula.io/application/o/userinfo/
curl -H "Authorization: Bearer TOKEN" https://auth.smigula.io/application/o/userinfo/emails

# Check Authentik logs
docker logs authentik-server -f
```

## Summary

This implementation provides:

- Proper OAuth authentication (not just proxy headers)
- Workaround for Grafana's /emails endpoint bug
- Role-based access control through group mappings
- Single Sign-On experience with Authentik

The key is creating the custom Property Mapping and Scope in Authentik to handle the /emails endpoint that Grafana incorrectly appends to the userinfo URL.
