# Documentation Index

This directory contains detailed documentation for the Multi-Stack Container Infrastructure.

## Quick Navigation

### Getting Started

- **[Quick Start Guide](guides/quick-start.md)** - Complete installation and setup guide
- **[Rootless Docker Setup](configuration/rootless-docker.md)** - Docker installation for security

### Stack Documentation

Individual stack guides with architecture diagrams and management commands:

- **[Traefik Stack](stacks/traefik.md)** - Reverse proxy with automatic HTTPS
- **[Authentication Stack](stacks/authentik.md)** - Unified identity provider with SSO
- **[Monitoring Stack](stacks/monitoring.md)** - Complete observability platform
- **[Storage Stack](stacks/storage.md)** - S3-compatible object storage
- **[Registry Stack](stacks/registry.md)** - OCI-compliant container registry
- **[Media Stack](stacks/media.md)** - Automated media server with Plex

### Configuration Guides

Detailed configuration and setup instructions:

- **[Traefik Configuration](configuration/traefik.md)** - Reverse proxy setup and migration guide
- **[CFSSL Configuration](configuration/cfssl.md)** - TLS certificate generation
- **[Zot Registry Configuration](configuration/zot-registry.md)** - Registry setup and options
- **[Zot OIDC Setup](configuration/zot-oidc.md)** - OIDC authentication with Authentik
- **[SOPS Configuration](configuration/sops.md)** - Secret management with encryption

### Operations Guides

Day-to-day operations and maintenance:

- **[Quick Start Guide](guides/quick-start.md)** - Complete installation and setup guide
- **[Authentik Setup Guide](guides/authentik-setup.md)** - Identity provider configuration
- **[Testing Guide](guides/testing.md)** - Registry testing procedures
- **[Monitoring Guide](guides/monitoring.md)** - Observability and query examples
- **[Troubleshooting Guide](guides/troubleshooting.md)** - Common issues and solutions

## Document Structure

```
docs/
├── README.md                    # This index file
├── stacks/                      # Individual stack documentation
│   ├── traefik.md
│   ├── authentik.md
│   ├── monitoring.md
│   ├── storage.md
│   ├── registry.md
│   └── media.md
├── configuration/               # Configuration guides
│   ├── rootless-docker.md
│   ├── traefik.md
│   ├── cfssl.md
│   ├── zot-registry.md
│   ├── zot-oidc.md
│   └── sops.md
└── guides/                      # Operation guides
    ├── quick-start.md
    ├── authentik-setup.md
    ├── testing.md
    ├── monitoring.md
    └── troubleshooting.md
```

## Main README

For the complete overview and architecture, see the [main README](../README.md).