# Authentik Expression Policy for Grafana /emails Endpoint
# This can be used in an Expression Policy to handle /emails requests
# Policy Name: Grafana Emails Endpoint Handler

# Import required modules
from django.http import JsonResponse
import json

# Get the request path
path = request.http_request.path if hasattr(request, "http_request") else ""

# Check if this is a request to the /emails endpoint
if path.endswith("/userinfo/emails") or path.endswith("/emails"):
    # Create the response Grafana expects
    emails_data = [
        {
            "email": request.user.email,
            "primary": True,
            "verified": True,
            "visibility": "public",
        }
    ]

    # You could also check for additional emails
    # if hasattr(request.user, 'emailaddress_set'):
    #     for email in request.user.emailaddress_set.all():
    #         if email.email != request.user.email:
    #             emails_data.append({
    #                 "email": email.email,
    #                 "primary": False,
    #                 "verified": email.verified,
    #                 "visibility": "public"
    #             })

    # Set the response in the context
    request.context["oauth_email_response"] = emails_data

    # Allow the request to continue
    return True

# For non-emails endpoints, continue normally
return True
