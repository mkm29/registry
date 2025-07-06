# Local Docker Registry Mirror with TLS and Monitoring Stack (Rootless Docker)

This repository provides a complete setup for a local Docker registry that acts as a Docker Hub mirror (pull-through cache). The registry is secured with TLS using self-signed certificates and includes a full monitoring stack with Prometheus, Jaeger, and Grafana. This setup is optimized for **rootless Docker** with native Alloy installation for better security and performance.

- [Local Docker Registry Mirror with TLS and Monitoring Stack (Rootless Docker)](#local-docker-registry-mirror-with-tls-and-monitoring-stack-rootless-docker)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
    - [Required Software](#required-software)
    - [Optional Tools](#optional-tools)
    - [System Requirements](#system-requirements)
    - [Docker Hub Account](#docker-hub-account)
  - [Rootless Docker Setup](#rootless-docker-setup)
    - [1. Remove Regular Docker (if installed)](#1-remove-regular-docker-if-installed)
    - [2. Install Docker CE](#2-install-docker-ce)
    - [3. Install Rootless Docker](#3-install-rootless-docker)
    - [4. Start Rootless Docker](#4-start-rootless-docker)
    - [5. Configure Docker Daemon](#5-configure-docker-daemon)
  - [Install and Configure Alloy](#install-and-configure-alloy)
    - [1. Download and Install Alloy](#1-download-and-install-alloy)
    - [2. Create Alloy Configuration](#2-create-alloy-configuration)
    - [3. Create Systemd User Service](#3-create-systemd-user-service)
  - [Architecture](#architecture)
  - [Available Commands](#available-commands)
  - [Quick Start](#quick-start)
  - [CFSSL Configuration](#cfssl-configuration)
    - [1. Root CA Configuration (`cfssl/ca.json`)](#1-root-ca-configuration-cfsslcajson)
    - [2. Intermediate CA Configuration (`cfssl/intermediate-ca.json`)](#2-intermediate-ca-configuration-cfsslintermediate-cajson)
    - [3. Registry Certificate Configuration (`cfssl/registry.json`)](#3-registry-certificate-configuration-cfsslregistryjson)
    - [4. Certificate Profiles (`cfssl/cfssl.json`)](#4-certificate-profiles-cfsslcfssljson)
    - [Common Customizations](#common-customizations)
    - [Example for Local Development](#example-for-local-development)
  - [Certificate Generation with CFSSL](#certificate-generation-with-cfssl)
  - [Registry Configuration](#registry-configuration)
    - [Key Configuration Settings](#key-configuration-settings)
      - [Storage Configuration](#storage-configuration)
      - [HTTP/TLS Configuration](#httptls-configuration)
      - [Proxy Cache Configuration](#proxy-cache-configuration)
      - [Health Checks](#health-checks)
  - [Services Architecture](#services-architecture)
    - [Docker Registry (port 5000)](#docker-registry-port-5000)
    - [Jaeger (port 16686)](#jaeger-port-16686)
    - [Prometheus (port 9090)](#prometheus-port-9090)
    - [Loki (port 3100)](#loki-port-3100)
    - [Grafana Alloy (port 12345) - Native Installation](#grafana-alloy-port-12345---native-installation)
    - [Grafana (port 3000)](#grafana-port-3000)
  - [Docker Compose Configuration](#docker-compose-configuration)
  - [Testing the Registry](#testing-the-registry)
    - [Configure Docker to Trust the Registry](#configure-docker-to-trust-the-registry)
      - [Step 1: Configure TLS Trust](#step-1-configure-tls-trust)
        - [Option A: Configure Docker daemon certificates (Recommended)](#option-a-configure-docker-daemon-certificates-recommended)
        - [Option B: System-wide trust (macOS)](#option-b-system-wide-trust-macos)
      - [Step 2: Configure Docker Hub Mirror](#step-2-configure-docker-hub-mirror)
        - [Rootless Docker](#rootless-docker)
        - [macOS (Docker Desktop)](#macos-docker-desktop)
        - [Linux (Regular Docker)](#linux-regular-docker)
        - [Verify Mirror Configuration](#verify-mirror-configuration)
    - [Test Registry Access](#test-registry-access)
  - [Monitoring and Observability](#monitoring-and-observability)
    - [Grafana Dashboard](#grafana-dashboard)
    - [Prometheus Queries](#prometheus-queries)
    - [Jaeger Traces](#jaeger-traces)
    - [Loki Log Queries](#loki-log-queries)
  - [Management Commands](#management-commands)
    - [Docker Compose Operations](#docker-compose-operations)
    - [Registry Maintenance](#registry-maintenance)
    - [Alloy Management](#alloy-management)
  - [Security Considerations](#security-considerations)
  - [Troubleshooting](#troubleshooting)
    - [Rootless Docker Issues](#rootless-docker-issues)
    - [Alloy Issues](#alloy-issues)
    - [Volume Permission Issues](#volume-permission-issues)
    - [Certificate Issues](#certificate-issues)
    - [Registry Connection Issues](#registry-connection-issues)
    - [Metrics Not Appearing](#metrics-not-appearing)
  - [File Structure](#file-structure)
  - [Performance Tuning](#performance-tuning)
  - [References](#references)

## Overview

This setup creates a production-ready local Docker registry with:

- **Rootless Docker**: Enhanced security with user-namespace isolation
- **Docker Hub Mirror**: Acts as a pull-through cache that automatically intercepts and caches Docker Hub images
- **TLS Security**: Self-signed certificates using CFSSL with proper certificate chain
- **Bandwidth Optimization**: Caches images locally to reduce repeated downloads from Docker Hub
- **Native Alloy**: Grafana Alloy runs as a native systemd service for better Docker socket access
- **Distributed Tracing**: OpenTelemetry integration with Jaeger
- **Metrics Collection**: Prometheus scraping with pre-configured dashboards
- **Log Aggregation**: Loki for centralized log collection and querying
- **Visualization**: Grafana dashboards for monitoring registry performance and logs

When properly configured, all `docker pull` commands for Docker Hub images will automatically use your local registry mirror, significantly improving pull speeds and reducing bandwidth usage.

## Prerequisites

### Required Software

1. **CFSSL** (CloudFlare's PKI toolkit)

   - macOS: `brew install cfssl`
   - Linux: `sudo apt-get install golang-cfssl` or download from [CFSSL releases](https://github.com/cloudflare/cfssl/releases)
   - Verify: `cfssl version`

1. **Make** (GNU Make 3.81 or later)

   - macOS: Included with Xcode Command Line Tools or `brew install make`
   - Linux: `sudo apt-get install build-essential`
   - Verify: `make --version`

1. **OpenSSL** (for certificate verification)

   - macOS/Linux: Usually pre-installed
   - Verify: `openssl version`

### Optional Tools

- **curl** or **wget**: For testing endpoints (usually pre-installed)
- **jq**: For parsing JSON responses (`brew install jq` or `apt-get install jq`)

### System Requirements

- **Disk Space**: At least 10GB free for Docker images and registry storage
- **Memory**: Minimum 4GB RAM (8GB recommended for full monitoring stack)
- **Ports**: Ensure the following ports are available:
  - 5000: Registry API
  - 3000: Grafana
  - 9090: Prometheus
  - 16686: Jaeger UI
  - 3100: Loki
  - 12345: Alloy UI

### Docker Hub Account

You'll need a Docker Hub account for the pull-through cache functionality:

1. Create a free account at [hub.docker.com](https://hub.docker.com)
1. Note your username and password for the `.env` configuration

## Rootless Docker Setup

### 1. Remove Regular Docker (if installed)

```bash
sudo systemctl stop docker
sudo systemctl disable docker
sudo apt remove docker docker-engine docker.io containerd runc
```

### 2. Install Docker CE

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3. Install Rootless Docker

```bash
# Install rootless Docker
dockerd-rootless-setuptool.sh install

# Add to shell profile
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> ~/.bashrc
source ~/.bashrc
```

### 4. Start Rootless Docker

```bash
systemctl --user enable --now docker

# Verify installation
docker version
docker info
```

### 5. Configure Docker Daemon

```bash
# Create Docker configuration directory
mkdir -p ~/.config/docker

# Create daemon.json configuration
tee ~/.config/docker/daemon.json << 'EOF'
{
  "data-root": "/home/madmin/.config/containers/storage",
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "insecure-registries": [ "localhost:5000" ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  },
  "features": {
    "buildkit": true
  },
  "registry-mirrors": ["http://localhost:5000"]
}
EOF

# Restart Docker to apply configuration
systemctl --user restart docker
docker info  # Verify configuration
```

## Install and Configure Alloy

### 1. Download and Install Alloy

```bash
# Create local bin directory
mkdir -p ~/.local/bin

# Download Alloy
cd /tmp
wget https://github.com/grafana/alloy/releases/download/v1.9.2/alloy-linux-amd64.zip
unzip alloy-linux-amd64.zip
mv alloy-linux-amd64 ~/.local/bin/alloy
chmod +x ~/.local/bin/alloy

# Verify installation
~/.local/bin/alloy --version
```

### 2. Create Alloy Configuration

```bash
# Create config directory
mkdir -p ~/alloy

# Create configuration file
tee ~/alloy/config.alloy << 'EOF'
discovery.docker "containers" {
  host = "unix:///run/user/1000/docker.sock"
  refresh_interval = "5s"
}

discovery.relabel "containers" {
  targets = discovery.docker.containers.targets

  rule {
    source_labels = ["__meta_docker_container_name"]
    target_label  = "container"
  }

  rule {
    source_labels = ["__meta_docker_container_log_stream"]
    target_label  = "stream"
  }

  rule {
    source_labels = ["__meta_docker_container_id"]
    target_label  = "container_id"
  }

  rule {
    source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
    target_label  = "service"
  }
}

loki.source.file "docker_logs" {
  targets    = discovery.relabel.containers.output
  forward_to = [loki.process.docker_logs.receiver]
}

loki.process.docker_logs "docker_logs" {
  forward_to = [loki.write.loki.receiver]

  stage.json {
    expressions = {
      timestamp = "time",
      message   = "log",
    }
  }

  stage.timestamp {
    source = "timestamp"
    format = "RFC3339Nano"
  }

  stage.labels {
    values = {
      level = "level",
    }
  }
}

loki.write "loki" {
  endpoint {
    url = "http://localhost:3100/loki/api/v1/push"
  }
}

logging {
  level  = "info"
  format = "logfmt"
}
EOF
```

### 3. Create Systemd User Service

```bash
# Create user systemd directory
mkdir -p ~/.config/systemd/user

# Create service file
tee ~/.config/systemd/user/alloy.service << 'EOF'
[Unit]
Description=Grafana Alloy
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=%h
ExecStart=%h/.local/bin/alloy run %h/registry/alloy/config.alloy --server.http.listen-addr=0.0.0.0:12345 --storage.path=%h/.local/share/alloy
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Reload and enable service
systemctl --user daemon-reload
systemctl --user enable --now alloy

# Enable user services to start at boot (optional)
sudo loginctl enable-linger $USER
```

## Architecture

```mermaid
graph TB
    subgraph "External"
        DH[Docker Hub<br/>registry-1.docker.io]
        Client[Docker Client]
    end

    subgraph "Rootless Docker Environment"
        subgraph "Docker Compose Network"
            subgraph "Registry Service"
                Reg[Docker Registry<br/>:5000]
                TLS[TLS Certificates<br/>Self-signed]
                Cache[Pull-through Cache]

                Reg --> TLS
                Reg --> Cache
            end

            subgraph "Monitoring Stack"
                Jaeger[Jaeger<br/>:4318 OTLP]
                Prom[Prometheus<br/>:9090]
                Loki[Loki<br/>:3100]
                Grafana[Grafana<br/>:3000]

                Prom --> Grafana
                Jaeger --> Grafana
                Loki --> Grafana
            end

            subgraph "Rootless Docker Infrastructure"
                Docker[Rootless Docker Daemon<br/>~/.local/share/docker]
                Logs[Container Logs<br/>~/.local/share/docker/containers]
                Socket[Docker Socket<br/>/run/user/1000/docker.sock]

                Docker --> Logs
                Docker --> Socket
            end
        end

        subgraph "Native Services"
            Alloy[Grafana Alloy<br/>:12345<br/>Systemd User Service]

            Alloy -->|Read| Socket
            Alloy -->|Read| Logs
            Alloy -->|Push logs| Loki
        end
    end

    Client -->|HTTPS :5000| Reg
    Cache -->|Proxy| DH
    Reg -->|Traces| Jaeger
    Prom -->|Scrape :5001/metrics| Reg
    Prom -->|Scrape :14269| Jaeger

    style DH fill:#000000,color:#ffffff
    style Client fill:#000000,color:#ffffff
    style Reg fill:#2496ed
    style Jaeger fill:#60d0e4,color:#000000
    style Prom fill:#e6522c
    style Loki fill:#ff0000,color:#ffffff
    style Alloy fill:#800080,color:#ffffff
    style Grafana fill:#f46800
    style TLS fill:#404040,color:#ffffff
    style Cache fill:#404040,color:#ffffff
    style Docker fill:#00ff00,color:#000000
    style Logs fill:#404040,color:#ffffff
    style Socket fill:#404040,color:#ffffff
```

## Available Commands

Run `make help` to see all available commands:

```bash
make help         # Show all available commands
make quickstart   # One-command setup: generates certs and starts services
make certs        # Generate all TLS certificates
make up           # Start all services
make down         # Stop all services
make status       # Check service status and URLs
make logs         # View logs from all services
make clean        # Stop services and remove volumes

# TLS configuration
make configure-docker-tls                # Configure Docker to trust registry
make trust-cert                          # Trust CA in system keychain (macOS)

# Registry API commands
make list-repos                          # List all repositories
make list-tags REPO=library/alpine       # List tags for a repository
make get-manifest REPO=library/alpine TAG=latest  # Get image manifest

# Alloy management
make alloy-start                         # Start Alloy service
make alloy-stop                          # Stop Alloy service
make alloy-status                        # Check Alloy status
make alloy-logs                          # View Alloy logs
```

## Quick Start

1. **Set up environment variables**:

   ```bash
   cat <<EOF > .env
   REGISTRY_PROXY_USERNAME=<your_docker_hub_username>
   REGISTRY_PROXY_PASSWORD=<your_docker_hub_password>
   GF_SECURITY_ADMIN_USER=admin
   GF_SECURITY_ADMIN_PASSWORD=admin
   EOF
   ```

1. **Setup rootless Docker** (if not already done):

   Follow the [Rootless Docker Setup](#rootless-docker-setup) section above.

1. **Install and configure Alloy** (if not already done):

   Follow the [Install and Configure Alloy](#install-and-configure-alloy) section above.

1. **Quick start (generates certs and starts services)**:

   ```bash
   make quickstart
   ```

1. **Start Alloy service**:

   ```bash
   systemctl --user start alloy
   ```

1. **Configure Docker to trust the registry**:

   ```bash
   # Required: Configure Docker daemon to trust the registry
   make configure-docker-tls

   # Optional: Add to system keychain (macOS)
   make trust-cert
   ```

1. **Access services**:

   ```bash
   make status  # Shows all service URLs and status
   ```

   Service URLs:

   - Registry API: <https://localhost:5000/v2/> (Docker Registry HTTP API V2)
   - Grafana: <http://localhost:3000> (admin/admin)
   - Prometheus: <http://localhost:9090>
   - Jaeger: <http://localhost:16686>
   - Loki: <http://localhost:3100>
   - Alloy: <http://localhost:12345> (Grafana Alloy UI)

1. **View logs in Grafana**:

   - Navigate to <http://localhost:3000>
   - Login with admin/admin
   - Go to Explore → Select Loki datasource
   - Try queries like `{container="registry"}` or `{job="docker_logs"}`

## CFSSL Configuration

Before generating certificates, you need to customize the CFSSL configuration files for your environment. The following files contain default values that should be updated:

### 1. Root CA Configuration (`cfssl/ca.json`)

Edit the following fields in `cfssl/ca.json`:

```json
{
  "CN": "Smigula Root CA",     // Replace with your root CA name
  "names": [{
    "C": "US",                           // Your country code
    "L": "Tampa",                    // Your city
    "O": "Smigula",            // Your organization name
    "OU": "development",             // Your department/unit
    "ST": "FL"                   // Your state/province
  }]
}
```

### 2. Intermediate CA Configuration (`cfssl/intermediate-ca.json`)

Update the same fields in `cfssl/intermediate-ca.json`:

```json
{
  "CN": "Smigula Intermediate CA",
  "names": [{
    "C": "US",
    "L": "Tampa",
    "O": "Smigula",
    "OU": "development",
    "ST": "FL"
  }],
  "ca": {
    "expiry": "42720h"    // 5 years - adjust as needed
  }
}
```

### 3. Registry Certificate Configuration (`cfssl/registry.json`)

This is the most important configuration to customize:

```json
{
  "CN": "registry.smigula.io",        // Your registry's FQDN
  "hosts": [
    "registry.smigula.io",            // Your registry's domain
    "registry",                           // Short hostname
    "localhost",                          // Keep for local testing
    "127.0.0.1",                          // Localhost IP
    "10.0.0.100"                          // Your registry's IP (if static)
  ],
  "names": [{
    "C": "US",
    "L": "Tampa",
    "O": "Smigula",
    "OU": "development",
    "ST": "FL"
  }]
}
```

### 4. Certificate Profiles (`cfssl/cfssl.json`)

The default profiles are suitable for most use cases, but you can adjust certificate expiry times:

```json
{
  "signing": {
    "profiles": {
      "intermediate_ca": {
        "expiry": "8760h",    // 1 year - adjust as needed
        ...
      },
      "server": {
        "expiry": "8760h",    // 1 year for server certs
        ...
      }
    }
  }
}
```

### Common Customizations

1. **For Local Development**:

   - Keep "localhost" and "127.0.0.1" in the hosts array
   - Add your machine's hostname
   - Use a simple organization name like "Development"

1. **For Production**:

   - Use proper FQDN for the registry
   - Add all possible access names (load balancer DNS, service names, etc.)
   - Set appropriate certificate expiry times
   - Use official organization details

1. **For Kubernetes**:

   - Add service names: `registry.namespace.svc.cluster.local`
   - Add service IPs if using ClusterIP
   - Include any ingress hostnames

### Example for Local Development

Here's a complete example for local development:

```bash
# Edit ca.json
sed -i '' 's/Smigula Root CA/My Local Root CA/g' cfssl/ca.json
sed -i '' 's/Smigula/My Organization/g' cfssl/ca.json
sed -i '' 's/Tampa/My City/g' cfssl/ca.json
sed -i '' 's/FL/My State/g' cfssl/ca.json

# Edit registry.json for local use
cat > cfssl/registry.json <<EOF
{
  "CN": "localhost",
  "hosts": [
    "localhost",
    "127.0.0.1",
    "registry",
    "registry.local",
    "*.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "US",
    "L": "My City",
    "O": "My Organization",
    "OU": "Development",
    "ST": "My State"
  }]
}
EOF
```

## Certificate Generation with CFSSL

After customizing the configuration files, you can generate the certificates. This setup uses a proper PKI hierarchy with root and intermediate CAs:

```bash
# Generate all certificates at once
make certs

# Or generate them step by step:
make cert-ca              # Generate root CA
make cert-intermediate    # Generate intermediate CA
make cert-registry        # Generate registry certificates

# Verify the certificate chain
make verify-certs
```

The Makefile automates the following steps:

1. Generates root CA certificate
1. Generates intermediate CA certificate
1. Signs intermediate CA with root CA
1. Generates registry certificates (peer, server, client profiles)
1. Creates certificate chain for the registry

## Registry Configuration

The Docker Registry is configured via `config.yaml`. For detailed configuration options, see the [official registry documentation](https://distribution.github.io/distribution/about/configuration/).

### Key Configuration Settings

Our configuration (`config.yaml`) includes:

#### Storage Configuration

```yaml
storage:
  delete:
    enabled: true                         # Allows deletion of image blobs
  cache:
    blobdescriptor: inmemory              # In-memory cache for blob metadata
  filesystem:
    rootdirectory: /var/lib/registry
```

#### HTTP/TLS Configuration

```yaml
http:
  addr: :5000                               # Main API port
  debug:
    addr: :5001                             # Debug/metrics endpoint
    prometheus:
      enabled: true                         # Expose Prometheus metrics
      path: /metrics
  tls:
    certificate: /etc/ssl/certs/domain.crt  # Full cert chain
    key: /etc/ssl/private/domain.key        # Private key
    minimumtls: tls1.2                      # Enforce TLS 1.2 minimum
```

#### Proxy Cache Configuration

```yaml
proxy:
  remoteurl: https://registry-1.docker.io  # Docker Hub
  username: ${DOCKER_HUB_USERNAME}         # From environment
  password: ${DOCKER_HUB_PASSWORD}         # From environment
```

#### Health Checks

```yaml
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

## Services Architecture

### Docker Registry (port 5000)

- **Purpose**: Local Docker image storage and Docker Hub proxy cache
- **Features**:
  - TLS encryption with self-signed certificates
  - Pull-through cache for Docker Hub
  - OpenTelemetry tracing to Jaeger
  - Prometheus metrics exposure
- **API Endpoints** (accessible at `https://localhost:5000`):
  - `/v2/` - API version check
  - `/v2/_catalog` - List all repositories
  - `/v2/{name}/tags/list` - List tags for a repository
  - `/v2/{name}/manifests/{reference}` - Get/Put/Delete manifests
  - `/v2/{name}/blobs/{digest}` - Get/Put/Delete blobs
- **Internal endpoints**:
  - `:5000` - Main API (mapped to host port 5000)
  - `:5001` - Debug/metrics (internal only)

### Jaeger (port 16686)

- **Purpose**: Distributed tracing for registry operations
- **Features**:
  - Collects traces via OTLP protocol
  - Provides trace visualization and analysis
- **Internal endpoints**:
  - `:4317` - OTLP gRPC
  - `:4318` - OTLP HTTP
  - `:14269` - Metrics for Prometheus

### Prometheus (port 9090)

- **Purpose**: Metrics collection and storage
- **Scrape targets**:
  - Docker Registry metrics (HTTP with mutual TLS authentication)
  - Jaeger metrics
  - Self-monitoring
- **Configuration**: `prometheus/prometheus.yml`
- **TLS Setup**: Uses registry certificates for client authentication when scraping metrics
- **Rootless considerations**: Uses init container to set proper permissions

### Loki (port 3100)

- **Purpose**: Log aggregation system for collecting and querying logs
- **Features**:
  - Collects logs from Docker containers via Grafana Alloy
  - Supports LogQL query language for log searching
  - Uses TSDB (Time Series Database) index for efficient storage
  - Schema v13 with structured metadata support
  - 7-day retention policy with automatic cleanup
  - Integrates seamlessly with Grafana for visualization
- **Configuration**: `loki/loki-config.yaml`
  - Storage: Filesystem-based with TSDB shipper
  - Retention: 168 hours (7 days)
  - Ingestion limits: 4MB/s rate, 6MB burst
- **Internal endpoints**:
  - `:3100/ready` - Health check endpoint
  - `:3100/loki/api/v1/push` - Log ingestion endpoint
  - `:3100/loki/api/v1/query_range` - Query endpoint for log ranges
- **Rootless considerations**: Uses init container to set proper permissions (UID 10001)

### Grafana Alloy (port 12345) - Native Installation

- **Purpose**: Modern observability collector running as native systemd user service
- **Features**:
  - Automatically discovers Docker containers via rootless Docker socket
  - Collects and processes container logs from `~/.local/share/docker/containers`
  - Extracts metadata and labels from containers
  - Parses JSON log format and extracts fields
  - Provides a web UI for monitoring collection status
  - Supports complex processing pipelines
- **Configuration**: `~/alloy/config.alloy`
- **Service Management**: `systemctl --user {start|stop|status} alloy`
- **UI Access**: <http://localhost:12345>
- **Rootless advantages**:
  - Direct access to rootless Docker socket (`/run/user/1000/docker.sock`)
  - No namespace isolation issues
  - Better performance than containerized version
  - Easier debugging and configuration

### Grafana (port 3000)

- **Purpose**: Metrics visualization and dashboards
- **Features**:
  - Pre-configured datasources (Prometheus, Jaeger, Loki)
  - Docker Registry dashboard included
  - Log exploration with Loki integration
  - Anonymous viewer access enabled
- **Default credentials**: Configured in `.env`

## Docker Compose Configuration

The docker-compose.yml has been optimized for rootless Docker:

```yaml
services:
  # Prometheus init container for permissions
  prometheus-init:
    image: alpine:latest
    container_name: prometheus-init
    volumes:
      - prometheus-data:/prometheus
    command: >
      sh -c "
        chown -R 65534:65534 /prometheus &&
        chmod -R 755 /prometheus
      "
    restart: "no"

  # Loki init container for permissions
  loki-init:
    image: alpine:latest
    container_name: loki-init
    volumes:
      - loki-data:/loki
    command: >
      sh -c "
        chown -R 10001:10001 /loki &&
        chmod -R 755 /loki
      "
    restart: "no"

  # Note: Alloy service is removed from docker-compose
  # It runs as a native systemd user service instead
```

**Key changes for rootless Docker**:

- Added init containers to fix volume permissions
- Removed Alloy from docker-compose (runs natively)
- Updated health checks and dependencies
- Optimized for user namespace isolation

## Testing the Registry

### Configure Docker to Trust the Registry

Before Docker can communicate with the registry, you need to configure both TLS trust and registry mirroring:

#### Step 1: Configure TLS Trust

##### Option A: Configure Docker daemon certificates (Recommended)

**Rootless Docker:**

```bash
# Create Docker certificate directory for the registry
mkdir -p ~/.docker/certs.d/localhost:5000

# Copy the CA certificate (required)
cp certs/ca.pem ~/.docker/certs.d/localhost:5000/ca.crt

# Optional: For mutual TLS authentication
cp certs/registry-peer.pem ~/.docker/certs.d/localhost:5000/client.cert
cp certs/registry-peer-key.pem ~/.docker/certs.d/localhost:5000/client.key
chmod 644 ~/.docker/certs.d/localhost:5000/client.cert
chmod 600 ~/.docker/certs.d/localhost:5000/client.key
```

**Linux (Regular Docker):**

```bash
# Create Docker certificate directory for the registry
sudo mkdir -p /etc/docker/certs.d/localhost:5000

# Copy the CA certificate (required)
sudo cp certs/ca.pem /etc/docker/certs.d/localhost:5000/ca.crt

# Set proper permissions
sudo chmod 644 /etc/docker/certs.d/localhost:5000/ca.crt

# Optional: For mutual TLS authentication
sudo cp certs/registry-peer.pem /etc/docker/certs.d/localhost:5000/client.cert
sudo cp certs/registry-peer-key.pem /etc/docker/certs.d/localhost:5000/client.key
sudo chmod 644 /etc/docker/certs.d/localhost:5000/client.cert
sudo chmod 600 /etc/docker/certs.d/localhost:5000/client.key
```

##### Option B: System-wide trust (macOS)

```bash
# This command adds all certificates to system keychain
make trust-cert

# Or manually add each certificate:
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca.pem
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/intermediate_ca.pem
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/registry-server.pem
```

#### Step 2: Configure Docker Hub Mirror

To use this registry as a pull-through cache for Docker Hub, update your Docker daemon configuration:

##### Rootless Docker

```bash
# Edit daemon configuration
nano ~/.config/docker/daemon.json

# Add or update the configuration:
{
  "registry-mirrors": ["https://localhost:5000"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  },
  "storage-driver": "overlay2",
  "features": {
    "buildkit": true
  },
  "insecure-registries": ["localhost:5000"]
}

# Restart Docker
systemctl --user restart docker
```

##### macOS (Docker Desktop)

1. Open Docker Desktop preferences
1. Go to Docker Engine settings
1. Update the JSON configuration:

```json
{
  "registry-mirrors": ["https://localhost:5000"]
}
```

4. Click "Apply & Restart"

##### Linux (Regular Docker)

1. Edit or create `/etc/docker/daemon.json`:

```bash
sudo nano /etc/docker/daemon.json
```

2. Add or update the configuration:

```json
{
  "registry-mirrors": ["https://localhost:5000"]
}
```

3. Restart Docker:

```bash
sudo systemctl restart docker
```

##### Verify Mirror Configuration

```bash
# Check Docker daemon configuration
docker info | grep -A1 "Registry Mirrors"

# Should show:
# Registry Mirrors:
#  https://localhost:5000/
```

### Test Registry Access

1. **Test the registry mirror (pull-through cache)**:

   ```bash
   # With registry-mirrors configured, this automatically uses your local registry
   docker pull alpine:latest

   # Check that the image was cached in your registry
   curl -sk https://localhost:5000/v2/_catalog
   # Should show: {"repositories":["library/alpine"]}
   ```

1. **Test direct registry access**:

   ```bash
   # Pull directly from the registry (bypasses mirror config)
   make test-pull
   # Or: docker pull localhost:5000/library/alpine:latest
   ```

1. **Test pushing to the registry**:

   ```bash
   # Push a local image to the registry
   make test-push
   # Or: docker tag alpine:latest localhost:5000/myimage:latest
   #     docker push localhost:5000/myimage:latest
   ```

   Note: When configured as a mirror, the registry only caches images from Docker Hub.
   To push your own images, you must use the full registry URL (localhost:5000).

1. **Access the Registry API directly**:

   The registry implements the [Docker Registry HTTP API V2](https://docs.docker.com/registry/spec/api/). Common endpoints:

   ```bash
   # Check registry availability
   curl -k https://localhost:5000/v2/

   # List all repositories
   curl -k https://localhost:5000/v2/_catalog

   # List tags for a specific repository
   curl -k https://localhost:5000/v2/library/alpine/tags/list

   # Get manifest for a specific tag
   curl -k https://localhost:5000/v2/library/alpine/manifests/latest

   # Get image configuration
   curl -k -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        https://localhost:5000/v2/library/alpine/manifests/latest
   ```

   Note: The registry does not have a web UI. All interactions are through the Docker client or the HTTP API.

## Monitoring and Observability

### Grafana Dashboard

1. Access at <http://localhost:3000>
1. Login with configured credentials
1. Navigate to **Dashboards → Docker Registry**
1. Monitor:
   - HTTP request rates and latencies
   - Cache hit ratios
   - Response code distribution
   - Storage metrics
1. For log exploration:
   - Navigate to **Explore → Loki**
   - Query registry logs using LogQL

### Prometheus Queries

Access at <http://localhost:9090> and try these queries:

```promql
# Request rate by method
rate(registry_http_requests_total[5m])

# 99th percentile latency
histogram_quantile(0.99, rate(registry_http_request_duration_seconds_bucket[5m]))

# Cache hit ratio
rate(registry_storage_cache_hits_total[5m]) / rate(registry_storage_cache_requests_total[5m])
```

### Jaeger Traces

1. Access at <http://localhost:16686>
1. Select service: `docker-registry`
1. View traces for:
   - Image pulls/pushes
   - Manifest operations
   - Blob uploads/downloads

### Loki Log Queries

Access Loki through Grafana's Explore interface or use these example LogQL queries:

```logql
# View all Docker container logs
{job="docker_logs"}

# View logs from the registry container
{container="registry"}

# Filter by compose service
{service="registry"}

# Filter registry logs by level
{container="registry"} |= "level=error"

# Search for specific operations in registry
{container="registry"} |= "pull" |= "manifest"

# View logs from all monitoring stack containers
{compose_project="registry"} |> {container=~"registry|prometheus|grafana|loki"}

# Parse and filter registry logs by HTTP status
{container="registry"} | json | line_format "{{.log}}" | regexp `(?P<method>\S+)\s+(?P<path>\S+)\s+(?P<status>\d{3})` | status >= 400

# Show logs for specific image pulls
{container="registry"} |= "library/alpine"

# Rate of errors over time
rate({container="registry"} |= "error" [5m])
```

## Management Commands

### Docker Compose Operations

```bash
# Start all services
make up

# Stop all services
make down

# Restart all services
make restart

# View logs
make logs              # All services
make logs-registry     # Registry only
make logs-prometheus   # Prometheus only
make logs-grafana      # Grafana only
make logs-jaeger       # Jaeger only
make logs-loki         # Loki only

# Clean up (including volumes)
make clean

# Check service status
make status
```

### Registry Maintenance

```bash
# Garbage collection (remove unused blobs)
make gc

# Check registry health
make health

# List repositories in registry
curl -k https://localhost:5000/v2/_catalog

# Get repository tags
curl -k https://localhost:5000/v2/<repository>/tags/list

# View registry metrics
make metrics
```

### Alloy Management

```bash
# Start Alloy service
systemctl --user start alloy
# Or: make alloy-start

# Stop Alloy service
systemctl --user stop alloy
# Or: make alloy-stop

# Check Alloy status
systemctl --user status alloy
# Or: make alloy-status

# View Alloy logs
journalctl --user -u alloy -f
# Or: make alloy-logs

# Restart Alloy service
systemctl --user restart alloy

# Access Alloy UI
curl http://localhost:12345
# Or open http://localhost:12345 in browser
```

## Security Considerations

1. **Rootless Docker**: Provides better security isolation with user-namespace separation
1. **Self-signed certificates**: Not suitable for production environments
1. **Credentials**: Stored in `.env` file - ensure it's in `.gitignore`
1. **Network isolation**: Internal service ports not exposed to host
1. **TLS enforcement**: Minimum TLS 1.2 with strong cipher suites
1. **Mutual TLS**: Prometheus authenticates to registry using client certificates
1. **User services**: Alloy runs as user service with limited privileges
1. **Socket access**: Rootless Docker socket has restricted access
1. **Volume permissions**: Init containers ensure proper ownership

## Troubleshooting

### Rootless Docker Issues

1. **Docker daemon not starting**:

   ```bash
   # Check rootless Docker status
   systemctl --user status docker

   # Check for namespace issues
   echo $XDG_RUNTIME_DIR
   ls -la /run/user/$(id -u)/docker.sock

   # Restart rootless Docker
   systemctl --user restart docker
   ```

1. **Resource control warnings**:

   ```bash
   # Expected warnings in docker info (these are normal)
   WARNING: No cpuset support
   WARNING: No io.weight support

   # Enable cgroup delegation if needed
   sudo mkdir -p /etc/systemd/system/user@.service.d
   sudo tee /etc/systemd/system/user@.service.d/delegate.conf << 'EOF'
   [Service]
   Delegate=cpu cpuset io memory pids
   EOF
   sudo systemctl daemon-reload
   sudo systemctl restart user@$(id -u).service
   ```

### Alloy Issues

1. **Cannot connect to Docker socket**:

   ```bash
   # Check socket path and permissions
   ls -la /run/user/$(id -u)/docker.sock

   # Verify Alloy configuration
   ~/.local/bin/alloy fmt ~/alloy/config.alloy

   # Test manually
   ~/.local/bin/alloy run ~/alloy/config.alloy --server.http.listen-addr=0.0.0.0:12345
   ```

1. **Service fails to start**:

   ```bash
   # Check service logs
   journalctl --user -u alloy -f

   # Verify binary location
   ls -la ~/.local/bin/alloy

   # Check service configuration
   systemctl --user cat alloy
   ```

1. **No containers discovered**:

   ```bash
   # Access Alloy UI to debug
   curl http://localhost:12345

   # Check if Docker is running containers
   docker ps

   # Verify socket access
   docker version
   ```

### Volume Permission Issues

1. **Prometheus/Loki permission denied**:

   ```bash
   # Check init containers ran successfully
   docker-compose logs prometheus-init
   docker-compose logs loki-init

   # Manual permission fix if needed
   docker run --rm -v prometheus-data:/data alpine chown -R 65534:65534 /data
   docker run --rm -v loki-data:/data alpine chown -R 10001:10001 /data
   ```

1. **Volume ownership issues**:

   ```bash
   # Remove and recreate volumes
   docker-compose down
   docker volume rm $(docker-compose config --volumes)
   docker-compose up -d
   ```

### Certificate Issues

```bash
# Verify certificate chain
make verify-certs

# Test TLS connection
make test-tls

# Check Docker certificate configuration
ls -la ~/.docker/certs.d/localhost:5000/  # Rootless
ls -la /etc/docker/certs.d/localhost:5000/ # Regular Docker
```

### Registry Connection Issues

```bash
# Check if registry is responding
make health

# Test specific API endpoints
curl -k https://localhost:5000/v2/
curl -k https://localhost:5000/v2/_catalog

# View detailed logs
make logs-registry

# Check Docker daemon configuration
docker info | grep -A1 "Registry Mirrors"
```

### Metrics Not Appearing

1. Check Prometheus targets:

   ```bash
   make prometheus-targets
   ```

1. Verify registry metrics endpoint:

   ```bash
   make metrics
   ```

1. Check Prometheus logs:

   ```bash
   make logs-prometheus
   ```

1. Verify TLS certificates are properly mounted in Prometheus container:

   ```bash
   make verify-prometheus-certs
   ```

## File Structure

```text
.
├── cfssl/                    # Certificate configurations
│   ├── ca.json               # Root CA config
│   ├── intermediate-ca.json  # Intermediate CA config
│   ├── cfssl.json            # Certificate profiles
│   └── registry.json         # Registry certificate config
├── certs/                    # Generated certificates (git ignored)
├── prometheus/               # Prometheus configuration
│   └── prometheus.yml        # Scrape configurations with TLS client auth
├── loki/                     # Loki configuration
│   └── loki-config.yaml      # Loki server configuration
├── grafana/                  # Grafana provisioning
│   └── provisioning/
│       ├── datasources/      # Pre-configured datasources (Prometheus, Jaeger, Loki)
│       └── dashboards/       # Pre-configured dashboards
├── config.yaml               # Registry configuration
├── docker-compose.yaml       # Service definitions (without Alloy)
├── .env.example              # Environment template
├── .gitignore                # Git ignore patterns
└── README.md                 # This file

# User-specific files (rootless Docker)
~/.config/docker/daemon.json  # Docker daemon configuration
~/.local/bin/alloy            # Alloy binary
~/alloy/config.alloy          # Alloy configuration
~/.config/systemd/user/alloy.service  # Alloy systemd service
~/.local/share/docker/        # Docker data directory
~/.local/share/alloy/         # Alloy data directory
```

## Performance Tuning

- **Cache size**: Adjust blob descriptor cache size for larger deployments
- **Concurrent operations**: Modify `tag.concurrencylimit` based on load
- **Storage driver**: Consider S3 or other drivers for production
- **Resource limits**: Add CPU/memory limits in docker-compose.yaml
- **Rootless optimizations**:
  - Use cgroup delegation for better resource control
  - Consider running critical services natively (like Alloy)
  - Monitor resource usage with `docker stats`

## References

- [Docker Registry Configuration Reference](https://distribution.github.io/distribution/about/configuration/)
- [Docker Hub Registry Mirror Documentation](https://docs.docker.com/docker-hub/image-library/mirror/)
- [Rootless Docker Documentation](https://docs.docker.com/engine/security/rootless/)
- [CFSSL Documentation](https://github.com/cloudflare/cfssl)
- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/)
- [OpenTelemetry Registry Instrumentation](https://opentelemetry.io/)
- [Loki LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
