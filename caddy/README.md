# Caddy Reverse Proxy for smigula.io

This directory contains a Caddy reverse proxy setup that provides automatic HTTPS certificates and proxies traffic to your backend services.

## Services

- **Main Domain**: [https://smigula.io](https://smigula.io) → Landing page
- **Grafana**: [https://grafana.smigula.io](https://grafana.smigula.io) → localhost:3000
- **Jaeger**: [https://jaeger.smigula.io](https://jaeger.smigula.io) → localhost:16686
- **Registry**: [https://registry.smigula.io](https://registry.smigula.io) → localhost:5000

## Quick Start

1. **Configure DNS** - Point all domains to your server's IP address
1. **Update .env** - Set your email address for certificate notifications
1. **Start services**: `./start.sh`
1. **Check status**: `./status.sh`

## DNS Configuration

Ensure these A records point to your server:

```bash
A    smigula.io         -> YOUR_SERVER_IP
A    grafana.smigula.io -> YOUR_SERVER_IP
A    jaeger.smigula.io  -> YOUR_SERVER_IP
A    registry.smigula.io -> YOUR_SERVER_IP
```

## Firewall

Ensure ports 80 and 443 are open:

```bash
sudo ufw allow 80
sudo ufw allow 443
```

## Backend Services

Ensure these services are running on your server:

- Grafana: [http://localhost:3000](http://localhost:3000)
- Jaeger: [http://localhost:16686](http://localhost:16686)
- Registry: [http://localhost:5000](http://localhost:5000)

## Certificate Provider

By default, this uses **Let's Encrypt** for automatic HTTPS certificates.

To switch to **ZeroSSL**, uncomment this line in the Caddyfile:

```bash
# acme_ca https://acme.zerossl.com/v2/DV90
```

And comment out the Let's Encrypt line:

```bash
acme_ca https://acme-v02.api.letsencrypt.org/directory
```

## Logs

- View all logs: `./logs.sh`
- Access logs are stored in `/data/logs/` inside the container
- Admin API: [http://localhost:2019](http://localhost:2019)

## Management Commands

```bash
./setup.sh   # Setup script to initialize environment
./status.sh  # Check status and certificates
```

## Troubleshooting

1. **Certificate issues**: Check logs and ensure DNS is properly configured
1. **Backend not accessible**: Verify services are running on expected ports
1. **Permission issues**: Ensure Caddy can bind to ports 80/443

## File Structure

```bash
.
├── docker-compose.yaml  # Docker Compose configuration
├── Caddyfile          # Caddy reverse proxy configuration
├── html/              # Landing page files
├── .env               # Environment variables
├── status.sh          # Status script
└── README.md          # This file
```
