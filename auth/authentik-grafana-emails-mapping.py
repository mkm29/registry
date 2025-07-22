# Authentik Property Mapping for Grafana /emails Endpoint
# This script should be used in a Property Mapping of type "Scope Mapping"
# Name: Grafana Email Endpoint Handler
# Scope name: email_endpoint

# The main issue is that Grafana 12.0.2 appends /emails to the userinfo endpoint
# and expects a specific JSON structure in response

# Check if this is a request context (not just attribute evaluation)
if 'request' in locals() and hasattr(request, 'context'):
    # Get the original request path if available
    request_path = request.context.get('request_path', '')
    
    # Also check if we're in an OAuth context with http_request
    if hasattr(request, 'http_request') and hasattr(request.http_request, 'path'):
        request_path = request.http_request.path
    
    # Check if this is an /emails endpoint request
    if '/emails' in request_path or request_path.endswith('/emails'):
        # Return the format Grafana expects for /emails endpoint
        return [{
            "email": user.email,
            "primary": True,
            "verified": True,
            "visibility": "public"
        }]

# For regular email attribute requests, return the email normally
return user.email