# Creating Custom Scopes in Authentik - Correct Method

## Important: How Scopes Work in Authentik

In Authentik, scopes are not created as separate objects. Instead:

- **Property Mappings** of type "Scope Mapping" automatically become available as scopes
- Scopes are managed directly in the OAuth Provider configuration
- The "Scope name" field in the Property Mapping becomes the scope identifier

## Step 1: Create a Scope Mapping

1. **Navigate to Property Mappings**:

   - Go to **Customization** → **Property Mappings**

1. **Create New Property Mapping**:

   - Click **Create**
   - Select **Scope Mapping** as the type (this is crucial!)

1. **Configure the Scope Mapping**:

   ```
   Name: Grafana Email Endpoint Handler
   Scope name: grafana_emails
   Description: Handle Grafana /emails endpoint requests
   ```

   **Important**: The "Scope name" field is what creates the actual scope that can be used in OAuth

1. **Add the Expression**:

   ```python
   # This expression runs when the scope is requested
   return [{
       "email": request.user.email,
       "primary": True,
       "verified": True
   }]
   ```

1. **Save the Property Mapping**

## Step 2: Add the Scope to Your OAuth Provider

1. **Navigate to Your OAuth Provider**:

   - Go to **Applications** → **Providers**
   - Click on your "Grafana OAuth" provider

1. **Configure Scopes**:

   - Scroll down to the **Scopes** section
   - You should now see `grafana_emails` in the available scopes list
   - Move it to the selected scopes
   - Your selected scopes should include:
     - `openid`
     - `profile`
     - `email`
     - `grafana_emails`

1. **Save the Provider**

## Step 3: Alternative Approach - Modify Existing Email Scope

Instead of creating a new scope, you could modify how the existing email scope behaves:

1. **Find Existing Email Mapping**:

   - Go to **Customization** → **Property Mappings**
   - Look for mappings related to email (usually named something like "OAuth2: email")

1. **Create a Custom Email Mapping**:

   - Click **Create** → **Scope Mapping**
   - Name: `Custom Email Scope`
   - Scope name: `email_custom`
   - Expression:

   ```python
   # Check if Grafana is requesting /emails endpoint
   if hasattr(request, 'http_request') and '/emails' in request.http_request.path:
       return [{
           "email": request.user.email,
           "primary": True,
           "verified": True
       }]
   # Default email response
   return request.user.email
   ```

## Step 4: OAuth2 Provider Advanced Settings

In your OAuth provider settings, you might also need to:

1. **Check Advanced Protocol Settings**:

   - Include claims in id_token: ✓
   - This ensures the email data is included in the token

1. **Token Validity**:

   - Set appropriate token lifetimes

## Understanding Authentik's Scope System

- **Scope Mapping**: A Property Mapping with type "Scope Mapping" automatically creates a scope
- **Scope Name**: The "scope name" field in the mapping IS the scope identifier
- **No Separate Scope Objects**: Unlike some other identity providers, Authentik doesn't have separate scope objects
- **Automatic Availability**: Once you create a Scope Mapping, it automatically appears in OAuth providers

## Testing Your Custom Scope

1. **Check Available Scopes**:

   - In your OAuth provider, the custom scope should appear in the available scopes list
   - If it doesn't appear, refresh the page or check that the Property Mapping type is "Scope Mapping"

1. **Update Grafana Configuration**:

   ```ini
   [auth.generic_oauth]
   scopes = openid email profile grafana_emails
   ```

## If This Doesn't Work: Alternative Solutions

### Option 1: Use Provider Flow Customization

Some versions of Authentik allow customizing the OAuth flow:

1. Go to **Flows & Stages** → **Flows**
1. Find the OAuth2 authorization flow
1. Add custom stages to handle the /emails endpoint

### Option 2: Custom OAuth2 Provider

Create a custom OAuth2 provider class (requires Authentik customization):

- This is more complex and requires modifying Authentik's code
- Not recommended unless you're comfortable with Django/Python

### Option 3: Proxy/Middleware Solution

Use Traefik to intercept and modify the request:

- Strip the `/emails` suffix
- Or redirect `/emails` requests to the regular userinfo endpoint
