# Authentik Configuration for Grafana /emails Endpoint

This guide provides step-by-step instructions to configure Authentik to handle Grafana 12.0.2's hardcoded /emails endpoint bug.

## Step 1: Create Custom Property Mapping

1. Log into Authentik Admin Interface
2. Navigate to **Customization** → **Property Mappings**
3. Click **Create** → **Scope Mapping**
4. Configure the mapping:
   - **Name**: `Grafana Email Endpoint`
   - **Scope name**: `grafana_emails`
   - **Description**: `Handle Grafana /emails endpoint requests`
   - **Expression**:
```python
   # Check if this is a request to the /emails endpoint
if hasattr(request, 'http_request') and request.http_request.path.endswith('/emails'):
   # Return email data in the format Grafana expects
   return [{
      "email": request.user.email,
      "primary": True,
      "verified": True
   }]
# For regular userinfo requests, return email normally
return request.user.email
```

## Step 2: Create Custom Scope

1. Navigate to **System** → **Scopes**
2. Click **Create**
3. Configure the scope:
   - **Name**: `grafana-email`
   - **Display name**: `Grafana Email Compatibility`
   - **Description**: `Provides email data in format expected by Grafana /emails endpoint`
   - **Property mappings**: Select **Grafana Email Endpoint** (created in Step 1)

## Step 3: Update OAuth Provider

1. Navigate to **Applications** → **Providers**
2. Find and edit your **Grafana OAuth** provider
3. In the **Scopes** section:
   - Add `grafana-email` to the selected scopes
   - Ensure `openid`, `profile`, `email`, and `grafana-email` are all selected
4. Save the provider

## Step 4: Alternative Property Mapping (More Robust)

If the above doesn't work, create a more comprehensive Property Mapping:

1. Create a new **Scope Mapping**:
   - **Name**: `Grafana Email Handler`
   - **Scope name**: `grafana_email_handler`
   - **Expression**:
   ```python
   # Import required modules
   import json
   from django.http import JsonResponse
   
   # Check if this is an emails endpoint request
   if hasattr(request, 'http_request'):
       path = request.http_request.path
       if path.endswith('/emails'):
           # Return array of email objects
           emails = [{
               "email": request.user.email,
               "primary": True,
               "verified": request.user.email_verified if hasattr(request.user, 'email_verified') else True,
               "visibility": "public"
           }]
           # For additional emails if user has them
           if hasattr(request.user, 'additional_emails'):
               for additional_email in request.user.additional_emails:
                   emails.append({
                       "email": additional_email,
                       "primary": False,
                       "verified": True,
                       "visibility": "public"
                   })
           return emails
   
   # Default return for non-emails endpoint
   return request.user.email
   ```

## Step 5: Create URL Path Override (Alternative Approach)

If custom scopes don't work, you can create a custom view in Authentik:

1. Navigate to **Flows & Stages** → **Flows**
2. Create a new flow for handling /emails endpoint
3. Use an **Expression Policy** to detect /emails requests
4. Return the expected JSON structure

## Step 6: Verify Configuration

1. Test the userinfo endpoint directly:
   ```bash
   # Get an access token first, then:
   curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
        https://auth.smigula.io/application/o/userinfo/
   ```

2. Test the emails endpoint:
   ```bash
   curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
        https://auth.smigula.io/application/o/userinfo/emails
   ```

## Step 7: Update Grafana Configuration (if needed)

If you need to adjust Grafana's configuration after implementing the fix:

```ini
[auth.generic_oauth]
# Existing configuration remains the same
# But ensure these scopes are included:
scopes = openid email profile grafana-email
```

## Troubleshooting

### If /emails endpoint still returns 404:

1. Check Authentik logs for the request path
2. Verify the Property Mapping expression is executing
3. Consider implementing a middleware in Traefik to rewrite the URL

### If Grafana still shows InternalError:

1. Enable debug logging in Grafana:
   ```ini
   [log]
   level = debug
   [auth.generic_oauth]
   # Your existing config
   ```

2. Check if Grafana is receiving the expected response format

### Expected Response Format

Grafana expects the /emails endpoint to return:
```json
[
  {
    "email": "user@example.com",
    "primary": true,
    "verified": true
  }
]
```

## Notes

- This workaround addresses a bug in Grafana 12.0.2
- The bug is fixed in Grafana 12.1+
- Consider upgrading Grafana as a long-term solution