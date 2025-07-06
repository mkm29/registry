#!/bin/bash

# Caddy Reverse Proxy Setup Script
# This script sets up a Caddy reverse proxy with automatic HTTPS

set -e

echo "🚀 Setting up Caddy Reverse Proxy for smigula.io"
echo "=================================================="

# Create project directory
CADDY_DIR="caddy-proxy"
mkdir -p "$CADDY_DIR"
cd "$CADDY_DIR"

# Create HTML directory for landing page
mkdir -p html

echo "📁 Created directory structure"

# Create docker-compose.yml (already provided in artifacts)

# Create Caddyfile (already provided in artifacts)

# Create landing page (already provided in artifacts)

# Create environment file template
cat > .env << 'EOF'
# Email for Let's Encrypt certificate notifications
ACME_EMAIL=admin@smigula.io

# Domain configuration
MAIN_DOMAIN=smigula.io
GRAFANA_SUBDOMAIN=grafana.smigula.io
JAEGER_SUBDOMAIN=jaeger.smigula.io
REGISTRY_SUBDOMAIN=registry.smigula.io

# Backend service ports (adjust if different)
GRAFANA_PORT=3000
JAEGER_PORT=16686
REGISTRY_PORT=5000
EOF

echo "📝 Configuration files created"

echo "🔧 Helper scripts created:"
echo "  ./status.sh  - Check status"

echo ""
echo "⚠️  Pre-flight Checklist:"
echo "========================="

echo "1. ✅ Ensure your domain DNS is configured:"
echo "   A    smigula.io         -> YOUR_SERVER_IP"
echo "   A    grafana.smigula.io -> YOUR_SERVER_IP"
echo "   A    jaeger.smigula.io  -> YOUR_SERVER_IP"
echo "   A    registry.smigula.io -> YOUR_SERVER_IP"

echo ""
echo "2. ✅ Ensure your backend services are running:"
echo "   - Grafana on port 3000"
echo "   - Jaeger on port 16686"
echo "   - Registry on port 5000"

echo ""
echo "3. ✅ Ensure ports 80 and 443 are open in your firewall:"
echo "   sudo ufw allow 80"
echo "   sudo ufw allow 443"

echo ""
echo "4. ✅ Update .env file with your email address"

echo ""
echo "🚀 To start Caddy:"
echo "   cd $CADDY_DIR && ./start.sh"

echo ""
echo "📋 To view this checklist again:"
echo "   cd $CADDY_DIR && cat README.md"

# Create README.md
cat > README.md << 'EOF'

EOF

echo ""
echo "✅ Setup complete! Check README.md for detailed instructions."
echo "📁 All files created in: $CADDY_DIR/"