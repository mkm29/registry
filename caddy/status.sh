#!/bin/bash
echo "📊 Caddy Status:"
echo "================"
docker-compose ps

echo ""
echo "🔗 Service URLs:"
echo "  Main site: https://smigula.io"
echo "  Grafana:   https://grafana.smigula.io"
echo "  Jaeger:    https://jaeger.smigula.io"
echo "  Registry:  https://registry.smigula.io"

echo ""
echo "📈 Certificate Status:"
curl -s http://localhost:2019/config/apps/tls/certificates | jq -r '.[] | "\(.names[0]): \(.not_after)"' 2>/dev/null || echo "Admin API not accessible or jq not installed"

echo ""
echo "🏥 Health Check:"
echo "Caddy Admin API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:2019/config/ || echo "Failed")"